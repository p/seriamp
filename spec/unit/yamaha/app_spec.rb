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
      client.should receive(:main_volume_down)
      client.should receive(:main_volume_down)
      client.should receive(:main_volume).and_return(42)

      post '/main/volume/down', '2'

      last_response.status.should == 200
      last_response.body.should == '42'
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
