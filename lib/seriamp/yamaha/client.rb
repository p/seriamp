# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/yamaha/protocol/methods'
require 'seriamp/yamaha/protocol/get_constants'
require 'seriamp/yamaha/protocol/status'
require 'seriamp/yamaha/protocol/extended/response_base'
require 'seriamp/yamaha/protocol/extended/generic_response'
require 'seriamp/yamaha/protocol/extended/distance_response'
require 'seriamp/yamaha/protocol/extended/graphic_eq_response'
require 'seriamp/yamaha/protocol/extended/parametric_eq_response'
require 'seriamp/yamaha/protocol/extended/main_tone_response'
require 'seriamp/yamaha/protocol/extended/volume_trim_response'
require 'seriamp/yamaha/protocol/extended/io_assignment_response'
require 'seriamp/yamaha/protocol/extended/input_label_response'
require 'seriamp/yamaha/parser'
require 'seriamp/client'

module Seriamp
  module Yamaha

    class Client < Seriamp::Client
      include Parser

      # Yamahas do not care what flow control is set to.
      MODEM_PARAMS = {
        baud: 9600,
        data_bits: 8,
        stop_bits: 1,
        parity: 0, # SerialPort::NONE
      }.freeze

      # The manual says response should be received in 500 ms.
      # However, the status response takes 850 ms to be received in my
      # environment (RX-V1500/1800/2500).
      # 1 second is insufficient here to turn the receiver on after it has
      # just been powered off.
      # For RX-V2700, this timeout is insufficient when powering up
      # the receiver from standby.
      DEFAULT_RS232_TIMEOUT = 2

      include Protocol::Methods

      def present?
        # TODO find a faster command to issue
        status
        true
      end

      def status_string
        with_lock do
          with_retry do
            with_device do
              dispatch(STATUS_REQ)
              # There could potentialy be multiple responses here if
              # receiver is sending status updates to host?
              extract_one_response!
            end
          end
        end
      end

      def status
        with_lock do
          with_retry do
            with_device do
              resp = nil
              status = dispatch_and_parse(STATUS_REQ)
              # Device could have been closed by now.
              # TODO keep the device open the entire time if thread safety
              # (locking) is enabled.
              if @io
                buf = Utils.consume_data(@io, logger,
                  "Serial device readable after completely reading status response - concurrent access?")
                report_unread_response(buf)
              end

              @model_code, @version, @status_string =
                status.fetch(:model_code), status.fetch(:firmware_version),
                status.fetch(:raw_string)
              @status = status
            end
          end
        end
      end

      def all_status
        status.merge(
          all_io_assignments,
          tone,
          volume_trim,
        )
      end

      def current_status
        unless @current_status
          status
        end
        @current_status.dup
      end

      def clear_cache
        @status = nil
      end

      %i(
        model_code firmware_version system_status power main_power zone2_power
        zone3_power input input_name audio_source program_select
        main_volume zone2_volume zone3_volume
        program program_name sleep night night_name
        format sample_rate
      ).each do |meth|
        define_method(meth) do
          status.fetch(meth)
        end
      end

      alias main_input_name input_name

      %i(
        multi_ch_input effect pure_direct speaker_a speaker_b
      ).each do |meth|
        define_method("#{meth}?") do
          status.fetch(meth)
        end
      end

      # Shows a message via the on-screen display. The message must be 16
      # characters or fewer. The message is NOT displayed on the front panel,
      # it is shown only on the connected TV's OSD.
      def osd_message(msg)
        if msg.length < 16
          msg = msg.dup
          while msg.length < 16
            msg += ' '
          end
        elsif msg.length > 16
          raise ArgumentError, "Message must be no more than 16 characters, #{msg.length} given"
        end

        with_lock do
          with_retry do
            with_device do
              @io.syswrite("#{STX}21000#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[0..3]}#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[4..7]}#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[8..11]}#{ETX}".encode('ascii'))
              @io.syswrite("#{STX}3#{msg[12..15]}#{ETX}".encode('ascii'))
              @io.clear_rts
            end
          end
        end

        nil
      end

      def remote_command(cmd, read_response: true, expect_response_state: nil, include_response_state: nil)
        if expect_response_state || include_response_state and !read_response
          raise ArgumentError, "Cannot accept response requirements when asked not to read the response"
        end
        with_lock do
          with_retry do
            cmd = "#{STX}0#{cmd}#{ETX}"
            dispatch(cmd, read_response: false)
            if read_response
              resp = nil
              # Response should have been to our RS-232 command, verify.
              loop do
                with_device do
                  self.read_response
                end
                resp = get_command_response
                # +resp+ here could be a status response that the receiver just
                # sends out when it wasn't requested (either trying to be
                # helpful for "power on" command specifically, or maybe
                # periodically in general).
                # The status response doesn't have a control type, and
                # it's presently returned as a hash.
                # TODO have the response type be explicit here somehow.
                if Hash === resp && resp.key?(:ready)
                  # Status response
                  update_current_status(resp)
                  logger&.debug("Received status response in response to command - continuing to read looking for a command response")
                  next
                end
                begin
                  control_type = resp.fetch(:control_type)
                rescue KeyError
                  raise NotImplementedError, "Response was missing control type: #{resp}"
                end
                if control_type != :rs232
                  # Receiver can be sending system responses, ignore them.
                  #raise UnhandledResponse, "Response was not to our command: #{resp}"
                  update_current_status(resp)
                  next
                end
                if expect_response_state && !resp.fetch(:state).keys.include?(expect_response_state)
                  logger&.debug("Wanted state: #{expect_response_state}; continuing to read")
                  next
                end
                break
              end
              resp.fetch(:state)
            end
          end
        end
      end

      def system_command(cmd)
        with_lock do
          with_retry do
            resp = dispatch_and_parse("#{STX}2#{cmd}#{ETX}")
            if resp.fetch(:control_type) != :rs232
              raise "Wrong control type: #{resp[:control_type]}"
            end
            if guard = resp[:guard]
              raise NotApplicable, "Command guarded by '#{guard}'"
            end
            resp[:state]
          end
        end
      end

      def extended_command(cmd)
        payload = "20#{'%02X' % cmd.length}#{cmd}"
        checksum = calculate_checksum(payload)
        with_lock do
          with_retry do
            resp = dispatch_and_parse("#{DC4}#{payload}#{checksum}#{ETX}")
          end
        end
      end

      private

      include Protocol::GetConstants

      # ASCII table: https://www.asciitable.com/
      DC1 = ?\x11
      DC2 = ?\x12
      DC4 = ?\x14
      ETX = ?\x03
      STX = ?\x02
      DEL = ?\x7f

      STATUS_REQ = "#{DC1}001#{ETX}"

      ZERO_ORD = '0'.ord

      def response_complete?
        read_buf.end_with?(self.class.const_get(:ETX))
      end

      def extract_one_response
        extract_delimited_response(self.class.const_get(:ETX))
      end

      def parse_response(resp)
        case first_byte = resp[0]
        when STX
          parse_framed_stx_response(resp).tap do |resp|
            # Sometimes the response isn't parsed (yet) by seriamp,
            # which causes state to be missing here...
            begin
              state = resp.fetch(:state)
            rescue KeyError
              raise NotImplementedError, "Response was missing state: #{resp}"
            end
            update_current_status(state)
          end
        when DC2
          parse_status_response(resp).tap do |resp|
            update_current_status(resp)
          end
        when DC4
          parse_extended_response(resp[1...-1]).tap do |resp|
            if resp
              # Extended commands have empty responses, i.e. the receiver
              # does not report the state back.
              # We need to store the state ourselves then based on the
              # issued command or perform a query.
              update_current_status(resp.to_state)
            end
          end
        else
          raise NotImplementedError, "\\x#{'%02x' % first_byte.ord} first response byte not handled"
        end
      end

      def update_current_status(resp)
        logger&.debug("Updating current status: #{resp}")
        if @current_status &&
          @current_status[:model_code] && resp[:model_code] &&
          @current_status[:model_code] != resp[:model_code]
        then
          @current_status = nil
        end
        if @current_status
          @current_status.update(resp)
        else
          @current_status = resp.dup
        end
      end

      def parse_extended_response(resp)
        unless resp[..1] == '20'
          raise UnexpectedResponse, "Invalid response: expected to start with 20: #{resp} #{resp[0].ord}"
        end
        length = Integer(resp[2..3], 16)
        received_checksum = resp[-2..]
        calculated_checksum = calculate_checksum(resp[...-2])
        if received_checksum != calculated_checksum
          raise UnexpectedResponse, "Broken status response: calculated checksum #{calculated_checksum}, received checksum #{received_checksum}: #{data}"
        end
        data = resp[4...-2]

        if length != data.length
          raise UnexpectedResponse, "Advertised data length does not match actual data received: #{length} vs #{data.length}"
        end

        if data.empty?
          raise InvalidCommand, "Extended command not recognized"
        end

        command_id = data[...3]
        status = data[3]
        command_data = data[4..]

        case status
        when '0'
          # OK
        when '1'
          raise UnexpectedResponse, "Guard by system: #{data}"
        when '2'
          raise UnexpectedResponse, "Guard by setting: #{data}"
        when '3'
          raise InvalidCommand, "Unrecognized command: #{data}"
        when '4'
          raise InvalidCommand, "Command parameter error: #{data}"
        else
          raise UnexpectedResponse, "Unexpected status byte: #{status}: #{data}"
        end

        if command_data.empty?
          return nil
        end

        # Special case for input labels...
        # Apparently the receiver returns the "rename id" but no subsequent
        # fields.
        if command_id == '011' && command_data == '0'
          return nil
        end

        cls = Yamaha::Protocol::Extended::ResponseBase.registered_responses[command_id] ||
          Protocol::Extended::GenericResponse
        cls&.new(command_id, command_data)
      end

      def parse_framed_stx_response(resp)
        unless resp[0] == STX
          raise UnexpectedResponse, "Invalid response: expected to start with STX: #{resp} #{resp[0].ord}"
        end
        unless resp[-1] == ETX
          raise UnexpectedResponse, "Invalid response: expected to end with ETX: #{resp}"
        end
        parse_stx_response(resp[1...-1])
      end

      # TODO what happens to surround back channels when there's only one?
      CHANNEL_KEYS = %i(
        front_left
        front_right
        center
        surround_left
        surround_right
        surround_back_left
        surround_back_right
        subwoofer
        presence_left
        presence_right
      ).freeze

      def parse_stx_response(resp)
        control_type = parse_flag(resp[0], {
          '0' => :rs232,
          '1' => :remote,
          '2' => :key,
          '3' => :system,
          '4' => :encoder,
        }, 'Invalid control type value')
        guard = parse_flag(resp[1], {
          '0' => nil,
          '1' => :system,
          '2' => :setting,
        }, 'Invalid guard value')
        command = resp[2..3]
        data = resp[4..5]
        logger&.debug("Command response: #{command} #{data}")
        state = if field_name_or_spec = GET_MAP[command]
          case field_name_or_spec
          when Array
            field_name = field_name_or_spec.first
            const_name = field_name_or_spec.last
          else
            field_name = const_name = field_name_or_spec
          end
          map = self.class.const_get("#{const_name.upcase}_GET")
          # Value can be nil, e.g. lfe_indicator (when value is "---" in the
          # documentation).
          unless map.key?(data)
            logger&.warn("Unhandled value #{data} for #{command} (#{field_name})")
          end
          value = map[data]
          unless Hash === value
            value = {field_name => value}
          end
          value
        else
          case command
          when '15'
            if data.length != 2
              raise NotImplementedError
            end
            value = case Integer(data, 16)
            when 0xFF
              nil
            when 0x00..0x1F
              parse_sequence(data, '00', -31, 0, 1)
            else
              raise NotImplementedError
            end
            {dialog: value}
          when '16'
            parse_status_flags(data, 'STX response')
          when '22'
            {
              decoder_mode: DECODER_MODE_GET.fetch(data[0]),
              audio_source: AUDIO_SOURCE_GET.fetch(data[1]),
            }
          when '26'
            {main_volume: parse_half_db_volume(data, :main_volume)}
          when '27'
            {zone2_volume: parse_half_db_volume(data, :zone2_volume)}
          when 'A2'
            {zone3_volume: parse_half_db_volume(data, :zone3_volume)}
          when '40'
            {front_right_level: parse_speaker_level(data, 'report response')}
          when '41'
            {front_left_level: parse_speaker_level(data, 'report response')}
          when '42'
            {center_level: parse_speaker_level(data, 'report response')}
          when '43'
            {surround_right_level: parse_speaker_level(data, 'report response')}
          when '44'
            {surround_left_level: parse_speaker_level(data, 'report response')}
          when '45'
            {presence_right_level: parse_speaker_level(data, 'report response')}
          when '46'
            {presence_left_level: parse_speaker_level(data, 'report response')}
          when '47'
            {surround_back_right_level: parse_speaker_level(data, 'report response')}
          when '48'
            {surround_back_left_level: parse_speaker_level(data, 'report response')}
          when '49'
            {subwoofer_level: parse_speaker_level(data, 'report response')}
          when '4A'
            {subwoofer_2_level: parse_speaker_level(data, 'report response')}
          when '4B'
            {zone2_bass: parse_sequence(data, '00', -10, 10, 1)}
          when '4C'
            {zone2_treble: parse_sequence(data, '00', -10, 10, 1)}
          when '4D'
            {zone3_bass: parse_sequence(data, '00', -10, 10, 1)}
          when '4E'
            {zone3_treble: parse_sequence(data, '00', -10, 10, 1)}
          when '56'
            if data == 'FF'
              {hdmi_auto_audio_delay: nil}
            else
              {hdmi_auto_audio_delay: parse_sequence(data, '00', 0, 240, 1)}
            end
          when '60'
            if data.length != 2
              raise "Unexpected payload for 60: #{data}"
            end
            if data[0] != ?0
              raise "Unexpected payload for 60: #{data}"
            end
            {program_select: AUTO_LAST_GET.fetch(data[1])}
          when *SPEAKER_LAYOUT_MAP.keys
            if data[0] != '0'
              raise NotImplementedError
            end
            key, hash = SPEAKER_LAYOUT_MAP.fetch(command)
            {key => hash.fetch(data[1])}
          when 'A7'
            {eq_select: EQ_SELECT_GET.fetch(Integer(data).to_s)}
          when 'A8'
            {tone_auto_bypass: data == '00'}
          else
            #logger&.warn("Unhandled response: #{command} (#{data})")
            raise UnhandledResponse, "Unhandled STX response: command: #{command}; data: #{data}"
          end
        end
        {control_type: control_type}.tap do |res|
          res[:guard] = guard if guard
          res[:state] = state if state
        end
      end

      MODEL_NAMES = {
        # RX-V1000
        # RX-V3000
        # RX-V2200
        'R0112' => 'RX-V3200',
        'R0114' => 'RX-Z1',
        'R0132' => 'RX-V2300',
        'R0133' => 'RX-V3300',
        # Documentation for both RX-V2400 and RX-Z9 claims they identify as R0161
        'R0161' => 'RX-V2400/RX-Z9',
        # RX-V1500 and HTR-5890 both identify themselves as R0177
        'R0177' => 'RX-V1500/HTR-5890',
        'R0178' => 'RX-V2500',
        'R0190' => 'RX-V4600',
        'R0191' => 'RX-V1600',
        'R0193' => 'RX-V2600',
        # HTR-5990
        'R0210' => 'RX-V1700',
        'R0212' => 'RX-V2700',
        'R0225' => 'RX-V3800',
        'R0226' => 'RX-V1800',
        'R0227' => 'HTR-6190',
        'R0240' => 'RX-V1900',
        'R0241' => 'HTR-6290',
        # RX-V3900
        'R0258' => 'RX-V2065',
        'R0259' => 'HTR-6290',
        # RX-V1067
        # RX-V2067
        # RX-V3067
      }.freeze

      MODEL_IDS = MODEL_NAMES.invert.freeze

      def parse_status_response(resp)
        if resp.length < 10
          raise HandshakeFailure, "Broken status response: expected at least 10 bytes, got #{resp.length} bytes; concurrent operation on device?"
        end
        payload = resp[1...-1]
        model_code = payload[0..4]
        version = payload[5]
        length = payload[6..7].to_i(16)
        data = payload[8...-2]
        if data.length != length
          raise HandshakeFailure, "Broken status response: expected #{length} bytes for data, got #{data.length} bytes; concurrent operation on device? #{data}"
        end
        unless data.start_with?('@E01900')
          raise HandshakeFailure, "Broken status response: expected data to start with @E01900, actual #{data[0..6]}"
        end
        received_checksum = payload[-2..]
        calculated_checksum = calculate_checksum(payload[...-2])
        if received_checksum != calculated_checksum
          raise HandshakeFailure, "Broken status response: calculated checksum #{calculated_checksum}, received checksum #{received_checksum}: #{data}"
        end

        parse_status_response_inner(data, model_code).update(
          model_code: model_code,
          model_name: MODEL_NAMES.fetch(model_code),
          firmware_version: version,
          raw_string: data,
        )
      end

      def parse_status_response_inner(data, model_code)
        table = Protocol::Status::STATUS_FIELDS.fetch(model_code)
        index = 0
        result = {}
        table.each do |entry|
          if index >= data.length
            # Truncated response - normally obtained when receiver is
            # in standby
            break
          end
          entry_index = 0
          case size_or_field = entry[entry_index]
          when Integer
            size = size_or_field
            entry_index += 1
          else
            size = 1
          end
          value = data[index...index+size]
          field = entry[entry_index]
          if field.nil?
            index += size
            next
          end
          fn = entry[entry_index+1] || field
          constant = "#{fn.to_s.upcase}_GET"
          parsed = begin
            table = Protocol::GetConstants.const_get(constant)
          rescue NameError
            send("parse_#{fn}", value, field)
          else
            parse_table(value, field, table, index)
          end
          case parsed
          when Hash
            result.update(parsed)
          else
            result.update(field => parsed)
          end
          index += size
        end
        result
      end

      def parse_table(value, field, table, index)
        # Some values are nil, e.g. sleep
        if table.key?(value)
          table[value]
        else
          raise UnhandledResponse, "Bad value for field #{field}: #{value} (at DT#{index})"
        end
      end

      def calculate_checksum(str)
        sum = str.each_byte.map(&:ord).inject(0) { |sum, c| sum + c }
        '%02X' % (sum & 0xFF)
      end

      def extract_text(resp)
        # TODO: assert resp[0] == DC1, resp[-1] == ETX
        resp[0...-1]
      end

      def report_unread_response(buf)
        if buf.nil?
          raise ArgumentError, 'buffer should not be nil here'
        end

        return if buf.empty?

        if buf.count(ETX) > 1
          logger&.warn("Multiple unread responses: #{buf}")

          buf.split(ETX).each do |resp|
            report_unread_response(resp + ETX)
          end
          return
        end

        case buf[0]
        when DC2
          logger&.warn("Status response, #{buf.length} bytes")
        when STX
          logger&.warn("Command response: #{buf} #{parse_framed_stx_response(buf)}")
        else
          logger&.warn("Unknown unread response: #{buf}")
        end
      end

      def extend_next_deadline
        # 2 seconds here is definitely insufficient for RX-V1500 powering on
        @next_earliest_deadline = Utils.monotime + 3
      end
    end
  end
end
