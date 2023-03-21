# frozen_string_literal: true

require 'forwardable'
require 'socket'

module Seriamp
  module Backend
    module TcpBackend

      class Device
        extend Forwardable

        def initialize(device, logger: nil, modem_params: nil)
          @logger = logger
          unless device.scan(':').length == 1
            raise ArgumentError, 'TCP backend requires host:port to connect to as the device'
          end
          host, port = device.split(':')
          @io = TCPSocket.new(host, Integer(port))

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
