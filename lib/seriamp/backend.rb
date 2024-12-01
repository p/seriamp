# frozen_string_literal: true

module Seriamp
  module Backend
    autoload :Logging, 'seriamp/backend/logging'
    autoload :StructuredLogging, 'seriamp/backend/structured_logging'

    autoload :FFIBackend, 'seriamp/backend/ffi'
    autoload :SerialPortBackend, 'seriamp/backend/serial_port'
    autoload :LoggingSerialPortBackend, 'seriamp/backend/logging_serial_port'
    autoload :TcpBackend, 'seriamp/backend/tcp'
    autoload :LoggingTcpBackend, 'seriamp/backend/logging_tcp'
    autoload :IoBackend, 'seriamp/backend/io'
  end
end
