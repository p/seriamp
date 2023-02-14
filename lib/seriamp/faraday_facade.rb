require 'faraday'
autoload :JSON, 'json'

module Seriamp
  class FaradayFacade
    class HttpError < StandardError
    end

    def initialize(**opts)
      @options = {}
      if timeout = opts.delete(:timeout)
        @options[:timeout] = timeout
      end

      @conn = Faraday.new(**opts) do |faraday|
        #faraday.response :logger, nil, { headers: true, bodies: false }
        #faraday.response :logger
      end

      @base_url = opts.fetch(:url)
    end

    attr_reader :options
    attr_reader :base_url

    def get(uri)
      conn.get(uri) do |req|
        configure_request(req)
      end
    end

    def get!(url)
      resp = get(url)
      if resp.status != 200
        raise HttpError, "Bad status: #{resp.status} for #{base_url} #{url} with #{options}"
      end
      resp.body
    end

    def get_json(url)
      resp = get!(url)
      JSON.parse(resp)
    end

    def put(uri, body: nil)
      conn.put(uri) do |req|
        configure_request(req)
        if body
          req.body = body
        end
      end
    end

    def put!(url, **opts)
      put(url, **opts).tap do |resp|
        unless resp.success?
          raise HttpError, "Bad status: #{resp.status} for #{url}"
        end
      end
    end

    def post(uri, body: nil)
      conn.post(uri) do |req|
        configure_request(req)
        if body
          req.body = body
        end
      end
    end

    def post!(url, **opts)
      post(url, **opts).tap do |resp|
        unless resp.success?
          raise HttpError, "Bad status: #{resp.status} for #{url}"
        end
      end
    end

    private

    attr_reader :conn

    def configure_request(req)
      req.options.timeout = options[:timeout]
      req.options.read_timeout = options[:timeout]
      req.options.open_timeout = options[:timeout]
    end
  end
end
