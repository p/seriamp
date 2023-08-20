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

  describe '#main_tone_bass_speaker' do
    let(:result) { client.main_tone_bass_speaker }

    it 'works' do
      result.should be_a(Hash)
      result.should have_key(:frequency)
      result.should have_key(:gain)
      result[:frequency].should be_a(Integer)
      result[:gain].should be_a(Float)
    end
  end

  xdescribe '#current_status' do
    it 'preserves state' do
=begin
      client.should receive(:open_device)
      client.should receive(:dispatch_and_parse).and_return(
        model_code: 'R0272', firmware_version: '', raw_string: '',
        main_power: true)
=end
      #client.status
      client.current_status.should == {}
      client.set_main_volume(-21)
      client.current_status.should == {}
    end
  end
end
