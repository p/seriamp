# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Response
      module ExtendedResponse
        class InputLabelResponse < ResponseBase
          include Yamaha::Helpers

          register '011'

          def initialize(cmd, value)
            super

            if value.length != 14
              raise ArgumentError, "Invalid value length: expected 14: #{value} (#{value.length})"
            end

            @input_name = Yamaha::Protocol::GetConstants::VOLUME_TRIM_INPUT_NAME_2_GET.fetch(value[1..2])
            # "Character No." (length?) is always 09 in my testing.
            # p value[3..4]
            @label = value[5..]
          end

          attr_reader :input_name
          attr_reader :label

          def to_s
            "#<#{self.class.name}: #{input_name}: #{label}>"
          end

          def to_state
            {"#{input_name.gsub(%r,[/ -],, '_').downcase}_label": label}
          end
        end
      end
    end
  end
end
