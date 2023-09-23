# frozen_string_literal: true

module Seriamp
  module Backend
    module MockSerialPortBackend

      class Device
        def initialize(exchanges)
          @exchanges = exchanges
          @exchange_index = 0
          @exchange_pos = 0

          if block_given?
            yield self
          end
        end

        attr_reader :exchanges

        def read
          exchange = exchanges[exchange_index]
          if exchange.nil?
            return nil
          end
          if exchange.first == 'w'
            raise "Exchange #{exchange_index} is a write, read attempted"
          end
          exchange.last.tap do
            @exchange_index += 1
          end
        end

        def readable?(timeout = 0)
          !!IO.select([io], nil, nil, timeout)
        end

        def errored?
          !!IO.select(nil, nil, [io], 0)
        end

        def clear_rts
        end
      end
    end
  end
end
