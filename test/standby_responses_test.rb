require 'serialport'
require 'logger'
require 'benchmark'

device = ARGV.shift

logger = Logger.new(STDERR)

logger.info "Using #{device}; verify device is off"
#sleep 1

c = SerialPort.new(device)
if IO.select([c], [], [c], 0)
  logger.info "Device readable - not good"
  c.read_nonblock(1024)
  exit 1
end

STATUS_REQ = "\x11001\x03"

logger.info "Writing status request"
c.write(STATUS_REQ)

logger.info "Reading"
chunk = nil
time = Benchmark.realtime do
  chunk = c.read(1024)
end

puts "Elapsed #{time} seconds, read #{chunk.length} bytes: #{chunK}"

logger.info 'Done'
