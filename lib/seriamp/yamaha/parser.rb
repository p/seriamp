# frozen_string_literal: true

require 'seriamp/ascii_table'

module Seriamp
  module Yamaha
    module Parser
      include Seriamp::AsciiTable

      def self.parse(resp, logger: nil)
        unless resp[-1] == ETX
          raise UnexpectedResponse, "Invalid response: expected to end with ETX: #{resp}"
        end

        case first_byte = resp[0]
        when DC2
          StatusResponseParser.parse(resp[1...-1], logger: logger)
        when STX
          CommandResponseParser.parse(resp[1...-1], logger: logger)
        when DC4
          ExtendedResponseParser.parse(resp[1...-1], logger: logger)
        else
          raise NotImplementedError, "\\x#{'%02x' % first_byte.ord} first response byte not handled"
        end
      end
    end
  end
end

require 'seriamp/yamaha/parser/status_response_parser'
require 'seriamp/yamaha/parser/command_response_parser'
require 'seriamp/yamaha/parser/extended_response_parser'
