# frozen_string_literal: true

require 'seriamp/formatter'

module Seriamp
  module Yamaha
    class Formatter < Seriamp::Formatter
      def format_status(result)
        result.inspect
      end
    end
  end
end
