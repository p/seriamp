# frozen_string_literal: true

require 'seriamp/ascii_table'

module Seriamp
  module Yamaha
    class Response
      include Seriamp::AsciiTable
      
      def self.parse(resp, logger: nil)
        unless resp[-1] == ETX
          raise UnexpectedResponse, "Invalid response: expected to end with ETX: #{resp}"
        end
        
        case first_byte = resp[0]
        when STX
          CommandResponse.parse(resp[1..-1], logger: logger)
        when DC2
          StatusResponse.parse(resp[1..-1], logger: logger)
        when DC4
          ExtendedResponse.parse(resp[1..-1], logger: logger)
        else
          raise NotImplementedError, "\\x#{'%02x' % first_byte.ord} first response byte not handled"
        end
      end
    end
  end
end

require 'seriamp/yamaha/response/status_response'
require 'seriamp/yamaha/response/command_response'
require 'seriamp/yamaha/response/extended_response'
