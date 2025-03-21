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

        def control_type
          :rs232
        end

        def guard
          nil
        end
      end
    end
  end
end
