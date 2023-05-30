# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Client do
  let(:client) { described_class.new }

  describe '#parse_status_response' do
    let(:parsed) { client.send(:parse_status_response, status_response) }

    context 'RX-V1500' do

      let(:status_response) do
        "R0177F8A@E01900021000517A773413240001102300000000230110029242626262020282832000000141400000014005100000020240110000242926262620202828325177000070104"
      end

      it 'works' do
        parsed.should == {}
      end
    end

    context 'RX-V1800' do

      let(:status_middle) do
        -'@E0190002040050B94D3403140300000108200F1020001002828282828282828282800030114140000A00400511000000000002000200000000000200000010504D00012100070E01FFFF0110000A0014A0014210A0A00FF10110'
      end

      let(:status_response) do
        "R0226JB5#{status_middle}1E"
      end

      let(:expected) do
        {
          :busy_standby=>"OK",
          :main_power=>true,
          :zone2_power=>false,
          :zone3_power=>false,
          :input_name=>"MD/TAPE",
          :audio_select=>"Auto",
          :mute=>false,
          :zone2_input_name=>"DVD",
          :zone2_mute=>false,
          :main_volume=>-7.0,
          :zone2_volume=>-61.0,
          :program_name=>"2ch Stereo",
          :es_key=>"Auto",
          :osd_message=>'Short',
          :sleep=>nil,
          :tuner_page=>"A",
          :tuner_number=>4,
          :format=>"PCM",
          :sample_rate=>"44100",
          :channel_indicator=>"2/0",
          :headphone=>false,
          :tuner_band=>"FM",
          :lfe_indicator=>"---",
          :trigger1=>true,
          :decoder_mode=>"Auto",
          :dual_mono_out=>"All",
          :trigger1_control=>"All",
          :trigger2_control=>"All",
          :trigger2=>true,
          :zone2_speaker_out=>"Ext",
          :front_right_level=>0.0,
          :front_left_level=>0.0,
          :center_level=>0.0,
          :surround_right_level=>0.0,
          :surround_left_level=>0.0,
          :surround_back_right_level=>0.0,
          :surround_back_left_level=>0.0,
          :presence_right_level=>0.0,
          :presence_left_level=>0.0,
          :subwoofer_level=>0.0,
          :xm_preset_page=>"A",
          :xm_preset_number=>1,
          :xm_search_mode=>"All",
          :on_screen=>"Always",
          :xm_channel_number=>1,
          :speaker_lfe_level=>-10.0,
          :headphone_lfe_level=>-10.0,
          :audio_delay=>0,
          :initial_volume=>nil,
          :max_volume=>16.5,
          :decoder_mode_setting=>"Auto",
          :audio_select_setting=>"Auto",
          :dimmer=>0,
          :osd_shift=>0,
          :gray_back=>true,
          :video_conversion=>true,
          :speaker_dynamic_range=>"Max",
          :headphone_dynamic_range=>"Max",
          :zone2_volume_out=>"Variable",
          :zone3_volume_out=>"Variable",
          :memory_guard=>false,
          :center_speaker_setting=>"Large",
          :front_speaker_setting=>"Large",
          :surround_speaker_setting=>"Large",
          :surround_back_speaker_setting=>"Large x2",
          :zone3_speaker_out=>"Ext",
          :presence_speaker_setting=>true,
          :bass_out=>"Both",
          :subwoofer_phase=>"Normal",
          :test_mode=>false,
          :eq_select=>"Off",
          :hdmi_audio=>true,
          :component_ip=>false,
          :hdmi_upscaling=>"Through",
          :hdmi_aspect=>"Through",
          :decoder_select=>"Pro Logic",
          :tuner_remote_id=>"ID1",
          :advanced_setup=>false,
          :amp_remote_id=>"ID1",
          :speaker_impedance=>8,
          :tuner_setup=>"AM9/FM0",
          :pure_direct=>false,
          :zone3_input_name=>"DVD",
          :zone3_mute=>false,
          :zone3_volume=>-61.0,
          :remote_sensor=>false,
          :multi_ch_select=>"6ch",
          :remote_id_xm=>"ID1",
          :biamp=>false,
          :subwoofer_crossover=>80,
          :tv_format=>"NTSC",
          :presence_surround_back_select=>"Presence",
          :zone2_bass=>-3,
          :zone2_treble=>4,
          :tone_bypass=>true,
          :wake_on_rs232=>true,
          :bit_rate=>"---",
          :dialog_level=>"---",
          :fl_scroll=>"Continue",
          :multi_ch_bgv=>"Last",
          :ipod_charge_standby=>true,
          :ipod_repeat=>"Off",
          :ipod_shuffle=>"Off",
          :zone2_max_volume=>16.5,
          :zone2_initial_volume=>nil,
          :zone2_balance=>0.0,
          :zone3_max_volume=>16.5,
          :zone3_initial_volume=>nil,
          :zone3_balance=>0.0,
          :monitor_check=>true,
          :zone3_bass=>0,
          :zone3_treble=>0,
          :dd_karaoke=>false,
          :dd_61=>false,
          :dts_es_matrix_61=>false,
          :dts_es_discrete_61=>false,
          :dts_96_24=>false,
          :pre_emphasis=>false,
          :dpl_encoded=>false,
          :raw_string=>status_middle,
        }
      end

      it 'works' do
        parsed.should == expected
      end
    end

    context 'RX-V2700' do

      let(:status_middle) do
        -'@E01900020430507B778003140500000108200F1020001002828262626262628282800020114140000A114055110000020240120001000000103002000000115077000121100A0A01FFFF0110000A0014A0014210A0A00'
      end

      let(:status_response) do
        "R0212IAE#{status_middle}A8"
      end

      let(:expected) do
        {
          :busy_standby=>"OK",
          :main_power=>true,
          :zone2_power=>false,
          :zone3_power=>false,
          :input_name=>"MD/TAPE",
          :audio_select=>"Coax / Opt",
          :mute=>false,
          :zone2_input_name=>"DVD",
          :zone2_mute=>false,
          :main_volume=>-38.0,
          :zone2_volume=>-40.0,
          :program_name=>"Straight",
          :es_key=>"Auto",
          :osd_message=>'Short',
          :sleep=>nil,
          :tuner_page=>"A",
          :tuner_number=>6,
          :night_mode=>"Off",
          :night_mode_parameter=>"Low",
          :format=>"PCM",
          :sample_rate=>"44100",
          :channel_indicator=>"2/0",
          :headphone=>false,
          :tuner_band=>"FM",
          :lfe_indicator=>"---",
          :trigger1=>true,
          :decoder_mode=>"Auto",
          :dual_mono_out=>"All",
          :trigger1_control=>"All",
          :trigger2_control=>"All",
          :trigger2=>true,
          :zone2_speaker_out=>"Ext",
          :front_right_level=>0.0,
          :front_left_level=>0.0,
          :center_level=>-1.0,
          :surround_right_level=>-1.0,
          :surround_left_level=>-1.0,
          :surround_back_right_level=>-1.0,
          :surround_back_left_level=>-1.0,
          :presence_right_level=>0.0,
          :presence_left_level=>0.0,
          :subwoofer_level=>0.0,
          :xm_preset_page=>"A",
          :xm_preset_number=>1,
          :xm_search_mode=>"All",
          :on_screen=>"30",
          :xm_channel_number=>1,
          :speaker_lfe_level=>-10.0,
          :headphone_lfe_level=>-10.0,
          :audio_delay=>0,
          :initial_volume=>nil,
          :max_volume=>16.5,
          :decoder_mode_setting=>"Last",
          :audio_select_setting=>"Last",
          :dimmer=>0,
          :gui_position_h=>0,
          :gui_position_v=>0,
          :gray_back=>true,
          :video_conversion=>true,
          :speaker_dynamic_range=>"Max",
          :headphone_dynamic_range=>"Max",
          :zone2_volume_out=>"Variable",
          :zone3_volume_out=>"Variable",
          :memory_guard=>false,
          :center_speaker_setting=>"None",
          :front_speaker_setting=>"Large",
          :surround_speaker_setting=>"None",
          :surround_back_speaker_setting=>"None",
          :zone3_speaker_out=>"Ext",
          :presence_speaker_setting=>false,
          :bass_out=>"Both",
          :subwoofer_phase=>"Normal",
          :test_mode=>false,
          :eq_select=>"GEQ",
          :wallpaper=>"Yes",
          :hdmi_audio=>true,
          :component_ip=>false,
          :hdmi_ip=>true,
          :gui_language=>"English",
          :hdmi_upscaling=>"720p",
          :hdmi_aspect=>"Through",
          :zone_osd=>"Zone2 & Zone3",
          :decoder_select=>"Pro Logic",
          :tuner_remote_id=>"ID1",
          :advanced_setup=>false,
          :amp_remote_id=>"ID1",
          :speaker_impedance=>8,
          :tuner_setup=>"AM9/FM0",
          :pure_direct=>true,
          :zone3_input_name=>"DVD",
          :zone3_mute=>false,
          :zone3_volume=>-40.0,
          :remote_sensor=>false,
          :multi_ch_select=>"6ch",
          :remote_id_xm=>"ID1",
          :biamp=>false,
          :subwoofer_crossover=>80,
          :tv_format=>"NTSC",
          :presence_surround_back_select=>"Surround Back",
          :zone2_bass=>0,
          :zone2_treble=>0,
          :tone_bypass=>true,
          :wake_on_rs232=>true,
          :bit_rate=>"---",
          :dialog_level=>"---",
          :fl_scroll=>"Continue",
          :multi_ch_bgv=>"Last",
          :ipod_charge_standby=>true,
          :ipod_repeat=>"Off",
          :ipod_shuffle=>"Off",
          :net_usb_repeat=>"Off",
          :net_usb_shuffle=>false,
          :zone2_max_volume=>16.5,
          :zone2_initial_volume=>nil,
          :zone2_balance=>0.0,
          :zone3_max_volume=>16.5,
          :zone3_initial_volume=>nil,
          :zone3_balance=>0.0,
          :net_usb_source=>"USB",
          :monitor_check=>true,
          :zone3_bass=>0,
          :zone3_treble=>0,
          :dd_karaoke=>false,
          :dd_61=>false,
          :dts_es_matrix_61=>false,
          :dts_es_discrete_61=>false,
          :dts_96_24=>false,
          :pre_emphasis=>false,
          :dpl_encoded=>false,
          :raw_string=>status_middle,
        }
      end

      it 'works' do
        parsed.should == expected
      end
    end
  end
end
