# Receiver & Amplifier Serial Control Ruby Library

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

### Serial Adapter & Cable Considerations

The adapters and cables have either screws or nuts on them to secure
the connections together. Ideally one side of the connection should
have a screw and the other a nut. If both sides have screws, the
connection would work but would be loose. If both sides have nuts,
the connection won't work as the connectors will physically not able to
meet.

Cables and adapters come with a variety of combinations of male/female
connectors and nuts/screws, therefore this is a good area
to pay attention to when purchasing the hardware.

USB to serial adapters:

- [Male connector with nuts](https://www.amazon.com/gp/product/B00IDSM6BW)
- [Male connector with screws](https://www.amazon.com/gp/product/B0759HSLP1),
  also [this](https://www.amazon.com/gp/product/B017D51ZRQ) and
  [this](https://www.amazon.com/gp/product/B00ZHP2NN0)

Serial cables:

- [Male/screw to female/screw, null modem](https://www.amazon.com/gp/product/B00CEMGMMM)
- [Male/screw to male/screw, null modem](https://www.amazon.com/gp/product/B00006B8BJ)

Mini adapters / gender changers:

- [Null modem male/screw to male/nut](https://www.ebay.com/itm/225083094726)
- [Null modem male/screw to female/nut](https://www.ebay.com/itm/123731343721)
- [Null modem male/screw to female/screw](https://www.ebay.com/itm/255420011438)
- [Null modem female/screw to female/nut](https://www.ebay.com/itm/123732427356)
- [Null modem female/screw to female/screw](https://www.ebay.com/itm/333767424713)
- [Straight female/screw to female/screw](https://www.ebay.com/itm/313578863735)

The mini adapters/gender changers are generally cheaper than serial cables,
but cables can be sourced for quite cheap as well. For example, as of
this writing, the adapters are sold on eBay for about $3.50 and cables can
be bought on Amazon for about $5.50. When using adapters instead of or
in addition to cables, keep in mind that the adapters, being rigidly attached
to the device, will protrude backwards and in particular if a receiver or
amplifier is already positioned close to a wall (or the rear wall of a cabinet),
adding an adapter to the receiver/amplifier may require moving the device
further away from the wall in order to fit the adapter and the serial
cable connector.

### Sonance Sonamp 875D / 875D MK II

- 3-pin cable should be sufficient according to manual
- Null-modem cable required
- Receiver socket is female with nuts

Connection options:

- PC with serial port (male) <-> null-modem cable female to male <->
  receiver
- USB-serial adapter (male) <-> null-modem male to female adapter <->
  receiver

### Yamaha RX-V**00

- 5-pin cable required (with RTS pin connected)
- Null-modem cable required
- Receiver socket is male with nuts

Connection options:

- PC with serial port (male) <-> null-modem cable female to female <->
  receiver
- USB-serial adapter (male) <-> null-modem female to female adapter <->
  receiver

The following table shows which Yamaha receivers have RS-232 connector
and which do not:

| Family   | RS-232C Present              | RS-232C Absent |
| -------- | ---------------------------- | -------------- |
| RX-Vx000 | RX-V3000, RX-V1000           |                |
|          |                              | HTR-5280       |
| RX-Vx200 | RX-V3200, RX-V2200           | RX-V1200       |
|          |                              | HTR-5490       |
| RX-Vx300 | RX-V3300, RX-V2300           | RX-V1300       |
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

### Integra

Tested with DTR-50.4.

- Straight cable required (if using a USB to serial adapter which already
contains a serial cable with male end, no additional cable may be needed).
- Receiver socket is female.
- Receiver socket has the nuts for fixing the cable connector.
[This FTDI adapter](https://www.amazon.com/gp/product/B0759HSLP1)
has screws on the serial end and attaches directly to the receiver.
[This PL2303 adapter]((https://www.amazon.com/gp/product/B00IDSM6BW)
has nuts on the serial end and does not attach to the receiver, requiring
either a straight through female to male serial cable or removing the nuts
from one of the ends (the USB to serial adapter is the cheaper device,
I modify the adapters rather than the receivers/amplifiers).

Connection options:

- PC with serial port (male) <-> straight cable female to male <->
  receiver
- USB-serial adapter (male) <-> receiver

## Implementation Notes

### Yamaha Serial Protocol

In order for the receiver to respond, the RTS bit must be set on the wire.
Setting this bit requires a 5-wire cable. I have some RS232 to 3.5 mm cables
which aren't usable with Yamahas.

Linux appears to automatically set the RTS bit upon opening the serial port,
thus setting it explicitly may not be needed.

To monitor serial communications under Linux, I used
[slsnif](https://github.com/aeruder/slsnif) which I found via
[this summary of serial port monitoring tools](https://serverfault.com/questions/112957/sniff-serial-port-on-linux).

### Yamaha Timeout

The manual specifies that commands should be responded to in 500 ms and to
retry after this timeout elapsed. However in my environment (RX-V1500/1800/2500)
the status command takes 850 ms to complete, thus the timeout must be set to
at least one second.

### Yamaha Status in Standby

The receiver is very frequently not responding to the "ready" command.
The documentation mentions retrying this command but in my experience the
first time this command is sent to a RX-V1500 which is in standby it is
*always* igored.

Documentation for Onkyo/Pioneer receivers provides an explanation for
this behavior: when the receiver is in standby mode and it receives serial
communication, the transmission wakes up the CPU but is not processed.
The next transmission, received after a small delay, will be processed by
the now running CPU.

### Yamaha Volume in Standby

Yamaha receivers I have (RX-V1500, RX-V2500, RX-V1800)
respond to volume changes while in standby. While the volume knob is
doing nothing while in standby, sending volume commands via RS232 does
alter the volume when the receiver is subsequently turned on.
As far as I can tell this behavior is not documented.

Some of the other parameters are not changeable in standby - for example,
input name and pure direct setting.

### Yamaha Receiver Documentation

I have RX-V1500 and RX-V2500, however I couldn't locate RS232 protocol manuals
for these receivers. I am primarily using RX-V1700/RX-V2700 manual with some
references to RX-V1000/RX-V3000 manual. The commands are mostly or completely
identical, with RX-V1700/RX-V2700 manual describing most or all of what
RX-V1500/RX-V2500 support, but the status responses are very different.
For my RX-V1500/RX-V2500 I had to reverse-engineer the status responses, and
because of this they only have a limited number of fields decoded.

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

### Integra Documentation

When reading the protocol documentation, you should read the version that
matches the receiver you are operating on. For example, DTR-50.4 was
added in version 1.23; the closest specification I have is 1.24 and this
document contains DTR-50.4 in the compatibility tables, whereas the
newest version 1.46 does not (it has newer receivers instead).

### Integra Volume

At least for DTR-50.4, as far as I can tell,
volume can only be changed in 1 dB steps via the
serial interface, whereas the front panel volume knob and the remote change
the volume in 0.5 dB steps.

The volume value mapping is as follows:

| RS-232 value - integer | RS-232 value - hexadecimal | dB value         |
| ---------------------- | -------------------------- | ---------------- |
| 0                      | 00                         | Mute (-infinity) |
| 1                      | 01                         | -81 dB           |
| ...                    | ...                        |                  |
| 10                     | 0A                         | -72 dB           |
| 15                     | 0F                         | -67 dB           |
| 97                     | 61                         | +15 dB           |
| 98                     | 62                         | +16 dB           |
| 99                     | 63                         | +16 dB           |
| 100                    | 64                         | +16 dB           |

Notes / observations:

- The lowest non-mute volume is -81.5 dB on DTR-50.4. This volume is not
attainable via the serial interface.
- The maximum volume the DTR-50.4 permits is +16 dB. This is reached with
the serial value of 97. 98, 99 and 100 are accepted by the receiver and
are all mapped to +16 dB.
- MVLUP1 / MVLDOWN1 commands round up to the next full dB value,
rather than increasing or decreasing the volume by 1 dB as the documentation
claims. For example, starting with -10.5 dB, MVLUP1 will set the volume to
-10 dB and MVLDOWN1 will set the volume to -11 dB, a 0.5 dB change in either
case.
- Although DTR-50.4 can change the volume levels in 0.5 dB increments,
the readouts are always in 1 dB increments. In particular, this causes the
-81.5 dB volume level to be read out as MVL00 which is the same as mute.

Unlike Yamaha receivers, the volume up/down commands immediately alter the
volume (Yamaha receivers ignore the first up/down command, treating it
as the command to display current volume level on the front panel).

### Functionality Comparison

- *Subwoofer crossover frequency*: settable in Yamaha receivers, not settable
in Onkyo/Integra receivers.
- *Speaker configuration (small/large)*: settable in Yamaha receivers, not
settable in Onkyo/Integra receivers.
- *Bass destination (front speakers/subwoofer)*: settable in Yamaha receivers,
not settable in Onkyo/Integra receivers.
- *Volume*: main zone volume is settable in Yamaha and Onkyo/Integra receivers
while the receiver is in standby.

### Yamaha Python Buffering

While testing with Python, I ran into [this issue](https://bugs.python.org/issue20074) -
to open a TTY in Python, buffering must be disabled.

## Other Libraries & Tools

Yamaha RS232/serial protocol:

- [YRXV1500-MQTT](https://github.com/FireFrei/yrxv1500-mqtt)
- [YamahaController](https://github.com/mrworf/yamahacontroller)
- [Homie ESP8266 Yamaha RX-Vxxxx Control](https://github.com/memphi2/homie-yamaha-rs232)
- [Here](https://www.avsforum.com/threads/enhancing-yamaha-avrs-via-rs-232.1066484/)

Serial port communication in Ruby:

- [rubyserial](https://github.com/hybridgroup/rubyserial)
- [Ruby/SerialPort](https://github.com/hparra/ruby-serialport)

Yamaha YNCA protocol:

- [yamaha_ynca](https://github.com/mvdwetering/yamaha_ynca)

Integra serial control:

- [Many resources](https://www.avforums.com/threads/onkyo-tx-nr-1007-webinterface-programming.1107346/page-14)
- [onkyoweb-php](https://github.com/guikubivan/onkyoweb-php)
- [onkyo-eiscp](https://github.com/miracle2k/onkyo-eiscp)
- [onpc](https://github.com/mkulesh/onpc)
- [ISCP/eISCP](https://habr.com/en/post/427985/)
- [Decrypting Onkyo firmware](http://divideoverflow.com/2014/04/decrypting-onkyo-firmware-files/)
- [Post](https://robotskirts.com/2012/04/28/controlling-onkyo-integra-receivers-via-rs-232/)

Pioneer serial control:

- [Manuals](https://www.pioneerelectronics.com/PUSA/Support/Home-Entertainment-Custom-Install/RS-232+&+IP+Codes/A+V+Receivers)

Harman/Kardon serial control:

- [avr_control](https://github.com/Teque5/avr_control)
- [hifictl](https://github.com/jherland/hifictl)

## Helpful Links

- [Serial port programming in Ruby](https://www.thegeekdiary.com/serial-port-programming-reading-writing-status-of-control-lines-dtr-rts-cts-dsr/)
