# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'pp'
require 'seriamp'
require 'seriamp/utils'
require 'seriamp/detect'

module Seriamp
  class Cmd
    def initialize(args = ARGV, stdin = STDIN, module_name: nil)
      options = {module: module_name}
      OptionParser.new do |opts|
        opts.banner = "Usage: seriamp -m module [options] command arg..."

        opts.on("-m", "--module MODULE", "Device module to use: integra|sonamp|yamaha") do |v|
          options[:module] = v
        end

        opts.on("-d", "--device DEVICE", "TTY to use (default autodetect /dev/ttyUSB*)") do |v|
          options[:device] = v
        end

        opts.on("-s", "--service URL", "Route commands through the webapp service at URL") do |v|
          options[:service_url] = v
        end

        opts.on('-T', '--timeout TIMEOUT', 'Timeout to use') do |v|
          options[:timeout] = Float(v)
        end
      end.parse!(args)

      @options = options

      @mod_name = options.fetch(:module)

      require "seriamp/#{mod_name}"
      require "seriamp/#{mod_name}/executor"

      @mod = Seriamp.const_get(mod_name.sub(/(.)/) { $1.upcase })

      @logger = Logger.new(STDERR)
      if url = options[:service_url]
        @service_client = Seriamp::FaradayFacade.new(url: url, timeout: options[:timeout])
      else
        @direct_client = mod.const_get(:Client).new(device: options[:device],
          logger: @logger, timeout: options[:timeout])
      end

      @args = args
      @stdin = stdin
    end

    attr_reader :mod_name
    attr_reader :mod
    attr_reader :args
    attr_reader :stdin
    attr_reader :logger
    attr_reader :options

    def run
      commands = if args.any?
        [args]
      else
        stdin.each_line.map do |line|
          line.strip!
          line.sub!(/#.*/, '')
          if line.empty?
            nil
          else
            line.strip.split(%r,\s+,)
          end
        end.compact
      end

      if service_client
        body = commands.map do |args|
          args.join(' ')
        end.join("\n")
        resp = service_client.post!('', body: body)
        puts resp.body
      else
        commands.each do |args|
          run_command(args)
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
        device = Seriamp.detect_device(mod, *args, logger: logger)
        if device
          puts device
          exit 0
        else
          STDERR.puts("#{mod} device not found")
          exit 3
        end
      else
        format_output(executor.run_command(cmd, *args))
      end
    end

    private

    attr_reader :direct_client
    attr_reader :service_client

    def executor
      @executor ||= mod.const_get(:Executor).new(
        direct_client, timeout: options[:timeout])
    end

    def format_output(result)
      case result
      when Hash
        result.keys.sort.each do |k|
          puts "  #{k}: #{result[k]}"
        end
      else
        pp result
      end
    end
  end
end
