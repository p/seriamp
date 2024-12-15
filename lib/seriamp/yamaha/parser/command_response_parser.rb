# frozen_string_literal: true

require 'seriamp/yamaha/response/command_response'
require 'seriamp/yamaha/parsing_helpers'
require 'seriamp/yamaha/helpers'
require 'seriamp/yamaha/protocol/get_constants'

module Seriamp
  module Yamaha
    module Parser; end

    module Parser::CommandResponseParser
      extend Yamaha::ParsingHelpers
      extend Yamaha::Helpers
      include Yamaha::Protocol::GetConstants

      def self.parse(resp, logger: nil)
        control_type = parse_flag(resp[0], {
          '0' => :rs232,
          '1' => :remote,
          '2' => :key,
          '3' => :system,
          '4' => :encoder,
        }, 'Invalid control type value')
        guard = parse_flag(resp[1], {
          '0' => nil,
          '1' => :system,
          '2' => :setting,
        }, 'Invalid guard value')
        command = resp[2..3]
        data = resp[4..5]
        logger&.debug("Command response: #{command} #{data}")
        state = if field_name_or_spec = GET_MAP[command]
          case field_name_or_spec
          when Array
            field_name = field_name_or_spec.first
            const_name = field_name_or_spec.last
          else
            field_name = const_name = field_name_or_spec
          end
          map = Yamaha::Protocol::GetConstants.const_get("#{const_name.upcase}_GET")
          # Value can be nil, e.g. lfe_indicator (when value is "---" in the
          # documentation).
          unless map.key?(data)
            logger&.warn("Unhandled value #{data} for #{command} (#{field_name})")
          end
          value = map[data]
          unless Hash === value
            value = {field_name => value}
          end
          value
        else
          case command
          when '15'
            if data.length != 2
              raise NotImplementedError
            end
            value = case Integer(data, 16)
            when 0xFF
              nil
            when 0x00..0x1F
              parse_sequence(data, '00', -31, 0, 1)
            else
              raise NotImplementedError
            end
            {dialog: value}
          when '16'
            parse_status_flags(data, 'STX response')
          when '22'
            {
              decoder_mode: DECODER_MODE_GET.fetch(data[0]),
              audio_source: AUDIO_SOURCE_GET.fetch(data[1]),
            }
          when '26'
            {main_volume: parse_half_db_volume(data, :main_volume)}
          when '27'
            {zone2_volume: parse_half_db_volume(data, :zone2_volume)}
          when '2D'
            {
              extended_surround: EXTENDED_SURROUND_GET.fetch(data),
            }
          when 'A2'
            {zone3_volume: parse_half_db_volume(data, :zone3_volume)}
          when '40'
            {front_right_level: parse_speaker_level(data, 'report response')}
          when '41'
            {front_left_level: parse_speaker_level(data, 'report response')}
          when '42'
            {center_level: parse_speaker_level(data, 'report response')}
          when '43'
            {surround_right_level: parse_speaker_level(data, 'report response')}
          when '44'
            {surround_left_level: parse_speaker_level(data, 'report response')}
          when '45'
            {presence_right_level: parse_speaker_level(data, 'report response')}
          when '46'
            {presence_left_level: parse_speaker_level(data, 'report response')}
          when '47'
            {surround_back_right_level: parse_speaker_level(data, 'report response')}
          when '48'
            {surround_back_left_level: parse_speaker_level(data, 'report response')}
          when '49'
            {subwoofer_level: parse_speaker_level(data, 'report response')}
          when '4A'
            {subwoofer_2_level: parse_speaker_level(data, 'report response')}
          when '4B'
            {zone2_bass: parse_sequence(data, '00', -10, 10, 1)}
          when '4C'
            {zone2_treble: parse_sequence(data, '00', -10, 10, 1)}
          when '4D'
            {zone3_bass: parse_sequence(data, '00', -10, 10, 1)}
          when '4E'
            {zone3_treble: parse_sequence(data, '00', -10, 10, 1)}
          when '56'
            if data == 'FF'
              {hdmi_auto_audio_delay: nil}
            else
              {hdmi_auto_audio_delay: parse_sequence(data, '00', 0, 240, 1)}
            end
          when '60'
            if data.length != 2
              raise "Unexpected payload for 60: #{data}"
            end
            if data[0] != ?0
              raise "Unexpected payload for 60: #{data}"
            end
            {program_select: AUTO_LAST_GET.fetch(data[1])}
          when *SPEAKER_LAYOUT_MAP.keys
            if data[0] != '0'
              raise NotImplementedError
            end
            key, hash = SPEAKER_LAYOUT_MAP.fetch(command)
            {key => hash.fetch(data[1])}
          when 'A7'
            {eq_select: EQ_SELECT_GET.fetch(Integer(data).to_s)}
          when 'A8'
            {tone_auto_bypass: data == '00'}
          else
            #logger&.warn("Unhandled response: #{command} (#{data})")
            raise UnhandledResponse, "Unhandled STX response: command: #{command}; data: #{data}"
          end
        end

        Yamaha::Response::CommandResponse.new(control_type: control_type, guard: guard, state: state)
      end
    end
  end
end
