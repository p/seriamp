# frozen_string_literal: true

module Seriamp
  module Utils

    module_function def parse_on_off(value)
      case value&.downcase
      when '1', 'on', 'yes', 'true'
        true
      when '0', 'off', 'no', 'false'
        false
      else
        raise ArgumentError, "Invalid on/off value: #{value}"
      end
    end

    module_function def monotime
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    module_function def consume_data(io, logger, msg)
      warned = false
      read_bytes = 0
      while IO.select([io], nil, nil, 0)
        unless warned
          logger&.warn(msg)
          warned = true
        end
        buf = io.read_nonblock(1024)
        read_bytes += buf.length
      end
      if read_bytes > 0
        logger&.warn("Consumed #{read_bytes} bytes")
      end
      nil
    end
  end
end
