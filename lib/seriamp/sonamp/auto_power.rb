autoload :JSON, 'json'
autoload :FileUtils, 'fileutils'
require 'seriamp/faraday_facade'
require 'seriamp/utils'

module Seriamp
  module Sonamp
    class ReceiverDetector
      def initialize(**options)
        @options = options.dup.freeze
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

      def yamaha_client
        @yamaha_client ||= FaradayFacade.new(
          url: options.fetch(:yamaha_url),
          timeout: options[:yamaha_timeout] || 5,
        )
      end
    end

    class SonampDetector
    end

    class AutoPower
      def initialize(**opts)
        @options = opts.dup.freeze

        unless options[:sonamp_url]
          raise ArgumentError, 'Sonamp URL is required'
        end
        unless options[:yamaha_url]
          raise ArgumentError, 'Yamaha URL is required'
        end

        @detector = ReceiverDetector.new(**opts)
      end

      attr_reader :options

      def logger
        options[:logger]
      end

      def run
        load_sonamp_power

        bump('application start')

        prev_sonamp_power = nil
        prev_sonamp_on = nil
        handle_exceptions do
          prev_sonamp_power = sonamp_client.get_json('power')
          store_sonamp_power(prev_sonamp_power, prev_sonamp_power)
          prev_sonamp_on = prev_sonamp_power.values.any? { |v| v == true }
        end

        loop do
          sonamp_power = nil
          sonamp_on = nil
          handle_exceptions do
            sonamp_power = sonamp_client.get_json('power')
            sonamp_on = sonamp_power.values.any? { |v| v == true }
            if sonamp_on && prev_sonamp_on == false
              bump('amplifier turned on')
            end
            store_sonamp_power(prev_sonamp_power, sonamp_power)
            prev_sonamp_power = sonamp_power
            prev_sonamp_on = sonamp_on
          end

          # If we cannot query the receiver, assume it is on to prevent unintended
          # turn-offs.
          receiver_power = handle_exceptions do
            detector.on?
          end
          case receiver_power
          when true
            bump('receiver is on')
            if sonamp_on == false
              puts("turning on amplifier")
              sonamp_set_on
            end
          when nil
            bump('failed to communicate with receiver - assuming it is on')
          end

          delta = (@alive_through - Utils.monotime).to_i
          if delta < 0 && sonamp_on
            logger&.info("Turning amplifier off")
            handle_exceptions do
              sonamp_client.post!('off')
            end
          elsif ttl > 0
            puts "TTL: #{delta / 60}:#{'%02d' % (delta % 60)}"
          end

          sleep 20
        end
      end

      private

      attr_reader :stored_sonamp_power
      attr_reader :detector

      def handle_exceptions
        yield
      rescue Interrupt, SystemExit, NoMemoryError
        raise
      rescue => exc
        logger&.warn("Unhandled exception: #{exc.class}: #{exc}")
        nil
      end

      def bump(reason)
        if ttl > 0
          logger&.debug("Bumping #{ttl} seconds: #{reason}")
        end
        @alive_through = Utils.monotime + ttl*60
      end

      def sonamp_client
        @sonamp_client ||= FaradayFacade.new(
          url: options.fetch(:sonamp_url),
          timeout: options[:sonamp_timeout] || 3,
        )
      end

      def ttl
        @ttl ||= begin
          options[:ttl] || 0
        end
      end

      def load_sonamp_power
        if (state_path = options[:state_path]) && File.exist?(state_path)
          begin
            @stored_sonamp_power = File.open(state_path) do |f|
              JSON.load(f)
            end
          rescue JSON::ParserError => exc
            logger&.warn("Failed to load state: #{exc.class}: #{exc}")
          end
        end
      end

      def store_sonamp_power(prev_sonamp_power, sonamp_power)
        # Wait for the power state to be stable - both readings should be
        # the same.
        if prev_sonamp_power == sonamp_power && sonamp_power.values.any? { |v| v == true }
          @stored_sonamp_power = sonamp_power
          if state_path = options[:state_path]
            File.open(state_path + '.part', 'w') do |f|
              f << JSON.dump(sonamp_power)
            end
            FileUtils.mv(state_path + '.part', state_path)
          end
        end
      end

      def sonamp_set_on
        if stored_sonamp_power
          logger&.debug("sonamp on")
          stored_sonamp_power.each do |zone, value|
            if value
              logger&.debug("Sonamp: zone #{zone} on")
              sonamp_client.put!("zone/#{zone}/power", body: 'true')
            end
          end
        else
          logger&.warn("No stored sonamp power")
        end
      end
    end
  end
end
