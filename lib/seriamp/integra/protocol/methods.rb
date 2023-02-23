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
      end
    end
  end
end
