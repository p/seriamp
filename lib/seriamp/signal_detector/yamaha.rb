# frozen_string_literal: true

module Seriamp
  module SignalDetector
    # Queries receiver for power status.
    #
    # Requires giving the auto power daemon the receiver daemon address,
    # and requires the receiver daemon to be running.
    class Yamaha
      def initialize(**opts)
        @options = opts.dup.freeze
      end

      def on?
        case resp = yamaha_client.get!('power')
          when 'true'
            true
          when 'false'
            false
          else
            raise "Unknown yamaha power response: #{resp}"
          end
      end

      private

      def yamaha_client
        @yamaha_client ||= FaradayFacade.new(
          url: options.fetch(:yamaha_url),
          timeout: options[:yamaha_timeout] || 5,
        )
      end
    end
  end
end
