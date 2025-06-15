# frozen_string_literal: true

require_relative 'client'

module Seriamp

  class ThreadedClient < Client
    def initialize(**opts)
      super

      @write_queue = Queue.new
      @notify_read, @notify_write = IO.pipe
      @stop_requested = false
      @responses = Queue.new

      @io_thread = Thread.new do
        Thread.current.name = "seriamp #{self.class.name} I/O: #{device}"

        loop do
          # Need to break here because with_device maybe contains a loop?
          break if @stop_requested

          with_device do
            unless @io
              raise InternalError, "@io is nil in threaded client"
            end

            readable, = IO.select([@notify_read, @io.io])

            # This does not break the outermost loop.
            break if @stop_requested

            readable.each do |readable_io|
              if readable_io == @io.io
                read_any = false
                begin
                  while chunk = @io.read_nonblock(1024)
                    #@read_buf ||= +''
                    @read_buf << chunk
                    read_any = true
                  end
                rescue IO::EAGAINWaitReadable
                end
                if read_any
                  while response_complete?
                    @responses << extract_one_response!
                  end
                end
              else
                # @notify_read
                payload, mutex, cv = @write_queue.pop
                @io.syswrite(payload)
                @io.clear_rts
                mutex.synchronize { cv.signal }
              end
            end
          end
        rescue => exc
          #raise
          warn "Seriamp I/O thread uncaught exception: #{exc.class}: #{exc}"
          sleep 1
        end
      end
    end

    attr_reader :responses

    def close
      @stop_requested = true
      begin
        Timeout.timeout(1) do
          @notify_write << 'q'
        end
      rescue Timeout::Error
        #raise
      end
      begin
        Timeout.timeout(5) do
          @io_thread.join
        end
      rescue Timeout::Error
        #raise
      end
      @io_thread.kill
      @notify_read.close rescue nil
      @notify_write.close rescue nil
    end

    # do_write performs encoding to ascii in the calling thread, and
    # the actual I/O in the I/O thread. Thus the parent do_write implementation
    # is spread over two methods.
    def do_write(payload)
      mutex = Mutex.new
      cv = ConditionVariable.new
      @write_queue << [payload.encode('ascii'), mutex, cv]
      @notify_write << 'w'
      mutex.synchronize { cv.wait(mutex) }
    end

    alias_method :read_response_impl, :read_response

    def read_response(append: true, timeout: nil)
      Timeout.timeout(timeout || 1) do
        responses.shift
      end
    end

    def consume_unread_responses
    end

    def reset_read_buf_before_reading
    end
  end
end
