require 'spec_helper'

describe 'Integra integration - client' do
  require_integration_device :integra
  let(:device) { integration_device(:integra) }

  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Integra::Client.new(device: device, logger: logger) }

  after do
    client.close
  end

  describe 'status' do
    before do
      client.main_power.should be true
    end

    let(:status) { client.status }

    it 'works' do
      status.should be_a(Hash)
      status.fetch(:main_power).should be true
      [true, false].should include(status.fetch(:zone2_power))
      [true, false].should include(status.fetch(:zone3_power))
      status.fetch(:main_volume).should be_a(Integer)
    end
  end
end
