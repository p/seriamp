# Yamaha Receiver Serial Control Ruby Library

## Implementation Notes

In order for the receiver to respond, the RTS bit must be set on the wire.
Setting this bit requires a 5-wire cable. I have some RS232 to 3.5 mm cables
which aren't usable with Yamahas.

Linux appears to automatically set the RTS bit upon opening the serial port,
thus setting it explicitly may not be needed.

To monitor serial communications under Linux, I used
[slsnif](https://github.com/aeruder/slsnif) which I found via
[this summary of serial port monitoring tools](https://serverfault.com/questions/112957/sniff-serial-port-on-linux).

The receiver is very frequently not responding to the "ready" command.
The documentation mentions retrying this command but in my experience the
first time this command is sent to a RX-V1500 which is in standby it is
*always* igored.

I have RX-V1500 and RX-V2500, however I couldn't locate RS232 protocol manuals
for these receivers. I am primarily using RX-V1700/RX-V2700 manual with some
references to RX-V1000/RX-V3000 manual. The commands are mostly or completely
identical, with RX-V1700/RX-V2700 manual describing most or all of what
RX-V1500/RX-V2500 support, but the status responses are very different.
For my RX-V1500/RX-V2500 I had to reverse-engineer the status responses, and
because of this they only have a limited number of fields decoded.

Volume level is set and reported as follows: 0 means muting is active,
otherwise the minimum level for the zone is 39 and each step in the level is
the next integer value up. For the main zone on RX-V1500/RX-V2500, the volume
is adjusted in 0.5 dB increments from -80 dB to 14.5 dB, giving the integer
values the range of 39-228. For zones 2 and 3 the volume is adjusted in whole
dB increments from -33 dB to 0 dB, giving the integer range of 39-72.

While testing with Python, I ran into [this issue](https://bugs.python.org/issue20074) -
to open a TTY in Python, buffering must be disabled.

## Other Libraries

Yamaha RS232/serial protocol:

- [YRXV1500-MQTT](https://github.com/FireFrei/yrxv1500-mqtt)
- [YamahaController](https://github.com/mrworf/yamahacontroller)
- [Homie ESP8266 Yamaha RX-Vxxxx Control]https://github.com/memphi2/homie-yamaha-rs232)

Serial port communication in Ruby:

- [rubyserial](https://github.com/hybridgroup/rubyserial)
- [Ruby/SerialPort](https://github.com/hparra/ruby-serialport)
