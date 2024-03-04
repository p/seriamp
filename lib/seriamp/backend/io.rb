# frozen_string_literal: true

require 'forwardable'

module Seriamp
  module Backend
    module IoBackend

      class Device
        extend Forwardable

        def initialize(io, **opts)
          unless IO === io
            raise ArgumentError, "First argument must be an IO: #{io}"
          end
          
          @io = io

          if block_given?
            yield self
          end
        end

        attr_reader :io

        def_delegators :io, :close, :sysread, :read_nonblock, :readline

        def readable?(timeout = 0)
          !!IO.select([io], nil, nil, timeout)
        end

        def errored?
          !!IO.select(nil, nil, [io], 0)
        end
      end
    end
  end
end
