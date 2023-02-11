# frozen_string_literal: true

module Seriamp
  module Yamaha
    class Executor
      def initialize(client)
        @client = client
      end

      attr_reader :client

      def run_command(cmd, *args)
        cmd = cmd.gsub('_', '-')
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
        when 'center-speaker-layout'
          client.set_center_speaker_layout(args.shift)
        when 'surround-speaker-layout'
          client.set_surround_speaker_layout(args.shift)
        when 'surround-back-speaker-layout'
          client.set_surround_back_speaker_layout(args.shift)
        when 'front-speaker-layout'
          client.set_front_speaker_layout(args.shift)
        when 'presence-speaker-layout'
          client.set_presence_speaker_layout(args.shift)
        when 'bass-out'
          client.set_bass_out(args.shift)
        when 'subwoofer-phase'
          client.set_subwoofer_phase(args.shift)
        when 'subwoofer-crossover'
          client.set_subwoofer_crossover(Integer(args.shift))
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
    end
  end
end
