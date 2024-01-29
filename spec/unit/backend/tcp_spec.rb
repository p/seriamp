# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Backend::TcpBackend::Device do
  run_app 18990, 'bin/yamaha-web', '-t', '1', '-d', '/dev/nonexistent', '--', '-p', '18990'

  let(:device) do
    described_class.new('localhost:18990')
  end

  describe '#readable?' do
    context 'when nothing was written' do
      it 'is false' do
        device.readable?.should be false
      end
    end

    context 'when a request was written' do
      it 'is true' do
        device.syswrite("GET / HTTP/1.0\r\n\r\n")
        sleep 0.1

        # Returns 500 in this test because the remote client isn't pointed
        # anywhere sensible.
        device.readable?.should be true
      end
    end
  end

  describe '#errored?' do
    context 'when nothing was written' do
      it 'is false' do
        device.errored?.should be false
      end
    end
  end
end
