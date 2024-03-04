# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Backend::IoBackend::Device do
  let(:pipe) { IO.pipe }
  let(:read_io) { pipe[0] }
  let(:write_io) { pipe[1] }
  let(:device) { described_class.new(read_io) }

  describe '#read_nonblock' do
    context 'when there is no data' do
      it 'raises EAGAINWaitReadable' do
        lambda do
          device.read_nonblock(10)
        end.should raise_error(IO::EAGAINWaitReadable)
      end
    end

    context 'when there is data' do
      it 'returns the data' do
        write_io.write('test')

        device.read_nonblock(10).should == 'test'
      end
    end
  end
end
