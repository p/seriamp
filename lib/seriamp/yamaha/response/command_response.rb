# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Response
      class CommandResponse

        def initialize(control_type:, guard:, state:)
          @control_type = control_type
          @guard = guard
          @state = state
        end

        attr_reader :control_type
        attr_reader :guard
        attr_reader :state

        alias to_state state
      end
    end
  end
end
