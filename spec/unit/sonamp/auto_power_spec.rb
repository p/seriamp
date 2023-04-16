# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Sonamp::AutoPower do
  let(:logger) { Logger.new(STDERR) }

  describe '#initialize' do
    context 'with yamaha detector' do
      it 'works' do
        described_class.new(sonamp_url: 'http://test/sonamp', detector: :yamaha,
          yamaha_url: 'http://test/yamaha')
      end
    end

    context 'with sonamp detector' do
      it 'works' do
        described_class.new(sonamp_url: 'http://test/sonamp', detector: :sonamp)
      end
    end
  end

  describe '#turn_on_cmd' do
    let(:default) { nil }
    let(:ap) { described_class.new(sonamp_url: 'test', default_zones: default) }
    let(:result) { ap.send(:turn_on_cmd) }

    context 'no input' do
      it 'raises NoPowerStateAvailable' do
        lambda do
          result
        end.should raise_error(Seriamp::NoPowerStateAvailable)
      end
    end

    context 'zone only input' do
      let(:default) do
        [1, 2]
      end

      it 'works' do
        result.should == "power 1 on\npower 2 on"
      end
    end

    context 'zone volume input' do
      let(:default) do
        {3 => 70}
      end

      it 'works' do
        result.should == "zone_volume 3 70\npower 3 on"
      end
    end

    context 'channel volume input' do
      let(:default) do
        {3 => [70, 71]}
      end

      it 'works' do
        result.should == "channel_volume 5 70\nchannel_volume 6 71\npower 3 on"
      end
    end
  end

  def mock_scope(&block)
    RSpec::Mocks.with_temporary_scope(&block)
  end

  describe '#run_one' do
    context 'with sonamp detector' do
      let(:runner) do
        described_class.new(sonamp_url: 'http://test/sonamp', detector: :sonamp, logger: logger)
      end

      let(:conn) do
        # Not a double because doubles cannot be used across mock scopes,
        # and the connection object is cached by the client.
        Object.new
      end

      context 'when initial connection fails' do
        it 'retries on next iteraton' do
          Seriamp::FaradayFacade.should receive(:new).and_return(conn)

          mock_scope do
            conn.should_receive(:get_json).and_raise(Faraday::ConnectionFailed)
            runner.should receive(:sleep).with(5)
            runner.send(:run_one)
            runner.state.should be :initial
          end

          mock_scope do
            conn.should_receive(:get_json).and_raise(Faraday::ConnectionFailed)
            runner.should receive(:sleep).with(5)
            runner.send(:run_one)
            runner.state.should be :initial
          end

          mock_scope do
            conn.should_receive(:get_json).and_return({})
            runner.send(:run_one)
            runner.state.should be :good
          end
        end
      end

      xcontext 'no input signal' do
        let(:all_on) do
          {1 => true, 2 => true, 3 => true, 4 => true }
        end

        let(:all_off) do
          {1 => false, 2 => false, 3 => false, 4 => false }
        end

        before do
          Seriamp::FaradayFacade.should receive(:new).and_return(conn)
          conn.should_receive(:get_json).with('power').and_return(all_on)
          conn.should_receive(:get_json).with('power').and_return(all_on)
          conn.should_receive(:get_json).with('auto_trigger_input').and_return({})

          #conn.should_receive(:get_json).with('power').and_return(all_on)
          #conn.should_receive(:get_json).with('auto_trigger_input').and_return({})

          conn.should_receive(:post!).with('off')
        end

        it 'powers amplifier off' do
          runner.should receive(:wait_for_next_iteration)
          runner.should receive(:wait_for_next_iteration).and_throw(:finish)

          catch(:finish) do
            runner.run
          end
        end
      end
    end
  end

  describe Seriamp::Sonamp::AutoPower::Utils do
    describe '.parse_default_zones' do
      let(:result) do
        described_class.parse_default_zones(input)
      end

      context 'one value' do
        let(:input) { '3' }
        it 'parses correctly' do
          result.should == {3 => true}
        end
      end

      context 'two zones' do
        let(:input) { '3,4' }
        it 'parses correctly' do
          result.should == {3 => true, 4 => true}
        end
      end

      context 'two zones with zone and channel volumes' do
        let(:input) { '3=40,4=41/51' }
        it 'parses correctly' do
          result.should == {3 => 40, 4 => [41, 51]}
        end
      end
    end
  end

end
