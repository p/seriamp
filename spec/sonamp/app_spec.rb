# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Sonamp::App do
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

  let(:client_cls) { Seriamp::Sonamp::Client }
  let(:client) { double('sonamp client') }

  describe '/off' do
    let(:final_state) do
      {'1' => false, '2' => false, '3' => false, '4' => false}
    end

    it 'works' do

      client.should receive(:set_zone_power).with(1, false)
      client.should receive(:set_zone_power).with(2, false)
      client.should receive(:set_zone_power).with(3, false)
      client.should receive(:set_zone_power).with(4, false)
      client.should receive(:get_zone_power).and_return(final_state)

      post '/off'

      last_response.status.should == 200
      JSON.parse(last_response.body).should == final_state
    end
  end

  describe '/zone/:zone/power' do
    it 'works' do
      client.should_receive(:set_zone_power).with(2, true)

      put '/zone/2/power', 'true'

      last_response.status.should == 204
      p last_response.body.should == ''
    end

    context 'when value is invalid' do
      it 'returns 422' do
        client.should_not receive(:set_zone_power)

        put '/zone/2/power', 'bogus'

        last_response.status.should == 422
        last_response.body.should =~ /\AError: .* bogus/
      end
    end
  end
end
