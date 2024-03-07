# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class GraphicEqResponse < ResponseBase
          include Yamaha::Helpers
          include Constants

          register '030'

          def initialize(cmd, value)
            super

            if value.length != 4
              raise ArgumentError, "Invalid value length: expected 4: #{value}"
            end

            @channel = GRAPHIC_EQ_CHANNEL_MAP.fetch(value[0])
            band_map = GRAPHIC_EQ_CHANNEL_BAND_MAP.fetch(channel)
            @frequency = band_map.fetch(value[1])
            @gain = parse_sequence(value[2..3], '03', -6, 6, 0.5)
          end

          attr_reader :channel
          attr_reader :frequency
          attr_reader :gain

          def to_s
            "#<#{self.class.name}: #{channel} freq=#{frequency} gain=#{gain}>"
          end

          def to_state
            {
              "#{channel}_geq_#{frequency}": gain,
            }
          end
        end
      end
    end
  end
end
