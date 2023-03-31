# frozen_string_literal: true

module Seriamp
  module Integra
    module Protocol
      module Constants

        private

        BOOLEAN_QUESTION = {
          '00' => false,
          '01' => true,
        }.freeze

        VOLUME_1DB_STEP = {
          '00' => nil,
        }

        1.upto(100) do |value|
          VOLUME_1DB_STEP['%02x' % value] = -80 + value
        end

        VOLUME_1DB_STEP.freeze

        RESPONSE_VALUES = {
          'PWR' => [:power, BOOLEAN_QUESTION],
          'ZPW' => [:zone2_power, BOOLEAN_QUESTION],
          'PW3' => [:zone3_power, BOOLEAN_QUESTION],
          'PW4' => [:zone3_power, BOOLEAN_QUESTION],
          'MVL' => [:main_volume, VOLUME_1DB_STEP],
        }.freeze

      end
    end
  end
end
