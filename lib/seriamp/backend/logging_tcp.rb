# frozen_string_literal: true

require 'seriamp/backend/tcp'
require 'seriamp/backend/logging'

module Seriamp
  module Backend
    module LoggingTcpBackend

      class Device < TcpBackend::Device
        include Backend::Logging
      end
    end
  end
end
