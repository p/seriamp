autoload :JSON, 'json'
autoload :FileUtils, 'fileutils'
require 'seriamp/faraday_facade'
require 'seriamp/utils'

module Seriamp
  module Sonamp
    # Queries receiver for power status.
    #
    # Requires giving the auto power daemon the receiver daemon address,
    # and requires the receiver daemon to be running.
    class YamahaDetector
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

    # Determines receiver power status by inspecting signal sensing
    # state of the amplifier. Essentially this mirrors how the amplifier
    # itself handles the automatic power management.
    #
    # This may not work when amplifier is set to high gain and input
    # signal level is low - the amplifier may not consider the input
    # signal to be above threshold. You can use the receiver detector
    # in this case.
    class SonampDetector
      def initialize(**opts)
        @options = opts.dup.freeze

        # The daemon needs the sonamp client anyway to turn the power
        # on and off, thus require the client to be passed to this
        # detector.
        @sonamp_client = opts.fetch(:sonamp_client)
      end

      def on?
        # There isn't an "all" auto trigger input return - sonamp
        # only returns per-zone auto triggers.
        # If any of the zones have audio signal, consider the amplifier
        # to be receiving audio from the receiver.
        # This seems like reasonable behavior when the amplifier is
        # connected to a single receiver outputting one zone of audio,
        # but perhaps wouldn't work well in a multi-zone installation.
        # A multi-zone installation however would likely need different
        # rules for how to turn the amplifier on (perhaps, for example,
        # based on simply auto trigger input for each zone).
        sonamp_client.get_json('auto_trigger_input').values.any? { |v| v == true }
      end

      private

      attr_reader :sonamp_client
    end

    class AutoPower
      def initialize(**opts)
        opts = opts.dup
        if default = opts[:default]
          if Array === default
            opts[:default] = Hash[default.map { |v| [v, true] }]
          end
        end
        @options = opts.freeze

        unless options[:sonamp_url]
          raise ArgumentError, 'Sonamp URL is required'
        end

        @detector = case opts[:detector]
          when :yamaha
            unless options[:yamaha_url]
              raise ArgumentError, 'Yamaha URL is required'
            end
            YamahaDetector.new(**opts)
          when nil, :sonamp
            SonampDetector.new(sonamp_client: sonamp_client)
          else
            raise ArgumentError, "Invalid detector option: #{opts[:detector]}"
          end
      end

      attr_reader :options

      def logger
        options[:logger]
      end

      # Initial state: no amplifier information, no receiver information
      # Request amplifier information, request receiver information

      def run
        # This may not load anything if the state file is missing, etc.
        load_sonamp_power
        @state = :initial

        loop do
          report_state
          prev_state = @state
          begin
            send("run_#{@state}")
            wait_time = 20
          rescue => exc
            puts "#{exc.class}: #{exc}"
            wait_time = 5
          end
          # If state has not changed, sleep, otherwise do not sleep.
          # If there was an error, also sleep, but not as long.
          if @state == prev_state
            sleep(wait_time)
          end
        end
      end

      attr_reader :sonamp_power_state

      def signal?
        @signal
      end

      def any_zones_on?
        sonamp_power_state.any? { |k, v| v }
      end

      def report_state
        puts "State: #{@state}"
        puts "Sonamp power: #{sonamp_power_state}"
        puts "Signal: #{signal?.inspect}"
      end

      def run_initial
        @sonamp_power_state = sonamp_client.get_json('power')
        @state = :good
      end

      def run_good
        if @sonamp_power_state
          @prev_sonamp_power_state = @sonamp_power_state
        end

        @signal = detector.on?
        unless [true, false].include?(@signal)
          raise "#{@signal.inspect} not a valid return value"
        end
        # Get the amplifier state again, if this fails the amplifier is
        # not reachable and turning it on or off won't work either.
        @sonamp_power_state = sonamp_client.get_json('power')

        if signal? && !any_zones_on?
          logger&.debug("Signal on and no zones off, turning zones on")
          sonamp_client.post!('', body: turn_on_cmd)
        elsif !signal? && any_zones_on?
          logger&.debug("Signal off and zones on, turning zones off")
          sonamp_client.post!('off')
        end
      end

      def turn_on_cmd
        if default = options[:default]
          default.map do |zone, levels|
            prefix = case levels
            when Array
              if levels.length != 2
                raise "Expected two values for channel levels"
              end
              "channel_volume #{zone*2-1} #{levels.first}\n" +
              "channel_volume #{zone*2} #{levels.last}\n"
            when Integer
              "zone_volume #{zone} #{levels}\n"
            when true
              ''
            else
              raise "Invalid volume specification: #{levels.inspect}"
            end
            prefix + "power #{zone} on"
          end.join("\n")
        else
          raise NoPowerStateAvailable, "No state available to generate the turn on command"
        end
      end

      def runx
        load_sonamp_power

        bump('application start')

        prev_sonamp_power = nil
        prev_sonamp_on = nil
        handle_exceptions do
          prev_sonamp_power = sonamp_client.get_json('power')
          store_sonamp_power(prev_sonamp_power, prev_sonamp_power)
          prev_sonamp_on = prev_sonamp_power.values.any? { |v| v == true }
        end

        wait_for_next_iteration(5)

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

          delta = (@alive_through - Seriamp::Utils.monotime).to_i
          if delta <= 0 && sonamp_on
            logger&.info("Turning amplifier off")
            handle_exceptions do
              sonamp_client.post!('off')
            end
          elsif ttl > 0
            puts "TTL: #{delta / 60}:#{'%02d' % (delta % 60)}"
          end

          wait_for_next_iteration(20)
        end
      end

      private

      attr_reader :stored_sonamp_power
      attr_reader :detector

      def wait_for_next_iteration(delay)
        sleep delay
      end

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
        @alive_through = Seriamp::Utils.monotime + ttl*60
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
          rescue IOError, SystemCallError, JSON::ParserError => exc
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

      module Utils
        module_function def parse_default_zones(value)
          Hash[value.split(',').map do |v|
            if v.include?('=')
              zone, level = v.split('=')
              level = if level.include?('/')
                level.split('/').map { |v| Integer(v) }.tap do |v|
                  if v.length != 2
                    raise "Two volume levels expected for channel volumes"
                  end
                end
              else
                Integer(level)
              end
              [Integer(zone), level]
            else
              [Integer(v), true]
            end
          end]
        end
      end
    end
  end
end
