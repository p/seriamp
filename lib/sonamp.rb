module Sonamp
  VERSION = '0.0.1'.freeze

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

    def get_power(zone = nil)
      if zone
        if zone < 1 || zone > 4
          raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
        end
        dispatch(":P#{zone}?")
      else
        dispatch(":PG?", 4).map do |resp|
          resp[2] == '1' ? true : false
        end
      end
    end

    def power(zone, state)
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
        dispatch(":V#{zone}?")
      else
        dispatch(":VG?", 4).map do |resp|
          resp[2...].to_i
        end
      end
    end

    def zone_volume(zone, volume)
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

    def channel_volume(channel, volume)
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

    def status
      # Reusing the opened device file makes :VTIG? fail even with a delay
      # in front.
      #open_device do
        p dispatch(':VER?')
        p dispatch(':TP?')
        p get_power
        p dispatch(':FPG?', 4)
        p get_zone_volume
        p dispatch(':VCG?', 8)
        p dispatch(':ATIG?', 4)
        sleep 0.1
        p dispatch(':VTIG?', 4)
        p dispatch(':TVLG?', 8)
        p dispatch(':MG?', 4)
        p dispatch(':MCG?', 8)
        p dispatch(':BPG?', 4)
        p dispatch(':BBG?', 4)
      #end
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

    def read_line(f, cmd)
      f.readline.strip.tap do |resp|
        if resp == 'ERR'
          raise InvalidCommand, "Invalid command: #{cmd}"
        elsif resp == 'N/A'
          raise NotApplicable, "Command was recognized but could not be executed - is serial control enabled on the amplifier?"
        end
      end
    end
  end
end
