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

      def run_command(cmd, *args)
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
        when 'power'
          zones = parse_zone(args.shift)
          state = Utils.parse_on_off(args.shift)
          zones.each do |zone|
            client.set_power(zone, state)
          end
          nil
        when 'zvol'
          zones = parse_zone(args.shift)
          volume = Integer(args.shift)
          zones.each do |zone|
            client.set_zone_volume(zone, volume)
          end
          nil
        when 'cvol'
          channels = parse_channel(args.shift)
          volume = Integer(args.shift)
          channels.each do |channel|
            client.set_channel_volume(channel, volume)
          end
          nil
        when 'zmute'
          zones = parse_zone(args.shift)
          mute = Utils.parse_on_off(args.shift)
          zones.each do |zone|
            client.set_zone_mute(zone, mute)
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
