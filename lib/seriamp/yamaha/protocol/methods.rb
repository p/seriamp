# frozen_string_literal: true

require 'seriamp/yamaha/protocol/set_constants'
require 'seriamp/yamaha/protocol/extended/constants'
require 'seriamp/yamaha/helpers'

module Seriamp
  module Yamaha
    module Protocol
      module Methods
        include SetConstants
        include Yamaha::Helpers
        include Extended::Constants

        POWER_ON_TIMEOUT = 5

        def advanced_setup(state)
          system_command("B00#{state ? '1' : '0'}")
        end

        def set_speaker_impedance(value)
          value = case value
          when 8
            '0'
          when 6
            '1'
          else
            raise ArgumentError, "Invalid value: must be 6 or 8: #{value}"
          end
          system_command("B30#{value}")
        end

        # Turns the receiver on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_power(state)
          # Sometimes this command returns power state and sometimes it does not?
          remote_command("7A1#{state ? 'D' : 'E'}")
          extend_next_deadline if state
          nil
        end

        # Turns main zone power on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_main_power(state)
          if state
            retry_for_interval(POWER_ON_TIMEOUT) do
              # Sometimes this command returns power state and sometimes it does not?
              remote_command("7E7E")
            end
            extend_next_deadline
          else
            remote_command("7E7F")
          end
          nil
        end

        # Turns zone 2 power on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_zone2_power(state)
          remote_command("7EB#{state ? 'A' : 'B'}")
        end

        # Turns zone 3 power on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_zone3_power(state)
          remote_command("7AE#{state ? 'D' : 'E'}")
        end

        # Sets main zone volume.
        #
        # @param [ Float ] volume The volume in decibels.
        def set_main_volume(volume)
          value = Integer((volume + 80) * 2 + 39)
          # TODO verify the received value is the value we requested?
          system_command("30#{'%02x' % value}").fetch(:main_volume)
        end

        # Sets zone 2 volume.
        #
        # @param [ Float ] volume The volume in decibels.
        def set_zone2_volume(volume)
          value = Integer((volume + 80) * 2 + 39)
          # TODO verify the received value is the value we requested?
          system_command("31#{'%02x' % value}").fetch(:zone2_volume)
        end

        def main_volume_up
          # In RX-V1700 and newer, the volume up/down commands sent via
          # the serial connection increase or decrease the volume by one
          # step, i.e. by 0.5 dB. This is in contrast to the volume up/down
          # buttons on the remote which, on first press, display the current
          # volume but don't change it, and on the second and subsequent
          # presses (in a short interval) actually change the volume by one
          # step. In RX-V1500, the volume up/down commands sent via the serial
          # connection operate identically to the remote buttons, i.e. the
          # first up/down command shows the current volume on the receiver
          # front panel but doesn't change the volume itself.
          # My guess is RX-V1600 is more likely to behave like RX-V1700 than
          # RX-V1500.
          # Higher level models (RX-V2x00/RX-V3x00) mirror the behavor of
          # RX-V1x00 of the same generation.
          remote_command('7A1A').fetch(:main_volume)
        end

        def main_volume_down
          remote_command('7A1B').fetch(:main_volume)
        end

        def zone2_volume_up
          remote_command('7ADA').fetch(:zone2_volume)
        end

        def zone2_volume_down
          remote_command('7ADB').fetch(:zone2_volume)
        end

        # Sets zone 3 volume.
        #
        # @param [ Integer ] volume The raw volume value.
        def set_zone3_volume(volume)
          value = Integer((volume + 80) * 2 + 39)
          system_command("34#{'%02x' % value}").fetch(:zone3_volume)
        end

        def zone3_volume_up
          remote_command('7AFD').fetch(:zone3_volume)
        end

        def zone3_volume_down
          remote_command('7AFE').fetch(:zone3_volume)
        end

        def main_mute?
          current_status.fetch(:main_mute)
        end

        def zone2_mute?
          current_status.fetch(:zone2_mute)
        end

        def zone3_mute?
          current_status.fetch(:zone3_mute)
        end

        def set_main_mute(state)
          cmd = if state == :attenuate || state == 'attenuate'
            '7EDF'
          elsif state
            '7EA2'
          else
            '7EA3'
          end
          remote_command(cmd, expect_response_state: :main_mute, include_response_state: %i(mute_type))
        end

        def set_zone2_mute(state)
          remote_command("7EA#{state ? '0' : '1'}")
        end

        def set_zone3_mute(state)
          remote_command("7E#{state ? '2' : '6'}6")
        end

        {
          front_left: '41',
          front_right: '40',
          center: '42',
          surround_left: '44',
          surround_right: '43',
          surround_back_left: '48',
          surround_back_right: '47',
          subwoofer: '49',
          subwoofer_1: '49',
          subwoofer_2: '4A',
          presence_left: '46',
          presence_right: '45',
        }.each do |channel, prefix|
          # TODO does this affect headphones?
          define_method("set_#{channel}_level") do |level|
            encoded = encode_sequence(level, '14', -10, 10, 0.5)
            system_command(prefix + encoded)
          end
        end

        {
          front_left: '2',
          front_right: '3',
          center: '0',
          surround_left: '4',
          surround_right: '5',
          surround_back_left: '6',
          surround_back_right: '7',
          subwoofer: 'A',
          presence_left: '8',
          presence_right: '9',
        }.each do |channel, prefix|
          define_method("#{channel}_distance_meters") do
            extended_command("0410#{prefix}0")
          end

          define_method("set_#{channel}_distance_meters") do |distance|
            encoded = encode_sequence(distance, '01E', 0.3, 24, 0.01)
            extended_command("0411#{prefix}0#{encoded}")
          end

          define_method("#{channel}_distance_feet") do
            extended_command("0410#{prefix}1")
          end

          define_method("set_#{channel}_distance_feet") do |distance|
            encoded = encode_sequence(distance, '00A', 0, 80, 0.1)
            extended_command("0411#{prefix}1#{encoded}")
          end
        end

        def get_main_volume_text
          extract_text(system_command("2001"))[3...].strip
        end

        def get_zone2_volume_text
          extract_text(system_command("2002"))[3...].strip
        end

        def get_zone3_volume_text
          extract_text(system_command("2005"))[3...].strip
        end

        # Turns pure direct mode on or off.
        #
        # @param [ true | false ] state Desired state.
        def set_pure_direct(state)
          remote_command("7E8#{state ? '0' : '2'}")
        end

        def set_program(value)
          program_code = PROGRAM_SET.fetch(value.downcase.gsub(/[^a-z]/, '_'))
          remote_command("7E#{program_code}")
        end

        def set_main_input(source)
          canonical_source = source.downcase.gsub(/[^a-z0-9]/, '_')
          source_code = fetch_hash(MAIN_INPUTS_SET, canonical_source, 'input name', source)
          remote_command("7A#{source_code}")
        end

        def set_zone2_input(source)
          source_code = ZONE2_INPUTS_SET.fetch(source.downcase.gsub(/[^a-z]/, '_'))
          remote_command("7A#{source_code}")
        end

        def set_zone3_input(source)
          source_code = ZONE3_INPUTS_SET.fetch(source.downcase.gsub(/[^a-z]/, '_'))
          remote_command("7A#{source_code}")
        end

        def set_center_speaker_layout(layout)
          value = CENTER_SPEAKER_LAYOUTS[layout.to_s]
          unless value
            raise ArgumentError, "Invalid center speaker layout: #{layout}; valid layouts: #{CENTER_SPEAKER_LAYOUTS.keys.join(', ')}"
          end
          system_command("70#{value}")
        end

        def set_front_speaker_layout(layout)
          value = FRONT_SPEAKER_LAYOUTS[layout.to_s]
          unless value
            raise ArgumentError, "Invalid front speaker layout: #{layout}; valid layouts: #{FRONT_SPEAKER_LAYOUTS.keys.join(', ')}"
          end
          system_command("71#{value}")
        end

        def set_surround_speaker_layout(layout)
          value = SURROUND_SPEAKER_LAYOUTS[layout.to_s]
          unless value
            raise ArgumentError, "Invalid surround speaker layout: #{layout}; valid layouts: #{SURROUND_SPEAKER_LAYOUTS.keys.join(', ')}"
          end
          system_command("72#{value}")
        end

        def set_surround_back_speaker_layout(layout)
          value = SURROUND_BACK_SPEAKER_LAYOUTS[layout.to_s]
          unless value
            raise ArgumentError, "Invalid surround back speaker layout: #{layout}; valid layouts: #{SURROUND_BACK_SPEAKER_LAYOUTS.keys.join(', ')}"
          end
          system_command("73#{value}")
        end

        def set_presence_speaker_layout(layout)
          value = PRESENCE_SPEAKER_LAYOUTS[layout.to_s]
          unless value
            raise ArgumentError, "Invalid presence speaker layout: #{layout}; valid layouts: #{PRESENCE_SPEAKER_LAYOUTS.keys.join(', ')}"
          end
          system_command("74#{value}")
        end

        def set_bass_out(v)
          value = BASS_OUTS[v.to_s]
          unless value
            raise ArgumentError, "Invalid bass out value: #{v}; valid values: #{BASS_OUTS.keys.join(', ')}"
          end
          system_command("75#{value}")
        end

        def set_subwoofer_phase(v)
          value = SUBWOOFER_PHASES[v.to_s]
          unless value
            raise ArgumentError, "Invalid subwoofer phase value: #{v}; valid values: #{SUBWOOFER_PHASES.keys.join(', ')}"
          end
          system_command("76#{value}")
        end

        def set_subwoofer_crossover(v)
          value = SUBWOOFER_CROSSOVERS[v]
          unless value
            raise ArgumentError, "Invalid subwoofer crossover frequency: #{v}; valid freuencies: #{SUBWOOFER_CROSSOVERS.keys.join(', ')}"
          end
          system_command("7E#{value}")
        end

        BASS_FREQUENCY_MAP = {
          bass: {
            125 => 0,
            350 => 1,
            500 => 2,
          }.freeze,
          treble: {
            2500 => 0,
            3500 => 1,
            8000 => 2,
          }.freeze,
        }.freeze

        def tone
          {}.tap do |result|
            %i(speaker headphone).each do |output|
              this_result = public_send("main_#{output}_tone")
              result.update(prefix_keys(this_result, :"main_#{output}_tone_"))
            end
          end
        end

        private def prefix_keys(hash, prefix)
          Hash[hash.map do |k, v|
            prefixed_k = "#{prefix}#{k}"
            if Symbol === k
              prefixed_k = prefixed_k.to_sym
            end
            [prefixed_k, v]
          end]
        end

        {speaker: '0', headphone: '1'}.each do |output, output_value|
          define_method("main_#{output}_tone") do
            result = {}
            {bass: '0', treble: '1'}.each do |tone, tone_value|
              this_result = extended_command("0330#{output_value}#{tone_value}")
              result.update(
                "#{tone}_frequency": this_result.frequency,
                "#{tone}_gain": this_result.gain,
              )
            end
            result
          end

          {bass: '0', treble: '1'}.each do |tone, tone_value|
            define_method("main_#{output}_tone_#{tone}") do
              result = extended_command("0330#{output_value}#{tone_value}")
              {frequency: result.frequency, gain: result.gain}
            end

            define_method("set_main_#{output}_tone_#{tone}") do |value|
              if Hash === value
                freq = value.fetch(:frequency)
                gain = value.fetch(:gain)
              else
                freq = nil
                gain = value
              end
              if freq.nil?
                freq = send("main_#{output}_tone_#{tone}").fetch(:frequency)
              end
              # Round to 0.5 dB
              use_gain = (gain * 2).round / 2.0
              if use_gain < -6 || use_gain > 6
                raise ArgumentError, "Gain out of range: must be -6..6: #{gain}"
              end
              gain_enc = serialize_volume(gain, -6, 0, 0.5)
              freq_map = BASS_FREQUENCY_MAP.fetch(tone)
              frequency_enc = begin
                freq_map.fetch(freq)
              rescue KeyError
                raise ArgumentError, "Invalid turnover frequency: #{freq}: must be one of: #{freq_map.keys.map(&:to_s).join(', ')}"
              end
              extended_command("0331#{output_value}#{tone_value}#{frequency_enc}#{gain_enc}")
            end
          end
        end

        # RX-V1700, RX-V1800, probably RX-V1900 also?
        # RX-V2700 does not support this apparently and instead offers
        # the "parametric EQ".
        # RX-V4600 has "parametric EQ" which is different from this,
        # does not support graphic EQ according to documentation.
        GRAPHIC_EQ_CHANNEL_MAP.invert.each do |channel, channel_value|
          GRAPHIC_EQ_CHANNEL_BAND_MAP.fetch(channel).invert.each do |band, band_value|
            define_method("#{channel}_graphic_eq_#{band}") do
              v = extended_command("0300#{channel_value}#{band_value}")
              if channel != v.channel
                raise UnexpectedResponse, "Expected graphic EQ response for #{channel} but received one for #{v.channel}"
              end
              if band != v.frequency
                raise UnexpectedResponse, "Expected graphic EQ response for #{band} hz but received one for #{v.frequency} hz"
              end
              v.gain
            end

            define_method("set_#{channel}_graphic_eq_#{band}") do |gain|
              gain_enc = serialize_volume(gain, -6, 3, 0.5)
              extended_command("0301#{channel_value}#{band_value}#{gain_enc}")
            end
          end

          define_method("#{channel}_graphic_eq") do
            {}.tap do |result|
              GRAPHIC_EQ_CHANNEL_BAND_MAP.fetch(channel).each_value do |band|
                res = send("#{channel}_graphic_eq_#{band}")
                result[band] = res
              end
            end
          end

          1.upto(7) do |band|
            define_method("#{channel}_parametric_eq_#{band}") do
              v = extended_command("0340#{channel_value}#{(band - 1).to_s}")
              if channel != v.channel
                raise UnexpectedResponse, "Expected parametric EQ response for #{channel} but received one for #{v.channel}"
              end
              if band != v.band
                raise UnexpectedResponse, "Expected parametric EQ response for #{band} hz but received one for #{v.frequency} hz"
              end
              v
            end
          end

          define_method("#{channel}_parametric_eq") do
            {}.tap do |result|
              1.upto(7) do |band|
                res = send("#{channel}_parametric_eq_#{band}")
                result[band] = res.to_state.values.first
              end
            end
          end
        end

        def graphic_eq
          {}.tap do |result|
            GRAPHIC_EQ_CHANNEL_MAP.each_value do |channel|
              result[channel] = send("#{channel}_graphic_eq")
            end
          end
        end

        def volume_trim(input_name)
          # RX-V1600 use a single byte for input ID,
          # RX-V2500 does not support volume trim over serial.
          input_id = hash_get_with_upcase(
            GetConstants::VOLUME_TRIM_INPUT_NAME_2_SET, input_name)
          extended_command("0120#{input_id}")
        end

        def set_volume_trim(input_name, value)
          # RX-V1600 use a single byte for input ID,
          # RX-V2500 does not support volume trim over serial.
          input_id = hash_get_with_upcase(
            GetConstants::VOLUME_TRIM_INPUT_NAME_2_SET, input_name)
          value = encode_sequence(value, '00', -6, 6, 0.5)
          extended_command("0121#{input_id}#{value}")
        end

        # RX-V3800
        VOLUME_TRIM_REQS = [
          'PHONO',
          'CD',
          'TUNER',
          'CD-R',
          'MD/TAPE',
          'DVD',
          # Should be DTV/CBL
          'DTV',
          # Should be VCR
          'VCR1',
          # Should be DVR
          'DVR/VCR2',
          'V-AUX',
          'XM',
          'Multi-Channel',
          'BD/HD DVD',
          'Dock',
          'PC/MCX',
          'Net Radio',
          'USB',
        ].freeze

        def all_volume_trims
          status = {}
          VOLUME_TRIM_REQS.each do |req|
            status.update(volume_trim(req).to_state)
          end
          status
        end

        def input_label(input_name)
          input_id = hash_get_with_upcase(
            GetConstants::VOLUME_TRIM_INPUT_NAME_2_SET, input_name)
          extended_command("01100#{input_id}")
        end

        def set_input_label(input_name, label)
          input_id = hash_get_with_upcase(
            GetConstants::VOLUME_TRIM_INPUT_NAME_2_SET, input_name)
          if label.length > 9
            raise ArgumentError, "Label must be no more than 9 characters long"
          end
          if false
            label = label + ' ' * (8 - label.length)
            extended_command("01110#{input_id}09#{label}")
          else
            # Labels of fewer than 9 characters work on at least RX-V3800,
            # they are always padded with spaces to 9 characters by the
            # receiver.
            # If length doesn't match length of provided label the receiver
            # subsequently produces responses that Seriamp barfs on.
            # I haven't investigated whether this is due to the response
            # being broken, receiver storing excessive or broken data or
            # a Seriamp issue.
            # To fix the receiver if it got into such a state, set a new
            # input label while correctly specifying its length.
            extended_command("01110#{input_id}0#{label.length}#{label}")
          end
        end

        def all_input_labels
          status = {}
          VOLUME_TRIM_REQS.each do |req|
            status.update(input_label(req).to_state)
          end
          status
        end

        # jack_number is 1-based, e.g. HDMI 1, component A, optical 1
        def io_assignment(jack_type, jack_number)
          jack_type_enc = GetConstants::IO_ASSIGNMENT_JACK_TYPE_SET.fetch(jack_type.to_sym)
          jack_number_enc = encode_sequence(jack_number, '0', 1, 6, 1)
          extended_command("0100#{jack_type_enc}#{jack_number_enc}")
        end

        def set_io_assignment(jack_type, jack_number, input_name)
          jack_type_enc = GetConstants::IO_ASSIGNMENT_JACK_TYPE_SET.fetch(jack_type.to_sym)
          jack_number_enc = encode_sequence(jack_number, '0', 1, 6, 1)
          # NB not all input names are valid for assignment.
          # Not ass assignable inputs can be assigned to all physical jacks -
          # for example, MD/TAPE cannot be assigned to HDMI jacks.
          value = hash_get_with_upcase(
            GetConstants::VOLUME_TRIM_INPUT_NAME_2_SET, input_name)
          extended_command("0101#{jack_type_enc}#{jack_number_enc}#{value}")
        end

        # RX-V3800
        JACKS = {
          coaxial_in: 3,
          optical_out: 2,
          optical_in: 4,
          hdmi_in: 4,
        }.freeze

        def all_io_assignments
          status = {}
          JACKS.each do |jack_type, jack_count|
            1.upto(jack_count) do |jack_num|
              status.update(io_assignment(jack_type, jack_num).to_state)
            end
          end
          status
        end

        def set_program_select(value)
          enc_value = AUTO_LAST_SET.fetch(value.to_s.downcase)
          system_command("600#{enc_value}")
        end

        private

        def fetch_hash(hash, key, value_desc, original_value)
          if hash.key?(key)
            hash[key]
          else
            raise InvalidSettingValue, "Invalid value for #{value_desc}: #{original_value}; valid values are: #{hash.keys.join(', ')}"
          end
        end
      end
    end
  end
end
