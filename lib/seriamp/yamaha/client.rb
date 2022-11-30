# frozen_string_literal: true

require 'timeout'
require 'seriamp/backend/serial_port'
require 'seriamp/yamaha/protocol/methods'

module Seriamp
  module Yamaha

    # The manual says response should be received in 500 ms.
    RS232_TIMEOUT = 0.75

    class Client
      include Protocol::Methods

      def initialize(device: nil, glob: nil, logger: nil)
        @logger = logger

        @device = device
        @detect_device = device.nil?
        @glob = glob

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

      def detect_device?
        @detect_device
      end

      def present?
        last_status
        true
      end

      def last_status
        unless @status
          with_device do
          end
        end
        @status.dup
      end

      def last_status_string
        unless @status_string
          with_device do
          end
        end
        @status_string.dup
      end

      def status
        do_status
        last_status
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

      private

      include Protocol::Constants

      def open_device
        if detect_device? && device.nil?
          @device = Seriamp.detect_device(Yamaha, *glob, logger: logger)
          if @device
            logger&.info("Using #{device} as TTY device")
          else
            raise NoDevice, "No device specified and device could not be detected automatically"
          end
        end

        @io = Backend::SerialPortBackend::Device.new(device, logger: logger)

        begin
          tries = 0
          begin
            do_status
          rescue CommunicationTimeout
            tries += 1
            if tries < 5
              logger&.warn("Timeout handshaking with the receiver - will retry")
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

      def with_device(&block)
        if @io
          yield @io
        else
          open_device(&block)
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
        with_device do
          @io.syswrite(cmd.encode('ascii'))
          read_response
        end
      end

      def read_response
        resp = +''
        Timeout.timeout(2, CommunicationTimeout) do
          loop do
            ch = @io.sysread(1)
            if ch
              resp << ch
              break if ch == ETX
            else
              sleep 0.1
            end
          end
        end
        resp
      end

      MODEL_NAMES = {
        'R0177' => 'RX-V1500',
        'R0178' => 'RX-V2500',
      }.freeze

      PURE_DIRECT_FIELD = {
        'R0177' => 28,
        'R0178' => 126,
      }.freeze

      def do_status
        resp = nil
        loop do
          resp = dispatch(STATUS_REQ)
          again = false
          while @io && IO.select([@io.io], nil, nil, 0)
            logger&.warn("Serial device readable after completely reading status response - concurrent access?")
            read_response
            again = true
          end
          break unless again
        end
        payload = resp[1...-1]
        @model_code = payload[0..4]
        @version = payload[5]
        length = payload[6..7].to_i(16)
        data = payload[8...-2]
        if data.length != length
          raise HandshakeFailure, "Broken status response: expected #{length} bytes, got #{data.length} bytes; concurrent operation on device?"
        end
        unless data.start_with?('@E01900')
          raise HandshakeFailure, "Broken status response: expected to start with @E01900, actual #{data[0..6]}"
        end
        @status_string = data
        @status = {
          model_code: @model_code,
          model_name: MODEL_NAMES[@model_code],
          firmware_version: @version,
          system_status: data[7].ord - ZERO_ORD,
          power: power = data[8].ord - ZERO_ORD,
          main_power: [1, 4, 5, 2].include?(power),
          zone2_power: [1, 4, 3, 6].include?(power),
          zone3_power: [1, 5, 3, 7].include?(power),
        }
        if data.length > 9
          @status.update(
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
            pure_direct: data[PURE_DIRECT_FIELD.fetch(@model_code)] == '1',
            speaker_a: data[29] == '1',
            speaker_b: data[30] == '1',
            format: data[31..32],
            sample_rate: data[33..34],
          )
        end
        @status
      end

      def remote_command(cmd)
        dispatch("#{STX}0#{cmd}#{ETX}")
      end

      def system_command(cmd)
        dispatch("#{STX}2#{cmd}#{ETX}")
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
    end
  end
end
