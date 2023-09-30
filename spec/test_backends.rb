# frozen_string_literal: true

require 'forwardable'

module Seriamp
  module Backend
    module TimeoutBackend
      class Device
        extend Forwardable

        def initialize(device, **opts)
        end

        def readable?(timeout)
          sleep timeout
          false
        end

        def syswrite(chunk)
        end

        def read_nonblock(chunk)
          nil
        end

        def clear_rts
        end
      end
    end
  end
end
