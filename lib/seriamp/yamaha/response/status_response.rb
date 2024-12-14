# frozen_string_literal: true

module Seriamp
  module Yamaha
    class Response::StatusResponse < Response
      def self.parse(str)
        new
      end
    end
  end
end
