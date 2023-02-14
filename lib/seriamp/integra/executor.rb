# frozen_string_literal: true

module Seriamp
  module Integra
    class Executor
      def initialize(client)
        @client = client
      end

      attr_reader :client

      def run_command(cmd, *args)
        cmd = cmd.gsub('_', '-')
        case cmd
        when 'detect'
          device = Seriamp.detect_device(Integra, *args, logger: logger)
          if device
            puts device
            exit 0
          else
            STDERR.puts("Integra receiver not found")
            exit 3
          end
        when 'status'
          pp client.status
        else
          raise ArgumentError, "Unknown command: #{cmd}"
        end
      end
    end
  end
end
