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

        def value
          if state.length == 1
            state.values.first
          else
            raise UnexpectedResponse, "Received multi-variable state: #{state}"
          end
        end

        def ==(other)
          other.is_a?(self.class) &&
          control_type == other.control_type &&
          guard == other.guard &&
          state == other.state
        end
      end
    end
  end
end
