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

  # This test verifies that the first request to the receiver that is in
  # standby produces no response. (The request should wake up the
  # microcontroller, and the next request sent within an unspecified time
  # withow while the microcontroller is still powered on should produce
  # a response, but the first request does not produce a response).
  #
  # Initial state: receiver is in standby.
  # Test: send status request.
  # Expected outcome: there is no response from the receiver at all.
  def test_standby_status
    logger.info "Using #{device}; verify device is off\n"

    verify_device_not_readable

    logger.info "Writing status request"
    c.write(STATUS_REQ)

    timeout = 30
    begin
      Timeout.timeout(timeout) do
        logger.info "Reading"
        chunk = nil

        time = Benchmark.realtime do
          chunk = c.read(1024)
        end

        logger.info "Elapsed #{time} seconds, read #{chunk.length} bytes: #{chunK}"
      end
    rescue Timeout::Error
      logger.info "Timed out after #{timeout} seconds"
    end

    verify_device_not_readable
  end

  # This test sends two requests to a receiver in standby.
  # Its objective is to determine the time interval that is needed for the
  # second request to return a response.
  # The second request must be sent after the microcontroller is woken up
  # by the first request, but before the microcontroller is powered off again.
  #
  # Initial state: receiver is in standby.
  # Test: send status request.
  # Expected outcome: there is no response from the receiver at all.
  def test_standby_status_2
    logger.info "Using #{device}; verify device is off\n"

    verify_device_not_readable

    logger.info "Writing status request"
    c.write(STATUS_REQ)

    timeout = 1
    begin
      Timeout.timeout(timeout) do
        logger.info "Reading"
        chunk = nil

        time = Benchmark.realtime do
          chunk = c.read(1024)
        end

        logger.info "Elapsed #{time} seconds, read #{chunk.length} bytes: #{chunK}"
      end
    rescue Timeout::Error
      logger.info "Timed out after #{timeout} seconds"
    end

    logger.info "Writing status request"
    c.write(STATUS_REQ)

    timeout = 20
    begin
      Timeout.timeout(timeout) do
        logger.info "Reading"
        chunk = nil

        time = Benchmark.realtime do
          chunk = c.read(1024)
        end

        logger.info "Elapsed #{time} seconds, read #{chunk.length} bytes: #{chunK}"
      end
    rescue Timeout::Error
      logger.info "Timed out after #{timeout} seconds"
    end

    verify_device_not_readable
  end

  def logger
    @logger ||= Logger.new(STDERR)
  end

  def device_readable?
    !!IO.select([c], [], [c], 0)
  end

  def report_device_buffer
    chunk = c.read_nonblock(1024)
    logger.info "Read #{chunk.size} bytes: #{chunk.inspect}"
  end

  def verify_device_not_readable
    if device_readable?
      logger.error "Device readable - not good"
      report_device_buffer
      exit 1
    end
  end
end

tester = Tester.new(device)
tester.test_standby_status_2
tester.logger.info 'Done'
