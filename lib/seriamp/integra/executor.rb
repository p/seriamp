# frozen_string_literal: true

module Seriamp
  module Integra
    class Executor
      def initialize(client, **opts)
        @client = client
        @options = opts.dup.freeze
      end

      attr_reader :client
      attr_reader :options

      def run_command(cmd, *args)
        cmd = cmd.gsub('_', '-')
        case cmd
        when 'detect'
          device = Seriamp.detect_device(Integra, *args, logger: logger, timeout: options[:timeout])
          if device
            puts device
            exit 0
          else
            STDERR.puts("Integra receiver not found")
            exit 3
          end
        when 'power'
          which = args.shift&.downcase
          if %w(main zone2 zone3 zone4).include?(which)
            method = "set_#{which}_power"
            state = Utils.parse_on_off(args.shift)
          else
            method = 'set_power'
            state = Utils.parse_on_off(which)
          end
          client.public_send(method, state)
        when 'status'
          pp client.status
        else
          raise ArgumentError, "Unknown command: #{cmd}"
        end
      end
    end
  end
end
