# frozen_string_literal: true

require 'timeout'
require 'yamaha/backend/serial_port'

module Yamaha

  class Error < StandardError; end
  class BadDevice < Error; end
  class BadStatus < Error; end
  class InvalidCommand < Error; end
  class NotApplicable < Error; end
  class UnexpectedResponse < Error; end

  RS232_TIMEOUT = 9
  DEFAULT_DEVICE_GLOB = '/dev/ttyUSB*'

  class Client
    def self.detect_device(*patterns, logger: nil)
      if patterns.empty?
        patterns = [DEFAULT_DEVICE_GLOB]
      end
      devices = patterns.map do |pattern|
        Dir.glob(pattern)
      end.flatten.uniq
      found = nil
      threads = devices.map do |device|
        Thread.new do
          Timeout.timeout(RS232_TIMEOUT) do
            logger&.debug("Trying #{device}")
            new(device, logger: logger).status
            logger&.debug("Found receiver at #{device}")
            found = device
          end
        end
      end
      threads.map(&:join)
      found
    end

    def initialize(device = nil, logger: nil)
      @logger = logger

      if device.nil?
        device = Dir[DEFAULT_DEVICE_GLOB].sort.first
        if device
          logger&.info("Using #{device} as TTY device")
        end
      end

      unless device
        raise ArgumentError, "No device specified and device could not be detected automatically"
      end

      @device = device
    end

    attr_reader :device
    attr_accessor :logger

    def last_status
      unless @status
        open_device do
        end
      end
      @status.dup
    end

    def last_status_string
      unless @status_string
        open_device do
        end
      end
      @status_string.dup
    end

    def status
      do_status
      last_status
    end

    def set_power(state)
      remote_command("7A1#{state ? 'D' : 'E'}")
    end

    def set_main_power(state)
      remote_command("7E7#{state ? 'E' : 'F'}")
    end

    def set_zone2_power(state)
      remote_command("7EB#{state ? 'A' : 'B'}")
    end

    def set_zone3_power(state)
      remote_command("7AE#{state ? 'D' : 'E'}")
    end

    def set_main_volume(value)
      system_command("30#{'%02x' % value}")
    end

    def set_main_volume_db(volume)
      value = Integer((volume + 80) * 2 + 39)
      set_main_volume(value)
    end

    def set_zone2_volume(value)
      system_command("31#{'%02x' % value}")
    end

    def set_zone2_volume_db(volume)
      value = Integer(volume + 33 + 39)
      set_zone2_volume(value)
    end

    def zone2_volume_up
      remote_command('7ADA')
    end

    def zone2_volume_down
      remote_command('7ADB')
    end

    def set_zone3_volume(volume)
      remote_command("234#{'%02x' % value}")
    end

    def zone3_volume_up
      remote_command('7AFD')
    end

    def zone3_volume_down
      remote_command('7AFE')
    end

    def set_subwoofer_level(level)
      dispatch("#{STX}249#{'%02x' % level}#{ETX}")
    end

    def get_main_volume_text
      extract_text(dispatch("#{STX}22001#{ETX}"))[3...]
    end

    def get_zone2_volume_text
      extract_text(dispatch("#{STX}22002#{ETX}"))[3...]
    end

    def get_zone3_volume_text
      extract_text(dispatch("#{STX}22005#{ETX}"))[3...]
    end

    def set_pure_direct(state)
      dispatch("#{STX}07E8#{state ? '0' : '2'}#{ETX}")
    end

    MAIN_INPUTS_SET = {
      'phono' => '14',
      'cd' => '15',
      'tuner' => '16',
      'cd_r' => '19',
      'md_tape' => '18',
      'dvd' => 'C1',
      'dtv' => '54',
      'cbl_sat' => 'C0',
      'vcr1' => '0F',
      'dvr_vcr2' => '13',
      'v_aux_dock' => '55',
      'multi_ch' => '87',
      'xm' => 'B4',
    }.freeze

    def set_main_input(source)
      source_code = MAIN_INPUTS_SET.fetch(source.downcase.gsub(/[^a-z]/, '_'))
      remote_command("7A#{source_code}")
    end

    private

    def open_device
      @f = Backend::SerialPortBackend::Device.new(device, logger: logger)
      yield
      @f.close
    end

    # ASCII table: https://www.asciitable.com/
    DC1 = +?\x11
    DC2 = +?\x12
    ETX = +?\x03
    STX = +?\x02
    DEL = +?\x7f

    STATUS_REQ = -"#{DC1}001#{ETX}"

    ZERO_ORD = '0'.ord

    def dispatch(cmd)
      open_device do
        @f.syswrite(cmd.encode('ascii'))
        read_response
      end
    end

    def read_response
      resp = +''
      Timeout.timeout(2) do
        loop do
          ch = @f.sysread(1)
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

    MAIN_INPUTS_GET = {
      '0' => 'PHONO',
      '1' => 'CD',
      '2' => 'TUNER',
      '3' => 'CD-R',
      '4' => 'MD/TAPE',
      '5' => 'DVD',
      '6' => 'DTV',
      '7' => 'CBL/SAT',
      '8' => 'SAT',
      '9' => 'VCR1',
      'A' => 'DVR/VCR2',
      'B' => 'VCR3/DVR',
      'C' => 'V-AUX/DOCK',
      'D' => 'NET/USB',
      'E' => 'XM',
    }.freeze

    AUDIO_SELECT_GET = {
      '0' => 'Auto', # Confirmed RX-V1500
      '2' => 'DTS', # Confirmed RX-V1500
      '3' => 'Coax / Opt', # Unconfirmed
      '4' => 'Analog', # Confirmed RX-V1500
      '5' => 'Analog Only', # Unconfirmed
      '8' => 'HDMI', # Unconfirmed
    }.freeze

    NIGHT_GET = {
      '0' => 'Off',
      '1' => 'Cinema',
      '2' => 'Music',
    }.freeze

    SLEEP_GET = {
      '0' => 120,
      '1' => 90,
      '2' => 60,
      '3' => 30,
      '4' => nil,
    }.freeze

    PROGRAM_GET = {
      '00' => 'Munich',
      '01' => 'Hall B',
      '02' => 'Hall C',
      '04' => 'Hall D',
      '05' => 'Vienna',
      '06' => 'Live Concert',
      '07' => 'Hall in Amsterdam',
      '08' => 'Tokyo',
      '09' => 'Freiburg',
      '0A' => 'Royaumont',
      '0B' => 'Chamber',
      '0C' => 'Village Gate',
      '0D' => 'Village Vanguard',
      '0E' => 'The Bottom Line',
      '0F' => 'Cellar Club',
      '10' => 'The Roxy Theater',
      '11' => 'Warehouse Loft',
      '12' => 'Arena',
      '14' => 'Disco',
      '15' => 'Party',
      '17' => '7ch Stereo',
      '18' => 'Music Video',
      '19' => 'DJ',
      '1C' => 'Recital/Opera',
      '1D' => 'Pavilion',
      '1E' => 'Action Gamae',
      '1F' => 'Role Playing Game',
      '20' => 'Mono Movie',
      '21' => 'Sports',
      '24' => 'Spectacle',
      '25' => 'Sci-Fi',
      '28' => 'Adventure',
      '29' => 'Drama',
      '2C' => 'Surround Decode',
      '2D' => 'Standard',
      '30' => 'PLII Movie',
      '31' => 'PLII Music',
      '32' => 'Neo:6 Movie',
      '33' => 'Neo:6 Music',
      '34' => '2ch Stereo',
      '35' => 'Direct Stereo',
      '36' => 'THX Cinema',
      '37' => 'THX Music',
      '3C' => 'THX Game',
      '40' => 'Enhancer 2ch Low',
      '41' => 'Enhancer 2ch High',
      '42' => 'Enhancer 7ch Low',
      '43' => 'Enhancer 7ch Higgh',
      '80' => 'Straight',
    }.freeze

    def do_status
      resp = nil
      loop do
        resp = dispatch(STATUS_REQ)
        again = false
        while @f && IO.select([@f], nil, nil, 0)
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
        raise BadStatus, "Broken status response: expected #{length} bytes, got #{data.length} bytes; concurrent operation on device?"
      end
      unless data.start_with?('@E01900')
        raise BadStatus, "Broken status response: expected to start with @E01900, actual #{data[0..6]}"
      end
      puts data, data.length
      p payload
      @status_string = data
      @status = {
        # RX-V1500: model R0177
        model_code: @model_code,
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
          pure_direct: data[28] == '1',
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
      resp[1...-1]
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
