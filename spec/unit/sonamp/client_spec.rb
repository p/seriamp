# frozen_string_literal: true

require 'spec_helper'
require 'serialport'

describe Seriamp::Sonamp::Client do
  describe '#initialize' do
    it 'works' do
      described_class.new
    end
  end

  let(:extra_client_options) { {} }
  let(:client) { described_class.new(**{device: '/dev/bogus'}.update(extra_client_options)) }
  let(:device) do
    tty_double
  end

  describe '#status' do
    before do
      SerialPort.should receive(:open).and_return(device)
      allow(IO).to receive(:select)
    end

    let(:rr) {
      [
        %w(:VER? VER1.00),
        %w(:TP? TP1),
        %w(:PG? P11 P21 P31 P41),
        %w(:FPG? FP11 FP21 FP31 FP41),
        %w(:VG? V11 V21 V31 V41),
        %w(:VCG? VC11 VC21 VC31 VC41 VC51 VC61 VC71 VC81),
        %w(:MG? M11 M21 M31 M41),
        %w(:MCG? MC11 MC21 MC31 MC41 MC51 MC61 MC71 MC81),
        %w(:BPG? BP11 BP21 BP31 BP41),
        %w(:BHG? BH11 BH21 BH31 BH41),
        %w(:BLG? BL11 BL21 BL31 BL41),
        %w(:ATIG? ATI11 ATI21 ATI31 ATI41),
        %w(:VTIG? VTI11 VTI21 VTI31 VTI41 VTIA1),
        %w(:TVLG? TVL11 TVL21 TVL31 TVL41 TVL51 TVL61 TVL71 TVL81),
      ]
    }

    let(:expected_status) do
      {
        firmware_version: '1.00',
        temperature: 1,
        power: {1 => true, 2 => true, 3 => true, 4 => true},
        zone_fault: {1 => true, 2 => true, 3 => true, 4 => true},
        zone_mute: {1 => true, 2 => true, 3 => true, 4 => true},
        zone_volume: {1 => 1, 2 => 1, 3 => 1, 4 => 1},
        channel_volume: {1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1, 6 => 1, 7 => 1, 8 => 1},
        channel_mute: {1 => true, 2 => true, 3 => true, 4 => true, 5 => true, 6 => true, 7 => true, 8 => true},
        bbe: {1 => true, 2 => true, 3 => true, 4 => true},
        bbe_high_boost: {1 => true, 2 => true, 3 => true, 4 => true},
        bbe_low_boost: {1 => true, 2 => true, 3 => true, 4 => true},
        auto_trigger_input: {1 => true, 2 => true, 3 => true, 4 => true},
        # TODO fix to read "global"
        voltage_trigger_input: {1 => true, 2 => true, 3 => true, 4 => true, 5 => true},
        channel_front_panel_level: {1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1, 6 => 1, 7 => 1, 8 => 1},
      }
    end

    it 'works' do
      setup_sonamp_requests_responses(device, rr)
      client.status.should == expected_status
    end

    context 'when thread safety is enabled' do
      let(:extra_client_options) { {thread_safe: true} }

      it 'works' do
        setup_sonamp_requests_responses(device, rr)
        client.status.should == expected_status
      end
    end
  end
end
