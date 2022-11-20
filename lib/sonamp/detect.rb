# frozen_string_literal: true

require 'timeout'

module Sonamp

  DEFAULT_DEVICE_GLOB = '/dev/ttyUSB*'

  module_function def detect_device(*patterns, logger: nil)
    if patterns.empty?
      patterns = [DEFAULT_DEVICE_GLOB]
    end
    devices = patterns.map do |pattern|
      Dir.glob(pattern)
    end.flatten.uniq
    queue = Queue.new
    threads = devices.map do |device|
      Thread.new do
        Timeout.timeout(RS232_TIMEOUT * 2, CommunicationTimeout) do
          logger&.debug("Trying #{device}")
          Client.new(device, logger: logger).get_zone_power
          logger&.debug("Found amplifier at #{device}")
          queue << device
        end
      rescue CommunicationTimeout, IOError, SystemCallError => exc
        logger&.debug("Failed on #{device}: #{exc.class}: #{exc}")
      end
    end
    wait_thread = Thread.new do
      threads.map(&:join)
      queue << nil
    end
    queue.shift.tap do
      threads.map(&:kill)
      wait_thread.kill
    end
  end
end
