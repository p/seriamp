# frozen_string_literal: true

module Seriamp
  module Backend
    module TimeoutBackend
      class Device
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

        def errored?
          false
        end
      end
    end
  end
end
