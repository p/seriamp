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

  describe '#run' do
    context 'with sonamp detector' do
      let(:runner) do
        described_class.new(sonamp_url: 'http://test/sonamp', detector: :sonamp, logger: logger)
      end

      context 'when initial connection fails' do
        let(:conn) { double('test connection') }

        before do
          Seriamp::FaradayFacade.should receive(:new).and_return(conn)
          conn.should_receive(:get_json).and_raise(Faraday::ConnectionFailed)
        end

        it 'stays running and retries' do
          runner.run
        end
      end

      context 'no input signal' do
        it 'powers amplifier off' do
          runner.should receive(:wait_for_next_iteration).and_throw(:finish)

          catch(:finish) do
            runner.run
          end
        end
      end
    end
  end

end
