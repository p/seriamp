# frozen_string_literal: true

module Seriamp
  module Yamaha
    class Executor
      def self.usage
        <<-EOT
Yamaha module commands:

detect
remote-command 4-char-code
remote-command-nr 4-char-code # Do not attempt to read the response
system-command 4-char-code
ext-command arg # Extended command
power [main|zone2|zone3] on/true/yes|off/false/no
volume [main|zone2|zone3] value|up|down|./-/mute
input [main|zone2|zone3] input-name
program program-name
pure-direct bool
center-speaker-layout arg
surround-speaker-layout arg
front-speaker-layout arg
presence-speaker-layout arg
bass-out arg
subwoofer-phase arg
subwoofer-crossover arg
main-(speaker|headphone)-tone-(bass|treble) gain [frequency]
graphic-eq [channel [band [value]]]
(front|center|surround|surround-back|subwoofer)-level value
(front|center|surround|surround-back|subwoofer)-distance value
distance [ft|m]
distance (front|center|surround|surround-back|subwoofer) [ft|m]
distance (front|center|surround|surround-back|subwoofer) value [ft|m]
volume-trim channel value
osd-message message
advanced-setup bool
speaker-impedance 4|8
status
all-status
dev-status
EOT
      end

      def initialize(client, **opts)
        @client = client
        @options = opts.dup.freeze
      end

      attr_reader :client
      attr_reader :options

      def run_command(cmd, *args)
        cmd = cmd.gsub('_', '-')
        case cmd
        when 'detect'
          device = Seriamp::Detect::Serial.detect_device(Yamaha, *args, logger: logger, timeout: options[:timeout])
          if device
            puts device
            exit 0
          else
            STDERR.puts("Yamaha receiver not found")
            exit 3
          end
        when 'remote-command'
          cmd = args.shift.upcase
          client.remote_command(cmd)
        # Some remote commands do not produce responses, for example
        # SET MENU navigation ones (up/down/+/-). The "nr" version of
        # remote-command does not attempt to read a response.
        when 'remote-command-nr'
          cmd = args.shift.upcase
          client.remote_command(cmd, read_response: false)
        when 'system-command'
          cmd = args.shift.upcase
          client.system_command(cmd)
        when 'ext-command'
          cmd = args.shift.upcase
          client.extended_command(cmd)
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
        when 'mute'
          which = args.shift
          if %w(main zone2 zone3).include?(which)
            value = args.shift
          else
            value = which
            which = 'main'
          end
          if value.nil?
            return client.public_send("#{which}_mute?")
          end
          value = Utils.parse_on_off(value)
          client.public_send("set_#{which}_mute", value)
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
            return client.send("#{which}_volume")
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
            if %w(att attenuate).include?(value)
              method = "#{prefix}_mute"
              value = :attenuate
            elsif %w(. - mute).include?(value)
              method = "#{prefix}_mute"
              value = true
            elsif value == 'unmute'
              method = "#{prefix}_mute"
              value = false
            else
              method = "#{prefix}_volume"
              value = cmd_line_float(value)
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
            puts client.public_send("#{which}_input_name")
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
          client.set_subwoofer_crossover(cmd_line_integer(args.shift))
        when /\Amain-(speaker|headphone)-tone-(bass|treble)\z/
          output, tone = $1, $2
          if args.any?
            if args.length == 1
              value = cmd_line_float(args.shift)
              client.public_send("set_main_#{output}_tone_#{tone}", value)
            else
              args = {
                gain: cmd_line_float(args.shift),
                frequency: Integer(args.shift),
              }
              client.public_send("set_main_#{output}_tone_#{tone}", **args)
            end
          else
            client.public_send("main_#{output}_tone_#{tone}")
          end
        when 'graphic-eq'
          case args.length
          when 3
            # set value
            channel = args.shift.gsub('-', '_').to_sym
            band = cmd_line_integer(args.shift)
            value = cmd_line_float(args.shift)
            client.public_send("set_#{channel}_graphic_eq_#{band}", value)
          when 2
            # get channel & band
            channel = args.shift.gsub('-', '_').to_sym
            band = cmd_line_integer(args.shift)
            client.public_send("#{channel}_graphic_eq_#{band}")
          when 1
            # get channel all
            channel = args.shift.gsub('-', '_').to_sym
            client.public_send("#{channel}_graphic_eq")
          when 0
            # get all
            client.graphic_eq
          else
            raise "Wrong number of arguments: #{args}"
          end
        when /\A(.*)-level\z/
          # TODO validate the method name before passing user input to
          # public_send.
          channel = $1.downcase.gsub('-', '_')
          client.public_send("set_#{channel}_level", Float(args.shift))
        when 'distance'
          args_orig = args
          args = args.map { |arg| arg.downcase.gsub('-', '_') }
          if args.last == 'ft'
            unit = 'feet'
            args.pop
          elsif args.last == 'm'
            unit = 'meters'
            args.pop
          else
            unit = 'feet'
          end
          # TODO validate channels
          case args.length
          when 2
            client.public_send("set_#{args[0]}_distance_#{unit}", Float(args[1]))
          when 1
            client.public_send("#{args[0]}_distance_#{unit}")
          when 0
            Client::CHANNEL_KEYS.each do |channel|
              value = client.public_send("#{channel}_distance_#{unit}")
              channel_name = channel.to_s.gsub(/(_(.))/) { |m| ' ' + $2.upcase }.sub(/^(.)/) { |m| m.upcase }
              puts "#{channel_name}: #{value.distance} #{value.unit}"
            end
          else
            raise "Wrong number of arguments: #{args_orig}"
          end
        when /\A(.*)-distance\z/
          # TODO validate the method name before passing user input to
          # public_send.
          channel = $1.downcase.gsub('-', '_')
          unit = case value = args.shift
          when 'f', 'F'
            :feet
          when 'm', 'M'
            :meters
          else
            raise "First argument must be unit (m/M or f/F): #{value}"
          end
          if args.any?
            client.public_send("set_#{channel}_distance_#{unit}", Float(args.shift))
          else
            client.public_send("#{channel}_distance_#{unit}")
          end
        when 'volume-trim'
          case args.length
          when 0
            pp client.all_volume_trims
          when 1
            p client.volume_trim(args.shift)
          when 2
            input_name = args.shift
            gain = cmd_line_float(args.shift)
            client.set_volume_trim(input_name, gain)
          else
            raise "Bogus volume-trim usage"
          end
        when 'assign', 'io-assignment'
          case args.length
          when 0
            pp client.all_io_assignments
          when 2
            jack_type = args[0]
            jack_number = Integer(args[1])
            p client.io_assignment(jack_type, jack_number)
          when 3
            jack_type = args[0]
            jack_number = Integer(args[1])
            input_name = args[2]
            client.set_io_assignment(jack_type, jack_number, input_name)
          else
            raise "Bogus io-assignment usage"
          end
        # This is called "audio select setting" in the specification.
        when 'program-select'
          case args.length
          when 0
            puts client.program_select
          when 1
            client.set_program_select(args.first)
          else
            raise "Bogus program-select usage"
          end
        when 'osd-message'
          client.osd_message(args.shift)
        when 'advanced-setup'
          client.advanced_setup
        # This command can be given in normal operation, it does not require
        # being in the "advanced setup" menu for serial access.
        when 'speaker-impedance'
          client.set_speaker_impedance(cmd_line_integer(args.shift))
        when 'status'
          pp client.status
        when 'all-status'
          pp client.all_status
        when 'dev-status'
          status = client.status_string
          fields = Client::STATUS_HEAD_FIELDS
          0.upto(fields.length-1).each do |i|
            puts "%3d %3s # %s" % [i, status[i], fields[i]]
          end
          model_name = status[1..5]
          payload_length = Integer(status[7..8], 16)
          puts '---'
          start = fields.length
          fields = build_status_fields(model_name)
          0.upto(payload_length-1).each do |i|
            puts "%3d %3s # DT%-3d %s" % [start+i, status[start+i], i, fields[i]]
          end
          puts '---'
          start += payload_length
          fields = Client::STATUS_TAIL_FIELDS
          start.upto(status.length-1).each do |i|
            puts "%3d %3s # %s" % [i, status[i], fields[i-start]]
          end
          nil
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

      def cmd_line_integer(value)
        if value[0] == ?,
          value = value[1..]
        end
        Integer(value)
      end

      def cmd_line_float(value)
        if value[0] == ?,
          value = value[1..]
        end
        Float(value)
      end

      def build_status_fields(model_name)
        list = Protocol::Status::STATUS_FIELDS[model_name]
        return {} unless list
        fields = []
        list.each do |spec|
          case spec.first
          when Integer
            size = spec.first
            label = spec[1]
          else
            size = 1
            label = spec.first
          end
          1.upto(size) do
            fields << (label || '--')
          end
        end
        fields
      end
    end
  end
end
