require 'spec_helper'

describe 'Yamaha integration' do
  if (ENV['SERIAMP_INTEGRATION_YAMAHA'] || '').empty?
    before(:all) do
      skip "Set SERIAMP_INTEGRATION_YAMAHA=/dev/ttyXXX in environment to run integration tests"
    end
  end

  let(:logging_options) do
    {logger: logger, backend: :logging_serial_port}.freeze
  end
  let(:logging_options) { {}.freeze }

  let(:device) { ENV.fetch('SERIAMP_INTEGRATION_YAMAHA') }
  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Yamaha::Client.new(**logging_options.merge(device: device)) }
  let(:executor) { Seriamp::Yamaha::Executor.new(client) }

  describe 'dev-status' do
    before do
      client.main_power.should be true
    end

    let(:result) { executor.run_command('dev-status') }

    it 'works' do
      # Result is printed to standard output
      result.should be nil
    end
  end

  describe 'main-tone-bass-speaker' do
    before do
      client.main_power.should be true
    end

    context 'gain only' do
      it 'works' do
        executor.run_command('main-tone-bass-speaker', '0').should be nil
        resp = executor.run_command('main-tone-bass-speaker')
        resp.fetch(:gain).should == 0

        executor.run_command('main-tone-bass-speaker', '-2.5').should be nil
        resp = executor.run_command('main-tone-bass-speaker')
        resp.fetch(:gain).should == -2.5
      end
    end

    context 'gain + frequency' do
      it 'works' do
        skip 'requires RX-V3xxx'

        executor.run_command('main-tone-bass-speaker', '0', '125').should be nil
        resp = executor.run_command('main-tone-bass-speaker')
        resp.fetch(:gain).should == 0
        resp.fetch(:frequency).should == 125

        executor.run_command('main-tone-bass-speaker', '-2.5', '500').should be nil
        resp = executor.run_command('main-tone-bass-speaker')
        resp.fetch(:gain).should == -2.5
        resp.fetch(:frequency).should == 500
      end
    end
  end
end
