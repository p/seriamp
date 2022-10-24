require 'timeout'
require 'ffi'

module Yamaha
  VERSION = -'0.0.1'

  class Error < StandardError; end
  class BadDevice < Error; end
  class BadStatus < Error; end
  class InvalidCommand < Error; end
  class NotApplicable < Error; end
  class UnexpectedResponse < Error; end

  class Client
    def initialize(device = nil, logger: nil)
      @logger = logger

      if device.nil?
        device = Dir['/dev/ttyUSB*'].sort.first
        if device
          logger&.info("Using #{device} as TTY device")
        end
      end

      unless device
        raise ArgumentError, "No device specified and device could not be detected automatically"
      end

      @device = device
    end

    attr_reader :device
    attr_accessor :logger

    def last_status
      unless @status
        open_device do
        end
      end
      @status.dup
    end

    def last_status_string
      unless @status_string
        open_device do
        end
      end
      @status_string.dup
    end

    def status
      do_status
      last_status
    end

    def set_power(state)
      dispatch("#{STX}07A1#{state ? 'D' : 'E'}#{ETX}")
    end

    def set_zone2_power(state)
      dispatch("#{STX}07EB#{state ? 'A' : 'B'}#{ETX}")
    end

    def set_volume(volume)
    end

    def set_zone2_volume(volume)
      dispatch("#{STX}23144#{ETX}")
    end

    def zone2_volume_up
      dispatch("#{STX}07ADA#{ETX}")
    end

    def zone2_volume_down
      dispatch("#{STX}07ADB#{ETX}")
    end

    def set_zone3_volume(volume)
      dispatch("#{STX}23444#{ETX}")
    end

    def set_subwoofer_level(level)
      dispatch("#{STX}249ff#{ETX}")
    end

    def get_zone2_volume_text
      extract_text(dispatch("#{STX}22002#{ETX}"))[3...]
    end

    def get_zone3_volume_text
      extract_text(dispatch("#{STX}22005#{ETX}"))[3...]
    end

    def set_pure_direct(state)
      dispatch("#{STX}07E8#{state ? '0' : '2'}#{ETX}")
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

    # ASCII table: https://www.asciitable.com/
    DC1 = +?\x11
    DC2 = +?\x12
    ETX = +?\x03
    STX = +?\x02
    DEL = +?\x7f

    TIOCMGET = 0x5415
    TIOCMSET = 0x5418
    TIOCM_DTR = 0x002
    TIOCM_RTS = 0x004
    TIOCM_CTS = 0x020

    STATUS_REQ = -"#{DC1}001#{ETX}"

    ZERO_ORD = '0'.ord

    def open_device
      if @f
        yield
      else
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

    def set_rts
      ptr = IntPtr.new
      C.ioctl_p(@f.fileno, TIOCMGET, ptr)
      ptr[:value] |= TIOCM_RTS
      C.ioctl_p(@f.fileno, TIOCMSET, ptr)
    end

    def dispatch(cmd)
      open_device do
        @f.write(cmd.encode('ascii'))
        read_response
      end
    end

    def read_response
      resp = +''
      Timeout.timeout(2) do
        loop do
          ch = @f.read(1)
          if ch
            resp << ch
            break if ch == ETX
          else
            sleep 0.1
          end
        end
      end
      resp
    end

    def do_status
      resp = nil
      loop do
        resp = dispatch(STATUS_REQ)
        again = false
        while IO.select([@f], nil, nil, 0)
          logger&.warn("Serial device readable after completely reading status response - concurrent access?")
          read_response
          again = true
        end
        break unless again
      end
      payload = resp[1...-1]
      @model_code = payload[0..4]
      @version = payload[5]
      length = payload[6..7].to_i(16)
      data = payload[8...-2]
      if data.length != length
        raise BadStatus, "Broken status response: expected #{length} bytes, got #{data.length} bytes; concurrent operation on device?"
      end
      puts data
      p payload
      @status_string = data
      @status = {
        # RX-V1500: model R0177
        pure_direct: data[28] == '1',
      }
    end

    def remote_command(cmd)
      dispatch("#{STX}\x00#{cmd}#{ETX}")
    end

    def extract_text(resp)
      # TODO: assert resp[0] == DC1, resp[-1] == ETX
      resp[1...-1]
    end
  end
end

# https://www.thegeekdiary.com/serial-port-programming-reading-writing-status-of-control-lines-dtr-rts-cts-dsr/
