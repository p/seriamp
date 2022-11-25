# frozen_string_literal: true

require 'timeout'
require 'sonamp/error'
require 'sonamp/backend/serial_port'

module Sonamp

  RS232_TIMEOUT = 3

  class Client
    def initialize(device = nil, logger: nil)
      @logger = logger

      if device.nil?
        device = Sonamp.detect_device(logger: logger)
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

    def get_zone_power(zone = nil)
      get_zone_state('P', zone)
    end

    def set_zone_power(zone, state)
      if zone < 1 || zone > 4
        raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
      end
      cmd = ":P#{zone}#{state ? 1 : 0}"
      expected = cmd[1...cmd.length]
      dispatch_assert(cmd, expected)
    end

    def power_off
      1.upto(4).each do |zone|
        set_zone_power(zone, false)
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

    def get_zone_fault(zone = nil)
      get_zone_state('FP', zone)
    end

    def get_bbe(zone = nil)
      get_zone_state('BP', zone)
    end

    def get_bbe_high_boost(zone = nil)
      get_zone_state('BH', zone)
    end

    def get_bbe_low_boost(zone = nil)
      get_zone_state('BL', zone)
    end

    def get_auto_trigger_input(zone = nil)
      get_zone_state('ATI', zone)
    end

    def get_voltage_trigger_input(zone = nil)
      get_zone_state('VTI', zone)
    end

    def get_firmware_version
      global_query('VER')
    end

    def get_temperature
      Integer(global_query('TP'))
    end

    def status
      # Reusing the opened device file makes :VTIG? fail even with a delay
      # in front.
      #open_device do
        {
          firmware_version: get_firmware_version,
          temperature: get_temperature,
          zone_power: get_zone_power,
          zone_fault: get_zone_fault,
          zone_volume: get_zone_volume,
          channel_volume: get_channel_volume,
          zone_mute: get_zone_mute,
          channel_mute: get_channel_mute,
          bbe: get_bbe,
          bbe_high_boost: get_bbe_high_boost,
          bbe_low_boost: get_bbe_low_boost,
          auto_trigger_input: get_auto_trigger_input,
          voltage_trigger_input: get_voltage_trigger_input,
          channel_front_panel_level: get_channel_front_panel_level,
        }
      #end
    end

    private

    def open_device
      if @f
        yield
      else
        Backend::SerialPortBackend::Device.new(device, 'r+b') do |f|
          @f = f
          yield.tap do
            @f = nil
          end
        end
      end
    end

    def dispatch(cmd, resp_lines_count = 1)
      open_device do
        with_timeout do
          @f.syswrite("#{cmd}\x0d")
        end
        resp = 1.upto(resp_lines_count).map do
          read_line(@f, cmd)
        end
        if resp_lines_count == 1
          resp.first
        else
          resp
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
      Timeout.timeout(RS232_TIMEOUT, CommunicationTimeout, &block)
    end

    def read_line(f, cmd)
      with_timeout do
        f.readline.strip.tap do |resp|
          if resp == 'ERR'
            raise InvalidCommand, "Invalid command: #{cmd}"
          elsif resp == 'N/A'
            raise NotApplicable, "Command was recognized but could not be executed - is serial control enabled on the amplifier?"
          end
        end
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

    def get_zone_value(cmd_prefix, zone, boolize: false)
      if zone
        if zone < 1 || zone > 4
          raise ArgumentError, "Zone must be between 1 and 4: #{zone}"
        end
        resp = dispatch(":#{cmd_prefix}#{zone}?")
        typecast_value(resp[cmd_prefix.length + 1..], boolize)
      else
        index = 1
        hashize_query_result(dispatch(":#{cmd_prefix}G?", 4), cmd_prefix, boolize)
      end
    end

    def hashize_query_result(resp_lines, cmd_prefix, boolize)
      index = 1
      Hash[resp_lines.map do |resp|
        value = typecast_value(extract_suffix(resp, "#{cmd_prefix}#{index}"), boolize)
        [index, value].tap do
          index += 1
        end
      end]
    end

    def get_zone_state(cmd_prefix, zone)
      get_zone_value(cmd_prefix, zone, boolize: true)
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
        hashize_query_result(dispatch(":#{cmd_prefix}G?", 8), cmd_prefix, boolize)
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
  end
end
