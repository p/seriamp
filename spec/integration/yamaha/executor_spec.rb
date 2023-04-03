require 'spec_helper'

describe 'Yamaha integration' do
  if (ENV['SERIAMP_INTEGRATION_YAMAHA'] || '').empty?
    before(:all) do
      skip "Set SERIAMP_INTEGRATION_YAMAHA=/dev/ttyXXX in environment to run integration tests"
    end
  end

  let(:device) { ENV.fetch('SERIAMP_INTEGRATION_YAMAHA') }
  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Yamaha::Client.new(device: device, logger: logger) }
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

    #let(:result) { executor.run_command('main-tone-bass-speaker') }

    it 'works' do
      p executor.run_command('main-tone-bass-speaker')
    end
  end
end
