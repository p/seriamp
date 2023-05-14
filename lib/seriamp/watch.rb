# frozen_string_literal: true

require 'optparse'
require 'pp'
require 'seriamp'
require 'seriamp/utils'
require 'seriamp/detect/serial'

module Seriamp
  # Shows report responses received from the receiver with no input.
  #
  # The intended usage for this utility is to start it then operate the
  # receiver using the front panel or the remote. The watch utility should
  # print reports from the receiver in response to front panel and remote
  # operations.
  #
  # Running this utility concurrently with issuing commands via the serial
  # protocol (using the Cmd utility for example) will generally result in
  # broken responses as the responses will be split between the two utilities,
  # however this can be used to confirm that the watch utility is working.
  class Watch
    def initialize(args = ARGV, stdin = STDIN, module_name: nil)
      options = {module: module_name}
      OptionParser.new do |opts|
        opts.banner = "Usage: seriamp-watch -m module [options]"

        opts.on("-m", "--module MODULE", "Device module to use: integra|sonamp|yamaha") do |v|
          options[:module] = v
        end

        opts.on("-b", "--backend BACKEND", "Backend to use for communication") do |v|
          options[:backend] = v
        end

        opts.on("-d", "--device DEVICE", "TTY to use (default autodetect /dev/ttyUSB*)") do |v|
          options[:device] = v
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
      require "seriamp/#{mod_name}/client"

      @mod = Seriamp.const_get(
        mod_name.sub(/(.)/) { $1.upcase }.gsub(/_(.)/) { $1.upcase }
      )

      @logger = Utils.logger_from_options(**options)
      @direct_client = mod.const_get(:Client).new(device: options[:device],
        backend: options[:backend],
        logger: @logger, timeout: options[:timeout])
    end

    attr_reader :mod_name
    attr_reader :mod
    attr_reader :logger
    attr_reader :options

    def run
      loop do
        direct_client.with_device do
          begin
            direct_client.send(:read_response, append: true, timeout: 5)
            while direct_client.send(:response_complete?)
              resp = direct_client.send(:extract_one_response!)
              parsed = direct_client.send(:parse_response, resp)
              STDOUT << "\r"
              p parsed
            end
          rescue CommunicationTimeout
            if STDOUT.tty?
              STDOUT << "\r#{progress_char}"
            end
            retry
          rescue NoResponse
            puts "No response"
            sleep 1
            retry
          end
        end
      rescue NoMemoryError, Interrupt, SystemExit
        raise
      rescue Exception => exc
        puts "\r#{exc.class}: #{exc}"
        sleep 1
        retry
      end
    end

    private

    attr_reader :direct_client

    PROGRESS_CHARS = '/-\|'

    def progress_char
      @progress_index ||= 0
      @progress_index = (@progress_index + 1) % 4
      PROGRESS_CHARS[@progress_index]
    end
  end
end
