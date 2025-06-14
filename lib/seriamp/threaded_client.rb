# frozen_string_literal: true

require_relative 'client'

module Seriamp

  class ThreadedClient < Client
    def initialize(**opts)
      super

      @write_queue = Queue.new
      @notify_read, @notify_write = IO.pipe

      @io_thread = Thread.new do
        with_device do
          loop do
            readable = IO.select([@notify_read])
            payload, mutex, cv = @write_queue.pop
            @io.syswrite(payload)
            @io.clear_rts
            mutex.synchronize { cv.signal }
          end
        end
      end
    end

    def do_write(payload)
      mutex = Mutex.new
      cv = ConditionVariable.new
      @write_queue << [payload.encode('ascii'), mutex, cv]
      @notify_write << 'w'
      mutex.synchronize { cv.wait(mutex) }
    end
  end
end
