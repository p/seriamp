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
    subject { client.send(:parse_half_db_volume, value) }

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

  describe 'control methods' do
    let(:extra_client_options) { {} }
    let(:client) { described_class.new(**{device: '/dev/bogus'}.update(extra_client_options)) }
    let(:device) do
      tty_double
    end

    before do
      setup_requests_responses(device, rr)
      SerialPort.should receive(:open).and_return(device)
      allow(IO).to receive(:select)
    end

    describe '#set_main_volume' do
      let(:rr) do
        [
          %W(\x022303b\x03 \x0200263B\x03),
        ]
      end

      it 'works' do
        client.set_main_volume(-70).should == {
          control_type: :rs232c,
          state: {main_volume: -70.0},
        }
      end
    end

    describe '#set_zone2_volume' do
      let(:rr) do
        [
          %W(\x022313b\x03 \x0200273B\x03),
        ]
      end

      it 'works' do
        client.set_zone2_volume(-70).should == {
          control_type: :rs232c,
          state: {zone2_volume: -70.0},
        }
      end
    end

    describe '#set_zone3_volume' do
      let(:rr) do
        [
          %W(\x022343b\x03 \x0200A23B\x03),
        ]
      end

      it 'works' do
        client.set_zone3_volume(-70).should == {
          control_type: :rs232c,
          state: {zone2_volume: -70.0},
        }
      end
    end
  end
end
