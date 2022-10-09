module Sonamp
  VERSION = '0.0.1'.freeze

  class Error < StandardError; end
  class NotApplicable < Error; end

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

    def power(zone, state)
      if zone < 1 || zone > 4
        raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
      end
      cmd = ":P#{zone}#{state ? 1 : 0}"
      dispatch(cmd)
    end

    private

    def dispatch(cmd, resp_lines_count = 1)
      File.open(device, 'r+') do |f|
        f << "#{cmd}\n"
        1.upto(resp_lines_count).map do
          read_line(f)
        end
      end
    end

    def read_line(f)
      f.readline.strip.tap do |resp|
        if resp == 'N/A'
          raise NotApplicable, "Command was recognized but could not be executed - is serial control enabled on the amplifier?"
        end
      end
    end
  end
end
