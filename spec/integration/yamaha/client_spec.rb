require 'spec_helper'

describe 'Yamaha integration' do
  require_integration_device :yamaha
  let(:device) { integration_device(:yamaha) }

  let(:logger) { Logger.new(STDERR) }
  let(:client_options) do
    {
      device: device,
      persistent: persistent,
      logger: logger,
      #backend: :logging_serial_port,
    }
  end
  let(:client) { Seriamp::Yamaha::Client.new(**client_options) }
  let(:persistent) { false }

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

      shared_examples 'can be queried continuously without errors' do
        it 'can be queried continuously without errors' do
          10.times do
            client.status
          end
        end
      end

      context 'when persistent client is not used' do
        let(:persistent) { false }

        include_examples 'can be queried continuously without errors'
      end

      context 'when persistent client is used' do
        let(:persistent) { true }

        include_examples 'can be queried continuously without errors'
      end
    end
  end

  describe '#set_main_power' do
    context 'when power is on' do
      before do
        client.main_power.should be true
      end

      it 'can be turned on' do
        client.set_main_power(true)

        client.main_power.should be true
      end

      shared_examples 'can be queried continuously without errors' do
        it 'can be queried continuously without errors' do
          10.times do
            client.set_main_power(true)
          end
        end
      end

      context 'when persistent client is not used' do
        let(:persistent) { false }

        include_examples 'can be queried continuously without errors'
      end

      context 'when persistent client is used' do
        let(:persistent) { true }

        include_examples 'can be queried continuously without errors'
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
