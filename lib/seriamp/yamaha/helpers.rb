# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Helpers
      def serialize_volume(value, min_value, min_serialized, step)
        '%02X' % (((value - min_value) / step).round + min_serialized)
      end

      def parse_sequence(value, min_serialized, min, max, step)
        i_value = Integer(value, 16)
        min_serialized = Integer(min_serialized, 16)
        max_serialized = (min_serialized + (max - min) / step).round
        if i_value < min_serialized || i_value > max_serialized
          raise ArgumentError, "Volume value out of range: #{value}"
        end
        (i_value - min_serialized) * step + min
      end

      def encode_sequence(value, min_serialized, min, max, step)
        delta = Integer((value - min) / step)
        base_value = Integer(min_serialized, 16)
        final_value = base_value + delta
        if final_value < 0 || final_value >= 0x100
          raise "Value out of range in serializer: #{final_value} for #{value}"
        end
        '%02X' % final_value
      end
    end
  end
end
