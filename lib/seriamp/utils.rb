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
        raise InvalidOnOffValue, "Invalid on/off value: #{value}"
      end
    end

    module_function def one_arg(args)
      if args.length != 1
        raise ArgumentError, "Exactly one argument is required"
      end
      args.first
    end

    module_function def monotime
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    # Consumes data available from the I/O device (i.e., data which
    # caeses the IO#select call to return the device as being readable.
    # If +wait+ is specified, the code waits up to that long for the
    # first read attempt and each subsequent read attempt (for devices which
    # may send multiple responses in succession).
    module_function def consume_data(bio, logger, msg, wait: nil)
      warned = false
      buf = +''
      while IO.select([bio.io], nil, nil, wait || 0)
        unless warned
          logger&.warn(msg)
          warned = true
        end
        buf += bio.read_nonblock(1024)
      end
      unless buf.empty?
        logger&.warn("Consumed #{buf.length} bytes")
      end
      buf
    end

    module_function def sleep_before_retry
      # Sleep a random time between 1 and 2 seconds
      sleep(rand + 1)
    end
  end
end
