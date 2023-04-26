# frozen_string_literal: true

require 'optparse'
require 'pp'
require 'seriamp'
require 'seriamp/utils'
require 'seriamp/detect/serial'

module Seriamp
  class Cmd
    def initialize(args = ARGV, stdin = STDIN, module_name: nil)
      options = {module: module_name}
      OptionParser.new do |opts|
        opts.banner = "Usage: seriamp -m module [options] command arg..."

        opts.on("-m", "--module MODULE", "Device module to use: integra|sonamp|yamaha|ynca") do |v|
          options[:module] = v
        end

        opts.on("-b", "--backend BACKEND", "Backend to use for communication: serial_port|logging_serial_port|tcp|logging_tcp") do |v|
          options[:backend] = v
        end

        opts.on("-d", "--device DEVICE", "TTY or hostname/IP to use (default autodetect /dev/ttyUSB*)") do |v|
          options[:device] = v
        end

        opts.on("-a", "--print-all", "Print the result of each command given (default: only the last)") do
          options[:print_all] = true
        end

        opts.on("-s", "--service URL", "Route commands through the webapp service at URL") do |v|
          options[:service_url] = v
        end

        opts.on('-t', '--timeout TIMEOUT', 'Timeout to use') do |v|
          options[:timeout] = Float(v)
        end
      end.parse!(args)

      unless options[:module]
        raise "Module is required"
      end

      @options = options

      @mod_name = options.fetch(:module)

      require "seriamp/#{mod_name}"
      require "seriamp/#{mod_name}/executor"

      @mod = Seriamp.const_get(
        mod_name.sub(/(.)/) { $1.upcase }.gsub(/_(.)/) { $1.upcase }
      )

      @logger = Utils.logger_from_options(**options)
      if url = options[:service_url]
        @service_client = Seriamp::FaradayFacade.new(url: url, timeout: options[:timeout])
      else
        @direct_client = mod.const_get(:Client).new(device: options[:device],
          backend: options[:backend], retries: true, lock: true, persistent: true,
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
        last_result = nil
        commands.each do |args|
          result = run_command(args)
          if options[:print_all]
            puts result
          else
            last_result = result
          end
        end

        unless options[:print_all]
          puts last_result
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
        device = Seriamp::Detect::Serial.detect_device(mod, *args, logger: logger)
        if device
          puts device
          exit 0
        else
          STDERR.puts("#{mod} device not found")
          exit 3
        end
      else
        result = executor.run_command(cmd, *args)
        meth = case cmd
        when 'status'
          :format_status
        else
          :format
        end
        formatter.public_send(meth, result)
      end
    end

    private

    attr_reader :direct_client
    attr_reader :service_client

    def executor
      @executor ||= mod.const_get(:Executor).new(
        direct_client, timeout: options[:timeout])
    end

    def formatter
      @formatter ||= mod.const_get(:Formatter).new
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
