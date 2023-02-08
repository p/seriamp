# frozen_string_literal: true

module Seriamp
  module Sonamp
    class Executor
      def initialize(client)
        @client = client
      end

      attr_reader :client

      def run_command(cmd, *args)
        case cmd
        when 'detect'
          device = Seriamp.detect_device(Sonamp, *args, logger: logger)
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
          zone = args.shift.to_i
          state = Utils.parse_on_off(args.shift)
          client.set_zone_power(zone, state)
        when 'zvol'
          zone = args.shift.to_i
          volume = args.shift.to_i
          client.set_zone_volume(zone, volume)
        when 'cvol'
          channel = args.shift.to_i
          volume = args.shift.to_i
          client.set_channel_volume(channel, volume)
        when 'zmute'
          zone = args.shift.to_i
          mute = args.shift.to_i
          client.set_zone_mute(zone, mute)
        when 'cmute'
          channel = args.shift.to_i
          mute = args.shift.to_i
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
