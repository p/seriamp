# frozen_string_literal: true

module Seriamp
  module Backend
    module MockSerialPortBackend

      class Error < StandardError; end
      class EndOfExchanges < Error; end
      class UnexpectedWrite < Error; end
      class UnexpectedExchangeType < Error; end
      class UnexpectedSituation < Error; end

      class Exchanges < Array
        attr_accessor :current_index
        attr_accessor :index_attempted

        def current
          self[current_index]
        end
      end

      class Device
        def initialize(exchanges, **opts)
          @exchanges = exchanges
          if exchanges.current_index.nil?
            exchanges.current_index = 0
          else
            # Skip to the next exchange when reinstantiating the Client
            # (presumably after a timeout or an error).
            if exchanges.index_attempted
              if exchanges.index_attempted == exchanges.current_index + 1
                exchanges.current_index += 1
              else
                raise UnexpectedSituation
              end
            end
          end

          if block_given?
            yield self
          end
        end

        attr_reader :exchanges

        def eof?
          !!@eof
        end

        def read_nonblock(max = nil)
          raise EndOfExchanges if eof?

          exchange = exchanges.current
          exchanges.index_attempted = exchanges.current_index
          if exchange.nil?
            @eof = true
            return nil
          end
          if exchange.first == :w || exchange.first == :write
            raise UnexpectedExchangeType, "Exchange #{exchanges.current_index + 1} is a write, read attempted"
          end
          if exchange.first == :read_timeout
            # Do not increment current_index here, otherwise the timeout
            # will be retried by the client logic (since a timeout is not
            # an error, it will always be retried).
            # Do sleep a bit since the mock device always pretends to be readable.
            sleep 0.1
            raise IO::EWOULDBLOCKWaitReadable
          end
          if exchange.first != :r && exchange.first != :read
            raise UnexpectedExchangeType, "Exchange #{exchanges.current_index + 1} should be read, is #{exchange.first}"
          end
          exchange.last.tap do
            exchanges.current_index += 1
          end
        end

        def syswrite(contents)
          exchange = exchanges.current
          if exchange.nil?
            raise UnexpectedWrite, "End of exchanges - write attempted: #{contents}"
          end

          if exchange.first == :r || exchange.first == :read
            raise UnexpectedWrite, "Exchange #{exchanges.current_index + 1} is a read, write attempted"
          end

          if exchange.first != :w && exchange.first != :write
            raise UnexpectedExchangeType "Exchange #{exchanges.current_index + 1} should be write, is #{exchange.first}"
          end

          if contents == exchange.last
            exchanges.current_index += 1
            return nil
          end

=begin
          # Write contents does not match exactly but check the next
          # operation - perhaps the write is split in the fixture
          merged_contents = exchange.last
          delta = 1
          loop do
            next_exchange = exchanges[exchanges.current_index + delta]
            if next_exchange and next_exchange.first == :w || next_exchange.first == :write
              merged_contents += next_exchange.last
              if merged_contents.length > contents.length
                raise UnexpectedWrite, "Unexpected write content: expected: #{exchange.last}, actual: #{contents} (index #{exchanges.current_index})"
              end

              if merged_contents == contents
                @exchanges.current_index += delta
                return nil
              end
            end

            delta += 1
          end
=end

          raise UnexpectedWrite, "Unexpected write content: expected: #{exchange.last}, actual: #{contents} (index #{exchanges.current_index})"
        end

        def readable?(timeout = 0)
          exchange = exchanges.current
          exchange&.first == :r
        end

        def errored?
          false
        end

        def clear_rts
        end
      end
    end

    module LoggingMockSerialPortBackend

      class Device < MockSerialPortBackend::Device
        include Backend::Logging
      end
    end
  end
end
