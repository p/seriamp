# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module Status

        private

        STATUS_FIELDS = {
          'R0178' => [
            [7],
            [:busy, :bool],
            [:power, :bool],
            [:input_name, :input_name_1],
            [:multi_ch_input, :bool],
            [:input_mode],
            [:mute, :bool],
            [:zone2_input_name, :input_name_1],
            [:zone2_mute, :bool],
            [2, :main_volume, :volume],
            [2, :zone2_volume, :volume],
            [2, :program_name],
            [:effect, :bool],
            [:es_key],
            [:osd],
            [:sleep],
            [:tuner_page],
            [:tuner_number],
            [:night],
            [:pure_direct, :bool],
            [:speaker_a, :bool],
            [:speaker_b, :bool],
            [:playback_mode],
            [:sample_rate],
            [:es_status],
            [:thr_bypass, :bool],
            [:red_dts_wait, :bool],
            [:headphone, :bool],
            [:tuner_band],
            [:tuned, :bool],
            [:trigger1, :bool],
            [2],
            [:trigger1_control, :trigger_control],
            [:dts_96_24, :bool],
            [:trigger2_control, :trigger_control],
            [:trigger2, :bool],
            [:speaker_b_zone],
            [:zone2_speaker, :bool],
            [2, :front_right_level, :speaker_level],
            [2, :front_left_level, :speaker_level],
            [2, :center_level, :speaker_level],
            [2, :surround_right_level, :speaker_level],
            [2, :surround_left_level, :speaker_level],
            [2, :surround_back_right_level, :speaker_level],
            [2, :surround_back_left_level, :speaker_level],
            [2, :presence_right_level, :speaker_level],
            [2, :presence_left_level, :speaker_level],
            [2, :subwoofer_level, :speaker_level],
            [:night_mode],
            [5],
            [2, :speaker_lfe_level, :speaker_level],
            [2, :headphone_lfe_level, :speaker_level],
            [2, :audio_delay],
            [4],
            [:input_mode_setting],
            [:dimmer],
            [:osd_message],
            [2, :osd_shift],
            [:gray_back, :bool],
            [:video_conversion, :bool],
            [:speaker_dynamic_range, :dynamic_range],
            [:headphone_dynamic_range, :dynamic_range],
            [:zone2_volume_out],
            [1],
            [:memory_guard, :bool],
            [:center_speaker_setting, :speaker_setting],
            [:front_speaker_setting, :speaker_setting],
            [:surround_speaker_setting, :speaker_setting],
            [:surround_back_speaker_setting, :speaker_setting],
            [:presence_speaker_setting, :inverted_bool],
            [:bass_out],
            [:multi_ch_center_out],
            [:multi_ch_subwoofer_out],
            [:main_level],
            [:test_mode],
            [1],
            [2, :multi_ch_front_left_level, :speaker_level],
            [2, :multi_ch_front_right_level, :speaker_level],
            [2, :multi_ch_center_level, :speaker_level],
            [2, :multi_ch_surround_left_level, :speaker_level],
            [2, :multi_ch_surround_right_level, :speaker_level],
            [2, :multi_ch_surround_back_left_level, :speaker_level],
            [2, :multi_ch_surround_back_right_level, :speaker_level],
            [2, :multi_ch_presence_left_level, :speaker_level],
            [2, :multi_ch_presence_right_level, :speaker_level],
            [2, :multi_ch_subwoofer_level, :speaker_level],
            [:zone3_input_name, :input_name_1],
            [:zone3_mute, :bool],
            [2, :zone3_volume, :volume],
            [1],
            [:multi_ch_select],
            [:multi_ch_surround_out],
            [:subwoofer_position],
            [:crossover],
            [:component_osd, :bool],
            [:presence_surround_back_select],
          ].freeze
        }.freeze

        STATUS_FIELDS_R0178 = [
          [nil, nil, 'Baud rate (@)'],
          [nil, nil, 'Receive buffer (E)'],
          [nil, nil, 'Receive buffer (0)'],
          [nil, nil, 'Command timeout (1)'],
          [nil, nil, 'Command timeout (9)'],
          [nil, nil, 'Command timeout (0)'],
          [nil, nil, 'Handshaking (0)'],

          [:busy, :off_on, 'System busy status'],
          [:power, :off_on, 'System power'],
          [:input, nil, 'Main zone input'],
          [:multi_ch_input, :off_on, 'Input is multi-channel input'],
          [:input_mode, nil, 'Input mode'],
          [:mute, :off_on, 'Main zone mute'],
        ].freeze

        STATUS_FIELDS_R0226 = (STATUS_FIELDS_R0178[..6] + [
        ]).freeze

        STATUS_FIELDS_MAP = {
          'R0178' => STATUS_FIELDS_R0178,
          'R0226' => STATUS_FIELDS_R0226,
        ].freeze
      end
    end
  end
end
