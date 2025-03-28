# frozen_string_literal: true

require 'seriamp/yamaha/parser/command_response_parser'
require 'spec_helper'

describe Seriamp::Yamaha::Parser::CommandResponseParser do
  describe '.parse' do
    let(:parsed) { described_class.parse(response_str) }

    shared_examples 'returns correct result' do
      let(:response_str) { "0 0 #{response_content}".gsub(' ', '') }
      it 'returns correct result' do
        parsed.should be_a(Seriamp::Yamaha::Response::CommandResponse)
        parsed.control_type.should be :rs232
        parsed.state.should == expected_state
      end
    end

    {
      '00 00' => {ready: 'OK'},
      '00 01' => {ready: 'Busy'},
      '00 02' => {ready: 'Standby'},
      '01 00' => {warning: 'Over Current'},
      '01 01' => {warning: 'DC Detect'},
      '01 02' => {warning: 'Power Trouble'},
      '01 03' => {warning: 'Over Heat'},
      '06 00' => {xm_message: 'Check Antenna'},
      '07 00' => {ipod_message: 'Loading'},
      '08 00' => {net_usb_message: 'Please Wait'},
      '10 01' => {audio_format: 'PCM'},
      '10 FE' => {audio_format: '???'},
      '11 08' => {sample_rate: '44100'},
      '12 02' => {channel_indicator: '2/0'},
      '13 FF' => {lfe_indicator: nil},
      '14 FF' => {bit_rate: nil},
      '15 00' => {dialog: -31},
      '15 1F' => {dialog: 0},
      '15 FF' => {dialog: nil},
      '16 00' => {dd_karaoke: false, dd_61: false, dpl_encoded: false, dts_96_24: false, dts_es_discrete_61: false, dts_es_matrix_61: false, pre_emphasis: false},
      '16 01' => {dd_karaoke: true, dd_61: false, dpl_encoded: false, dts_96_24: false, dts_es_discrete_61: false, dts_es_matrix_61: false, pre_emphasis: false},
      '20 00' => {main_power: false, zone2_power: false, zone3_power: false},
      '20 01' => {main_power: true, zone2_power: true, zone3_power: true},
      '21 04' => {input_name: 'MD/TAPE'},
      '22 00' => {audio_source: 'Auto', decoder_mode: 'Auto'},
      '23 00' => {main_mute: false},
      '24 00' => {zone2_input_name: 'PHONO'},
      '25 00' => {zone2_mute: false},
      '26 00' => {main_volume: nil},
      '26 27' => {main_volume: -80.0},
      '26 77' => {main_volume: -40.0},
      '26 E8' => {main_volume: 16.5},
      '27 00' => {zone2_volume: nil},
      '27 27' => {zone2_volume: -80},
      '27 E8' => {zone2_volume: 16.5},
      '28 34' => {program_name: '2ch Stereo'},
      '28 80' => {program_name: 'Straight'},
      '29 00' => {tuner_page: 'A'},
      '2A 00' => {tuner_number: 1},
      '2B 01' => {osd_message: 'Short'},
      '2C 00' => {sleep: 120},
      '2D 03' => {extended_surround: 'Auto'},
      '2E 00' => {speaker_a: false},
      '2E 01' => {speaker_a: true},
      '2F 00' => {speaker_b: false},
      '2F 01' => {speaker_b: true},
      '30 01' => {system_memory_load: 1},
      '31 01' => {system_memory_save: 1},
      '32 06' => {main_volume_memory_load: 6},
      '33 06' => {main_volume_memory_save: 6},
      '34 00' => {headphone: false},
      '34 01' => {headphone: true},
      '4B 00' => {zone2_bass: -10},
      '4C 14' => {zone2_treble: 10},
      '4D 01' => {zone3_bass: -9},
      '4E 13' => {zone3_treble: 9},
      '56 00' => {hdmi_auto_audio_delay: 0},
      '56 F0' => {hdmi_auto_audio_delay: 240},
      '56 FF' => {hdmi_auto_audio_delay: nil},
      '6C 01' => {zone_osd: 'Zone2'},
      '75 00' => {bass_out: 'Subwoofer'},
      '75 01' => {bass_out: 'Front/Main'},
      '75 02' => {bass_out: 'Both'},
      '7E 08' => {subwoofer_crossover: 200},
      '80 01' => {test: true},
      '81 00' => {pure_direct: false},
      '8C 01' => {pure_direct: true},
      'A1 00' => {zone3_mute: false},
      'A2 00' => {zone3_volume: nil},
      'A2 27' => {zone3_volume: -80},
      'A2 E8' => {zone3_volume: 16.5},
      'A7 00' => {eq_select: 'Auto PEQ'},
      'A7 01' => {eq_select: 'GEQ'},
      'A7 02' => {eq_select: 'Off'},
      'A8 00' => {tone_auto_bypass: true},
      'A8 01' => {tone_auto_bypass: false},
    }.each do |response_content, expected_state|

      context response_content do
        let(:response_content) { response_content }
        let(:expected_state) { expected_state }

        include_examples 'returns correct result'
      end
    end
  end
end
