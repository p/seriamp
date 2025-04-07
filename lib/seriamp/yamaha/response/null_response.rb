# frozen_string_literal: true

module Seriamp
  module Yamaha
    module Response
      class NullResponse
        def ==(other)
          self.class.eql?(other.class)
        end
      end
    end
  end
end
