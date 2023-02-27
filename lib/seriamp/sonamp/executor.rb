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
          device = Seriamp.detect_device(Sonamp, *args, logger: logger, timeout: options[:timeout])
          if device
            puts device
            exit 0
          else
            STDERR.puts("Yamaha receiver not found")
            exit 3
          end
        when 'off'
          client.set_zone_power(1, false)
          client.set_zone_power(2, false)
          client.set_zone_power(3, false)
          client.set_zone_power(4, false)
        when 'power'
          zone = Integer(args.shift)
          state = Utils.parse_on_off(args.shift)
          client.set_zone_power(zone, state)
        when 'zvol'
          zone = Integer(args.shift)
          volume = Integer(args.shift)
          client.set_zone_volume(zone, volume)
        when 'cvol'
          channel = Integer(args.shift)
          volume = Integer(args.shift)
          client.set_channel_volume(channel, volume)
        when 'zmute'
          zone = Integer(args.shift)
          mute = Utils.parse_on_off(args.shift)
          client.set_zone_mute(zone, mute)
        when 'cmute'
          channel = Integer(args.shift)
          mute = Utils.parse_on_off(args.shift)
          client.set_channel_mute(channel, mute)
        when 'status'
          client.status
        else
          raise ArgumentError, "Unknown command: #{cmd}"
        end
      end
    end
  end
end
