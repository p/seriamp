
### Yamaha RX-V**00 - RS-232

- 5-pin cable required (with RTS pin connected)
- Null-modem cable required
- Receiver socket is male with nuts

Connection options:

- PC with serial port (male) <-> null-modem cable female to female <->
  receiver
- USB-serial adapter (male) <-> null-modem female to female adapter <->
  receiver

The following table shows which Yamaha receivers have RS-232 and Ethernet
capability and which do not for the 2000 through 2010 models:

| Year | Family   | RS-232C                      | Network  | Neither            |
| ---- | -------- | ---------------------------- | -------- | ------------------ |
| 2000 | RX-Vx000 | RX-V3000, RX-V1000           |          | RX-V800 and lower  |
|      |          |                              |          | HTR-5280 and lower |
| 2001 | RX-Vx200 | RX-V3200, RX-V2200           |          | RX-V1200 and lower |
|      |          |                              |          | HTR-5490 and lower |
| 2002 | RX-Vx300 | RX-V3300, RX-V2300           |          | RX-V1300 and lower |
|      |          |                              |          | HTR-5590 and lower |
|      |          |                              |          | HTR-5660 and lower |
| 2003 | RX-Vx400 | RX-V2400                     |          | RX-V1400 and lower |
|      |          |                              |          | HTR-5790 and lower |
| 2004 | RX-Vx500 | RX-V2500, RX-V1500           |          |                    |
|      |          | HTR-5890                     |          | HTR-5860 and lower |
| 2005 | RX-Vx600 | RX-V2600, RX-V1600           |          |                    |
|      |          | HTR-5990                     |          | HTR-5960 and lower |
| 2006 | RX-Vx700 | RX-V2700, RX-V1700           | RX-V2700 |                    |
|      |          |                              |          | HTR-6090 and lower |
| 2007 | RX-Vx800 | RX-V3800, RX-V1800           | RX-V3800 |                    |
|      |          | HTR-6190                     |          | HTR-6180 and lower |
| 2009 | RX-Vx900 | RX-V3900, RX-V1900           | RX-V3900 |                    |
|      |          | RX-V2065                     | RX-V2065 | RX-V1065 and lower |
|      |          | HTR-6295, HTR-6290           |          | HTR-6280 and lower |
| 2010 | RX-Vx67  | RX-V3067, RX-V2067, RX-V1067 | RX-V3067, RX-V2067, RX-V1067, RX-V867 | RX-V767 and lower |

The models which have an Ethernet port in addition to RS-232C should be
controllable via the Yamaha YNCA protocol via either the Ethernet port or the
RS-232C port. Over time Yamaha has been adding networking functionality
to lower tier models, for example it is present in RX-V867, RX-V671 and RX-V475.

Models lower than the 1000 level receivers have never had RS-232C to my knowledge.

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
