# frozen_string_literal: true

require 'spec_helper'
require 'seriamp/uart'

describe Seriamp::Ynca::Client do
  describe '#initialize' do
    it 'works' do
      described_class.new
    end
  end

  describe 'control methods' do
    let(:extra_client_options) { {} }
    let(:client) { described_class.new(**{device: '/dev/bogus'}.update(extra_client_options)) }
    let(:device) do
      tty_double
    end

    before do
      setup_ynca_requests_responses(device, rr)
      mock_serial_device_once(device)
    end

    describe '#model_name' do
      let(:rr) do
        [
          %W(@SYS:MODELNAME=? @SYS:MODELNAME=RX-A710),
        ]
      end

      it 'works' do
        client.model_name.should == 'RX-A710'
      end
    end

    describe '#set_main_volume' do
      context 'floating-point value' do
        let(:rr) do
          [
            %W(@MAIN:VOL=-70.5 @MAIN:VOL=-70.5),
          ]
        end

        it 'works' do
          client.set_main_volume(-70.5).should == -70.5
        end
      end

      context 'integer value' do
        let(:rr) do
          [
            %W(@MAIN:VOL=-70.0 @MAIN:VOL=-70.0),
          ]
        end

        it 'works' do
          client.set_main_volume(-70).should == -70.0
        end
      end
    end
  end
end
