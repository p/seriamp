# frozen_string_literal: true

autoload :YAML, 'yaml'
require 'optparse'

module Seriamp
  class AppCmd
    def initialize(args = ARGV, stdin = STDIN, module_name: nil)
      bin_name = if module_name
        "#{module_name}-web"
      else
        'seriamp-web'
      end

      options = {module: module_name}
      OptionParser.new do |opts|
        if module_name
          opts.banner = "Usage: #{bin_name} [options] [-- rackup-options]"
        else
          opts.banner = "Usage: #{bin_name} -m module [options] [-- rackup-options]"

          opts.on("-m", "--module MODULE", "Device module to use: integra|sonamp|yamaha") do |v|
            options[:module] = v
          end
        end

        opts.on("-b", "--backend BACKEND", "Backend to use for communication") do |v|
          options[:backend] = v
        end

        opts.on("-d", "--device DEVICE", "TTY to use (default autodetect /dev/ttyUSB*)") do |v|
          options[:device] = v
        end

        opts.on("-l", "--log-level LEVEL", "Log level as symbol or integer (debug/0|info/1|warn/2|error/3|fatal/4)") do |v|
          options[:log_level] = v
        end

        opts.on('-S', '--structured-log', 'Produce an operation log before exiting in a machine-readable format') do
          options[:structured_log] = true
        end

        opts.on('-t', '--timeout TIMEOUT', 'Timeout to use') do |v|
          options[:timeout] = Float(v)
        end

        opts.separator ''
        opts.separator "To see rackup options: #{bin_name} -- -h"
      end.parse!(args)

      @options = options

      @mod_name = options.fetch(:module)

      require "seriamp/#{mod_name}"
      require "seriamp/#{mod_name}/app"
      require 'rackup/server'

      mod = Seriamp.const_get(mod_name.sub(/(.)/) { $1.upcase })
      @app_mod = mod.const_get(:App)

      @logger = Utils.logger_from_options(**options)

      @client = mod.const_get(:Client).new(device: options[:device],
        backend: options[:backend],
        logger: @logger,
        log_level: options[:log_level],
        structured_log: options[:structured_log],
        timeout: options[:timeout], thread_safe: true)

      @app_mod.set(:client, @client)

      @rack_options = Rackup::Server::Options.new.parse!(args)

      if @rack_options[:environment] == 'production'
        @app_mod.set(:show_exceptions, false)
      end
    end

    attr_reader :mod_name
    attr_reader :mod
    attr_reader :args
    attr_reader :stdin
    attr_reader :logger
    attr_reader :options

    def run
      Rackup::Server.start(@rack_options.merge(app: @app_mod))
    ensure
      if options[:structured_log]
        puts YAML.dump(@client.logged_operations)
      end
    end
  end
end
