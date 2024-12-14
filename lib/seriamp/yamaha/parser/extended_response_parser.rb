# frozen_string_literal: true

require 'seriamp/yamaha/helpers'
require 'seriamp/yamaha/response/extended_response'

module Seriamp
  module Yamaha
    module Parser; end

    module Parser::ExtendedResponseParser
      extend Yamaha::Helpers

      def self.parse(resp, logger: nil)
        unless resp[..1] == '20'
          raise UnexpectedResponse, "Invalid response: expected to start with 20: #{resp} #{resp[0].ord}"
        end
        length = Integer(resp[2..3], 16)
        received_checksum = resp[-2..]
        calculated_checksum = calculate_checksum(resp[...-2])
        if received_checksum != calculated_checksum
          raise UnexpectedResponse, "Broken status response: calculated checksum #{calculated_checksum}, received checksum #{received_checksum}: #{data}"
        end
        data = resp[4...-2]

        if length != data.length
          raise UnexpectedResponse, "Advertised data length does not match actual data received: #{length} vs #{data.length}"
        end

        if data.empty?
          raise InvalidCommand, "Extended command not recognized"
        end

        command_id = data[...3]
        status = data[3]
        command_data = data[4..]

        case status
        when '0'
          # OK
        when '1'
          raise UnexpectedResponse, "Guard by system: #{data}"
        when '2'
          raise UnexpectedResponse, "Guard by setting: #{data}"
        when '3'
          raise InvalidCommand, "Unrecognized command: #{data}"
        when '4'
          raise InvalidCommand, "Command parameter error: #{data}"
        else
          raise UnexpectedResponse, "Unexpected status byte: #{status}: #{data}"
        end

        if command_data.empty?
          return nil
        end

        # Special case for input labels...
        # Apparently the receiver returns the "rename id" but no subsequent
        # fields.
        if command_id == '011' && command_data == '0'
          return nil
        end

        cls = Yamaha::Response::ExtendedResponse::ResponseBase.registered_responses[command_id] ||
          Protocol::Extended::GenericResponse
        cls&.new(command_id, command_data)
      end
    end
  end
end
