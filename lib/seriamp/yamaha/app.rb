# frozen_string_literal: true

require 'sinatra/base'
require 'seriamp/utils'
require 'seriamp/detect'
require 'seriamp/yamaha/client'
require 'seriamp/yamaha/executor'
require 'seriamp/app_base'

module Seriamp
  module Yamaha
    class App < AppBase

      get '/' do
        clear_cache
        render_json(client.status)
      end

      post '/' do
        executor = Executor.new(client)
        request.body.read.split("\n").each do |line|
          args = line.strip.split(/\s+/)
          executor.run_command(args.first, *args[1..])
        end
        standard_response
      end

      get '/power' do
        render_json(client.status.fetch(:power) > 0)
      end

      %w(main zone2 zone3).each do |zone|
        get "/#{zone}/power" do
          render_json(client.status.fetch(:"#{zone}_power"))
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
          client.public_send("set_#{zone}_volume", value)
          empty_response
        end

        post "/#{zone}/volume/up" do
          client.public_send("#{zone}_volume_up")
          client.public_send("#{zone}_volume_up")
          plain_response client.main_volume
        end

        post "/#{zone}/volume/up/:step" do |step|
          client.public_send("#{zone}_volume_up")
          step.to_i.times do
            client.public_send("#{zone}_volume_up")
          end
          plain_response client.main_volume
        end

        post "/#{zone}/volume/down" do
          client.public_send("#{zone}_volume_down")
          client.public_send("#{zone}_volume_down")
          plain_response client.main_volume
        end

        post "/#{zone}/volume/down/:step" do |step|
          client.public_send("#{zone}_volume_down")
          step.to_i.times do
            client.public_send("#{zone}_volume_down")
          end
          plain_response client.main_volume
        end

        put "/#{zone}/input" do
          value = request.body.read
          client.public_send("set_#{zone}_input", value)
          empty_response
        end
      end

      put "/pure_direct" do
        state = Utils.parse_on_off(request.body.read)
        client.set_pure_direct(state)
        empty_response
      end

      put "/center_speaker_layout" do
        client.set_center_speaker_layout(request.body.read)
        empty_response
      end

      put "/front_speaker_layout" do
        client.set_front_speaker_layout(request.body.read)
        empty_response
      end

      put "/surround_speaker_layout" do
        client.set_surround_speaker_layout(request.body.read)
        empty_response
      end

      put "/surround_back_speaker_layout" do
        client.set_surround_back_speaker_layout(request.body.read)
        empty_response
      end

      put "/presence_speaker_layout" do
        client.set_presence_speaker_layout(request.body.read)
        empty_response
      end

      put "/bass_out" do
        client.set_bass_out(request.body.read)
        empty_response
      end

      put "/subwoofer_phase" do
        client.set_subwoofer_phase(request.body.read)
        empty_response
      end

      put "/subwoofer_crossover" do
        client.set_subwoofer_crossover(Integer(request.body.read))
        empty_response
      end

      error Error do |exc|
        case request.env['HTTP_ACCEPT']
        when 'application/json'
          headers['content-type'] = 'application/json'
          [500, {error: "#{exc.class}: #{exc}"}.to_json]
        else
          raise
        end
      end

      private

      def clear_cache
        if settings.client
          settings.client.clear_cache
        else
          @client&.clear_cache
        end
      end

      def client
        settings.client || begin
          @client ||= Yamaha::Client.new(settings.device,
            logger: settings.logger, retries: settings.retries, thread_safe: true)
        end
      end

      def standard_response
        if request.env['HTTP_ACCEPT'] == 'application/x-seriamp-status'
          render_json(client.status)
        else
          empty_response
        end
      end
    end
  end
end
