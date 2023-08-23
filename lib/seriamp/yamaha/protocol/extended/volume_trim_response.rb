# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class VolumeTrimResponse < GenericResponse
          include Yamaha::Helpers
          
          def initialize(cmd, value)
            super

            if value.length != 4
              raise ArgumentError, "Invalid value length: expected 4: #{value}"
            end

            @input_name = GetConstants::VOLUME_TRIM_INPUT_NAME_2_GET.fetch(value[0..1])
            @gain = parse_sequence(value[2..3], '00', -6, 6, 0.5)
          end
          
          attr_reader :input_name
          attr_reader :gain

          def to_s
            "#<#{self.class.name}: #{input_name}: #{gain} dB>"
          end
          
          def to_state
            {"#{input_name.gsub('/', '_').downcase}_volume_trim": gain}
          end
        end
      end
    end
  end
end
