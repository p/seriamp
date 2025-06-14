# frozen_string_literal: true

require_relative 'client'

module Seriamp

  class ThreadedClient < Client
    def initialize(**opts)
      super

      @write_queue = Queue.new
      @notify_read, @notify_write = IO.pipe
      @stop_requested = false

      @io_thread = Thread.new do
        Thread.current.name = "seriamp #{self.class.name} I/O: #{device}"

        loop do
          # Need to break here because with_device may be contains a loop?
          break if @stop_requested

          with_device do
            unless @io
              raise InternalError, "@io is nil in threaded client"
            end

            readable = IO.select([@notify_read, @io.io])

            # This does not break the outermost loop.
            break if @stop_requested

            payload, mutex, cv = @write_queue.pop
            @io.syswrite(payload)
            @io.clear_rts
            mutex.synchronize { cv.signal }
          end
        rescue => exc
          #raise
          warn "Seriamp I/O thread uncaught exception: #{exc.class}: #{exc}"
          sleep 1
        end
      end
    end

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

    end
  end
end
