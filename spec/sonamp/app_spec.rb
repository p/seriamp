# frozen_string_literal: true

require 'spec_helper'

describe Seriamp::Sonamp::App do
  include Rack::Test::Methods

  def last_payload
    JSON.parse(last_response.body)
  end

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

  describe 'get /' do
    context 'basic usage' do
      let(:client_status) do
        {
          zone_power: {1 => true, 2 => false, 3 => true, 4 => false},
          zone_fault: {1 => true, 2 => false, 3 => true, 4 => false},
        }
      end

      let(:expected_response) do
        {
          'zone_power' => {'1' => true, '2' => false, '3' => true, '4' => false},
          'zone_fault' => {'1' => true, '2' => false, '3' => true, '4' => false},
        }
      end

      it 'works' do
        client.should receive(:status).and_return(client_status)

        get '/'

        last_response.status.should == 200
        last_payload.should == expected_response
      end
    end

    context 'selected fields' do
      context 'valid fields' do
        let(:expected_response) do
          {
            'zone_power' => {'1' => true, '2' => false, '3' => true, '4' => false},
            'zone_volume' => {'1' => 10, '2' => 20, '3' => 33, '4' => 44},
          }
        end

        it 'works' do
          client.should receive(:with_session).and_yield
          client.should receive(:get_zone_power).and_return({1 => true, 2 => false, 3 => true, 4 => false})
          client.should receive(:get_zone_volume).and_return({1 => 10, 2 => 20, 3 => 33, 4 => 44})

          get '/?fields=zone_power,zone_volume'

          last_response.status.should == 200
          last_payload.should == expected_response
        end
      end

      context 'invalid fields' do
        it 'works' do
          # Retrieves the good fields up until the first bad one
          client.should receive(:with_session).and_yield
          client.should receive(:get_zone_power).and_return({1 => true, 2 => false, 3 => true, 4 => false})
          client.should_not receive(:get_zone_volume)

          get '/?fields=zone_power,bogus,zone_volume'

          last_response.status.should == 422
          last_payload.should == {'error' => "Invalid fields requested: bogus"}
        end
      end
    end
  end

  describe 'post /' do
    it 'works' do
      client.should receive(:set_zone_power).with(2, true)

      post '/', "power 2 on"

      last_response.status.should == 204
      last_response.body.should == ''
    end
  end
end
