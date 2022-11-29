# frozen_string_literal: true

require 'optparse'
require 'logger'
require 'pp'
require 'seriamp/utils'
require 'seriamp/detect'
require 'seriamp/yamaha/client'

module Seriamp
  module Yamaha
    class Cmd
      def initialize(args)
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: yamaha [-d device] command arg..."

          opts.on("-d", "--device DEVICE", "TTY to use (default autodetect)") do |v|
            options[:device] = v
          end
        end.parse!

        @options = options

        @logger = Logger.new(STDERR)
        @client = Yamaha::Client.new(device: options[:device], logger: @logger)

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
        when 'power'
          which = args.shift&.downcase
          if %w(main zone2 zone3).include?(which)
            method = "set_#{which}_power"
            state = Utils.parse_on_off(args.shift)
          else
            method = 'set_power'
            state = Utils.parse_on_off(which)
          end
          client.public_send(method, state)
        when 'volume'
          which = args.shift
          if %w(main zone2 zone3).include?(which)
            prefix = "set_#{which}"
            value = args.shift
          else
            prefix = 'set_main'
            value = which
          end
          if %w(. -).include?(value)
            method = "#{prefix}_mute"
            value = true
          else
            method = "#{prefix}_volume_db"
            if value[0] == ','
              value = value[1..]
            end
            value = Float(value)
          end
          client.public_send(method, value)
          p client.get_main_volume_text
          p client.get_zone2_volume_text
          p client.get_zone3_volume_text
        when 'input'
          which = args.shift&.downcase
          if %w(main zone2 zone3).include?(which)
            method = "set_#{which}_input"
            input = args.shift
          else
            method = 'set_main_input'
            input = which
          end
          client.public_send(method, input)
        when 'program'
          value = args.shift.downcase
          client.set_program(value)
        when 'pure-direct'
          state = Utils.parse_on_off(args.shift)
          client.set_pure_direct(state)
        when 'status'
          pp client.last_status
        when 'status_string'
          puts client.last_status_string
        when 'test'
          client.set_power(false)
          [true, false].each do |main_state|
            [true, false].each do |zone2_state|
              [true, false].each do |zone3_state|
                client.set_main_power(main_state)
                client.set_zone2_power(zone2_state)
                client.set_zone3_power(zone3_state)
                puts "#{main_state ?1:0} #{zone2_state ?1:0} #{zone3_state ?1:0} #{client.status[:power]}"
              end
            end
          end
        else
          raise ArgumentError, "Unknown command: #{cmd}"
        end
      end

      private

      attr_reader :client
    end
  end
end
