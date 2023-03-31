# frozen_string_literal: true

module Seriamp
  module Integra
    module Protocol
      module Constants

        private

        RESPONSE_VALUES = {
          'PWR' => {
            '00' => false,
            '01' => true,
          },
        }.freeze

      end
    end
  end
end
