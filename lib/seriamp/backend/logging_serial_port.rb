# frozen_string_literal: true

require 'forwardable'
require 'seriamp/backend/serial_port'

module Seriamp
  module Backend
    module LoggingSerialPortBackend

      class Device < SerialPortBackend::Device
        def sysread(*args)
          super.tap do |result|
            puts "Read: #{escape(result)}"
          end
        end
        
        def read_nonblock(*args)
          super.tap do |result|
            puts "Read: #{escape(result)}"
          end
        end
        
        def syswrite(chunk)
          puts "Write: #{escape(chunk)}"
          super
        end
        
        private
        
        def escape(str)
          str.split('').map do |c|
            if (ord = c.ord) <= 32
              "\\x#{'%02x' % ord}"
            else
              c
            end
          end.join
        end
      end
    end
  end
end
