# frozen_string_literal: true

require 'timeout'
require 'seriamp/error'

module Seriamp

  DEFAULT_DEVICE_GLOB = '/dev/ttyUSB*'

  module_function def detect_device(mod, *patterns, logger: nil, timeout: nil)
    if patterns.empty?
      patterns = [DEFAULT_DEVICE_GLOB]
    end
    devices = patterns.map do |pattern|
      Dir.glob(pattern)
    end.flatten.uniq
    if devices.length == 1
      logger&.debug("Assuming #{devices.first} as the only device matching the pattern(s)")
      return devices.first
    end
    queue = Queue.new
    timeout ||= mod.const_get(:DEFAULT_RS232_TIMEOUT)
    client_cls = mod.const_get(:Client)
    threads = devices.map do |device|
      Thread.new do
        Timeout.timeout(timeout * 2, CommunicationTimeout) do
          logger&.debug("Trying #{device}")
          client_cls.new(device: device, logger: logger, retries: false, timeout: timeout).present?
          logger&.debug("Found #{mod} device at #{device}")
          queue << device
        end
      rescue CommunicationTimeout, IOError, SystemCallError => exc
        logger&.debug("Failed on #{mod} #{device}: #{exc.class}: #{exc}")
      end
    end
    wait_thread = Thread.new do
      threads.each do |thread|
        # Unhandled exceptions raised in threads are reraised by the join method
        thread.join rescue nil
      end
      queue << nil
    end
    queue.shift.tap do
      threads.map(&:kill)
      wait_thread.kill
    end
  end
end
