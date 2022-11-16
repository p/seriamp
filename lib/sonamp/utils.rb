# frozen_string_literal: true

module Sonamp
  module Utils

    module_function def parse_on_off(value)
      case value&.downcase
      when '1', 'on', 'yes', 'true'
        true
      when '0', 'off', 'no', 'false'
        false
      else
        raise ArgumentError, "Invalid on/off value: #{value}"
      end
    end
  end
end
