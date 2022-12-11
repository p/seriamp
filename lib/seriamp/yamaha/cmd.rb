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
            value = args.shift
          else
            value = which
            which = 'main'
          end
          prefix = "set_#{which}"
          if value.nil?
            puts client.send("last_#{which}_volume_db")
            return
          end
          value = value.downcase
          if value == 'up'
            # Just like with remote, the first volume up or down command
            # doesn't do anything.
            client.public_send("#{which}_volume_up")
            client.public_send("#{which}_volume_up")
          elsif value == 'down'
            client.public_send("#{which}_volume_down")
            client.public_send("#{which}_volume_down")
          else
            if %w(. - mute).include?(value)
              method = "#{prefix}_mute"
              value = true
            elsif value == 'unmute'
              method = "#{prefix}_mute"
              value = false
            else
              method = "#{prefix}_volume_db"
              if value[0] == ','
                value = value[1..]
              end
              value = Float(value)
            end
            client.public_send(method, value)
          end
        when 'input'
          which = args.shift&.downcase
          if %w(main zone2 zone3).include?(which)
            input = args.shift
          else
            input = which
            which = 'main'
          end
          if input.nil?
            puts client.public_send("last_#{which}_input_name")
            return
          end
          client.public_send("set_#{which}_input", input)
        when 'program'
          value = args.shift.downcase
          client.set_program(value)
        when 'pure-direct'
          state = Utils.parse_on_off(args.shift)
          client.set_pure_direct(state)
        when 'status'
          pp client.last_status
        when 'dev-status'
          status = client.last_status_string
          0.upto(status.length-1).each do |i|
            puts "%3d  %s" % [i, status[i]]
          end
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
