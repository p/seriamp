# frozen_string_literal: true

module Seriamp
  module Yamaha
    class Response::StatusResponse < Response
      def self.parse(str, logger: nil)
        new
      end
    end
  end
end
