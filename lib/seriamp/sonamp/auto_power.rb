require 'seriamp/faraday_facade'
require 'seriamp/utils'

module Seriamp
  module Sonamp
    class AutoPower
      def initialize(**opts)
        @options = opts.dup.freeze

        unless options[:sonamp_url]
          raise ArgumentError, 'Sonamp URL is required'
        end
        unless options[:yamaha_url]
          raise ArgumentError, 'Yamaha URL is required'
        end
      end

      attr_reader :options

      def logger
        options[:logger]
      end

      def run
        bump('application start')

        prev_sonamp_power = nil
        handle_exceptions do
          prev_sonamp_power = sonamp_client.get_zone_power.values.any? { |v| v == true }
        end

        loop do
          sonamp_power = nil
          handle_exceptions do
            sonamp_power = sonamp_client.get_zone_power.values.any? { |v| v == true }
            if sonamp_power && prev_sonamp_power == false
              bump('amplifier turned on')
            end
            prev_sonamp_power = sonamp_power
          end

          # If we cannot query the receiver, assume it is on to prevent unintended
          # turn-offs.
          receiver_power = nil
          handle_exceptions do
            receiver_power = yamaha_client.main_power
          end
          p receiver_power
          case receiver_power
          when true
            bump('receiver is on')
            if sonamp_power == false
              puts("turning on amplifier")
              sonamp_client.set_zone_power(1, true)
              sonamp_client.set_zone_power(2, true)
              sonamp_client.set_zone_power(3, true)
            end
          when nil
            bump('failed to communicate with receiver - assuming it is on')
          end

          delta = (@alive_through - Utils.monotime).to_i
          if delta < 0
            logger&.info("Turning amplifier off")
            handle_exceptions do
              sonamp_client.power_off
            end
          else
            puts "TTL: #{delta / 60}:#{'%02d' % (delta % 60)}"
          end

          sleep 20
        end
      end

      private

      def handle_exceptions
        yield
      rescue Interrupt, SystemExit, NoMemoryError
        raise
      rescue => exc
        logger&.warn("Unhandled exception: #{exc.class}: #{exc}")
      end

      def bump(reason)
        logger&.debug("Bumping 7 minutes: #{reason}")
        @alive_through = Utils.monotime + 7*60
      end

      def sonamp_client
        @sonamp_client ||= FaradayFacade.new(
          url: options.fetch(:sonamp_url),
          timeout: options[:sonamp_timeout] || 3,
        )
      end

      def yamaha_client
        @yamaha_client ||= FaradayFacade.new(
          url: options.fetch(:yamaha_url),
          timeout: options[:yamaha_timeout] || 5,
        )
      end
    end
  end
end
