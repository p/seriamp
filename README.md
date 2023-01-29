# Yamaha Receiver Serial Control Ruby Library

## Hardware Requirements

I used USB to serial adapters with both Prolific PL2303 and FTDI chips.
Both chipsets work under Linux. The FTDI chipset appears to buffer the
incoming data - when reading from the device, it returns more than one
character at a time, whereas with the Prolific chipset only one character at
a time is returned. This means the FTDI chip can possibly offer faster
communication. Adapters based on the FTDI chip are also more expensive.

On Windows, FTDI provides drivers for at least Windows 7, however they
are not signed. Windows can be booted with the option to skip driver
signing enforcement, which makes the adapter work. I couldn't locate a
working Prolific driver for Windows 7.

These USB to serial adapters all have male connection on the RS232 end.
As such, no additional cable is needed if communicating with a receiver
that requires a straight cable and has a female terminal (such as the
Denon AVR-2308CI). For other receivers a gender changer or a cable is
necessary.

### Sonance Sonamp 875D / 875D MK II

- 3-pin cable should be sufficient according to manual
- Null-modem cable required
- Receiver socket is female

### Yamaha RX-V**00

- 5-pin cable required (with RTS pin connected)
- Null-modem cable required
- Receiver socket is male

The following table shows which Yamaha receivers have RS-232 connector
and which do not:

| Family   | RS-232C Present              | RS-232C Absent |
| -------- | ---------------------------- | -------------- |
| RX-Vx000 | RX-V3000, RX-V1000           |                |
|          |                              | HTR-5280       |
| RX-Vx200 | RX-V2200                     | RX-V1200       |
|          |                              | HTR-5490       |
| RX-Vx300 | RX-V2300                     | RX-V1300       |
|          |                              | HTR-5590       |
|          |                              | HTR-5660       |
| RX-Vx400 | RX-V2400                     | RX-V1400       |
|          |                              | HTR-5790       |
| RX-Vx500 | RX-V2500, RX-V1500           |                |
|          | HTR-5890                     | HTR-5860       |
| RX-Vx600 | RX-V2600, RX-V1600           |                |
|          | HTR-5990                     | HTR-5960       |
| RX-Vx700 | RX-V2700, RX-V1700           |                |
|          |                              | HTR-6090       |
| RX-Vx800 | RX-V3800, RX-V1800           |                |
|          | HTR-6190                     | HTR-6180       |
| RX-Vx900 | RX-V3900, RX-V1900           |                |
|          |                              | HTR-6290       |
| RX-Vx67  | RX-V3067, RX-V2067, RX-V1067 | RX-V867        |

RX-V2700, RX-V3800 and RX-V3900 have an Ethernet port in addition to
RS-232C and should be controllable via the Yamaha YNCA protocol via the
Ethernet port. Over time Yamaha has been adding networking functionality
to lower tier models, for example it is present in RX-V867, RX-V671 and RX-V475.

Models lower than 1000 level receivers have never had RS-232C to my knowledge.

### Denon AVR-2308CI

- Straight cable required
- Receiver socket is female

### Integra DTR

- Straight cable required

## Protocol Notes

### RX-V1500 Power Values

You might expect the power state to be a bit field, but it isn't - each
combination is assigned an independent value:

| Main zone | Zone 2 | Zone 3 | Value | Notes   |
| --------- | ------ | ------ | ----- | ------- |
| On        | On     | On     | 1     | All on  |
| On        | On     | Off    | 4     |         |
| On        | Off    | On     | 5     |         |
| On        | Off    | Off    | 2     |         |
| Off       | On     | On     | 3     |         |
| Off       | On     | Off    | 6     |         |
| Off       | Off    | On     | 7     |         |
| Off       | Off    | Off    | 0     | All off |

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

See [here](https://www.avsforum.com/threads/enhancing-yamaha-avrs-via-rs-232.1066484/)
for more Yamaha-related software.

## Other Libraries

Yamaha RS232/serial protocol:

- [YRXV1500-MQTT](https://github.com/FireFrei/yrxv1500-mqtt)
- [YamahaController](https://github.com/mrworf/yamahacontroller)
- [Homie ESP8266 Yamaha RX-Vxxxx Control](https://github.com/memphi2/homie-yamaha-rs232)

Serial port communication in Ruby:

- [rubyserial](https://github.com/hybridgroup/rubyserial)
- [Ruby/SerialPort](https://github.com/hparra/ruby-serialport)

## Helpful Links

- [Serial port programming in Ruby](https://www.thegeekdiary.com/serial-port-programming-reading-writing-status-of-control-lines-dtr-rts-cts-dsr/)
