require 'spec_helper'

describe 'Sonamp integration' do
  if (ENV['SERIAMP_INTEGRATION_SONAMP'] || '').empty?
    before(:all) do
      skip "Set SERIAMP_INTEGRATION_SONAMP=/dev/ttyXXX in environment to run integration tests"
    end
  end

  let(:device) { ENV.fetch('SERIAMP_INTEGRATION_SONAMP') }
  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Sonamp::Client.new(device: device, logger: logger) }

  after do
    client.close
  end

  describe 'status' do
    let(:status) { client.status }

    it 'works' do
      status.fetch(:zone_power).should be_a(Hash)
      1.upto(4) do |zone|
        status.fetch(:zone_power).should have_key(zone)
      end
    end
  end
end
