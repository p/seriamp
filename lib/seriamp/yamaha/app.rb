# frozen_string_literal: true

require 'sinatra/base'
require 'seriamp/utils'
require 'seriamp/detect/serial'
require 'seriamp/yamaha/client'
require 'seriamp/yamaha/executor'
require 'seriamp/app_base'

module Seriamp
  module Yamaha
    class App < AppBase

      get '/' do
        result = if params[:fresh]
          client.status
        else
          client.current_status
        end
        render_json(result)
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
          value = client.public_send("#{zone}_volume_up")
          # For RX-V1500 and presumably older, the first command shows
          # current volume on the front panel of the receiver but does not
          # change the volume. All of my hardware is now RX-V1700 or newer
          # which behaves sensibly, i.e. when the volume up/down command is
          # received over the serial connection it always immediately
          # changes the volume.
          # Older receivers can be supported by examining the status
          # response and determining the model number from that, then sending
          # two commands for the older models.
          # For me this would be innecessary overhead thus it's not currently
          # implemented.
          #client.public_send("#{zone}_volume_up")

          return_zone_volume(zone, value)
        end

        post "/#{zone}/volume/up/:steps" do |steps|
          value = client.public_send("#{zone}_volume_up")
          (Integer(steps) - 1).times do
            value = client.public_send("#{zone}_volume_up")
          end

          return_zone_volume(zone, value)
        end

        post "/#{zone}/volume/down" do
          value = client.public_send("#{zone}_volume_down")
          # Se the note under volume up method.
          #client.public_send("#{zone}_volume_down")

          return_zone_volume(zone, value)
        end

        post "/#{zone}/volume/down/:step" do |step|
          value = client.public_send("#{zone}_volume_down")
          (Integer(steps) - 1).times do
            client.public_send("#{zone}_volume_down")
          end

          return_zone_volume(zone, value)
        end

        put "/#{zone}/input" do
          value = request.body.read
          client.public_send("set_#{zone}_input", value)
          empty_response
        end
      end

      get '/pure_direct' do
        return_value 'pure_direct', client.pure_direct?
      end

      put "/pure_direct" do
        state = Utils.parse_on_off(request.body.read)
        client.set_pure_direct(state)
        empty_response
      end

      get '/program' do
        # TODO program does not round trip, the setter is set_program
        # and the getter is program_name which returns different contents.
        return_value 'program_name', client.program_name
      end

      put '/program' do
        client.set_program(request.body.read)
        empty_response
      end

      %i(bass treble).each do |tone|
        put "/main/speaker/tone/bass" do
          state = Float(request.body.read)
          client.public_send("set_main_speaker_tone_#{tone}", state)
          empty_response
        end
      end

      put "/main/center/speaker/layout" do
        client.set_center_speaker_layout(request.body.read)
        empty_response
      end

      put "/main/center/speaker/level" do
        client.set_center_level(Float(request.body.read))
        empty_response
      end

      %i(front surround surround_back presence).each do |channel_group|
        put "/main/#{channel_group}/speaker/layout" do
          client.public_send("set_#{channel_group}_speaker_layout", request.body.read)
          empty_response
        end

        %i(left right).each do |side|
          put "/main/#{channel_group}/#{side}/speaker/level" do
            client.public_send("set_#{channel_group}_#{side}_level", Float(request.body.read))
            empty_response
          end
        end
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

      put "/input/:input_name/volume_trim" do |input_name|
        client.set_volume_trim(input_name.gsub('_', '/'), Float(request.body.read))
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
          @client ||= Yamaha::Client.new(device: configured_device,
            logger: settings.logger, retries: settings.retries, thread_safe: true)
        end
      end

      def standard_response
        if return_current_status?
          render_json(client.current_status)
        elsif return_full_status?
          render_json(client.status)
        else
          empty_response
        end
      end

      def return_value(param, value)
        if return_current_status? || return_full_status?
          standard_response
        elsif return_json?
          render_json(param => value)
        else
          plain_response value
        end
      end

      def return_zone_volume(zone, value)
        return_value("#{zone}_volume", value)
      end
    end
  end
end
