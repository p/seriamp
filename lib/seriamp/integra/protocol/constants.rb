# frozen_string_literal: true

module Seriamp
  module Integra
    module Protocol
      module Constants

        private

        BOOLEAN_QUESTION = {
          '00' => false,
          '01' => true,
        }

        RESPONSE_VALUES = {
          'PWR' => BOOLEAN_QUESTION,
          'ZPW' => BOOLEAN_QUESTION,
          'PW3' => BOOLEAN_QUESTION,
          'PW4' => BOOLEAN_QUESTION,
        }.freeze

      end
    end
  end
end
