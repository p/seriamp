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

  after do
    client.close
  end

  describe 'status' do
    before do
      client.main_power.should be true
    end
    
    let(:status) { client.status }

    it 'works' do
      status.fetch(:main_power).should be true
    end
  end
end
