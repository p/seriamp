# frozen_string_literal: true

require 'forwardable'
require 'serialport'

module Seriamp
  module Backend
    module SerialPortBackend

      class Device
        extend Forwardable

        def initialize(device, logger: nil)
          @logger = logger
          @io = SerialPort.open(device)
          @io.baud = 9600
          @io.data_bits = 8
          @io.stop_bits = 1
          @io.parity = SerialPort::NONE
          @io.flow_control = SerialPort::HARD

          if block_given?
            begin
              yield self
            ensure
              close rescue nil
            end
          end
        end

        attr_reader :device

        attr_reader :io

        def_delegators :io, :close, :sysread, :syswrite, :read_nonblock
      end
    end
  end
end
