require 'spec_helper'

describe 'Sonamp integration' do
  if (ENV['SERIAMP_INTEGRATION_SONAMP'] || '').empty?
    before(:all) do
      skip "Set SERIAMP_INTEGRATION_SONAMP=/dev/ttyXXX in environment to run integration tests"
    end
  end

  let(:device) { ENV.fetch('SERIAMP_INTEGRATION_SONAMP') }
  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Sonamp::Client.new(device: device, logger: logger, backend: :logging_serial_port) }

  after do
    client.close
  end

  describe 'status' do
    let(:status) { client.status }

    it 'works' do
      status.fetch(:power).should be_a(Hash)
      1.upto(4) do |zone|
        status.fetch(:power).should have_key(zone)
      end
    end
  end

  shared_examples 'zone boolean-valued command' do
    it 'works' do
      result.should be_a(Hash)
      result.length.should == 4
      result.keys.should == [1, 2, 3, 4]
      result.values.each do |v|
        [true, false].should include(v)
      end
      result.values.all? { |v| v == true || v == false }.should be true
    end
  end

  describe 'zone power' do
    let(:result) { client.get_zone_power }

    include_examples 'zone boolean-valued command'
  end

  describe 'auto trigger input' do
    let(:result) { client.get_auto_trigger_input }

    include_examples 'zone boolean-valued command'
  end
end
