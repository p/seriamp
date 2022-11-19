# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'sonamp/utils'
require 'sonamp/client'

module Sonamp
  class Cmd
    def initialize(args)
      args = args.dup

      options = {}
      OptionParser.new do |opts|
        opts.banner = "Usage: sonamp [-d device] command arg..."

        opts.on("-d", "--device DEVICE", "TTY to use (default autodetect)") do |v|
          options[:device] = v
        end
      end.parse!(args)

      @options = options

      @logger = Logger.new(STDERR)
      @client = Sonamp::Client.new(options[:device], logger: @logger)

      @args = args
    end

    attr_reader :args
    attr_reader :logger

    def run
      if args.any?
        run_command(args)
      else
        STDIN.each_line do |line|
          line.strip!
          line.sub!(/#.*/, '')
          next if line.empty?

          run_command(line.strip.split(%r,\s+,)
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
        device = Sonamp.detect_device(*args, logger: logger)
        if device
          puts device
          exit 0
        else
          STDERR.puts("Sonamp amplifier not found")
          exit 3
        end
      when 'off'
        client.set_zone_power(1, false)
        client.set_zone_power(2, false)
        client.set_zone_power(3, false)
        client.set_zone_power(4, false)
      when 'power'
        zone = args.shift.to_i
        state = Utils.parse_on_off(ARGV.shift)
        client.set_zone_power(zone, state)
      when 'zvol'
        zone = args.shift.to_i
        volume = ARGV.shift.to_i
        client.set_zone_volume(zone, volume)
      when 'cvol'
        channel = args.shift.to_i
        volume = args.shift.to_i
        client.set_channel_volume(channel, volume)
      when 'zmute'
        zone = args.shift.to_i
        mute = ARGV.shift.to_i
        client.set_zone_mute(zone, mute)
      when 'cmute'
        channel = args.shift.to_i
        mute = args.shift.to_i
        client.set_channel_mute(channel, mute)
      when 'status'
        pp client.status
      else
        raise ArgumentError, "Unknown command: #{cmd}"
      end
    end

    private

    attr_reader :client
  end
end
