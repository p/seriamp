# frozen_string_literal: true

module Seriamp
  module Backend
    module MockSerialPortBackend

      class EndOfExchanges < StandardError; end
      class UnexpectedWrite < StandardError; end

      class Device
        def initialize(exchanges, **opts)
          @exchanges = exchanges
          @exchange_index = 0
          @exchange_pos = 0

          if block_given?
            yield self
          end
        end

        attr_reader :exchanges
        attr_reader :exchange_index

        def eof?
          !!@eof
        end

        def read_nonblock(max = nil)
          raise EndOfExchanges if eof?

          exchange = exchanges[exchange_index]
          if exchange.nil?
            @eof = true
            return nil
          end
          if exchange.first == :w
            raise "Exchange #{exchange_index} is a write, read attempted"
          end
          exchange.last.tap do
            @exchange_index += 1
          end
        end

        def syswrite(contents)
          exchange = exchanges[exchange_index]
          if exchange.nil?
            raise UnexpectedWrite, "End of exchanges - write attempted: #{contents}"
          end

          if exchange.first == :r
            raise UnexpectedWrite, "Exchange #{exchange_index} is a read, write attempted"
          end

          if contents != exchange.last
            raise UnexpectedWrite, "Unexpected write content: expected: #{exchange.last}, actual: #{contents}"
          end

          @exchange_index += 1
          nil
        end

        def readable?(timeout = 0)
          exchange = exchanges[exchange_index]
          exchange&.first == :r
        end

        def errored?
          false
        end

        def clear_rts
        end
      end
    end
  end
end
