# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::Executor do
  let(:executor) { described_class.new(client) }

  describe '#run_command' do
    let(:client) { double('test client') }

    context 'remote-command' do
      it 'works' do
        client.should receive(:remote_command).with('7A88').and_return(42)
        executor.run_command('remote-command', '7A88').should == 42
      end
    end

    context 'remote-command-nr' do
      it 'works' do
        client.should receive(:remote_command).with('7A88', read_response: false).and_return(42)
        executor.run_command('remote-command-nr', '7A88').should == 42
      end
    end

    context 'main-speaker-tone-bass' do
      it 'works' do
        client.should receive(:set_main_speaker_tone_bass).with(frequency: 125, gain: 3.0).and_return(42)
        executor.run_command('main-speaker-tone-bass', '3', '125').should == 42
      end
    end

    context 'assign' do
      it 'works' do
        client.should receive(:set_io_assignment).with('optical_in', 3, 'md/tape').and_return(42)
        executor.run_command('assign', 'optical_in', '3', 'md/tape').should == 42
      end
    end

    context 'dev-status' do
      let(:status_middle) do
        -'@E0190002040050B94D3403140300000108200F1020001002828282828282828282800030114140000A00400511000000000002000200000000000200000010504D00012100070E01FFFF0110000A0014A0014210A0A00FF10110'
      end

      let(:status_string) do
        "R0226JB5#{status_middle}1E"
      end

      it 'works' do
        client.should receive(:status_string).and_return(status_string)
        executor.run_command('dev-status')
        # Does not raise
      end
    end

    context 'graphic-eq' do
      context 'get channel' do
        it 'works' do
          client.should receive(:surround_left_graphic_eq).and_return(hello: 42)
          executor.run_command('graphic-eq', 'surround-left').should == {hello: 42}
        end
      end

      context 'all channels' do
        it 'works' do
          client.should receive(:graphic_eq).and_return(hello: 42)
          executor.run_command('graphic-eq').should == {hello: 42}
        end
      end

      context 'geq alias' do
        it 'works' do
          client.should receive(:surround_left_graphic_eq).and_return(hello: 42)
          executor.run_command('geq', 'surround-left').should == {hello: 42}
        end
      end
    end

    context 'parametric-eq' do
      context 'get channel' do
        it 'works' do
          client.should receive(:surround_left_parametric_eq).and_return(hello: 42)
          executor.run_command('parametric-eq', 'surround-left').should == {hello: 42}
        end
      end

      context 'all channels' do
        it 'works' do
          client.should receive(:parametric_eq).and_return(hello: 42)
          executor.run_command('parametric-eq').should == {hello: 42}
        end
      end

      context 'peq alias' do
        it 'works' do
          client.should receive(:surround_left_parametric_eq).and_return(hello: 42)
          executor.run_command('peq', 'surround-left').should == {hello: 42}
        end
      end
    end
  end

  describe '.usage' do
    it 'works' do
      described_class.usage
    end
  end
end
