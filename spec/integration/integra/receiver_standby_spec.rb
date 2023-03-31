require 'spec_helper'

describe 'Integra integration - standby commands' do
  if (ENV['SERIAMP_INTEGRATION_INTEGRA'] || '').empty?
    before(:all) do
      skip "Set SERIAMP_INTEGRATION_INTEGRA=/dev/ttyXXX in environment to run integration tests"
    end
  end

  let(:device) { ENV.fetch('SERIAMP_INTEGRATION_INTEGRA') }
  let(:logger) { Logger.new(STDERR) }
  let(:client) { Seriamp::Integra::Client.new(device: device, logger: logger) }

  before do
    client.set_power(true)
    sleep 1
    client.set_power(false)
    puts 'power off'
    
    start = Seriamp::Utils.monotime
    loop do
      lambda do
        loop do
          IO.select([io.io], nil, nil, 10)
          io.read_nonblock(1000)
        end
      end.should raise_error(IO::EAGAINWaitReadable)
      
      if (elapsed = Seriamp::Utils.monotime - start) >= 10
        break
      else
        puts "#{'%.2f' % elapsed} seconds elapsed, waiting until 10"
      end
    end
    puts 'socket drained'
    
    puts 'sleeping for 10 seconds to turn off microprocessor'
    sleep 10
  end
  
  let(:io) { Seriamp::Backend::LoggingSerialPortBackend::Device.new(device) }

  describe 'receiver behavior' do
    xit 'behaves as expected' do
      lambda do
        IO.select([io.io], nil, nil, 1)
      end.should raise_error(IO::EAGAINWaitReadable)
      
      io.syswrite("!1PWRQSTN\r")
      lambda do
        IO.select([io.io], nil, nil, 3)
        p :read
        p io.read_nonblock(1000)
        # This is not reliably working.
        # Somehow the microprocessor is responding immediately in some cases?
      end.should raise_error(IO::EAGAINWaitReadable)
    end
  end
end
