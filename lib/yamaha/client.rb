# frozen_string_literal: true

require 'timeout'
require 'ffi'

module Yamaha

  class Error < StandardError; end
  class BadDevice < Error; end
  class BadStatus < Error; end
  class InvalidCommand < Error; end
  class NotApplicable < Error; end
  class UnexpectedResponse < Error; end

  RS232_TIMEOUT = 9
  DEFAULT_DEVICE_GLOB = '/dev/ttyUSB*'

  class Client
    def self.detect_device(*patterns, logger: nil)
      if patterns.empty?
        patterns = [DEFAULT_DEVICE_GLOB]
      end
      devices = patterns.map do |pattern|
        Dir.glob(pattern)
      end.flatten.uniq
      found = nil
      threads = devices.map do |device|
        Thread.new do
          Timeout.timeout(RS232_TIMEOUT) do
            logger&.debug("Trying #{device}")
            new(device, logger: logger).status
            logger&.debug("Found receiver at #{device}")
            found = device
          end
        end
      end
      threads.map(&:join)
      found
    end

    def initialize(device = nil, logger: nil)
      @logger = logger

      if device.nil?
        device = Dir[DEFAULT_DEVICE_GLOB].sort.first
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
      remote_command("7A1#{state ? 'D' : 'E'}")
    end

    def set_zone2_power(state)
      remote_command("7EB#{state ? 'A' : 'B'}")
    end

    def set_zone3_power(state)
      remote_command("7AE#{state ? 'D' : 'E'}")
    end

    def set_volume(volume)
    end

    def set_zone2_volume(volume)
      dispatch("#{STX}231#{'%02x' % volume}#{ETX}")
    end

    def zone2_volume_up
      remote_command('7ADA')
    end

    def zone2_volume_down
      remote_command('7ADB')
    end

    def set_zone3_volume(volume)
      dispatch("#{STX}234#{'%02x' % volume}#{ETX}")
    end

    def zone3_volume_up
      remote_command('7AFD')
    end

    def zone3_volume_down
      remote_command('7AFE')
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

    def dispatch(cmd)
      open_device do
        @f.syswrite(cmd.encode('ascii'))
        read_response
      end
    end

    def read_response
      resp = +''
      Timeout.timeout(2) do
        loop do
          ch = @f.sysread(1)
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
        while @f && IO.select([@f], nil, nil, 0)
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
      unless data.start_with?('@E01900')
        raise BadStatus, "Broken status response: expected to start with @E01900, actual #{data[0..6]}"
      end
      puts data
      p payload
      @status_string = data
      @status = {
        # RX-V1500: model R0177
        # Volume values (0.5 dB increment):
        # mute: 0
        # -80.0 dB (min): 39
        # 0 dB: 199
        # +14.5 dB (max): 228
        # Zone2 volume values (1 dB increment):
        # mute: 0
        # -33 dB (min): 39
        # 0 dB (max): 72
        volume: volume = data[15..16].to_i(16),
        volume_db: int_to_half_db(volume),
        zone2_volume: zone2_volume = data[17..18].to_i(16),
        zone2_volume_db: int_to_full_db(zone2_volume),
        zone3_volume: zone3_volume = data[129..130].to_i(16),
        zone3_volume_db: int_to_full_db(zone3_volume),
        pure_direct: data[28] == '1',
      }
    end

    def remote_command(cmd)
      dispatch("#{STX}0#{cmd}#{ETX}")
    end

    def extract_text(resp)
      # TODO: assert resp[0] == DC1, resp[-1] == ETX
      resp[1...-1]
    end

    def int_to_half_db(value)
      if value == 0
        :mute
      else
        (value - 39) / 2.0 - 80
      end
    end

    def int_to_full_db(value)
      if value == 0
        :mute
      else
        (value - 39) - 33
      end
    end
  end
end
