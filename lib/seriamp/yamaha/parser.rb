# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Parser

      def parse_flag(value, map, error_msg)
        if map.key?(value)
          map[value]
        else
          raise UnexpectedResponse, "#{error_msg}: #{value}"
        end
      end

      def parse_half_db_volume(value, field_name)
        case i_value = Integer(value, 16)
        when 0
          # Mute
          nil
        when 0x27..0xE8
          (i_value - 0x27)/2.0 - 80
        else
          raise UnexpectedResponse, "Volume raw value (0.5 dB step) for #{fiel_name} out of range: #{value}"
        end
      end

      def parse_zone_tone(value, field_name)
        parse_sequence(value, '00', -10, 10, 1)
      end

      def parse_dialog_level(value, field_name)
        case value
        when 'FF'
          nil
        else
          parse_sequence(value, '00' -31, 0, 1)
        end
      end

      def parse_balance(value, field_name)
        parse_sequence(value, '00', -10, 10, 0.5)
      end

      def parse_status_flags(value, field_name)
        value = Integer(value, 16)
        {
          dd_karaoke: value & 0x1 != 0,
          dd_61: value & 0x2 != 0,
          dts_es_matrix_61: value & 0x4 != 0,
          dts_es_discrete_61: value & 0x8 != 0,
          dts_96_24: value & 0x10 != 0,
          pre_emphasis: value & 0x20 != 0,
          dpl_encoded: value & 0x40 != 0,
        }
      end

=begin I don't know what this is actually needed for, may have gotten myself confused with the Integra
      def parse_full_db_volume(value)
        case i_value = Integer(value, 16)
        when 0
          # Mute
          nil
        when 0x27..0x48
          i_value - 0x27 - 33
        else
          raise UnexpectedResponse, "Volume raw value (1 dB step) out of range: #{value}"
        end
      end

      def parse_zone2_volume(model_code, value)
        if model_code >= 'R0210'
          parse_half_db_volume(value)
        else
          parse_full_db_volume(value)
        end
      end
=end

      def parse_bool(value, field)
        case value
        when '0'
          false
        when '1'
          true
        else
          raise UnhandledResponse, "Bad value for boolean field #{field}: #{value}"
        end
      end

      def parse_inverted_bool(value, field)
        !parse_bool(value, field)
      end

      def parse_speaker_level(value, field)
        parse_sequence(value, '14', -10, 10, 0.5)
      end

      def parse_max_volume(value, field)
        case value
        when 'A'
          16.5
        else
          parse_sequence(value, '0', -30, 15, 5)
        end
      end

      def parse_osd_shift(value, field)
        parse_sequence(value, '00', -5, 5, 1)
      end

      def parse_gui_position(value, field)
        {
          gui_position_h: parse_sequence(value[0], '0', -5, 5, 1),
          gui_position_v: parse_sequence(value[1], '0', -5, 5, 1),
        }
      end
    end
  end
end
