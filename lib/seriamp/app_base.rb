# frozen_string_literal: true

require 'sinatra/base'

module Seriamp
  class AppBase < Sinatra::Base

    set :device, nil
    set :logger, nil
    set :client, nil
    set :retries, true

    def configured_device
      settings.device || ENV['SERIAMP_DEVICE']
    end

    private

    def return_current_status?
      request.env['HTTP_ACCEPT'] == 'application/x-seriamp-current-status'
    end

    def return_full_status?
      request.env['HTTP_ACCEPT'] == 'application/x-seriamp-status'
    end

    def return_json?
      accept = request.env['HTTP_ACCEPT']
      accept == 'application/json' || accept == 'application/x-seriamp-current-status'
    end

    def render_json(data)
      headers['content-type'] = 'application/json'
      data.to_json
    end

    def empty_response
      if return_json?
        render_json({})
      else
        [204, '']
      end
    end

    def plain_response(data)
      headers['content-type'] = 'text/plain'
      data.to_s
    end

    def render_error(code, error)
      if error.is_a?(Exception)
        error = "#{error.class}: #{error}"
      end

      if return_json?
        headers['content-type'] = 'application/json'
        [code, {error: error}.to_json]
      else
        headers['content-type'] = 'text/plain'
        [code, "Error: #{error}"]
      end
    end

    def render_422(error)
      render_error(422, error)
    end

    error InvalidOnOffValue do |e|
      render_error(422, e)
    end

    error IndeterminateDevice do |e|
      render_error(500, e)
    end

    error NoDevice do |e|
      render_error(500, e)
    end

    error CommunicationTimeout do |e|
      render_error(500, e)
    end
  end
end
