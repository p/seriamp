# frozen_string_literal: true

require 'sinatra/base'
require 'seriamp/utils'
require 'seriamp/sonamp/client'
require 'seriamp/sonamp/executor'
require 'seriamp/detect'
require 'seriamp/app_base'

module Seriamp
  module Sonamp
    class App < AppBase

      ALLOWED_STATUS_FIELDS = Hash[Client::STATUS_FIELDS.map do |field|
        [field.to_s, true]
      end]

      get '/' do
        if fields = params[:fields]
          status = {}
          bad_fields = []
          client.with_session do
            fields.split(',').each do |field|
              if ALLOWED_STATUS_FIELDS.key?(field)
                if bad_fields.empty?
                  status[field] = client.public_send("get_#{field}")
                end
              else
                bad_fields << field
              end
            end
          end
          if bad_fields.any?
            render_422("Invalid fields requested: #{bad_fields.join(', ')}")
          else
            render_json(status)
          end
        else
          render_json(client.status)
        end
      end

      get '/power' do
        render_json(client.get_zone_power)
      end

      get '/auto_trigger_input' do
        render_json(client.get_auto_trigger_input)
      end

      post '/off' do
        1.upto(4) do |zone|
          client.set_zone_power(zone, false)
        end
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
        empty_response
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
        executor = Executor.new(client)
        request.body.read.split("\n").each do |line|
          args = line.strip.split(/\s+/)
          executor.run_command(args.first, *args[1..])
        end
        empty_response
      end

      private

      def client
        settings.client || begin
          @client ||= Sonamp::Client.new(device: settings.device,
            logger: settings.logger, retries: settings.retries, thread_safe: true)
        end
      end

    end
  end
end
