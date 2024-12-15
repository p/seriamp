# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/recursive_mutex'

# I/O flow:
# dispatch: writes bytes to the device
# -> read_response: reads at least one complete response, may read
#      multiple responses; the responses are stored in @read_buf
# -> parse_one_response: parses responses in the read buffer, identifies
#      command responses, returns the most recent command response.
#      Warns if more than one response is in the read buffer.
#      (Processing of server-pushed status updates is not implemented yet.)

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

      if options[:structured_log]
        @logged_operations = []
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
        if @errored || @io.errored?
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
        @errored = false
      end
    end

    attr_reader :logged_operations

    private

    def backend
      options[:backend] || :serial_port
    end

    def device_cls
      backend = self.backend.to_s
      cls = Backend.const_get(
        backend[0..0].upcase +
          backend[1..].to_s.gsub(/_(.)/) { $1.upcase } +
          'Backend'
      ).const_get(:Device)
      if options[:structured_log]
        cls = Class.new(cls) do
          include Backend::StructuredLogging
        end
      end
      cls
    rescue NameError => exc
      raise InvalidBackend, "Backend #{backend} is not known: #{exc.class}: #{exc}"
    end

    def open_device
      if detect_device? && device.nil?
        logger&.debug("Detecting device")
        mod = eval(self.class.name.sub(/::\w+\z/, ''))
        @device = Seriamp::Detect::Serial.detect_device(mod, *glob, logger: logger, timeout: timeout)
        if @device
          logger&.info("Using #{device} as TTY device")
        else
          raise IndeterminateDevice, "No device specified and device could not be detected automatically"
        end
      end

      logger&.debug("Opening #{device}")
      modem_params = self.class.const_get(:MODEM_PARAMS)
      @io = device_cls.new(device, logger: logger, modem_params: modem_params)
      if options[:structured_log]
        @io.logged_operations = logged_operations
      end

      @read_buf = Utils.consume_data(@io, logger,
        "Serial device readable after opening - unread previous response?")
      report_unread_responses

      begin
        yield @io
      ensure
        unless persistent?
          close
        end
      end
    end

    def dispatch_and_parse(cmd)
      dispatch(cmd)
      get_command_response
    end

    def dispatch(cmd, read_response: true)
      start = Utils.monotime
      sanitized_cmd = cmd.gsub(/[\r\n]/, ' ').strip
      begin
        with_device do
          @io.syswrite(cmd.encode('ascii'))
          if read_response
            self.read_response
          end
          @io.clear_rts
        end.tap do
          elapsed = Utils.monotime - start
          logger&.debug("#{self.class.name}: #{sanitized_cmd} succeeded in #{'%.2f' % elapsed} s")
        end
      rescue => e
        elapsed = Utils.monotime - start
        logger&.debug("#{self.class.name}: #{sanitized_cmd} failed after #{'%.2f' % elapsed} s: #{e.class}: #{e}")
        raise
      end
    end

    def report_unread_responses
      loop do
        break if read_buf.empty?

        resp = extract_one_response!
        parsed_resp = begin
          parse_response(resp)
        rescue UnhandledResponse
          # seriamp doesn't know how to parse the response,
          # and the response was not expected to begin with.
          # Let this slide because otherwise any unhandled response
          # (and there are many cases where such can be produced)
          # causes desired operation to potentially fail.
          logger&.warn("Unhandled unread response: #{resp}")
          next
        end

        logger&.warn("Unread response: #{parsed_resp}")
      end
    end

    def extract_one_response
      raise NotImplementedError, 'Override in a subclass'
    end

    def extract_one_response!
      extract_one_response.tap do |resp|
        if resp.empty?
          raise NoResponse, "Empty response is unacceptable"
        end
        read_buf.replace(read_buf[resp.length..])
      end
    end

    def extract_delimited_response(*delimiters)
      if delimiters.empty?
        raise ArgumentError, 'Must specify at least one delimiter'
      end
      if delimiters.any?(&:empty?)
        raise ArgumentError, 'Delimiter cannot be empty'
      end
      if read_buf.empty?
        raise NoResponse, 'Attempting to extract a delimited response from an empty buffer'
      end
      best_index = nil
      best_delimiter_length = nil
      delimiters.each do |delimiter|
        index = read_buf.index(delimiter)
        if index and best_index.nil? || index < best_index
          best_index = index
          best_delimiter_length = delimiter.length
        end
      end
      if best_index
        read_buf[0..best_index+best_delimiter_length-1]
      else
        if delimiters.length == 1
          raise NoResponse, "Delimiter #{delimiter} not found in read buffer: #{read_buf}"
        else
          raise NoResponse, "No delimiters found in read buffer: #{read_buf}"
        end
      end
    end

    def get_command_response
      # TODO identify which are command responses and which are
      # status updates, handle accordingly.
      resp = extract_one_response!
      loop do
        if read_buf.empty?
          break
        end

        logger&.warn("Spurious response: #{resp}")
        # Yamaha receivers send unprompted status updates when e.g. receiver is
        # operated by the remote control.
        # These updates should be parsed and recorded in the current state
        # of the device, in order for the current state to be accurate.
        parse_response(resp)

        resp = extract_one_response!
      end
      parse_response(resp)
    end

    def parse_response(resp)
      raise NotImplementedError, 'Override in a subclass'
    end

    def reset_read_buf
      @read_buf = +''
    end

    attr_reader :read_buf

    # Reads at least one complete response into the read buffer.
    def read_response(append: false, timeout: nil)
      timeout ||= self.timeout
      unless append
        reset_read_buf
      end
      started = Utils.monotime
      deadline = [started + timeout, @next_earliest_deadline].max
      loop do
        begin
          chunk = @io.read_nonblock(1000)
          if chunk
            @read_buf += chunk
            break if response_complete?
          end
        rescue IO::WaitReadable
          budget = deadline - Utils.monotime
          if budget < 0
            raise CommunicationTimeout, "Timeout waiting for a response from receiver (waited #{'%.1f' % (Utils.monotime - started)} seconds)"
          end
          @io.readable?(budget)
        end
      end
      nil
    end

    def with_retry
      try = 1
      begin
        yield
      rescue NotApplicable
        raise
      rescue Seriamp::UnhandledResponse
        # The response was syntactically recognized but we don't handle it.
        # Retrying the operation is pointless in this case.
        raise
      rescue Seriamp::Error, IOError, SystemCallError => exc
        reset_device
        if try <= retries
          logger&.warn("Error during operation: #{exc.class}: #{exc} - will retry")
          try += 1
          Utils.sleep_before_retry
          retry
        else
          raise
        end
      rescue CommunicationTimeout
        reset_device
        raise
      end
    end

    def reset_device
      if detect_device?
        @device = nil
      end
      @errored = true
    end

    def retry_for_interval(interval)
      deadline = Utils.monotime + interval
      begin
        yield
      rescue Seriamp::Error => exc
        if Utils.monotime < deadline
          logger&.warn("Error during operation: #{exc.class}: #{exc} - will retry (#{interval} seconds)")
          retry
        end
      end
    end

    def extend_next_deadline(delta)
      # 2 seconds here is definitely insufficient for RX-V1500 powering on
      @next_earliest_deadline = Utils.monotime + delta
    end
  end
end
