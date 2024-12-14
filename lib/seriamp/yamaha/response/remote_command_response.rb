# frozen_string_literal: true

module Seriamp
  module Yamaha
    class Response::RemoteCommandResponse < Response
      def self.parse(str)
        new
      end
    end
  end
end
