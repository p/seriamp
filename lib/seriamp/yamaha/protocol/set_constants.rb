# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Protocol
      module SetConstants

        private

        PROGRAM_SET = {
          'munich' => 'E1',
          'vienna' => 'E5',
          'amsterdam' => 'E6',
          'freiburg' => 'E8',
          'chamber' => 'AF',
          'village_vanguard' => 'EB',
          'warehouse_loft' => 'EE',
          'cellar_club' => 'CD',
          'the_bottom_line' => 'EC',
          'the_roxy_theatre' => 'ED',
          'disco' => 'F0',
          'game' => 'F2',
          '7ch_stereo' => 'FF',
          '2ch_stereo' => 'C0',
          'sports' => 'F8',
          'action_game' => 'F2',
          'roleplaying_game' => 'CE',
          'music_video' => 'F3',
          'recital_opera' => 'F5',
          'standard' => 'FE',
          'spectacle' => 'F9',
          'sci-fi' => 'FA',
          'adventure' => 'FB',
          'drama' => 'FC',
          'mono_movie' => 'F7',
          'surround_decode' => 'FD',
          'thx_cinema' => 'C2',
          'thx_music' => 'C3',
          'thx_game' => 'C8',
        }.freeze

        MAIN_INPUTS_SET = {
          'phono' => '14',
          'cd' => '15',
          'tuner' => '16',
          'cd_r' => '19',
          'md_tape' => '18',
          'dvd' => 'C1',
          'dtv' => '54',
          'cbl_sat' => 'C0',
          'vcr1' => '0F',
          'dvr' => '13',
          'vcr2' => '13',
          'dvr_vcr2' => '13',
          'v_aux' => '55',
          'dock' => '55',
          'v_aux_dock' => '55',
          'multi_ch' => '87',
          'xm' => 'B4',
        }.freeze

        ZONE2_INPUTS_SET = {
          'phono' => 'D0',
          'cd' => 'D1',
          'tuner' => 'D2',
          'cd_r' => 'D4',
          'md_tape' => 'D3',
          'dvd' => 'CD',
          'dtv' => 'D9',
          'cbl_sat' => 'CC',
          'vcr1' => 'D6',
          'dvr_vcr2' => 'D7',
          'v_aux_dock' => 'D8',
          'xm' => 'B8',
        }.freeze

        ZONE3_INPUTS_SET = {
          'phono' => 'F1',
          'cd' => 'F2',
          'tuner' => 'F3',
          'cd_r' => 'F5',
          'md_tape' => 'F4',
          'dvd' => 'FC',
          'dtv' => 'F6',
          'cbl_sat' => 'F7',
          'vcr1' => 'F9',
          'dvr_vcr2' => 'FA',
          'v_aux_dock' => 'F0',
          'xm' => 'B9',
        }.freeze

        CENTER_SPEAKER_LAYOUTS = {
          'large' => '00',
          'small' => '01',
          'none' => '02',
        }.freeze

        FRONT_SPEAKER_LAYOUTS = {
          'large' => '00',
          'small' => '01',
        }.freeze

        SURROUND_SPEAKER_LAYOUTS = CENTER_SPEAKER_LAYOUTS

        SURROUND_BACK_SPEAKER_LAYOUTS = {
          'large_x2' => '00',
          'large_x1' => '01',
          'small_x2' => '02',
          'small_x1' => '03',
          'none' => '04',
        }.freeze

        PRESENCE_SPEAKER_LAYOUTS = {
          'yes' => '00',
          'none' => '01',
        }.freeze

        BASS_OUTS = {
          'subwoofer' => '00',
          'front' => '01',
          'both' => '02',
        }.freeze

        SUBWOOFER_PHASES = {
          'normal' => '00',
          'reverse' => '10',
        }.freeze

        SUBWOOFER_CROSSOVERS = {
          40 => '00',
          60 => '01',
          80 => '02',
          90 => '03',
          100 => '04',
          110 => '05',
          120 => '06',
          160 => '07',
          200 => '08',
        }.freeze

        AUTO_LAST_SET = {
          'auto' => '0',
          'last' => '1',
        }.freeze
      end
    end
  end
end
