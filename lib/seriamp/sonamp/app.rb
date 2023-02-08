# frozen_string_literal: true

require 'sinatra/base'
require 'seriamp/utils'
require 'seriamp/sonamp/client'
require 'seriamp/detect'

module Seriamp
  module Sonamp
    class App < Sinatra::Base

      set :device, nil
      set :logger, nil
      set :client, nil
      set :retries, true

      get '/' do
        render_json(client.status)
      end

      get '/power' do
        render_json(client.get_zone_power)
      end

      get '/volume' do
        payload = {
          zone_volume: client.get_zone_volume,
          zone_mute: client.get_zone_mute,
          channel_volume: client.get_channel_volume,
          channel_mute: client.get_channel_mute,
        }
        render_json(payload)
      end

      get '/zone/:zone/power' do |zone|
        render_json(client.get_zone_power(Integer(zone)))
      end

      put '/zone/:zone/power' do |zone|
        state = Utils.parse_on_off(request.body.read)
        client.set_zone_power(Integer(zone), state)
      end

      get '/zone/:zone/volume' do |zone|
        render_json(client.get_zone_volume(Integer(zone)))
      end

      put '/zone/:zone/volume' do |zone|
        volume = Integer(request.body.read)
        client.set_zone_volume(Integer(zone), volume)
      end

      put '/zone/:zone/mute' do |zone|
        state = Utils.parse_on_off(request.body.read)
        client.set_zone_mute(Integer(zone), state)
      end

      get '/channel/:channel/volume' do |channel|
        render_json(client.get_channel_volume(Integer(channel)))
      end

      put '/channel/:channel/volume' do |channel|
        volume = Integer(request.body.read)
        client.set_channel_volume(Integer(channel), volume)
      end

      put '/channel/:channel/mute' do |channel|
        state = Utils.parse_on_off(request.body.read)
        client.set_channel_mute(Integer(channel), state)
      end

      post '/' do
        executor = Executor.new
        request.body.read.split("\n").each do |line|
          args = line.strip.split(/\s+/)
          executor.run_command(args)
        end
        render_json({})
      end

      private

      def client
        settings.client || begin
          @client ||= Sonamp::Client.new(settings.device,
            logger: settings.logger, retries: settings.retries, thread_safe: true)
        end
      end

      def render_json(data)
        headers['content-type'] = 'application/json'
        data.to_json
      end
    end
  end
end
