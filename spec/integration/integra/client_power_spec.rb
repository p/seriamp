require 'spec_helper'

describe 'Integra integration - power' do
  require_integration_device :integra
  let(:device) { integration_device(:integra) }

  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Integra::Client.new(device: device,
    logger: logger, backend: :logging_serial_port, retry: true) }

  after do
    client.close
  end

  describe 'power on' do
    before do
      client.set_main_power(false)
    end

    it 'works' do
      client.set_main_power(true).should be nil

      # check
      client.main_power.should be true
    end

    after do
      sleep 3
    end
  end

  describe 'power off' do
    before do
      client.main_power.should be true
    end

    it 'works' do
      client.set_main_power(false).should be nil
=begin
      {
        main_power: false, zone2_power: false, zone3_power: false,
      }
=end

      # check
      client.main_power.should be false
    end
  end

  describe 'power cycle' do
    before do
      client.set_main_power(false)
    end

    it 'works' do
      client.set_main_power(true).should be nil
      client.main_power.should be true

      client.set_main_power(false).should be nil
      client.main_power.should be false

      client.set_main_power(true).should be nil
      client.main_power.should be true
    end
  end
end
