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
          # Sometimes this command returns power state and sometimes it does not?
          remote_command("7E7#{state ? 'E' : 'F'}")
          extend_next_deadline if state
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
          remote_command('7A1A')
        end

        def main_volume_down
          remote_command('7A1B')
        end

        def zone2_volume_up
          remote_command('7ADA')
        end

        def zone2_volume_down
          remote_command('7ADB')
        end

        # Sets zone 3 volume.
        #
        # @param [ Integer ] volume The raw volume value.
        def set_zone3_volume(volume)
          value = Integer((volume + 80) * 2 + 39)
          system_command("34#{'%02x' % value}").fetch(:zone3_volume)
        end

        def zone3_volume_up
          remote_command('7AFD')
        end

        def zone3_volume_down
          remote_command('7AFE')
        end

        def set_subwoofer_level(level)
          system_command("49#{'%02x' % level}")
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
          source_code = MAIN_INPUTS_SET.fetch(source.downcase.gsub(/[^a-z]/, '_'))
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

        {bass: '0', treble: '1'}.each do |tone, tone_value|
          {speaker: '0', headphone: '1'}.each do |output, output_value|
            define_method("main_tone_#{tone}_#{output}") do
              result = extended_command("0330#{output_value}#{tone_value}")
              {frequency: result.frequency, gain: result.gain}
            end

            define_method("set_main_tone_#{tone}_#{output}") do |value|
              if Hash === value
                freq = value.fetch(:frequency)
                gain = value.fetch(:gain)
              else
                freq = nil
                gain = value
              end
              if freq.nil?
                freq = send("main_tone_#{tone}_#{output}").fetch(:frequency)
              end
              # Round to 0.5 dB
              use_gain = (gain * 2).round / 2.0
              if use_gain < -6 || use_gain > 6
                raise ArgumentError, "Gain out of range: must be -6..6: #{gain}"
              end
              gain_enc = serialize_volume(gain, -6, 0, 0.5)
              frequency_enc = 0
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
              extended_command("0300#{channel_value}#{band_value}").gain
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
        end

        def graphic_eq
          {}.tap do |result|
            GRAPHIC_EQ_CHANNEL_MAP.each_value do |channel|
              result[channel] = send("#{channel}_graphic_eq")
            end
          end
        end
      end
    end
  end
end
