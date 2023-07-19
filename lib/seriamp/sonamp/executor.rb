# frozen_string_literal: true

module Seriamp
  module Sonamp
    class Executor
      def initialize(client, **opts)
        @client = client
        @options = opts.dup.freeze
      end

      attr_reader :client
      attr_reader :options

      ZONE_BOOLEAN_COMMANDS = %w(
        power
        bbe
        bbe_boost
        bbe_low_boost
        bbe_high_boost
        zone_mute
      ).freeze

      ZONE_INTEGER_COMMANDS = %w(
        zone_volume
      ).freeze

      ALIASES = {
        'zvol' => 'zone_volume',
        'zmute' => 'zone_mute',
      }.freeze

      def run_command(cmd, *args)
        cmd = cmd.gsub('-', '_')
        cmd = ALIASES.fetch(cmd, cmd)
        case cmd
        when 'detect'
          device = Seriamp::Detect::Serial.detect_device(Sonamp, *args, logger: logger, timeout: options[:timeout])
          if device
            puts device
            exit 0
          else
            STDERR.puts("Sonamp amplifier not found")
            exit 3
          end
        when 'off'
          client.set_power(1, false)
          client.set_power(2, false)
          client.set_power(3, false)
          client.set_power(4, false)
        when *ZONE_BOOLEAN_COMMANDS
          zones = parse_zone(args.shift)
          state = Utils.parse_on_off(args.shift)
          zones.each do |zone|
            client.public_send("set_#{cmd}", zone, state)
          end
          nil
        when *ZONE_INTEGER_COMMANDS
          zones = parse_zone(args.shift)
          value = Integer(args.shift)
          zones.each do |zone|
            client.public_send("set_#{cmd}", zone, value)
          end
          nil
        when 'cvol'
          channels = parse_channel(args.shift)
          volume = Integer(args.shift)
          channels.each do |channel|
            client.set_channel_volume(channel, volume)
          end
          nil
        when 'cmute'
          channels = parse_channel(args.shift)
          mute = Utils.parse_on_off(args.shift)
          channels.each do |channel|
            client.set_channel_mute(channel, mute)
          end
          nil
        when 'status'
          client.status
        else
          raise ArgumentError, "Unknown command: #{cmd}"
        end
      end

      private

      def parse_zone(str)
        parse_integer(str, 'zone', 4)
      end

      def parse_channel(str)
        parse_integer(str, 'channel', 8)
      end

      def parse_integer(str, what, max)
        str.downcase.split(',').map do |value|
          if %w(. * all).include?(value)
            1.upto(max).to_a
          else
            Integer(value).tap do |v|
              if v < 1 || v > max
                raise ArgumentError, "Invalid #{what}: #{v}"
              end
            end
          end
        end.flatten.uniq
      end
    end
  end
end
