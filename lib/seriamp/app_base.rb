# frozen_string_literal: true

require 'sinatra/base'

module Seriamp
  class AppBase < Sinatra::Base

    set :device, nil
    set :logger, nil
    set :client, nil
    set :retries, true

    private

    def accept_json?
      request.env['HTTP_ACCEPT'] == 'application/json'
    end

    def render_json(data)
      headers['content-type'] = 'application/json'
      data.to_json
    end

    def empty_response
      if accept_json?
        render_json({})
      else
        [204, '']
      end
    end

    def plain_response(data)
      headers['content-type'] = 'text/plain'
      data.to_s
    end

    def render_422(error)
      if accept_json?
        headers['content-type'] = 'application/json'
        [422, {error: error}.to_json]
      else
        headers['content-type'] = 'text/plain'
        [422, error]
      end
    end

    error InvalidOnOffValue do |e|
      render_422("Error: #{e.class}: #{e}")
    end
  end
end
