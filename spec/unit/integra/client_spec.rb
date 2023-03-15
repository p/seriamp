# frozen_string_literal: true

require 'spec_helper'
require 'serialport'

describe Seriamp::Integra::Client do
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

  def setup_requests_responses(device, rr)
    rr.each do |req, *resps|
      expect(device).to receive(:syswrite).with("#{req}\r")
      resps.each do |resp|
        expect(device).to receive(:read_nonblock).and_return("#{resp}\x1a")
      end
    end
  end

  describe '#set_main_volume' do
    before do
      SerialPort.should receive(:open).and_return(device)
      allow(IO).to receive(:select)
    end

    context 'integer value' do
      let(:rr) {
        [
          %w(!1MVL02 !1MVL02),
        ]
      }

      it 'works' do
        setup_requests_responses(device, rr)
        client.set_main_volume(-80)
      end
    end

    context 'float value' do
      let(:rr) {
        [
          %w(!1MVL01 !1MVL01),
        ]
      }

      it 'works' do
        setup_requests_responses(device, rr)
        client.set_main_volume(-80.5)
      end
    end
  end
end
