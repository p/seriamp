# frozen_string_literal: true

require 'seriamp/yamaha/helpers'
require 'seriamp/yamaha/parser'
require 'seriamp/yamaha/constants'

module Seriamp
  module Yamaha
    class Response; end

    class Response::StatusResponse < Response
      extend Yamaha::Helpers
      extend Yamaha::Parser
      include Yamaha::Constants

      def self.parse(resp, logger: nil)
        if resp.length < 8
          raise HandshakeFailure, "Broken status response: expected at least 8 bytes, got #{resp.length} bytes; concurrent operation on device?"
        end
        payload = resp
        model_code = payload[0..4]
        version = payload[5]
        length = payload[6..7].to_i(16)
        data = payload[8...-2]
        if data.length != length
          raise HandshakeFailure, "Broken status response: expected #{length} bytes for data, got #{data.length} bytes; concurrent operation on device? #{data}"
        end
        unless data.start_with?('@E01900')
          raise HandshakeFailure, "Broken status response: expected data to start with @E01900, actual #{data[0..6]}"
        end
        received_checksum = payload[-2..]
        calculated_checksum = calculate_checksum(payload[...-2])
        if received_checksum != calculated_checksum
          raise HandshakeFailure, "Broken status response: calculated checksum #{calculated_checksum}, received checksum #{received_checksum}: #{data}"
        end

        state = parse_status_response_inner(data, model_code).update(
          model_code: model_code,
          model_name: MODEL_NAMES.fetch(model_code),
          firmware_version: version,
          raw_string: data,
        )

        new(state)
      end

      def initialize(state)
        @state = state
      end

      attr_reader :state

      private

      def self.parse_status_response_inner(data, model_code)
        table = Protocol::Status::STATUS_FIELDS.fetch(model_code)
        index = 0
        result = {}
        table.each do |entry|
          if index >= data.length
            # Truncated response - normally obtained when receiver is
            # in standby
            break
          end
          entry_index = 0
          case size_or_field = entry[entry_index]
          when Integer
            size = size_or_field
            entry_index += 1
          else
            size = 1
          end
          value = data[index...index+size]
          field = entry[entry_index]
          if field.nil?
            index += size
            next
          end
          fn = entry[entry_index+1] || field
          constant = "#{fn.to_s.upcase}_GET"
          parsed = begin
            table = Protocol::GetConstants.const_get(constant)
          rescue NameError
            send("parse_#{fn}", value, field)
          else
            parse_table(value, field, table, index)
          end
          case parsed
          when Hash
            result.update(parsed)
          else
            result.update(field => parsed)
          end
          index += size
        end
        result
      end

      def self.parse_table(value, field, table, index)
        # Some values are nil, e.g. sleep
        if table.key?(value)
          table[value]
        else
          raise UnhandledResponse, "Bad value for field #{field}: #{value} (at DT#{index})"
        end
      end
    end
  end
end
