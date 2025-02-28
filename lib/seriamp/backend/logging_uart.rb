# frozen_string_literal: true

require 'seriamp/backend/uart'
require 'seriamp/backend/logging'

module Seriamp
  module Backend
    module LoggingUartBackend

      class Device < UartBackend::Device
        include Backend::Logging
      end
    end
  end
end
