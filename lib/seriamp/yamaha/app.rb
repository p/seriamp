# frozen_string_literal: true

require 'sinatra/base'
require 'seriamp/utils'
require 'seriamp/detect'
require 'seriamp/yamaha/client'

module Seriamp
  module Yamaha
    class App < Sinatra::Base

      set :device, nil
      set :logger, nil
      set :client, nil

      get '/' do
        render_json(client.status)
      end

      get '/power' do
        render_json(client.last_status.fetch(:power) > 0)
      end

      %w(main zone2 zone3).each do |zone|
        get "/#{zone}/power" do
          render_json(client.last_status.fetch(:"#{zone}_power"))
        end

        put "/#{zone}/power" do
          state = Utils.parse_on_off(request.body.read)
          client.with_device do
            client.public_send("set_#{zone}_power", state)
            rs = request.env['HTTP_RETURN_STATUS']
            if rs && Utils.parse_on_off(rs)
              render_json(client.status)
            else
              empty_response
            end
          end
        end

        get "/#{zone}/volume" do
          render_json(client.public_send("get_#{zone}_volume"))
        end

        put "/#{zone}/volume" do
          value = Float(request.body.read)
          client.public_send("set_#{zone}_volume_db", value)
          empty_response
        end

        post "/#{zone}/volume/up" do
          client.public_send("#{zone}_volume_up")
          client.public_send("#{zone}_volume_up")
          plain_response client.main_volume_db
        end

        post "/#{zone}/volume/up/:step" do |step|
          client.public_send("#{zone}_volume_up")
          step.to_i.times do
            client.public_send("#{zone}_volume_up")
          end
          plain_response client.main_volume_db
        end

        post "/#{zone}/volume/down" do
          client.public_send("#{zone}_volume_down")
          client.public_send("#{zone}_volume_down")
          plain_response client.main_volume_db
        end

        post "/#{zone}/volume/down/:step" do |step|
          client.public_send("#{zone}_volume_down")
          step.to_i.times do
            client.public_send("#{zone}_volume_down")
          end
          plain_response client.main_volume_db
        end

        put "/#{zone}/input" do
          value = request.body.read
          client.public_send("set_#{zone}_input", value)
          empty_response
        end
      end

      put "/pure-direct" do
        state = Utils.parse_on_off(request.body.read)
        client.public_send("set_pure_direct", state)
        empty_response
      end

      private

      def client
        settings.client || begin
          @client ||= Yamaha::Client.new(settings.device, logger: settings.logger)
        end
      end

      def render_json(data)
        headers['content-type'] = 'application/json'
        data.to_json
      end

      def empty_response
        [204, '']
      end

      def plain_response(data)
        headers['content-type'] = 'text/plain'
        data.to_s
      end
    end
  end
end
