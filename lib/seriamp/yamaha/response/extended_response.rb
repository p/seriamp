# frozen_string_literal: true

module Seriamp
  module Yamaha
    class Response::ExtendedResponse < Response
      def self.parse(str, logger: nil)
        new
      end
    end
  end
end
