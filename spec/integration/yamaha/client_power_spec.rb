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