# frozen_string_literal: true

require 'timeout'
require 'seriamp/error'
require 'seriamp/backend'
require 'seriamp/client'

module Seriamp
  module Sonamp

    class Client < Seriamp::Client

      # Sonamps do not work when HARD flow control is specified.
      # NONE and SOFT are OK.
      MODEM_PARAMS = {
        baud: 9600,
        data_bits: 8,
        stop_bits: 1,
        parity: 0, # SerialPort::NONE
        # flow_control: 0, # SerialPort::NONE
        # flow_control: 1, # SerialPort::SOFT
      }.freeze

      DEFAULT_RS232_TIMEOUT = 3

      def present?
        get_power(1)
        true
      end

      def get_power(zone = nil)
        get_zone_state('P', zone)
      end

      def set_power(zone, state)
        if zone < 1 || zone > 4
          raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
        end
        cmd = ":P#{zone}#{state ? 1 : 0}"
        expected = cmd[1...cmd.length]
        dispatch_assert(cmd, expected)
      end

      def power_off
        1.upto(4).each do |zone|
          set_power(zone, false)
        end
      end

      def get_zone_volume(zone = nil)
        get_zone_value('V', zone)
      end

      def set_zone_volume(zone, volume)
        if volume < 0 || volume > 100
          raise ArgumentError, "Volume must be between 0 and 100: #{volume}"
        end
        set_zone_value('V', zone, volume)
      end

      def set_zone_mute(zone, state)
        set_zone_value('M', zone, state ? 1 : 0)
      end

      def get_channel_volume(channel = nil)
        get_channel_value('VC', channel)
      end

      def set_channel_volume(channel, volume)
        if channel < 1 || channel > 8
          raise ArgumentError, "Channel must be between 1 and 4: #{channel}"
        end
        if volume < 0 || volume > 100
          raise ArgumentError, "Volume must be between 0 and 100: #{volume}"
        end
        cmd = ":VC#{channel}#{volume}"
        expected = cmd[1...cmd.length]
        dispatch_assert(cmd, expected)
      end

      def set_channel_mute(channel, state)
        set_channel_value('MC', channel, state ? 1 : 0)
      end

      def get_zone_mute(zone = nil)
        get_zone_state('M', zone)
      end

      def get_channel_mute(channel = nil)
        get_channel_state('MC', channel)
      end

      def get_channel_front_panel_level(channel = nil)
        get_channel_value('TVL', channel)
      end

      def get_fault(zone = nil)
        get_zone_state('FP', zone)
      end

      def set_bbe(zone, state)
        set_zone_value('BP', zone, state ? 1 : 0)
      end

      def get_bbe(zone = nil)
        get_zone_state('BP', zone)
      end

      def set_bbe_boost(zone, state)
        set_zone_value('BB', zone, convert_boolean_out(state))
      end

      def set_bbe_high_boost(zone, state)
        set_zone_value('BH', zone, convert_boolean_out(state))
      end

      def get_bbe_high_boost(zone = nil)
        get_zone_state('BH', zone)
      end

      def set_bbe_low_boost(zone, state)
        set_zone_value('BL', zone, convert_boolean_out(state))
      end

      def get_bbe_low_boost(zone = nil)
        get_zone_state('BL', zone)
      end

      def get_auto_trigger_input(zone = nil)
        get_zone_state('ATI', zone)
      end

      def get_voltage_trigger_input(zone = nil)
        get_zone_state('VTI', zone, include_all: true)
      end

      def get_firmware_version
        global_query('VER')
      end

      def get_temperature
        Integer(global_query('TP'))
      end

      STATUS_FIELDS = %i(
        firmware_version
        temperature
        power
        fault
        zone_volume
        channel_volume
        zone_mute
        channel_mute
        bbe
        bbe_high_boost
        bbe_low_boost
        auto_trigger_input
        voltage_trigger_input
        channel_front_panel_level
      ).freeze

      def status
        with_lock do
          # Reusing the opened device file makes :VTIG? fail even with a delay
          # in front.
          with_device do
            {}.tap do |status|
              STATUS_FIELDS.each do |field|
                status[field] = public_send("get_#{field}")
              end
            end
          end
        end
      end

      # Like with_device, but public.
      # This method does not yiel the device to the caller.
      def with_session
        with_device do
          yield
        end
      end

      private

      def with_device(&block)
        if @io
          yield @io
        else
          open_device(&block)
        end
      end

      def with_lock
        if thread_safe?
          @lock.synchronize do
            yield
          end
        else
          yield
        end
      end

      def dispatch(cmd, resp_lines_range_or_count = 1)
        resp_lines_range = if Range === resp_lines_range_or_count || Array === resp_lines_range_or_count
          resp_lines_range_or_count
        else
          1..resp_lines_range_or_count
        end

        with_lock do
          with_retry do
            with_device do
              with_timeout do
                @io.syswrite("#{cmd}\x0d")
              end
              resp = ''
              needed_lines = resp_lines_range.to_a.length
              loop do
                resp += read_line(@io, cmd)
                if resp.count("\r") >= needed_lines
                  break
                end
              end

              Utils.consume_data(@io, logger,
                "Serial device readable after completely reading status response - concurrent access?")

              lines = resp.strip.split("\r")
              lines.each do |line|
                if line == 'ERR'
                  raise InvalidCommand, "Invalid command: #{cmd}"
                elsif line == 'N/A'
                  raise NotApplicable, "Command was recognized but could not be executed - is serial control enabled on the amplifier?"
                end
              end

              if resp_lines_range_or_count == 1
                lines.first
              else
                lines
              end
            end
          end
        end
      end

      def dispatch_assert(cmd, expected)
        resp = dispatch(cmd)
        if resp != expected
          raise UnexpectedResponse, "Expected #{expected}, got #{resp}"
        end
      end

      def extract_suffix(resp, expected_prefix)
        unless resp[0..expected_prefix.length-1] == expected_prefix
          raise UnexpectedResponse, "Unexpected response: expected #{expected_prefix}..., actual #{resp}"
        end
        resp[expected_prefix.length..]
      end

      def dispatch_extract_suffix(cmd, expected_prefix)
        resp = dispatch(cmd)
        extract_suffix(resp, expected_prefix)
      end

      def global_query(cmd)
        dispatch_extract_suffix(":#{cmd}?", cmd)
      end

      def with_timeout(&block)
        Timeout.timeout(timeout, CommunicationTimeout, "Timeout waiting for a response from amplifier (waited #{'%.1f' % timeout} seconds)", &block)
      end

      def read_line(f, cmd)
        with_timeout do
          resp = +''
          started = Utils.monotime
          deadline = started + timeout
          loop do
            begin
              buf = f.read_nonblock(1024)
              if buf
                resp += buf
                break if buf[-1] == ?\r
              end
            rescue IO::WaitReadable
              budget = deadline - Utils.monotime
              if budget < 0
                raise CommunicationTimeout, "Timeout waiting for a response from amplifier (waited #{'%.1f' % (Utils.monotime - started)} seconds)"
              end
              f.readable?(budget)
            end
          end
          resp
        end
      end

      def set_zone_value(cmd_prefix, zone, value)
        if zone < 1 || zone > 4
          raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
        end
        cmd = ":#{cmd_prefix}#{zone}#{value}"
        expected = cmd[1...cmd.length]
        dispatch_assert(cmd, expected)
      end

      def get_zone_value(cmd_prefix, zone, boolize: false, include_all: false)
        if zone
          if zone < 1 || zone > 4
            raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
          end
          sent_prefix = "#{cmd_prefix}#{zone}"
          resp = dispatch(":#{sent_prefix}?")
          unless resp.start_with?(sent_prefix)
            raise UnexpectedResponse, "Expected #{sent_prefix}..., received #{resp}"
          end
          typecast_value(resp[sent_prefix.length..], boolize)
        else
          range = include_all ? [1, 2, 3, 4, 'A'] : (1..4).to_a
          hashize_query_result(dispatch(":#{cmd_prefix}G?", range), cmd_prefix, boolize, range)
        end
      end

      def hashize_query_result(resp_lines, cmd_prefix, boolize, range)
        index = 1
        Hash[resp_lines.map do |resp|
          value = typecast_value(extract_suffix(resp, "#{cmd_prefix}#{range.to_a[index-1]}"), boolize)
          [index, value].tap do
            index += 1
          end
        end]
      end

      def get_zone_state(cmd_prefix, zone, include_all: false)
        get_zone_value(cmd_prefix, zone, boolize: true, include_all: include_all)
      end

      def set_channel_value(cmd_prefix, channel, value)
        if channel < 1 || channel > 8
          raise ArgumentError, "Channel must be between 1 and 8: #{channel}"
        end
        cmd = ":#{cmd_prefix}#{channel}#{value}"
        expected = cmd[1...cmd.length]
        dispatch_assert(cmd, expected)
      end

      def get_channel_value(cmd_prefix, channel, boolize: false)
        if channel
          if channel < 1 || channel > 8
            raise ArgumentError, "Channel must be between 1 and 8: #{channel}"
          end
          typecast_value(dispatch_extract_suffix(":#{cmd_prefix}#{channel}?", "#{cmd_prefix}#{channel}"), boolize)
        else
          index = 1
          hashize_query_result(dispatch(":#{cmd_prefix}G?", 8), cmd_prefix, boolize, 1..8)
        end
      end

      def get_channel_state(cmd_prefix, channel)
        get_channel_value(cmd_prefix, channel, boolize: true)
      end

      def typecast_value(value, boolize)
        value = Integer(value)
        if boolize
          value = value == 1
        end
        value
      end

      def convert_boolean_out(value)
        case value
        when true, 1
          1
        when false, 0
          0
        else
          raise ArgumentError, "Invalid boolean value: #{value}"
        end
      end

      def report_unread_response(buf)
        return if buf.nil?

        logger&.warn("Unread response: #{buf}")
      end
    end
  end
end
