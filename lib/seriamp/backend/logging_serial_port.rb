# frozen_string_literal: true

require 'forwardable'
require 'seriamp/backend/serial_port'

module Seriamp
  module Backend
    module LoggingSerialPortBackend

      class Device < SerialPortBackend::Device
        def sysread(*args)
          super.tap do |result|
            puts "Read: #{result}"
          end
        end
        
        def read_nonblock(*args)
          super.tap do |result|
            puts "Read: #{result}"
          end
        end
        
        def syswrite(chunk)
          puts "Write: #{chunk}"
          super
        end
      end
    end
  end
end
