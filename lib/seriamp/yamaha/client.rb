# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/yamaha/protocol/methods'

module Seriamp
  module Yamaha

    # The manual says response should be received in 500 ms.
    # However, the status response takes 850 ms to be received in my
    # environment (RX-V1500/1800/2500).
    DEFAULT_RS232_TIMEOUT = 1

    class Client
      include Protocol::Methods

      def initialize(device: nil, glob: nil, logger: nil, retries: true,
        timeout: nil, thread_safe: false
      )
        @logger = logger

        @device = device
        @detect_device = device.nil?
        @glob = glob
        @retries = case retries
          when nil, false
            0
          when true
            1
          when Integer
            retries
          else
            raise ArgumentError, "retries must be an integer, true, false or nil: #{retries}"
          end
        @timeout = timeout || DEFAULT_RS232_TIMEOUT
        @thread_safe = !!thread_safe

        if thread_safe?
          @lock = Mutex.new
        end

        if block_given?
          begin
            yield self
          ensure
            close
          end
        end
      end

      attr_reader :device
      attr_reader :glob
      attr_reader :logger
      attr_reader :retries
      attr_reader :timeout

      def thread_safe?
        @thread_safe
      end

      def detect_device?
        @detect_device
      end

      def present?
        last_status
        true
      end

      def last_status
        unless @status
          with_lock do
            with_retry do
              with_device do
                unless @status
                  do_status
                end
              end
            end
          end
        end
        if @status.nil?
          raise "This should not happen"
        end
        @status.dup
      end

      def last_status_string
        unless @status_string
          with_lock do
            with_retry do
              with_device do
                status
              end
            end
          end
        end
        @status_string.dup
      end

      def status
        do_status
        last_status
      end

      def clear_cache
        @status = nil
      end

      %i(
        model_code firmware_version system_status power main_power zone2_power
        zone3_power input input_name audio_select audio_select_name
        main_volume main_volume_db zone2_volume zone2_volume_db
        zone3_volume zone3_volume_db program program_name sleep night night_name
        format sample_rate
      ).each do |meth|
        define_method(meth) do
          status.fetch(meth)
        end

        define_method("last_#{meth}") do
          last_status.fetch(meth)
        end
      end

      alias main_input_name input_name
      alias last_main_input_name last_input_name

      %i(
        multi_ch_input effect pure_direct speaker_a speaker_b
      ).each do |meth|
        define_method("#{meth}?") do
          status.fetch(meth)
        end

        define_method("last_#{meth}?") do
          last_status.fetch(meth)
        end
      end

      def with_device(&block)
        if @io
          yield @io
        else
          open_device(&block)
        end
      end

      def with_lock
        if thread_safe?
          @lock.synchronize do
            yield
          end
        else
          yield
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

      private

      include Protocol::Constants

      def open_device
        if detect_device? && device.nil?
          logger&.debug("Detecting device")
          @device = Seriamp.detect_device(Yamaha, *glob, logger: logger, timeout: timeout)
          if @device
            logger&.info("Using #{device} as TTY device")
          else
            raise NoDevice, "No device specified and device could not be detected automatically"
          end
        end

        logger&.debug("Opening #{device}")
        @io = Backend::SerialPortBackend::Device.new(device, logger: logger)

        buf = Utils.consume_data(@io.io, logger,
          "Serial device readable after opening - unread previous response?")
        report_unread_response(buf)

        begin
          tries = 0
          begin
            #do_status
          rescue CommunicationTimeout
            tries += 1
            if tries < 5
              logger&.warn("Timeout handshaking with the receiver - will retry")
              Utils.sleep_before_retry
              retry
            else
              raise
            end
          end

          yield @io
        ensure
          @io.close rescue nil
          @io = nil
        end
      end

      # ASCII table: https://www.asciitable.com/
      DC1 = ?\x11
      DC2 = ?\x12
      ETX = ?\x03
      STX = ?\x02
      DEL = ?\x7f

      STATUS_REQ = "#{DC1}001#{ETX}"

      ZERO_ORD = '0'.ord

      def dispatch(cmd)
        start = Utils.monotime
        with_device do
          @io.syswrite(cmd.encode('ascii'))
          read_response
        end.tap do
          elapsed = Utils.monotime - start
          logger&.debug("Yamaha: dispatched #{cmd} in #{'%.2f' % elapsed} s")
        end
      end

      def read_response
        resp = +''
        deadline = Utils.monotime + timeout
        loop do
          begin
            chunk = @io.read_nonblock(1000)
            if chunk
              resp += chunk
              break if chunk[-1] == ETX
            end
          rescue IO::WaitReadable
            budget = deadline - Utils.monotime
            if budget < 0
              raise CommunicationTimeout
            end
            IO.select([@io.io], nil, nil, budget)
          end
        end

        if resp.count(ETX) > 1
          logger&.warn("Multiple responses received: #{resp}")
        end

        parse_response(resp)
      end

      def parse_response(resp)
        unless resp[0] == STX
          raise UnexpectedResponse, "Invalid response: expected to start with STX: #{resp}"
        end
        unless resp[-1] == ETX
          raise UnexpectedResponse, "Invalid response: expected to end with ETX: #{resp}"
        end
        resp = resp[1...-1]
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
        state = case command
        when '20'
          POWER_GET.fetch(data)
        else
          raise UnexpectedResponse, "Unhandled response: #{command} (#{data})"
        end
        {
          control_type: control_type,
          guard: guard,
          state: state,
        }
      end

      def parse_flag(value, map, error_msg)
        if map.key?(value)
          map[value]
        else
          raise UnexpectedResponse, "#{error_msg}: #{value}"
        end
      end

      MODEL_NAMES = {
        'R0177' => 'RX-V1500',
        'R0178' => 'RX-V2500',
        'R0226' => 'RX-V1800',
      }.freeze

      PURE_DIRECT_FIELD = {
        'R0177' => 28,
        'R0178' => 126,
        'R0226' => 126,
      }.freeze

      INPUT_MODE_R0178 = {
        '0' => 'Auto',
        '2' => 'DTS',
        '4' => 'Analog',
        '5' => 'Analog Only',
      }.freeze

      SAMPLE_RATE_R0178 = {
        '0' => 'Analog',
        '1' => 32000,
        '2' => 44100,
        '3' => 48000,
        '4' => 64000,
        '5' => 88200,
        '6' => 96000,
        '7' => 'Unknown',
      }.freeze

      def do_status
        with_retry do
          resp = nil
          resp = dispatch(STATUS_REQ)
          buf = Utils.consume_data(@io.io, logger,
            "Serial device readable after completely reading status response - concurrent access?")
          report_unread_response(buf)
          if resp.length < 10
            raise HandshakeFailure, "Broken status response: expected at least 10 bytes, got #{resp.length} bytes; concurrent operation on device?"
          end
          payload = resp[1...-1]
          model_code = payload[0..4]
          version = payload[5]
          length = payload[6..7].to_i(16)
          data = payload[8...-2]
          if data.length != length
            raise HandshakeFailure, "Broken status response: expected #{length} bytes, got #{data.length} bytes; concurrent operation on device?"
          end
          unless data.start_with?('@E01900')
            raise HandshakeFailure, "Broken status response: expected to start with @E01900, actual #{data[0..6]}"
          end
          status_string = data
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
              input: input = data[9],
              input_name: MAIN_INPUTS_GET.fetch(input),
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
              main_volume: volume = data[15..16].to_i(16),
              main_volume_db: int_to_half_db(volume),
              zone2_volume: zone2_volume = data[17..18].to_i(16),
              zone2_volume_db: int_to_full_db(zone2_volume),
              zone3_volume: zone3_volume = data[129..130].to_i(16),
              zone3_volume_db: int_to_full_db(zone3_volume),
              program: program = data[19..20],
              program_name: PROGRAM_GET.fetch(program),
              # true: straight; false: effect
              effect: data[21] == '1',
              #extended_surround: data[22],
              #short_message: data[23],
              sleep: SLEEP_GET.fetch(data[24]),
              night: night = data[27],
              night_name: NIGHT_GET.fetch(night),
              pure_direct: data[PURE_DIRECT_FIELD.fetch(model_code)] == '1',
              speaker_a: data[29] == '1',
              speaker_b: data[30] == '1',
              # 2 positions on RX-Vx700
              #format: data[31..32],
              #sampling: data[33..34],
            )
            if model_code == 'R0178'
              status.update(
                input_mode: INPUT_MODE_R0178.fetch(data[11]),
                sampling: data[32],
                sample_rate: SAMPLE_RATE_R0178.fetch(data[32]),
              )
            end
          end

          @model_code, @version, @status_string =
            model_code, version, status_string
          @status = status
        end
      end

      def remote_command(cmd)
        with_lock do
          with_retry do
            dispatch("#{STX}0#{cmd}#{ETX}")
          end
        end
      end

      def system_command(cmd)
        with_lock do
          with_retry do
            dispatch("#{STX}2#{cmd}#{ETX}")
          end
        end
      end

      def extract_text(resp)
        # TODO: assert resp[0] == DC1, resp[-1] == ETX
        resp[0...-1]
      end

      def int_to_half_db(value)
        if value == 0
          :mute
        else
          (value - 39) / 2.0 - 80
        end
      end

      def int_to_full_db(value)
        if value == 0
          :mute
        else
          (value - 39) - 33
        end
      end

      def with_retry
        try = 1
        begin
          yield
        rescue Seriamp::Error, IOError, SystemCallError => exc
          if try <= retries
            logger&.warn("Error during operation: #{exc.class}: #{exc} - will retry")
            try += 1
            if detect_device?
              @device = nil
            end
            Utils.sleep_before_retry
            retry
          else
            raise
          end
        end
      end

      def report_unread_response(buf)
        return if buf.nil?

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
          logger&.warn("Command response: #{buf}")
        else
          logger&.warn("Unknown unread response: #{buf}")
        end
      end
    end
  end
end
