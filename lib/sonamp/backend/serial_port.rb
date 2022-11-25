# frozen_string_literal: true

require 'forwardable'
require 'serialport'

module Sonamp
  module Backend
    module SerialPortBackend

      class Device
        extend Forwardable

        def initialize(device, logger: nil)
          @logger = logger
          @io = SerialPort.open(device)

          if block_given?
            begin
              yield
            ensure
              close rescue nil
            end
          end
        end

        attr_reader :device

        attr_reader :io

        def_delegators :io, :close, :sysread, :syswrite
      end
    end
  end
end
