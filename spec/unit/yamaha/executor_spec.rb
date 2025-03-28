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

      context 'set channel' do
        it 'works' do
          client.should receive(:set_surround_left_parametric_eq_3).with(frequency: 250, gain: 2, q: 8).and_return(hello: 42)
          executor.run_command('parametric-eq', 'surround-left', '3', '250', '2', '8').should == {hello: 42}
        end
      end

      context 'reset band' do
        it 'works' do
          client.should receive(:reset_surround_left_parametric_eq).and_return(hello: 42)
          executor.run_command('parametric-eq', 'surround-left', 'reset').should == {hello: 42}
        end
      end

      context 'reset channel' do
        it 'works' do
          client.should receive(:reset_surround_left_parametric_eq_3).and_return(hello: 42)
          executor.run_command('parametric-eq', 'surround-left', '3', 'reset').should == {hello: 42}
        end
      end

      context 'reset all channels' do
        it 'works' do
          client.should receive(:reset_parametric_eq)
          executor.run_command('parametric-eq', 'reset').should be nil
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

    context 'program' do
      context 'underscore: 2ch_stereo' do
        it 'works' do
          client.should_receive(:set_program).with('2ch_stereo')
          executor.run_command('program', '2ch_stereo')
        end
      end
    end

    context 'bass_out' do
      %w(front subwoofer both).each do |value_|
        value = value_
        context "keyword: #{value}" do
          it 'works' do
            client.should_receive(:set_bass_out).with(value)
            executor.run_command('bass_out', value)
          end
        end
      end
    end

    context 'subwoofer_crossover' do
      context 'exact known value' do
        it 'works' do
          client.should_receive(:set_subwoofer_crossover).with(80)
          executor.run_command('subwoofer_crossover', '80')
        end
      end

      context 'non-integer value' do
        it 'raises ArgumentError' do
          lambda do
            executor.run_command('subwoofer_crossover', 'aa')
          end.should raise_error(ArgumentError, /invalid value for Integer/)
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
