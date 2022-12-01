# frozen_string_literal: true

require 'seriamp/yamaha/protocol/constants'

module Seriamp
  module Yamaha
    module Protocol
      module Methods
        include Constants

        # Turns the receiver on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_power(state)
          remote_command("7A1#{state ? 'D' : 'E'}")
        end

        # Turns main zone power on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_main_power(state)
          remote_command("7E7#{state ? 'E' : 'F'}")
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
        # @param [ Integer ] value The raw volume value.
        def set_main_volume(value)
          system_command("30#{'%02x' % value}")
        end

        # Sets main zone volume.
        #
        # @param [ Float ] volume The volume in decibels.
        def set_main_volume_db(volume)
          value = Integer((volume + 80) * 2 + 39)
          set_main_volume(value)
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
        def set_zone2_volume_db(volume)
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
      end
    end
  end
end
