require 'forwardable'
require 'serialport'

module Yamaha
  module Backend
    module SerialPortBackend

      class Device
        extend Forwardable

        def initialize(device, logger: nil)
          @logger = logger
          @io = SerialPort.open(device)
        end

        attr_reader :device

        attr_reader :io

        def_delegators :io, :close, :sysread, :syswrite
      end
    end
  end
end