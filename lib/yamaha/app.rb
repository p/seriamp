# frozen_string_literal: true

require 'sinatra/base'
require 'yamaha/utils'
require 'yamaha/client'

module Yamaha
  class App < Sinatra::Base

    set :device, nil
    set :logger, nil
    set :client, nil

    get '/power' do
      render_json(client.last_status.fetch(:power) > 0)
    end

    %w(main zone2 zone3).each do |zone|
      get "/#{zone}/power" do
        render_json(client.last_status.fetch(:"#{zone}_power"))
      end

      put "/#{zone}/power" do
        state = Utils.parse_on_off(request.body.read)
        client.public_send("set_#{zone}_power", state)
        empty_response
      end

      get '/#{zone}/volume' do
        render_json(client.public_send("get_#{zone}_volume"))
      end

      put '/#{zone}/volume' do
        value = Float(request.body.read)
        client.public_send("set_#{zone}_volume_db", value)
        empty_response
      end
    end

    private

    def client
      settings.client || begin
        @client ||= Yamaha::Client.new(settings.device, logger: settings.logger)
      end
    end

    def render_json(data)
      data.to_json
    end

    def empty_response
      render_json({})
    end
  end
end
