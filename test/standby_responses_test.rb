require 'serialport'
require 'timeout'
require 'logger'
require 'benchmark'

device = ARGV.shift

STATUS_REQ = "\x11001\x03"

class Tester
  def initialize(device)
    @device = device
  end

  attr_reader :device

  def c
    @c ||= SerialPort.new(device)
  end

  def test_standby_status
    logger.info "Using #{device}; verify device is off\n"

    if IO.select([c], [], [c], 0)
      logger.info "Device readable - not good"
      c.read_nonblock(1024)
      exit 1
    end

    logger.info "Writing status request"
    c.write(STATUS_REQ)

    Timeout.timeout(30) do
      logger.info "Reading"
      chunk = nil

      time = Benchmark.realtime do
        chunk = c.read(1024)
      end

      logger.info "Elapsed #{time} seconds, read #{chunk.length} bytes: #{chunK}"
    rescue Timeout::Error
      logger.info "Timed out after 30 seconds"
    end
  end

  def logger
    @logger ||= Logger.new(STDERR)
  end
end

tester = Tester.new(device)
tester.test_standby_status
tester.logger.info 'Done'
