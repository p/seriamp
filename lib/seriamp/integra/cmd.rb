# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'pp'
require 'seriamp/utils'
require 'seriamp/detect'
require 'seriamp/integra/client'
require 'seriamp/integra/executor'

module Seriamp
  module Integra
    class Cmd
      def initialize(args = ARGV, stdin = STDIN)
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: integra [-d device] command arg..."

          opts.on("-d", "--device DEVICE", "TTY to use (default autodetect)") do |v|
            options[:device] = v
          end
        end.parse!

        @options = options

        @logger = Logger.new(STDERR)
        @client = Integra::Client.new(device: options[:device], logger: @logger)

        @args = args
        @stdin = stdin
      end

      attr_reader :args
      attr_reader :stdin
      attr_reader :logger

      def run
        if args.any?
          run_command(args)
        else
          stdin.each_line do |line|
            line.strip!
            line.sub!(/#.*/, '')
            next if line.empty?

            run_command(line.strip.split(%r,\s+,))
          end
        end
      end

      def run_command(args)
        cmd = args.shift
        unless cmd
          raise ArgumentError, "No command given"
        end

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
        else
          executor.run_command(cmd, *args)
        end
      end

      private

      attr_reader :client

      def executor
        @executor ||= Executor.new(client)
      end
    end
  end
end