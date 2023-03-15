module Seriamp
  module Backend
    autoload :FFIBackend, 'seriamp/backend/ffi'
    autoload :SerialPortBackend, 'seriamp/backend/serial_port'
    autoload :LoggingSerialPortBackend, 'seriamp/backend/logging_serial_port'
  end
end
