require 'sinatra/base'
require 'sonamp/utils'
require 'sonamp/client'

module Sonamp
  class App < Sinatra::Base

    get '/zone/:zone/power' do |zone|
    end

    put '/zone/:zone/power' do |zone|
      state = Utils.parse_on_off(request.body)
      client.power(zone.to_i, state)
    end

    get '/zone/:zone/volume' do |zone|
    end

    put '/zone/:zone/volume' do |zone|
    end

    get '/channel/:channel/volume' do |channel|
    end

    put '/channel/:channel/volume' do |channel|
    end
  end
end
