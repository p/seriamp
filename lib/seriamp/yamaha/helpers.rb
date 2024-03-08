# frozen_string_literal: true

require 'seriamp/ascii_table'
require 'seriamp/yamaha/protocol/extended/constants'

module Seriamp
  module Yamaha
    module Helpers
      include Seriamp::AsciiTable

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
        if value < min || value > max
          # TODO consider a more specialized exception class.
          raise ArgumentError, "Sequence value out of range: #{value}: accepted range is #{min}..#{max}"
        end
        delta = Integer((value - min) / step)
        base_value = Integer(min_serialized, 16)
        final_value = base_value + delta
        "%0#{min_serialized.length}X" % final_value
      end

      def hash_get_with_upcase(hash, key)
        hash.fetch(key)
      rescue KeyError => exc
        begin
          hash.fetch(key.upcase)
        rescue KeyError
          raise exc
        end
      end

      def frame_extended_request(cmd)
        payload = "20#{'%02X' % cmd.length}#{cmd}"
        checksum = calculate_checksum(payload)
        "#{DC4}#{payload}#{checksum}#{ETX}"
      end

      def calculate_checksum(str)
        sum = str.each_byte.map(&:ord).inject(0) { |sum, c| sum + c }
        '%02X' % (sum & 0xFF)
      end

      PARAMETRIC_EQ_FREQUENCY_LOGS = Yamaha::Protocol::Extended::Constants::
        PARAMETRIC_EQ_MAP.map do |k, v|
          Math.log(v)
        end.freeze

      def serialize_parametric_frequency(freq)
        freq_log = Math.log(freq)

        pick_closest_value(freq_log, PARAMETRIC_EQ_FREQUENCY_LOGS,
          Yamaha::Protocol::Extended::Constants::PARAMETRIC_EQ_MAP)
      end

      def serialize_parametric_q(q)
        pick_closest_value(q,
          Yamaha::Protocol::Extended::Constants::PARAMETRIC_EQ_Q_MAP.values,
          Yamaha::Protocol::Extended::Constants::PARAMETRIC_EQ_Q_MAP)
      end

      def pick_closest_value(value, scale, mapping)
        if value <= scale.first
          return mapping.keys.first
        elsif value >= scale.last
          return mapping.keys.last
        end

        1.upto(scale.length-1) do |i|
          if scale[i] >= value
            if value - scale[i-1] < scale[i] - value
              return mapping.keys[i-1]
            else
              return mapping.keys[i]
            end
          end
        end

        raise NotImplemented, 'Should never get here'
      end
    end
  end
end
