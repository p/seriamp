# frozen_string_literal: true

module Seriamp
  module Backend
    module StructuredLogging

      def sysread(*args)
        super.tap do |result|
          add_operation(:read, result)
        end
      end

      def read_nonblock(*args)
        super.tap do |result|
          add_operation(:read, result)
        end
      end

      def syswrite(chunk)
        add_operation(:write, chunk)
        super
      end

      def readline
        super.tap do |result|
          add_operation(:read, result)
        end
      end

      attr_accessor :logged_operations

      private

      def add_operation(kind, data)
        @logged_operations ||= []
        @logged_operations << [kind, data]
      end
    end
  end
end
