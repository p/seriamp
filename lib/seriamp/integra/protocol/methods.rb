# frozen_string_literal: true

require 'seriamp/integra/protocol/constants'

module Seriamp
  module Integra
    module Protocol
      module Methods
        include Constants

        # Turns the receiver on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_power(state)
          command("PWR0#{state ? 1 : 0}")
        end

        alias set_main_power set_power

        # Turns zone 2 power on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_zone2_power(state)
          command("ZPW0#{state ? 1 : 0}")
        end

        # Turns zone 3 power on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_zone3_power(state)
          command("PW30#{state ? 1 : 0}")
        end

        # Turns zone 4 power on or off.
        #
        # @param [ true | false ] state Desired power state.
        def set_zone4_power(state)
          command("PW40#{state ? 1 : 0}")
        end

        def get_main_volume
          Integer(question('MVL'), 16)
        end

        {
          main: 'MVL',
          zone2: 'ZML',
          zone3: 'VL3',
          zone4: 'VL4',
        }.each do |which, cmd|
          _which, _cmd = which, cmd

          define_method("set_#{which}_volume") do |value|
            case value
            when nil
              0
            when Integer
              # Integer protocol - this will be incorrect for floating-point
              # protocol that is used by e.g. some of the 2016 receivers.
              value + 82
            when Float
              # Integer protocol - this will be incorrect for floating-point
              # protocol that is used by e.g. some of the 2016 receivers.
              value.round + 82
            end
            public_send("set_#{_which}_volume_raw", value)
          end

          define_method("set_#{which}_volume_raw") do |value|
            value = case value
            when String
              value
            when Integer
              '%02X' % value
            when Float
              raise ArgumentError, "Raw volume value must be an integer: #{value}"
            else
              raise ArgumentError, "Invalid raw volume value: #{value}"
            end
            command("#{cmd}#{value}")
          end

          define_method("#{which}_volume_up") do
            command("#{cmd}UP")
          end

          define_method("#{which}_volume_down") do
            command("#{cmd}DOWN")
          end
        end

        # 1 dB changes are for main zone only.
        def main_volume_up_1db
          command("MVLUP1")
        end

        # 1 dB changes are for main zone only.
        def main_volume_down_1db
          command("MVLDOWN1")
        end
      end
    end
  end
end
