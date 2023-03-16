# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/recursive_mutex'

module Seriamp

  class Client
    #DEFAULT_RS232_TIMEOUT = 2

    def initialize(**opts)
      @options = opts.dup.freeze

=begin
      device: nil, glob: nil, logger: nil, retries: true,
      timeout: nil, thread_safe: false, persistent: thread_safe
=end

      @logger = options[:logger]

      @device = options[:device]
      @detect_device = device.nil?
      @glob = options[:glob]
      @retries = case options[:retries]
        when nil, false
          0
        when true
          1
        when Integer
          retries
        else
          raise ArgumentError, "retries must be an integer, true, false or nil: #{retries}"
        end
      @timeout = options[:timeout] || self.class.const_get(:DEFAULT_RS232_TIMEOUT)
      @thread_safe = !!options[:thread_safe]
      if options.key?(:persistent)
        @persistent = !!options[:persistent]
      else
        @persistent = @thread_safe
      end

      if thread_safe?
        @lock = RecursiveMutex.new
      end

      @next_earliest_deadline = Utils.monotime

      if block_given?
        begin
          yield self
        ensure
          close
        end
      end
    end

    attr_reader :options
    attr_reader :device
    attr_reader :glob
    attr_reader :logger
    attr_reader :retries
    attr_reader :timeout

    def thread_safe?
      @thread_safe
    end

    def persistent?
      @persistent
    end

    def detect_device?
      @detect_device
    end

    def with_device(&block)
      if @io
        if IO.select(nil, nil, [@io.io], 0)
          logger&.debug("Closing stale device handle due to I/O error")
          close
        end
      end

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

    def close
      if @io
        @io.close rescue nil
        @io = nil
      end
    end

    private

    def backend
      options[:backend] || :serial_port
    end

    def device_cls
      backend = self.backend.to_s
      Backend.const_get(
        backend[0..0].upcase +
          backend[1..].to_s.gsub(/_(.)/) { $1.upcase } +
          'Backend'
      ).const_get(:Device)
    rescue NameError => exc
      raise InvalidBackend, "Backend #{backend} is not known: #{exc.class}: #{exc}"
    end

    def open_device
      if detect_device? && device.nil?
        logger&.debug("Detecting device")
        mod = eval(self.class.name.sub(/::\w+\z/, ''))
        @device = Seriamp.detect_device(mod, *glob, logger: logger, timeout: timeout)
        if @device
          logger&.info("Using #{device} as TTY device")
        else
          raise NoDevice, "No device specified and device could not be detected automatically"
        end
      end

      logger&.debug("Opening #{device}")
      @io = device_cls.new(device, logger: logger)

      buf = Utils.consume_data(@io.io, logger,
        "Serial device readable after opening - unread previous response?")
      report_unread_response(buf)

      begin
        yield @io
      ensure
        unless persistent?
          @io.close rescue nil
          @io = nil
        end
      end
    end

    def dispatch(cmd)
      start = Utils.monotime
      with_device do
        @io.syswrite(cmd.encode('ascii'))
        read_response
      end.tap do
        elapsed = Utils.monotime - start
        logger&.debug("#{self.class.name}: dispatched #{cmd} in #{'%.2f' % elapsed} s")
      end
    end

    def read_response
      resp = +''
      deadline = [Utils.monotime + timeout, @next_earliest_deadline].max
      loop do
        begin
          chunk = @io.read_nonblock(1000)
          if chunk
            resp += chunk
            break if complete_response?(chunk)
          end
        rescue IO::WaitReadable
          budget = deadline - Utils.monotime
          if budget < 0
            raise CommunicationTimeout
          end
          IO.select([@io.io], nil, nil, budget)
        end
      end
      resp
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

    def extend_next_deadline(delta)
      # 2 seconds here is definitely insufficient for RX-V1500 powering on
      @next_earliest_deadline = Utils.monotime + delta
    end
  end
end
