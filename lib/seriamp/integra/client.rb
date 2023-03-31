# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/integra/protocol/methods'
require 'seriamp/integra/command_response'
require 'seriamp/client'

module Seriamp
  module Integra

    class Client < Seriamp::Client

      MODEM_PARAMS = {
        baud: 9600,
        data_bits: 8,
        stop_bits: 1,
        parity: 0, # SerialPort::NONE
      }.freeze

      # When DTR-50.4 is in standby, it takes 1.55 seconds in my environment
      # to turn the power on.
      DEFAULT_RS232_TIMEOUT = 2

      include Protocol::Methods

      def status
        with_device do
          {
            main_power: power,
            zone2_power: zone2_power,
            zone3_power: zone3_power,
            # Main volume is returned when the power is off.
            main_volume: main_volume,
          }.tap do |status|
            if status[:zone2_power]
              status[:zone2_volume] = zone2_volume
            end
            if status[:zone3_power]
              status[:zone3_volume] = zone3_volume
            end
            begin
              status[:zone4_power] = zone4_power
              status[:zone4_volume] = zone4_volume
            rescue NotApplicable
            end
          end
        end
      end

      def command(cmd)
        with_lock do
          with_retry do
            with_device do
              dispatch_and_parse("!1#{cmd}\r", cmd[0..2]).tap do |resp|
                if resp.response[0..2] != cmd[0..2]
                  #raise UnexpectedResponse, "Expected #{cmd} as response but received #{resp.response}"
                end
              end
            end
          end
        end
      end

      private

      include Protocol::Constants

      EOT = ?\x1a

      def dispatch_and_parse(cmd, expected_resp_cmd)
        if expected_resp_cmd.length != 3
          raise ArgumentError, "Command should be 3 characters: #{expected_resp_cmd}"
        end

        dispatch(cmd)

        loop do
          if read_buf.empty?
            read_response
          end

          resp = extract_one_response!
          resp = parse_response(resp)
          if resp.raw_setting == expected_resp_cmd
            return resp
          else
            logger&.warn("Spurious response: #{resp}")
          end
        end
      end

      def response_complete?
        read_buf.end_with?(EOT)
      end

      def extract_one_response
        if read_buf =~ /\A(.+?\x1a)/
          $1
        else
          raise UnexpectedResponse, "Could not find a valid response in the read buffer: #{read_buf}"
        end
      end

      def parse_response(resp)
        unless resp =~ /\A!1.+\x1a\z/
          raise "Malformed response: #{resp}"
        end
        resp = resp[2...-1]
        if resp =~ %r,\A([A-Z0-9]{3})N/A\z,
          raise NotApplicable, "Command is not supported by the receiver or cannot be executed given the receiver's present state"
        end
        if resp =~ /\A([A-Z0-9]{3})([0-9A-F]{2})\z/
          cmd, raw_value = $1, $2
          setting, values_map = Protocol::Constants::RESPONSE_VALUES.fetch(cmd)
          value = values_map.fetch(raw_value)
          CommandResponse.new(resp, cmd, setting, value)
        else
          raise NotImplementedError, "Unknown response: #{resp}"
        end
      end

      def question(cmd)
        with_lock do
          with_retry do
            with_device do
              resp = dispatch_and_parse("!1#{cmd}QSTN\r", cmd[0..2])
              if resp.command == cmd
                RESPONSE_VALUES.fetch(cmd).fetch(resp.value)
              else
                raise UnexpectedResponse, "Bad response #{resp} for #{cmd}"
              end
            end
          end
        end
      end

      def boolean_question(cmd)
        resp = question(cmd)
        case resp
        when true, false
          resp
        else
          raise "Bad response #{resp} for boolean question #{cmd}"
        end
      end

      def integer_question(cmd)
        resp = question(cmd)
        case resp
        when 'N/A'
          # Used in responses to e.g. PW4 command when receiver does not
          # support zone 4 (but the firmware understands the PW4 command).
          # If the firmware does not understand the command, it simply
          # does not respond causing a timeout exception to be raised.
          raise NotApplicable
        else
          Integer(resp)
        end
      end

      def hex_integer_question(cmd)
        resp = question(cmd)
        case resp
        when 'N/A'
          # Used in responses to e.g. PW4 command when receiver does not
          # support zone 4 (but the firmware understands the PW4 command).
          # If the firmware does not understand the command, it simply
          # does not respond causing a timeout exception to be raised.
          # Also used in response to e.g. ZVL (zone 2 volume) when zone 2 is
          # turned off (turning on zone 2 will make this command return a
          # good response on the same receiver).
          raise NotApplicable, "#{cmd} not applicable to this receiver at this time"
        else
          Integer(resp, 16)
        end
      end
    end
  end
end
