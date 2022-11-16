# frozen_string_literal: true

require 'forwardable'
require 'ffi'

module Yamaha
  module Backend
    module FFIBackend

      class Device
        extend Forwardable

        def initialize(device, logger: nil)
          @logger = logger

          if @f
            yield
          else
            logger&.debug("Opening device #{device}")
            File.open(device, 'r+') do |f|
              unless f.isatty
                raise BadDevice, "#{device} is not a TTY"
              end
              @f = f
              set_rts

              if IO.select([f], nil, nil, 0)
                logger&.warn("Serial device readable without having been written to - concurrent access?")
              end

              tries = 0
              begin
                do_status
              rescue Timeout::Error
                tries += 1
                if tries < 5
                  logger&.warn("Timeout handshaking with the receiver - will retry")
                  retry
                else
                  raise
                end
              end
              yield.tap do
                @f = nil
              end
            end
          end
        rescue IOError => e
          if @f
            logger&.warn("#{e.class}: #{e} while operating, closing the device")
            @f.close
            raise
          end
        end

        attr_reader :logger
        def_delegators :@f, :close

        def set_rts
          ptr = IntPtr.new
          C.ioctl_p(@f.fileno, TIOCMGET, ptr)
          if logger&.level <= Logger::DEBUG
            flags = []
            %w(DTR RTS CTS).each do |bit|
              if ptr[:value] & self.class.const_get("TIOCM_#{bit}") > 0
                flags << bit
              end
            end
            if flags.empty?
              flags = ['(none)']
            end
            logger&.debug("Initial flags: #{flags.join(' ')}")
          end
          unless ptr[:value] & TIOCM_RTS
            logger&.debug("Setting RTS on #{device}")
            ptr[:value] |= TIOCM_RTS
            C.ioctl_p(@f.fileno, TIOCMSET, ptr)
          end
        end

        private

        class IntPtr < FFI::Struct
          layout :value, :int
        end

        module C
          extend FFI::Library
          ffi_lib 'c'

          # Ruby's ioctl doesn't support all of C ioctl interface,
          # in particular returning integer values that we need.
          # See https://stackoverflow.com/questions/1446806/getting-essid-via-ioctl-in-ruby.
          attach_function :ioctl, [:int, :int, :pointer], :int
          class << self
            alias :ioctl_p :ioctl
          end
          remove_method :ioctl
        end

        TIOCMGET = 0x5415
        TIOCMSET = 0x5418
        TIOCM_DTR = 0x002
        TIOCM_RTS = 0x004
        TIOCM_CTS = 0x020
      end
    end
  end
end
