# frozen_string_literal: true

require 'seriamp/backend/serial_port'
require 'seriamp/backend/logging'

module Seriamp
  module Backend
    module LoggingSerialPortBackend

      class Device < SerialPortBackend::Device
        include Backend::Logging
      end
    end
  end
end
