# frozen_string_literal: true

module Seriamp
  module Backend
    module Logging

      def sysread(*args)
        super.tap do |result|
          logger.debug("Read: #{escape(result)}")
        end
      end

      def read_nonblock(*args)
        super.tap do |result|
          logger.debug("Read: #{escape(result)}")
        end
      end

      def syswrite(chunk)
        logger.debug("Write: #{escape(chunk)}")
        super
      end

      def readline
        super.tap do |result|
          logger.debug("Readline: #{escape(result)}")
        end
      end

      private

      def logger
        @logger ||= Logger.new(STDERR)
      end

      def escape(str)
        str.split('').map do |c|
          if (ord = c.ord) <= 32
            "\\x#{'%02x' % ord}"
          else
            c
          end
        end.join
      end
    end
  end
end
