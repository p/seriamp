# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Yamaha::App do
  include Rack::Test::Methods

  describe '#initialize' do
    it 'works' do
      described_class.new
    end
  end

  let(:app) do
    described_class.tap do |app|
      app.client = client
    end
  end

  let(:client_cls) { Seriamp::Yamaha::Client }
  let(:client) { double('yamaha client') }

  describe 'get /' do
    let(:status) do
      {ready: 'OK', main_power: true}.freeze
    end

    context 'basic usage' do
      it 'works' do
        client.should receive(:current_status).and_return(status)

        get '/'

        last_response.status.should == 200
        JSON.parse(last_response.body).should == Utils.stringify_keys(status)
      end
    end

    context 'persistent client' do
      it 'returns current status' do
        client.should receive(:current_status).and_return(status)

        get '/'

        last_response.status.should == 200
        JSON.parse(last_response.body).should == Utils.stringify_keys(status)

        client.should receive(:current_status).and_return(status)

        get '/'

        last_response.status.should == 200
        JSON.parse(last_response.body).should == Utils.stringify_keys(status)
      end
    end
  end

  describe 'get /power' do
  end

  describe 'put /main/power' do
    it 'works' do
      client.should receive(:with_device).and_yield
      client.should receive(:set_main_power).with(true)

      put '/main/power', 'true'

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end

  describe 'post /main/volume/down' do
    it 'works' do
      #client.should receive(:main_volume_down).and_return(42)
      client.should receive(:main_volume_down).and_return(45)
      #client.should receive(:main_volume_down)
      #client.should receive(:main_volume).and_return(42)

      post '/main/volume/down', '2'

      last_response.status.should == 200
      last_response.body.should == '45'
    end
  end

  describe 'put /main/speaker/tone/bass' do
    it 'works' do
      #client.should receive(:with_device).and_yield
      client.should receive(:set_main_speaker_tone_bass).with(-4.5)

      put '/main/speaker/tone/bass', '-4.5'

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end

  describe 'put /main/front/left/speaker/level' do
    it 'works' do
      #client.should receive(:with_device).and_yield
      client.should receive(:set_front_left_level).with(-4.5)

      put '/main/front/left/speaker/level', '-4.5'

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end

  describe 'put /main/front/speaker/layout' do
    it 'works' do
      #client.should receive(:with_device).and_yield
      client.should receive(:set_front_speaker_layout).with('large')

      put '/main/front/speaker/layout', 'large'

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end

  describe 'get /pure_direct' do
    it 'works' do
      #client.should receive(:with_device).and_yield
      client.should receive(:pure_direct?).and_return('true')

      get '/pure_direct'

      last_response.status.should == 200
      last_response.body.should == 'true'
    end
  end

  describe 'get /program' do
    it 'works' do
      #client.should receive(:with_device).and_yield
      client.should receive(:program_name).and_return('2ch Stereo')

      get '/program'

      last_response.status.should == 200
      last_response.body.should == '2ch Stereo'
    end
  end

  describe 'put /program' do
    it 'works' do
      #client.should receive(:with_device).and_yield
      client.should receive(:set_program).with('2ch_stereo')

      put '/program', '2ch_stereo'

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end

  describe 'put /bass_out' do
    it 'works' do
      #client.should receive(:with_device).and_yield
      client.should receive(:set_bass_out).with('both')

      put '/bass_out', 'both'

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end

  describe 'put /subwoofer_crossover' do
    context 'known integer argument' do
      it 'works' do
        client.should receive(:set_subwoofer_crossover).with(80)

        put '/subwoofer_crossover', '80'

        last_response.status.should == 204
        last_response.body.should == ''
      end
    end

    context 'floating-point argument' do
      it 'returns 422' do
        put '/subwoofer_crossover', '80.0'

        last_response.status.should == 422
        last_response.body.should =~ /invalid value for Integer/
      end
    end
  end

  describe 'post /' do
    it 'works' do
      client.should receive(:set_main_power).with(true)

      post '/', "power main on"

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end
end
