# Receiver & Amplifier Serial Control Ruby Library

## Sonamp Auto Power Daemon

When Sonamp amplifiers are placed in RS-232 control mode, they lose the
automatic power management for the zones which are serial controlled.
This daemon performs the power management manually.

The daemon polls the power status of a receiver (currently, only Yamaha
receivers are implemented) and turns the amplifier zones on or off
to match the receiver power state.

When turning the zones on, the last state of the zones when the receiver was on
prior to being turned off is used. For example, if initially the
receiver is on and amplifier has zones 1 and 2 on and zones 3 and 4 off,
the auto power daemon will make a note that zones 1 and 2 are on
and zones 3 and 4 are off. If the receiver is turned off, the auto
power daemon will turn off zones 1 and 2, retaining the knowledge that
only those two zones had been on previously. If the receiver is then
turn on, the auto power daemon will turn on amplifier zones 1 and 2 only.

Currently the auto power daemon requires the sonamp and the receiver
webapp daemons to be running for accessing the respective devices -
the auto power daemon does not implement direct access to either
the receiver or the amplifier. This is because in practice all A/V
equipment that is supported by Seriamp only works with a single
control client (the webapp daemon in case of Seriamp), and direct access
by multiple clients will produce errors and potentially erroneous behavior.

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

### Yamaha RX-V**00 - RS-232

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
|          | HTR-6295, HTR-6290           | HTR-6280       |
| RX-Vx67  | RX-V3067, RX-V2067, RX-V1067 | RX-V867        |

RX-V2700, RX-V3800 and RX-V3900 have an Ethernet port in addition to
RS-232C and should be controllable via the Yamaha YNCA protocol via the
Ethernet port. Over time Yamaha has been adding networking functionality
to lower tier models, for example it is present in RX-V867, RX-V671 and RX-V475.

Models lower than 1000 level receivers have never had RS-232C to my knowledge.

### Yamaha YNCA

This protocol is implemented by Yamaha receivers that have a network port.
The following devices should be compatible:

- Aventage receivers (RX-Axxx)
- RX-V671, RX-V871, RX-V1071, RX-V2071, RX-V3071 and newer
- RX-V2600, RX-V2700, RX-V3800, RX-V3900
- RX-V500D
- TSR-5790 (reportedly uses port 49154)
- HTR-4065

It is claimed that receivers that implement MusicCast do not support the
YNCA protocol. I haven't owned any of these thus cannot confirm or deny.

The YNCA protocol can be used over the serial port (RS-232) and over the
network. The serial port is generally found on the higher end receiver
models, while the network connectivity has been migrating to lower end
models over the years. For example, RX-A700 has a serial port whereas
RX-A710 and newer do not; RX-A800 and newer and the higher end models
(1000/2000/3000) appear to offer the serial port. In the RX-V line, the
serial port is generally present in 2000 and higher models, absent in
models below 1000, and is present in some but not all of the 1000 models.

The default port for the YNCA protocol is 50000.

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

### Functionality Comparison

- *Subwoofer crossover frequency*: settable in Yamaha receivers, not settable
in Onkyo/Integra receivers.
- *Speaker configuration (small/large)*: settable in Yamaha receivers, not
settable in Onkyo/Integra receivers.
- *Bass destination (front speakers/subwoofer)*: settable in Yamaha receivers,
not settable in Onkyo/Integra receivers.
- *Volume*: main zone volume is settable in Yamaha and Onkyo/Integra receivers
while the receiver is in standby.
