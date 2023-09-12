# frozen_string_literal: true

require 'spec_helper'
require 'serialport'

describe Seriamp::Yamaha::Client do
  describe '#initialize' do
    it 'works' do
      described_class.new
    end
  end

  describe '#parse_response' do
    let(:client) { described_class.new }
    let(:parsed) { client.send(:parse_response, response) }

    context 'power on' do
      let(:response) { "\u0002002002\u0003" }
      it 'parses' do
        parsed.should == {
          control_type: :rs232c,
          state: {main_power: true, zone2_power: false, zone3_power: false},
        }
      end
    end
  end

  describe '#parse_half_db_volume' do
    let(:client) { described_class.new }
    subject { client.send(:parse_half_db_volume, value, :test) }

    context 'mute' do
      let(:value) { '00' }
      it 'decodes to nil' do
        subject.should be nil
      end
    end

    context 'min' do
      let(:value) { '27' }
      it 'decodes to -80' do
        subject.should be -80.0
      end
    end

    context '0 dB' do
      let(:value) { 'C7' }
      it 'decodes to 0' do
        subject.should be 0.0
      end
    end

    context 'max' do
      let(:value) { 'E8' }
      it 'decodes to 16.5' do
        subject.should be 16.5
      end
    end
  end

  describe '#parse_stx_response' do
    let(:client) { described_class.new }
    let(:parsed) { client.send(:parse_stx_response, resp) }

    shared_examples 'returns correct result' do
      let(:resp) { "0 0 #{response_content}".gsub(' ', '') }
      it 'returns correct result' do
        parsed.should == {control_type: :rs232c, state: expected_state}
      end
    end

    {
      '00 00' => {ready: 'OK'},
      '00 01' => {ready: 'Busy'},
      '00 02' => {ready: 'Standby'},
      '06 00' => {xm_message: 'Check Antenna'},
      '10 01' => {format: 'PCM'},
      '10 FE' => {format: '???'},
      '11 08' => {sample_rate: '44100'},
      '12 02' => {channel_indicator: '2/0'},
      '13 FF' => {lfe_indicator: '---'},
      '14 FF' => {bit_rate: '---'},
      #'15 00' => {dialog: -31},
      #'15 FF' => {dialog: nil},
      #'16 00' => {flags: []},
      '20 00' => {main_power: false, zone2_power: false, zone3_power: false},
      '20 01' => {main_power: true, zone2_power: true, zone3_power: true},
      '21 04' => {input_name: 'MD/TAPE'},
      '22 00' => {audio_select: 'Auto', decoder_mode: 'Auto'},
      '23 00' => {mute: false},
      '26 77' => {main_volume: -40.0},
      '28 34' => {program_name: '2ch Stereo'},
      '28 80' => {program_name: 'Straight'},
      #'2D 03' => {extended_surround: 'Auto'},
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
      '80 01' => {test: true},
      '8C 01' => {pure_direct: true},
      'A7 00' => {eq_select: 'Auto PEQ'},
      'A7 01' => {eq_select: 'GEQ'},
      'A7 02' => {eq_select: 'Off'},
      'A8 00' => {tone_auto_bypass: true},
      'A8 01' => {tone_auto_bypass: false},
    }.each do |_response_content, _expected_state|
      response_content, expected_state = _response_content, _expected_state

      context _response_content do
        let(:response_content) { _response_content }
        let(:expected_state) { _expected_state }

        include_examples 'returns correct result'
      end
    end
  end

  describe 'control methods' do
    let(:extra_client_options) { {} }
    let(:client) { described_class.new(**{device: '/dev/bogus'}.update(extra_client_options)) }
    let(:device) do
      tty_double
    end

    before do
      setup_requests_responses(device, rr)
      # If argument checks fail, device won't be opened.
      allow(SerialPort).to receive(:open).and_return(device)
      allow(IO).to receive(:select)
    end

    describe '#set_main_volume' do
      let(:rr) do
        [
          %W(\x022303b\x03 \x0200263B\x03),
        ]
      end

      it 'works' do
        client.set_main_volume(-70).should == -70.0
      end
    end

    describe '#set_zone2_volume' do
      let(:rr) do
        [
          %W(\x022313b\x03 \x0200273B\x03),
        ]
      end

      it 'works' do
        client.set_zone2_volume(-70).should == -70.0
      end
    end

    describe '#set_zone3_volume' do
      let(:rr) do
        [
          %W(\x022343b\x03 \x0200A23B\x03),
        ]
      end

      it 'works' do
        client.set_zone3_volume(-70).should == -70.0
      end
    end

    describe '#set_main_speaker_tone_bass' do
      let(:rr) do
        [
          %W(\x14200903310001083\x03 \x14200403308C\x03),
        ]
      end

      it 'works' do
        # No return value yet
        client.set_main_speaker_tone_bass(frequency: 125, gain: 2).should be nil
      end

      context 'treble frequency' do
        let(:rr) { [] }

        it 'raises error' do
          lambda do
            client.set_main_speaker_tone_bass(frequency: 8000, gain: 2)
          end.should raise_error(ArgumentError, /Invalid turnover frequency/)
        end
      end
    end

    describe '#set_main_speaker_tone_treble' do
      let(:rr) do
        [
          %W(\x14200903310121086\x03 \x14200403308C\x03),
        ]
      end

      it 'works' do
        # No return value yet
        client.set_main_speaker_tone_treble(frequency: 8000, gain: 2).should be nil
      end

      context 'bass frequency' do
        let(:rr) { [] }

        it 'raises error' do
          lambda do
            client.set_main_speaker_tone_treble(frequency: 125, gain: 2)
          end.should raise_error(ArgumentError, /Invalid turnover frequency/)
        end
      end
    end
  end

  describe '#current_status' do
    let(:exchanges) do
      [
        [:w, "001"],
        [:r, "\x12R0212IAE@E0190002000050A9778003140500000000200F1020001002828262626262628282800020114140000A114055110000020240120000000000103002000000115077000121100A0A01FFFF0110000A0014A0014210A0A0098\x03"],
        [:w, "2309d"],
        [:r, "\x0200269D\x03"],
      ]
    end

    let(:client) do
      described_class.new(backend: :mock_serial_port, device: exchanges, persistent: true)
    end

    let(:initial_status) do
      {
        :ready=>"OK",
        :main_power=>true,
        :zone2_power=>false,
        :zone3_power=>false,
        :input_name=>"PHONO",
        :audio_select=>"Auto",
        :mute=>false,
        :zone2_input_name=>"DVD",
        :zone2_mute=>false,
        :main_volume=>-15.0,
        :zone2_volume=>-40.0,
        :program_name=>"Straight",
        :es_key=>"Auto",
        :osd_message=>"Short",
        :sleep=>nil,
        :tuner_page=>"A",
        :tuner_number=>6,
        :night_mode=>"Off",
        :night_mode_parameter=>"Low",
        :format=>"Analog",
        :sample_rate=>"Analog",
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
        :eq_select=>"Auto PEQ",
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
        :tone_auto_bypass=>true,
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
        :model_code=>"R0212",
        :model_name=>"RX-V2700",
        :firmware_version=>"I",
        :raw_string=>
        "@E0190002000050A9778003140500000000200F1020001002828262626262628282800020114140000A114055110000020240120000000000103002000000115077000121100A0A01FFFF0110000A0014A0014210A0A00"
      }.freeze
    end

    it 'preserves state' do
=begin
      client.should receive(:open_device)
      client.should receive(:dispatch_and_parse).and_return(
        model_code: 'R0272', firmware_version: '', raw_string: '',
        main_power: true)
=end
      #client.status
      client.current_status.should == initial_status
      initial_status.fetch(:main_volume).should == -15
      client.set_main_volume(-21)
      client.current_status.should == initial_status.merge(main_volume: -21)
    end
  end
end
