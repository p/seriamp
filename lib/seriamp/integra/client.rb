# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/integra/protocol/methods'

module Seriamp
  module Integra

    RS232_TIMEOUT = 0.25

    class Client
      include Protocol::Methods

      def initialize(device: nil, glob: nil, logger: nil, retries: true, thread_safe: false)
        @logger = logger

        @device = device
        @detect_device = device.nil?
        @glob = glob
        @retries = case retries
          when nil, false
            0
          when true
            1
          when Integer
            retries
          else
            raise ArgumentError, "retries must be an integer, true, false or nil: #{retries}"
          end
        @thread_safe = !!thread_safe

        if thread_safe?
          @lock = Mutex.new
        end

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
      attr_reader :retries

      def thread_safe?
        @thread_safe
      end

      def detect_device?
        @detect_device
      end

      def get_power
        boolean_question('PWR')
      end

      def status
        {
          power: get_power,
        }
      end

      def with_device(&block)
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

      private

      include Protocol::Constants

      EOT = ?\x1a

      def open_device
        if detect_device? && device.nil?
          logger&.debug("Detecting device")
          @device = Seriamp.detect_device(Integra, *glob, logger: logger)
          if @device
            logger&.info("Using #{device} as TTY device")
          else
            raise NoDevice, "No device specified and device could not be detected automatically"
          end
        end

        logger&.debug("Opening #{device}")
        @io = Backend::SerialPortBackend::Device.new(device, logger: logger)

        Utils.consume_data(@io.io, logger,
          "Serial device readable after opening - unread previous response?")

        begin
          yield @io
        ensure
          @io.close rescue nil
          @io = nil
        end
      end

      def dispatch(cmd)
        start = Utils.monotime
        with_device do
          @io.syswrite(cmd.encode('ascii'))
          resp = read_response
          unless resp =~ /\A!1.+\x1a\z/
            raise "Malformed response: #{resp}"
          end
          resp[2...-1]
        end.tap do
          elapsed = Utils.monotime - start
          logger&.debug("Integra: dispatched #{cmd} in #{'%.2f' % elapsed} s")
        end
      end

      def read_response
        resp = +''
        deadline = Utils.monotime + 1
        loop do
          begin
            chunk = @io.read_nonblock(1000)
            if chunk
              resp += chunk
              break if chunk[-1] == EOT
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
            retry
          else
            raise
          end
        end
      end

      def question(cmd)
        dispatch("!1#{cmd}QSTN\r")
      end

      def boolean_question(cmd)
        resp = question(cmd)
        if resp.start_with?(cmd)
          case Integer(resp[cmd.length...])
          when 1
            true
          when 0
            false
          else
            raise "Bad response #{resp}"
          end
        end
      end
    end
  end
end
