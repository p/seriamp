# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Response
      class TextResponse

        def initialize(field_name, text)
          @field_name = field_name
          @text = text
        end

        attr_reader :field_name
        attr_reader :text

        def to_state
          {field_name => text}
        end

        # System commands can return CommandResponse or TextResponse;
        # implement CommandResponse methods to make response handling
        # more straightforward for downstream code.
        def control_type
          :rs232
        end

        # System commands can return CommandResponse or TextResponse;
        # implement CommandResponse methods to make response handling
        # more straightforward for downstream code.
        def guard
          nil
        end
      end
    end
  end
end
