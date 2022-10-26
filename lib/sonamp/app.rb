require 'sinatra/base'
require 'sonamp/utils'
require 'sonamp/client'

module Sonamp
  class App < Sinatra::Base

    set :device, nil
    set :logger, nil
    set :client, nil

    get '/power' do
      render_json(client.get_zone_power)
    end

    get '/zone/:zone/power' do |zone|
      render_json(client.get_zone_power(zone.to_i))
    end

    put '/zone/:zone/power' do |zone|
      state = Utils.parse_on_off(request.body)
      client.set_zone_power(zone.to_i, state)
    end

    get '/zone/:zone/volume' do |zone|
    end

    put '/zone/:zone/volume' do |zone|
    end

    get '/channel/:channel/volume' do |channel|
    end

    put '/channel/:channel/volume' do |channel|
    end

    private

    def client
      settings.client || begin
        @client ||= Sonamp::Client.new(settings.device, logger: settings.logger)
      end
    end

    def render_json(data)
      data.to_json
    end
  end
end
