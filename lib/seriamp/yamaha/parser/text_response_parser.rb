# frozen_string_literal: true

require 'seriamp/yamaha/response/text_response'
require 'seriamp/yamaha/parsing_helpers'

module Seriamp
  module Yamaha
    module Parser; end

    module Parser::TextResponseParser
      extend Yamaha::ParsingHelpers

      def self.parse(resp, logger: nil)
        if resp.length != 10
          raise "Unexpected text response: should be length 10: #{resp}"
        end
        if resp[0] != ?0
          raise "Unexpected first byte: #{resp[0]}; should be '0'"
        end
        field_name = parse_flag(resp[1], {
          '0' => :tuner_frequency_text,
          '1' => :main_volume_text,
          '2' => :zone2_volume_text,
          '3' => :input_name_text,
          '4' => :zone2_input_name_text,
          '5' => :zone3_volume_text,
          '6' => :zone3_input_name_text,
        }, 'Unknown field name')
        text = resp[2..].strip
        Yamaha::Response::TextResponse.new(field_name, text)
      end
    end
  end
end
