# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Response
      class StatusResponse

        def initialize(state)
          @state = state
        end

        attr_reader :state

        alias to_state state
      end
    end
  end
end
