# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Backend::MockSerialPortBackend::Device do
  let(:exchanges) do
    [
      [:w, 'write'],
      [:r, 'read'],
      [:r, 'read2'],
    ]
  end

  let(:device) { described_class.new(Seriamp::Backend::MockSerialPortBackend::Exchanges.new(exchanges)) }

  describe '#initialize' do
    it 'works' do
      lambda do
        device
      end.should_not raise_error
    end
  end

  describe '#syswrite' do
    it 'accepts expected writes' do
      lambda do
        device.syswrite('write')
      end.should_not raise_error
    end

    it 'rejects writes with wrong contents' do
      lambda do
        device.syswrite('writex')
      end.should raise_error(Seriamp::Backend::MockSerialPortBackend::UnexpectedWrite)
    end

    it 'rejects writes at wrong times' do
      device.syswrite('write')
      lambda do
        device.syswrite('writex')
      end.should raise_error(Seriamp::Backend::MockSerialPortBackend::UnexpectedWrite)
    end
  end

  describe '#read_nonblock' do
    let(:exchanges) do
      [
        [:r, 'read'],
        [:r, 'read2'],
      ]
    end

    it 'reads one exchange at a time' do
      device.read_nonblock.should == 'read'
      device.read_nonblock.should == 'read2'
    end

    context 'after writes' do
      let(:exchanges) do
        [
          [:w, 'write'],
          [:r, 'read'],
          [:r, 'read2'],
        ]
      end

      it 'reads exchanges after writes' do
        device.syswrite('write')
        device.read_nonblock.should == 'read'
        device.read_nonblock.should == 'read2'
      end
    end
  end
end
