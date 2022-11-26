# frozen_string_literal: true

require 'timeout'
require 'seriamp/error'

module Seriamp

  DEFAULT_DEVICE_GLOB = '/dev/ttyUSB*'

  module_function def detect_device(mod, *patterns, logger: nil)
    if patterns.empty?
      patterns = [DEFAULT_DEVICE_GLOB]
    end
    devices = patterns.map do |pattern|
      Dir.glob(pattern)
    end.flatten.uniq
    queue = Queue.new
    timeout = mod.const_get(:RS232_TIMEOUT)
    client_cls = mod.const_get(:Client)
    threads = devices.map do |device|
      Thread.new do
        Timeout.timeout(timeout * 2, CommunicationTimeout) do
          logger&.debug("Trying #{device}")
          client_cls.new(device, logger: logger).present?
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
