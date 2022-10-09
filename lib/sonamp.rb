module Sonamp
  VERSION = '0.0.1'.freeze

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

    attr_accessor :logger
  end
end
