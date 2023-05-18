# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/yamaha/protocol/methods'
require 'seriamp/yamaha/protocol/get_constants'
require 'seriamp/yamaha/protocol/extended/generic_response'
require 'seriamp/yamaha/protocol/extended/graphic_eq_response'
require 'seriamp/yamaha/protocol/extended/main_tone_response'
require 'seriamp/client'

module Seriamp
  module Yamaha

    class Client < Seriamp::Client

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

      def clear_cache
        @status = nil
      end

      %i(
        model_code firmware_version system_status power main_power zone2_power
        zone3_power input input_name audio_select audio_select_name
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
            end
          end
        end

        nil
      end

      def remote_command(cmd, read_response: true)
        with_lock do
          with_retry do
            cmd = "#{STX}0#{cmd}#{ETX}"
            if read_response
              dispatch_and_parse(cmd)
            else
              dispatch(cmd, read_response: false)
            end
          end
        end
      end

      def system_command(cmd)
        with_lock do
          with_retry do
            resp = dispatch_and_parse("#{STX}2#{cmd}#{ETX}")
            if resp.fetch(:control_type) != :rs232c
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

      def write_command(cmd)
        @io.syswrite(cmd.encode('ascii'))
      end

      def response_complete?
        read_buf.end_with?(self.class.const_get(:ETX))
      end

      def extract_one_response
        extract_delimited_response(self.class.const_get(:ETX))
      end

      def parse_response(resp)
        case first_byte = resp[0]
        when STX
          parse_framed_stx_response(resp)
        when DC2
          parse_status_response(resp)
        when DC4
          parse_extended_response(resp[1...-1])
        else
          raise NotImplementedError, "\\x#{'%02x' % first_byte.ord} first response byte not handled"
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

        #p [command_id,status,command_data]

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

        cls = case command_id
        when '033'
          if command_data.empty?
            nil
          else
            Protocol::Extended::MainToneResponse
          end
        when '030'
          if command_data.empty?
            nil
          else
            Protocol::Extended::GraphicEqResponse
          end
        else
          Protocol::Extended::GenericResponse
        end
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

      def parse_stx_response(resp)
        control_type = parse_flag(resp[0], {
          '0' => :rs232c,
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
        state = if field_name = GET_MAP[command]
          map = self.class.const_get("#{field_name.upcase}_GET")
          value = map[data]
          if value.nil?
            logger&.warn("Unhandled value #{data} for #{command} (#{field_name})")
          end
          unless Hash === value
            value = {field_name => value}
          end
          value
        else
          case command
          when '22'
            {
              decoder_mode: DECODER_MODE_GET.fetch(data[0]),
              audio_select: AUDIO_SELECT_GET.fetch(data[1]),
            }
          when '26'
            {main_volume: parse_half_db_volume(data)}
          when '27'
            {zone2_volume: parse_half_db_volume(data)}
          when 'A2'
            {zone3_volume: parse_half_db_volume(data)}
          when '4B'
            {zone2_bass: parse_volume(data, '00', -10, 10, 1)}
          when '4C'
            {zone2_treble: parse_volume(data, '00', -10, 10, 1)}
          when '4D'
            {zone3_bass: parse_volume(data, '00', -10, 10, 1)}
          when '4E'
            {zone3_treble: parse_volume(data, '00', -10, 10, 1)}
          else
            logger&.warn("Unhandled response: #{command} (#{data})")
            nil
          end
        end
        {control_type: control_type}.tap do |res|
          res[:guard] = guard if guard
          res[:state] = state if state
        end
      end

      def parse_flag(value, map, error_msg)
        if map.key?(value)
          map[value]
        else
          raise UnexpectedResponse, "#{error_msg}: #{value}"
        end
      end

      def parse_half_db_volume(value)
        case i_value = Integer(value, 16)
        when 0
          # Mute
          nil
        when 0x27..0xE8
          (i_value - 0x27)/2.0 - 80
        else
          raise UnexpectedResponse, "Volume raw value (0.5 dB step) out of range: #{value}"
        end
      end

=begin I don't know what this is actually needed for, may have gotten myself confused with the Integra
      def parse_full_db_volume(value)
        case i_value = Integer(value, 16)
        when 0
          # Mute
          nil
        when 0x27..0x48
          i_value - 0x27 - 33
        else
          raise UnexpectedResponse, "Volume raw value (1 dB step) out of range: #{value}"
        end
      end

      def parse_zone2_volume(model_code, value)
        if model_code >= 'R0210'
          parse_half_db_volume(value)
        else
          parse_full_db_volume(value)
        end
      end
=end

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

      PURE_DIRECT_FIELD = {
        'R0177' => 28,
        'R0178' => 126,
        'R0212' => 126,
        'R0226' => 126,
      }.freeze

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

        parse_status_response_inner(data).update(raw_string: data)
      end

      def parse_status_response_inner(data, model_code)
        table = STATUS_FIELDS.fetch(model_code)
        index = 0
        result = {}
        table.each do |entry|
          entry_index = 0
          case size_or_field = entry[entry_index]
          when Integer
            size = size_or_field
            entry_index += 1
          end
          value = data[index..index+size]
          index += size
          field = entry[entry_index]
          next if field.nil?
          fn = entry[entry_index+1] || field
          parsed = send("parse_#{fn}", value, field)
          case parsed
          when Hash
            result.update(parsed)
          else
            result.update(field => parsed)
          end
        end
        result
      end

      def parse_table(value, field, table)
        table[value].tap do |parsed|
          if parsed.nil?
            raise UnexpectedResponse, "Bad value for #{kind} field #{field}: #{value}"
          end
        end
      end

      def parse_bool(value, field)
        case value
        when '0'
          false
        when '1'
          true
        else
          raise UnexpectedResponse, "Bad value for boolean field #{field}: #{value}"
        end
      end

      def x
        status = {
          model_code: model_code,
          model_name: MODEL_NAMES[model_code],
          firmware_version: version,
          system_status: data[7].ord - ZERO_ORD,
          power: power = data[8].ord - ZERO_ORD,
          main_power: [1, 4, 5, 2].include?(power),
          zone2_power: [1, 4, 3, 6].include?(power),
          zone3_power: [1, 5, 3, 7].include?(power),
        }
        if data.length > 9
          status.update(
            input_name: MAIN_INPUTS_GET.fetch(data[9]),
            multi_ch_input: data[10] == '1',
            audio_select: audio_select = data[11],
            audio_select_name: AUDIO_SELECT_GET.fetch(audio_select),
            mute: data[12] == '1',
            # Volume values (0.5 dB increment):
            # mute: 0
            # -80.0 dB (min): 39
            # 0 dB: 199
            # +14.5 dB (max): 228
            # Zone2 volume values (1 dB increment):
            # mute: 0
            # -33 dB (min): 39
            # 0 dB (max): 72
            main_volume: parse_half_db_volume(data[15..16]),
            zone2_volume: parse_half_db_volume(data[17..18]),
            zone3_volume: parse_half_db_volume(data[129..130]),
            program_name: PROGRAM_GET.fetch(data[19..20]),
            # true: straight; false: effect
            effect: data[21] == '1',
            #extended_surround: data[22],
            #short_message: data[23],
            sleep: SLEEP_GET.fetch(data[24]),
            night_name: NIGHT_GET.fetch(data[27]),
            pure_direct: data[PURE_DIRECT_FIELD.fetch(model_code)] == '1',
            speaker_a: data[29] == '1',
            speaker_b: data[30] == '1',
            # 2 positions on RX-Vx700
            #format: data[31..32],
            #sampling: data[33..34],
          )
          if model_code >= 'R0178'
            status.update(
              input_mode: INPUT_MODE_R0178.fetch(data[11]),
              sample_rate: SAMPLE_RATE_R0178.fetch(data[32]),
            )
          end
          if model_code >= 'R0190'
            status.update(
              input_name: INPUT_NAME_GET.fetch(data[9..10]),
              format: FORMAT_GET.fetch(data[31..32]),
              sample_rate: SAMPLING_GET.fetch(data[33..34]),
            )
            # Multi-channel input as a flag is not provided by RX-V1600+
            status.delete(:multi_ch_input)
          end
        end
        status.update(raw_string: data)
        status
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
