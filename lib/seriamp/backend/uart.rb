# frozen_string_literal: true

require 'forwardable'
require 'seriamp/uart'

module Seriamp
  module Backend
    module UartBackend

      class Device
        extend Forwardable

        def initialize(device_path, logger: nil, modem_params: nil)
          @logger = logger
          begin
            @io = UART.open(device_path, **modem_params)
          rescue Errno::ENOENT => exc
            raise NoDevice, "Device path missing: #{device_path}: #{exc.class}: #{exc}"
          end

          if block_given?
            begin
              yield self
            ensure
              close rescue nil
            end
          end
        end

        attr_reader :device

        attr_reader :io

        def_delegators :io, :close, :sysread, :read_nonblock, :readline

        def syswrite(chunk)
          # In theory the commands (i.e. writes) should be spaced out from
          # the previous writes, and possibly reads, by a certain minimum
          # time interval.
          io.syswrite(chunk)
        end

        def readable?(timeout = 0)
          !!IO.select([io], nil, nil, timeout)
        end

        def errored?
          !!IO.select(nil, nil, [io], 0)
        end

        # Called after writing is finished to reduce the noise induced in
        # the amplifier by the serial port cabling.
        def clear_rts
          UART.set_rts(io, false)
        end
      end
    end
  end
end
