# frozen_string_literal: true

require 'seriamp/version'

module Seriamp
  autoload :FaradayFacade, 'seriamp/faraday_facade'
  autoload :Sonamp, 'seriamp/sonamp'
  autoload :Yamaha, 'seriamp/yamaha'
  autoload :Utils, 'seriamp/utils'

  # Reads any data from the device at specified path and returns it.
  # Intended for development/debugging.
  module_function def flush_device_read_buffer(path)
    contents = nil
    last_read = nil
    File.open(path) do |io|
      begin
        while chunk = io.read_nonblock(1024)
          contents ||= +''
          contents += chunk
          last_read = Utils.monotime
        end
      rescue IO::EAGAINWaitReadable
        # The receiver does not put the entire response on the wire all
        # at once. If we have been able to read something, we should wait
        # up to the 500 ms that the protocol documentation specifies as
        # the maximum permitted time for the hardware to respond to see
        # if additional data showed up on the wire.
        # TODO the Client code should apply the same logic if it read
        # a partial response.
        if last_read
          delta = last_read + 0.5 - Utils.monotime
          if delta > 0
            IO.select([io], nil, nil, delta)
            retry
          end
        end
      end
    end
    contents
  end
end
