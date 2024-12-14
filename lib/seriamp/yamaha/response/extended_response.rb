# frozen_string_literal: true

module Seriamp
  module Yamaha
    class Response::ExtendedResponse < Response
      def self.parse(str)
        new
      end
    end
  end
end
