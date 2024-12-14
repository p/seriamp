# frozen_string_literal: true

require 'seriamp/ascii_table'

module Seriamp
  module Yamaha
    class Response
      include Seriamp::AsciiTable
      
      def self.parse(resp)
        unless resp[-1] == ETX
          raise UnexpectedResponse, "Invalid response: expected to end with ETX: #{resp}"
        end
        
        case first_byte = resp[0]
        when STX
          RemoteCommandResponse.parse(resp[1..-1])
        when DC2
          StatusResponse.parse(resp[1..-1])
        when DC4
          ExtendedResponse.parse(resp[1..-1])
        else
          raise NotImplementedError, "\\x#{'%02x' % first_byte.ord} first response byte not handled"
        end
      end
    end
  end
end

require 'seriamp/yamaha/response/status_response'
require 'seriamp/yamaha/response/remote_command_response'
require 'seriamp/yamaha/response/extended_response'
