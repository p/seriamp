require 'spec_helper'

describe 'Yamaha integration' do
  require_integration_device :yamaha
  let(:device) { integration_device(:yamaha) }

  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Yamaha::Client.new(device: device, logger: logger) }

  after do
    client.close
  end

  describe 'status' do

    context 'when power is on' do
      before do
        client.main_power.should be true
      end

      let(:status) { client.status }

      it 'works' do
        status.fetch(:main_power).should be true
      end

      it 'can be queried continuously without errors' do
        10.times do
          client.status
        end
      end
    end
  end

  describe '#main_speaker_tone_bass' do
    let(:result) { client.main_speaker_tone_bass }

    it 'works' do
      result.should be_a(Hash)
      result.should have_key(:frequency)
      result.should have_key(:gain)
      result[:frequency].should be_a(Integer)
      result[:gain].should be_a(Float)
    end
  end
end
