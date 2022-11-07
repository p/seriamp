require 'optparse'
require 'logger'
require 'pp'
require 'yamaha/utils'
require 'yamaha/client'

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
      @client = Yamaha::Client.new(options[:device], logger: @logger)

      @args = args
    end

    attr_reader :args

    def run
      cmd = args.shift
      unless cmd
        raise ArgumentError, "No command given"
      end

      case cmd
      when 'detect'
        device = Yamaha::Client.detect_device(*args, logger: logger)
        if device
          puts device
          exit 0
        else
          STDERR.puts("Yamaha receiver not found")
          exit 3
        end
      when 'power'
        which = ARGV.shift&.downcase
        if %w(main zone2 zone3).include?(which)
          method = "set_#{which}_power"
          state = parse_on_off(ARGV.shift)
        else
          method = 'set_power'
          state = parse_on_off(which)
        end
        client.public_send(method, state)
      when 'volume'
        which = ARGV.shift
        if %w(main zone2 zone3).include?(which)
          prefix = "set_#{which}"
          value = ARGV.shift
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
        which = ARGV.shift&.downcase
        if %w(main zone2 zone3).include?(which)
          method = "set_#{which}_input"
          input = ARGV.shift
        else
          method = 'set_main_input'
          input = which
        end
        client.public_send(method, input)
      when 'program'
        value = ARGV.shift.downcase
        client.set_program(value)
      when 'pure-direct'
        state = parse_on_off(ARGV.shift)
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
