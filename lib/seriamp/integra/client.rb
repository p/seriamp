# frozen_string_literal: true

require 'timeout'
require 'seriamp/utils'
require 'seriamp/backend'
require 'seriamp/integra/protocol/methods'
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
        dispatch("!1#{cmd}\r")
      end

      private

      include Protocol::Constants

      EOT = ?\x1a

      def response_complete?
        read_buf.end_with?(EOT)
      end

      def read_response
        resp = super
        unless resp =~ /\A!1.+\x1a\z/
          raise "Malformed response: #{resp}"
        end
        resp[2...-1]
      end

      def question(cmd)
        resp = dispatch("!1#{cmd}QSTN\r")
        if resp.start_with?(cmd)
          resp[cmd.length...]
        else
          raise UnexpectedResponse, "Bad response #{resp} for #{cmd}"
        end
      end

      def boolean_question(cmd)
        resp = integer_question(cmd)
        case resp
        when 1
          true
        when 0
          false
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
