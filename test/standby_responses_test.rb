require 'serialport'
require 'timeout'
require 'logger'
require 'benchmark'

device = ARGV.first

MODEM_PARAMS = {
  baud: 9600,
  data_bits: 8,
  stop_bits: 1,
  parity: 0, # SerialPort::NONE
}.freeze

STATUS_REQ = "\x11001\x03"

class Tester
  def initialize(device)
    @device = device
  end

  attr_reader :device

  def c
    @c ||= SerialPort.new(device, modem_params: MODEM_PARAMS)
  end

  def reopen_device
    if @c && device_readable?
      logger.error "Device is readable when trying to reopen it"
      read_and_report
    end

    logger.debug "Reopening #{device}"
    @c.close
    @c = nil
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

    read_and_report(timeout: 30)

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

    read_and_report(timeout: 1)

    logger.info "Writing status request"
    c.write(STATUS_REQ)

    read_and_report(timeout: 5)

    verify_device_not_readable
    sleep 1
    reopen_device
    sleep 1
    verify_device_not_readable

    # Somehow when this test is run repeatedly, subsequent executions
    # have unread data in the device buffer (the null response).
    # But the data is not showing up as part of the test that should have
    # generated the response even if the device is reopened as above.

    if false
      cmd = "ruby #{$0} #{ARGV.join(' ')}"
      logger.info "Execute: #{cmd}"
      exec(cmd)
    end
  end

  def test_standby_status_3
    logger.info "Using #{device}; verify device is off\n"

    verify_device_not_readable

    3.times do
      reopen_device
      logger.info "Writing status request"
      c.write(STATUS_REQ)

      read_and_report(timeout: 2)
    end
  end

  def logger
    @logger ||= Logger.new(STDERR)
  end

  def device_readable?
    !!IO.select([c], [], [c], 0)
  end

  def report_device_buffer
    loop do
      chunk = c.read_nonblock(1024)
      if chunk
        logger.info "Read #{chunk.size} bytes: #{chunk.inspect}"
        next
      else
        sleep 0.25
        break unless device_readable?
      end
    end
  rescue IO::EAGAINWaitReadable
    sleep 0.25
    if device_readable?
      retry
    end
  end

  def verify_device_not_readable
    logger.debug "Checking #{device} is not readable"
    if device_readable?
      logger.error "Device readable - not good"
      report_device_buffer
      exit 1
    end
  end

  def read_and_report(timeout:)
    begin
      Timeout.timeout(timeout) do
        logger.info "Reading with timeout #{timeout}"
        chunk = nil

        time = Benchmark.realtime do
          chunk = c.read(1024)
        end

        logger.info "Elapsed #{time} seconds, read #{chunk.length} bytes: #{chunk.inspect}"

        loop do
          if device_readable?
            read_and_report(timeout: 1)
            sleep 0.250
          end
        end
      end
    rescue Timeout::Error
      logger.info "Timed out after #{timeout} seconds"
    end
  end
end

tester = Tester.new(device)
tester.test_standby_status_3
tester.logger.info 'Done'
