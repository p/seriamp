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
            # RX-V1800/RX-V3800 documentation states that for HDMI
            # inputs, the jack number is encoded 1-based (unlike 0-based
            # encoding used for all other inputs and outputs).
            # RX-V1700/RX-V2700 specify 0-based encoding for HDMI jacks also.
            # In reality the RX-V3800 hardware uses 0-based encoding.
            @gain = parse_sequence(value[2..3], '00', -6, 6, 0.5)
          end

          attr_reader :input_name
          attr_reader :gain

          def to_s
            "#<#{self.class.name}: #{input_name}: #{gain} dB>"
          end

          def to_state
            {"#{input_name.gsub(%r,[/ -],, '_').downcase}_volume_trim": gain}
          end
        end
      end
    end
  end
end
