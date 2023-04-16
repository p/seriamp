# frozen_string_literal: true

require 'io/console'

module Seriamp
  module YamahaMenu
    class InputReader
      def initialize
        @buf = +''
      end

      def get_key
        while buf.empty?
          IO.console.raw(intr: true) do
            if IO.select([STDIN], nil, nil, 1)
              buf << STDIN.read_nonblock(10)
            end
          end
        end

        if buf[0] == ?\e
          index = buf[1..].index(?\e)
          if index
            chunk = buf[0..index]
            @buf = buf[index..] || +''
          else
            chunk = buf
            @buf = +''
          end
        else
          chunk = buf[0]
          @buf = buf[1..] || +''
        end

        chunk
      end

      private

      attr_reader :buf
    end
  end
end
