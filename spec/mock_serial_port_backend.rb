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
          if exchange.first == :w || exchange.first == :write
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

          if exchange.first == :r || exchange.first == :read
            raise UnexpectedWrite, "Exchange #{exchange_index} is a read, write attempted"
          end

          if contents == exchange.last
            @exchange_index += 1
            return nil
          end

=begin
          # Write contents does not match exactly but check the next
          # operation - perhaps the write is split in the fixture
          merged_contents = exchange.last
          delta = 1
          loop do
            next_exchange = exchanges[exchange_index + delta]
            if next_exchange and next_exchange.first == :w || next_exchange.first == :write
              merged_contents += next_exchange.last
              if merged_contents.length > contents.length
                raise UnexpectedWrite, "Unexpected write content: expected: #{exchange.last}, actual: #{contents} (index #{exchange_index})"
              end

              if merged_contents == contents
                @exchange_index += delta
                return nil
              end
            end

            delta += 1
          end
=end

          raise UnexpectedWrite, "Unexpected write content: expected: #{exchange.last}, actual: #{contents} (index #{exchange_index})"
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
