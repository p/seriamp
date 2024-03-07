# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Extended
        class ParametricEqResponse < ResponseBase
          include Yamaha::Helpers
          include Constants

          register '034'

          def initialize(cmd, value)
            super

            if value.length != 7
              raise ArgumentError, "Invalid value length for parametric EQ response: expected 7: #{value}"
            end

            @channel = GRAPHIC_EQ_CHANNEL_MAP.fetch(value[0])
            @band = value[1].ord - '0'.ord + 1
            @frequency = value[2..3]
            @gain = parse_sequence(value[4..5], '00', -20, 6, 0.5)
            @q = PARAMETRIC_EQ_Q_MAP.fetch(value[6])
          end

          attr_reader :channel
          attr_reader :band
          attr_reader :frequency
          attr_reader :gain
          attr_reader :q

          def to_s
            "#<#{self.class.name}: #{channel} band=#{band} freq=#{frequency} gain=#{gain} q=#{q}>"
          end

          def to_state
            {
              "#{channel}_peq_#{band}": {frequency: frequency, gain: gain, q: q},
            }
          end
        end
      end
    end
  end
end
