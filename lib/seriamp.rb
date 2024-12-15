# frozen_string_literal: true

require 'seriamp/version'

module Seriamp
  autoload :FaradayFacade, 'seriamp/faraday_facade'
  autoload :Sonamp, 'seriamp/sonamp'
  autoload :Yamaha, 'seriamp/yamaha'

  # Reads any data from the device at specified path and returns it.
  # Intended for development/debugging.
  module_function def flush_device_read_buffer(path)
    contents = nil
    begin
      File.open(path) do |io|
        while chunk = io.read_nonblock(1024)
          contents ||= +''
          contents += chunk
        end
      end
    rescue IO::EAGAINWaitReadable
    end
    contents
  end
end
