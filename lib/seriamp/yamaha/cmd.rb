# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'pp'
require 'seriamp/utils'
require 'seriamp/detect'
require 'seriamp/yamaha/client'
require 'seriamp/yamaha/executor'

module Seriamp
  module Yamaha
    class Cmd
      def initialize(args = ARGV, stdin = STDIN)
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: yamaha [options] command arg..."

          opts.on("-d", "--device DEVICE", "TTY to use (default autodetect)") do |v|
            options[:device] = v
          end

          opts.on('-T', '--timeout TIMEOUT', 'Timeout to use') do |v|
            options[:timeout] = Float(v)
          end
        end.parse!(args)

        @options = options

        @logger = Logger.new(STDERR)
        @client = Yamaha::Client.new(device: options[:device],
          logger: @logger, timeout: options[:timeout])

        @args = args
        @stdin = stdin
      end

      attr_reader :args
      attr_reader :stdin
      attr_reader :logger
      attr_reader :options

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
          device = Seriamp.detect_device(Yamaha, *args, logger: logger)
          if device
            puts device
            exit 0
          else
            STDERR.puts("Yamaha receiver not found")
            exit 3
          end
        else
          executor.run_command(cmd, *args)
        end
      end

      private

      attr_reader :client

      def executor
        @executor ||= Executor.new(client, timeout: options[:timeout])
      end
    end
  end
end
