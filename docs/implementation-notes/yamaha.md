# Yamaha Protocol Implementation Notes

## Serial Protocol

In order for the receiver to respond, the RTS bit must be set on the wire.
Setting this bit requires a 5-wire cable. I have some RS232 to 3.5 mm cables
which aren't usable with Yamahas.

Linux appears to automatically set the RTS bit upon opening the serial port,
thus setting it explicitly may not be needed.

To monitor serial communications under Linux, I used
[slsnif](https://github.com/aeruder/slsnif) which I found via
[this summary of serial port monitoring tools](https://serverfault.com/questions/112957/sniff-serial-port-on-linux).

## Yamaha Timeout

The manual specifies that commands should be responded to in 500 ms and to
retry after this timeout elapsed. However in my environment (RX-V1500/1800/2500)
the status command takes 850 ms to complete, thus the timeout must be set to
at least one second.

## Yamaha Status in Standby

The receiver is very frequently not responding to the "ready" command.
The documentation mentions retrying this command but in my experience the
first time this command is sent to a RX-V1500 which is in standby it is
*always* igored.

Documentation for Onkyo/Pioneer receivers provides an explanation for
this behavior: when the receiver is in standby mode and it receives serial
communication, the transmission wakes up the CPU but is not processed.
The next transmission, received after a small delay, will be processed by
the now running CPU.

## Yamaha Volume in Standby

Yamaha receivers I have (RX-V1500, RX-V2500, RX-V1800)
respond to volume changes while in standby. While the volume knob is
doing nothing while in standby, sending volume commands via RS232 does
alter the volume when the receiver is subsequently turned on.
As far as I can tell this behavior is not documented.

Some of the other parameters are not changeable in standby - for example,
input name and pure direct setting.

## Volume

For all zones on RX-V1500/RX-V2500, the volume
is adjusted in 0.5 dB increments from -80 dB to 16.5 dB, giving the hex
values the range of 0x27-0xE8.

## Python Buffering

While testing with Python, I ran into [this issue](https://bugs.python.org/issue20074) -
to open a TTY in Python, buffering must be disabled.