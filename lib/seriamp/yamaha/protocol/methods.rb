# frozen_string_literal: true

require 'seriamp/yamaha/protocol/set_constants'

module Seriamp
  module Yamaha
    module Protocol
      module Methods
        include SetConstants

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
          system_command("30#{'%02x' % value}")
        end

        # Sets zone 2 volume.
        #
        # @param [ Integer ] value The raw volume value.
        def set_zone2_volume(value)
          system_command("31#{'%02x' % value}")
        end

        # Sets zone 2 volume.
        #
        # @param [ Float ] volume The volume in decibels.
        def set_zone2_volume(volume)
          value = Integer(volume + 33 + 39)
          set_zone2_volume(value)
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
          remote_command("234#{'%02x' % value}")
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
      end
    end
  end
end
