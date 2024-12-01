# frozen_string_literal: true

require 'spec_helper'
require_relative 'client_helpers'

describe Seriamp::Yamaha::Client do
  include YamahaHelpers
  include YamahaClientHelpers

  describe 'query methods' do
    include_context 'status request and response'

    let(:client) do
      described_class.new(backend: :mock_serial_port, device: exchanges, persistent: true)
    end

    describe '#main_mute?' do
      let(:exchanges) do
        [
          status_request,
          [:r, status_response],
        ]
      end

      context 'when false' do
        it 'returns correct value' do
          client.main_mute?.should be false
        end
      end

      context 'when muted' do
        let(:status_response) do
          "\x12R0225JB5@E01900020001C0ACE88003140200000000200F1020001002828262626262628282800020114140000A014055112000020040020001000000000002000000115077000121100A0A01FFFF0110000A0014A0014210A0A00FF101102D\x03"
        end

        it 'returns correct value' do
          client.main_mute?.should be true

          # check main is independent from zone 2
          client.zone2_mute?.should be false
          client.zone3_mute?.should be false
        end
      end
    end
  end

  describe 'control methods' do
    include_context 'rr mock'

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

    describe '#set_main_mute' do
      let(:rr) do
        [
          %W(\x0207EA2\x03 \x0200A500\x03 \x02002301\x03),
        ]
      end

      it 'works' do
        # No return value yet
        client.set_main_mute(true).should == {main_mute: true}
      end
    end

    describe '#set_main_input' do
      let(:rr) do
        [
          %W(\x0207A13\x03 \x0200210A\x03),
        ]
      end

      context 'canonical name: DVR/VCR2' do
        it 'works' do
          client.set_main_input('DVR/VCR2').should == {input_name: 'DVR/VCR2'}
        end
      end

      context 'dvr_vcr2' do
        it 'works' do
          client.set_main_input('dvr_vcr2').should == {input_name: 'DVR/VCR2'}
        end
      end

      context 'DVR alias' do
        it 'works' do
          client.set_main_input('DVR').should == {input_name: 'DVR/VCR2'}
        end
      end

      context 'program' do
        context 'integer in argument' do
          let(:rr) { [%W,\x0207EC0\x03 \x02002834\x03,] }

          it 'works' do
            client.set_program('2ch_stereo')
          end
        end
      end
    end

    describe '#set_bass_out' do
      let(:rr) do
        [
          %W(\x0227501\x03 \x02007500\x03),
        ]
      end

      it 'works' do
        client.set_bass_out(:front).should == {bass_out: 'Subwoofer'}
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

    describe '#set_front_left_level' do
      let(:rr) do
        [
          %W(\x022411F\x03 \x0200411F\x03),
        ]
      end

      it 'works' do
        client.set_front_left_level(-4.5).should == {front_left_level: -4.5}
      end
    end

    describe '#set_front_speaker_layout' do
      let(:rr) do
        [
          %W(\x0227100\x03 \x02007100\x03),
        ]
      end

      it 'works' do
        client.set_front_speaker_layout('large').should == {front_speaker_layout: 'Large'}
      end
    end

    describe '#volume_trim' do
      context 'rx-v1700+' do
        let(:rr) do
          [
            %W(\x142006012004EF\x03 \x1420080120040C64\x03),
          ]
        end

        let(:expected_cls) { Seriamp::Yamaha::Protocol::Extended::VolumeTrimResponse }

        let(:expected) do
          {
            md_tape_volume_trim: 0.0,
          }
        end

        let(:result) do
          client.volume_trim('md/tape')
        end

        it 'works' do
          result.should be_a(expected_cls)
          result.to_state.should == expected
        end
      end
    end

    describe '#set_volume_trim' do
      context 'rx-v1700+' do
        let(:rr) do
          [
            %W(\x142008012104095B\x03 \x142004012089\x03),
          ]
        end

        it 'works' do
          # No response at this time.
          client.set_volume_trim('md/tape', -1.5).should be nil
        end

        context 'when value is out of range' do
          let(:rr) do
            [
            ]
          end

          it 'raises ArgumentError' do
            lambda do
              client.set_volume_trim('md/tape', 7)
            end.should raise_error(ArgumentError)
          end
        end
      end
    end

    describe '#io_assignment' do
      context 'rx-v1700+' do
        let(:rr) do
          [
            %W(\x142006010062F1\x03 \x1420080100620659\x03),
          ]
        end

        let(:expected_cls) { Seriamp::Yamaha::Protocol::Extended::IoAssignmentResponse }

        let(:expected) do
          {
            hdmi_in_3_io_assignment: 'DTV',
          }
        end

        let(:result) do
          client.io_assignment(:hdmi_in, 3)
        end

        it 'works' do
          result.should be_a(expected_cls)
          result.to_state.should == expected
        end

        context 'string for source' do
          let(:result) do
            client.io_assignment('hdmi_in', 3)
          end

          it 'works' do
            result.should be_a(expected_cls)
            result.to_state.should == expected
          end
        end
      end
    end

    describe '#set_io_assignment' do
      context 'rx-v1700+' do
        let(:rr) do
          [
            %W(\x1420080101621156\x03 \x142004010087\x03),
          ]
        end

        context 'canonical case for destination' do
          it 'works' do
            # No response at this time.
            client.set_io_assignment(:hdmi_in, 3, 'BD/HD DVD').should be nil
          end
        end

        context 'lower case for destination' do
          it 'works' do
            # No response at this time.
            client.set_io_assignment(:hdmi_in, 3, 'bd/hd dvd').should be nil
          end
        end

        context 'string for source' do
          it 'works' do
            # No response at this time.
            client.set_io_assignment('hdmi_in', 3, 'bd/hd dvd').should be nil
          end
        end
      end
    end

    describe '#all_io_assignments' do
      context 'rx-v3800' do
        let(:rr) do
          [
            %W(\x142006010000E9\x03 \x142008010000014C\x03),
            %W(\x142006010001EA\x03 \x1420080100010551\x03),
            %W(\x142006010002EB\x03 \x1420080100020A5E\x03),
            %W(\x142006010010EA\x03 \x142008010010034F\x03),
            %W(\x142006010011EB\x03 \x1420080100110451\x03),
            %W(\x142006010020EB\x03 \x1420080100200451\x03),
            %W(\x142006010021EC\x03 \x1420080100211150\x03),
            %W(\x142006010022ED\x03 \x1420080100220554\x03),
            %W(\x142006010023EE\x03 \x1420080100230656\x03),
            %W(\x142006010060EF\x03 \x1420080100600F67\x03),
            %W(\x142006010061F0\x03 \x1420080100610557\x03),
            %W(\x142006010062F1\x03 \x1420080100621155\x03),
            %W(\x142006010063F2\x03 \x1420080100630A65\x03),
          ]
        end

        let(:expected) do
          {:coaxial_in_1_io_assignment=>"CD",
           :coaxial_in_2_io_assignment=>"DVD",
           :coaxial_in_3_io_assignment=>"DVR/VCR2",
           :optical_out_1_io_assignment=>"CD-R",
           :optical_out_2_io_assignment=>"MD/TAPE",
           :optical_in_1_io_assignment=>"MD/TAPE",
           :optical_in_2_io_assignment=>"BD/HD DVD",
           :optical_in_3_io_assignment=>"DVD",
           :optical_in_4_io_assignment=>"DTV",
           :hdmi_in_1_io_assignment=>"None",
           :hdmi_in_2_io_assignment=>"DVD",
           :hdmi_in_3_io_assignment=>"BD/HD DVD",
           :hdmi_in_4_io_assignment=>"DVR/VCR2"}
        end

        it 'works' do
          client.all_io_assignments.should == expected
        end
      end
    end

    describe '#all_input_labels' do
      context 'rx-v3800' do
        let(:rr) do
          [
            %W(\x14200701100001B\x03 \x142012011000009\x20\x20PHONO\x20\x2084\x03),
            %W(\x14200701100011C\x03 \x142012011000109\x20\x20\x20CD\x20\x20\x20\x20E8\x03),
            %W(\x14200701100021D\x03 \x142012011000209\x20\x20TUNER\x20\x2090\x03),
            %W(\x14200701100031E\x03 \x142012011000309\x20\x20CD-R\x20\x20\x2029\x03),
            %W(\x14200701100041F\x03 \x142012011000409\x20\x20\x20TC\x20\x20\x20\x20FB\x03),
            %W(\x142007011000520\x03 \x142012011000509\x20\x20\x20DVD\x20\x20\x2023\x03),
            %W(\x142007011000621\x03 \x142012011000609\x20DTV/CBL\x20B4\x03),
            %W(\x142007011000924\x03 \x142012011000909\x20\x20\x20VCR\x20\x20\x2034\x03),
            %W(\x142007011000A2C\x03 \x142012011000A09\x20\x20Coax\x20\x20\x20BC\x03),
            %W(\x142007011000C2E\x03 \x142012011000C09\x20\x20V-AUX\x20\x2084\x03),
            %W(\x142007011000E30\x03 \x142012011000E09\x20\x20\x20XM\x20\x20\x20\x201A\x03),
            %W(\x14200701100101C\x03 \x142012011001009MULTI\x20CH\x20D7\x03),
            %W(\x14200701100111D\x03 \x142012011001109BD/HD\x20DVDC1\x03),
            %W(\x14200701100201D\x03 \x142012011002009\x20\x20DOCK\x20\x20\x2043\x03),
            %W(\x14200701100211E\x03 \x142012011002109\x20\x20\x20\x20\x20\x20\x20\x20\x20A3\x03),
            %W(\x14200701100221F\x03 \x142012011002209\x20\x20\x20\x20\x20\x20\x20\x20\x20A4\x03),
            %W(\x142007011002320\x03 \x142012011002309\x20\x20\x20\x20\x20\x20\x20\x20\x20A5\x03),
          ]
        end

        let(:expected) do
          {:phono_label=>"  PHONO  ",
           :cd_label=>"   CD    ",
           :tuner_label=>"  TUNER  ",
           :cd_r_label=>"  CD-R   ",
           :md_tape_label=>"   TC    ",
           :dvd_label=>"   DVD   ",
           :dtv_label=>" DTV/CBL ",
           :vcr1_label=>"   VCR   ",
           :dvr_vcr2_label=>"  Coax   ",
           :v_aux_label=>"  V-AUX  ",
           :xm_label=>"   XM    ",
           :multi_channel_label=>"MULTI CH ",
           :bd_hd_dvd_label=>"BD/HD DVD",
           :dock_label=>"  DOCK   ",
           :pc_mcx_label=>"         ",
           :net_radio_label=>"         ",
           :usb_label=>"         "}
        end

        it 'works' do
          client.all_input_labels.should == expected
        end
      end
    end

    describe '#program_select' do
      let(:rr) do
        [
          ["001",
          "\x12R0212IAE@E0190002000050A9778003140500000000200F1020001002828262626262628282800020114140000A114055110000020240120000000000103002000000115077000121100A0A01FFFF0110000A0014A0014210A0A0098\x03"],
        ]
      end

      it 'works' do
        client.program_select.should == 'Last'
      end
    end

    describe '#set_program_select' do
      let(:rr) do
        [
          %W(\x0226001\x03 \x02006001\x03),
        ]
      end

      it 'works' do
        client.set_program_select('Last').should be == {program_select: 'Last'}
      end
    end

    describe 'graphic eq' do

      describe '#surround_left_graphic_eq' do
        let(:rr) do
          [
            [frame_ext_req('030040'), frame_ext_req('03004011')],
            [frame_ext_req('030042'), frame_ext_req('03004210')],
            [frame_ext_req('030044'), frame_ext_req('0300440F')],
            [frame_ext_req('030046'), frame_ext_req('03004611')],
            [frame_ext_req('030048'), frame_ext_req('0300480F')],
            [frame_ext_req('03004A'), frame_ext_req('03004A11')],
            [frame_ext_req('03004C'), frame_ext_req('03004C1B')],
          ]
        end

        it 'works' do
          client.surround_left_graphic_eq.should == {
            63 => 1,
            160 => 0.5,
            400 => 0,
            1000 => 1,
            2500 => 0,
            6300 => 1,
            16000 => 6,
          }
        end
      end

      describe '#set_surround_left_graphic_eq_400' do
        let(:rr) do
          [
            [frame_ext_req('03014413'), "\x142004030089\x03"],
          ]
        end

        it 'works' do
          client.set_surround_left_graphic_eq_400(2).should be nil
        end
      end
    end

    describe 'parametric eq' do

      describe '#surround_left_parametric_eq' do
        let(:rr) do
          [
            [frame_ext_req('034040'), frame_ext_req('0340401020A')],
            [frame_ext_req('034041'), frame_ext_req('0340411220A')],
            [frame_ext_req('034042'), frame_ext_req('0340421420A')],
            [frame_ext_req('034043'), frame_ext_req('0340431620A')],
            [frame_ext_req('034044'), frame_ext_req('0340441820A')],
            [frame_ext_req('034045'), frame_ext_req('0340451A20A')],
            [frame_ext_req('034046'), frame_ext_req('0340462020A')],
          ]
        end

        it 'works' do
          client.surround_left_parametric_eq.should == {
            1 => {frequency: 99.2, gain: -4, q: 5.04},
            2 => {frequency: 125, gain: -4, q: 5.04},
            3 => {frequency: 157.7, gain: -4, q: 5.04},
            4 => {frequency: 198.4, gain: -4, q: 5.04},
            5 => {frequency: 250, gain: -4, q: 5.04},
            6 => {frequency: 315, gain: -4, q: 5.04},
            7 => {frequency: 630, gain: -4, q: 5.04},
          }
        end
      end

      describe '#set_surround_left_parametric_eq_3' do
        let(:rr) do
          [
            [frame_ext_req('0341421C2CA'), "\x142004030089\x03"],
          ]
        end

        it 'works' do
          client.set_surround_left_parametric_eq_3(
            frequency: 396,
            gain: 2,
            q: 5,
          ).should be nil
        end
      end

      describe '#reset_surround_left_parametric_eq_3' do
        let(:rr) do
          [
            [frame_ext_req('0341421C2A3'), "\x142004030089\x03"],
          ]
        end

        it 'works' do
          client.reset_surround_left_parametric_eq_3.should be nil
        end
      end

      describe '#reset_surround_left_parametric_eq' do
        let(:rr) do
          [
            [frame_ext_req('0341400C2A3'), "\x142004030089\x03"],
            [frame_ext_req('034141142A3'), "\x142004030089\x03"],
            [frame_ext_req('0341421C2A3'), "\x142004030089\x03"],
            [frame_ext_req('034143242A3'), "\x142004030089\x03"],
            [frame_ext_req('0341442C2A3'), "\x142004030089\x03"],
            [frame_ext_req('034145342A3'), "\x142004030089\x03"],
            [frame_ext_req('0341463C2A3'), "\x142004030089\x03"],
          ]
        end

        it 'works' do
          client.reset_surround_left_parametric_eq.should be nil
        end
      end
    end
  end
end
