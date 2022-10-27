module Sonamp
  class Error < StandardError; end
  class InvalidCommand < Error; end
  class NotApplicable < Error; end
  class UnexpectedResponse < Error; end

  class Client
    def initialize(device = nil, logger: nil)
      @logger = logger

      if device.nil?
        device = Dir['/dev/ttyUSB*'].sort.first
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

    def get_zone_power(zone = nil)
      get_zone_state('P', zone)
    end

    def set_zone_power(zone, state)
      if zone < 1 || zone > 4
        raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
      end
      cmd = ":P#{zone}#{state ? 1 : 0}"
      expected = cmd[1...cmd.length]
      dispatch_assert(cmd, expected)
    end

    def get_zone_volume(zone = nil)
      if zone
        if zone < 1 || zone > 4
          raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
        end
        resp = dispatch(":V#{zone}?")
        resp[2...].to_i
      else
        dispatch(":VG?", 4).map do |resp|
          resp[2...].to_i
        end
      end
    end

    def set_zone_volume(zone, volume)
      if zone < 1 || zone > 4
        raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
      end
      if volume < 0 || volume > 100
        raise ArgumentError, "Volume must be between 0 and 100: #{volume}"
      end
      cmd = ":V#{zone}#{volume}"
      expected = cmd[1...cmd.length]
      dispatch_assert(cmd, expected)
    end

    def set_channel_volume(channel, volume)
      if channel < 1 || channel > 8
        raise ArgumentError, "Channel must be between 1 and 4: #{channel}"
      end
      if volume < 0 || volume > 100
        raise ArgumentError, "Volume must be between 0 and 100: #{volume}"
      end
      cmd = ":VC#{channel}#{volume}"
      expected = cmd[1...cmd.length]
      dispatch_assert(cmd, expected)
    end

    def get_zone_mute(zone = nil)
      get_zone_state('M', zone)
    end

    def get_zone_fault(zone = nil)
      get_zone_state('FP', zone)
    end

    def get_bbe(zone = nil)
      get_zone_state('BP', zone)
    end

    def get_bbe_high_boost(zone = nil)
      get_zone_state('BH', zone)
    end

    def get_bbe_low_boost(zone = nil)
      get_zone_state('BL', zone)
    end

    def get_auto_trigger_input(zone = nil)
      get_zone_state('ATI', zone)
    end

    def get_voltage_trigger_input(zone = nil)
      get_zone_state('VTI', zone)
    end

    def firmware_version
      global_query('VER')
    end

    def temperature
      Integer(global_query('TP'))
    end

    def status
      # Reusing the opened device file makes :VTIG? fail even with a delay
      # in front.
      #open_device do
        p dispatch(':VCG?', 8)
        sleep 0.1
        p dispatch(':TVLG?', 8)
        p dispatch(':MCG?', 8)
      #end
      {
        firmware_version: firmware_version,
        temperature: temperature,
        zone_power: get_zone_power,
        zone_fault: get_zone_fault,
        zone_volume: get_zone_volume,
        mute: get_zone_mute,
        bbe: get_bbe,
        bbe_high_boost: get_bbe_high_boost,
        bbe_low_boost: get_bbe_low_boost,
        auto_trigger_input: get_auto_trigger_input,
        voltage_trigger_input: get_voltage_trigger_input,
      }
    end

    private

    def open_device
      if @f
        yield
      else
        File.open(device, 'r+') do |f|
          @f = f
          yield.tap do
            @f = nil
          end
        end
      end
    end

    def dispatch(cmd, resp_lines_count = 1)
      open_device do
        @f << "#{cmd}\x0d"
        resp = 1.upto(resp_lines_count).map do
          read_line(@f, cmd)
        end
        if resp_lines_count == 1
          resp.first
        else
          resp
        end
      end
    end

    def dispatch_assert(cmd, expected)
      resp = dispatch(cmd)
      if resp != expected
        raise UnexpectedResponse, "Expected #{expected}, got #{resp}"
      end
    end

    def dispatch_extract_suffix(cmd, expected_prefix)
      resp = dispatch(cmd)
      unless resp[0..expected_prefix.length-1] == expected_prefix
        raise "Unexpected response: expected #{expected_prefix}..., actual #{resp}"
      end
      resp[expected_prefix.length..]
    end

    def global_query(cmd)
      dispatch_extract_suffix(":#{cmd}?", cmd)
    end

    def read_line(f, cmd)
      f.readline.strip.tap do |resp|
        if resp == 'ERR'
          raise InvalidCommand, "Invalid command: #{cmd}"
        elsif resp == 'N/A'
          raise NotApplicable, "Command was recognized but could not be executed - is serial control enabled on the amplifier?"
        end
      end
    end

    def get_zone_state(cmd_prefix, zone)
      if zone
        if zone < 1 || zone > 4
          raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
        end
        resp = dispatch(":#{cmd_prefix}#{zone}?")
        resp[cmd_prefix.length + 1] == '1' ? true : false
      else
        dispatch(":#{cmd_prefix}G?", 4).map do |resp|
          resp[cmd_prefix.length + 1] == '1' ? true : false
        end
      end
    end
  end
end
