# Yamaha RX-V**00 - RS-232

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

Note that pre-2010 receivers that have both a serial port and a network port
(namely, RX-V2700, RX-V3800 and RX-V3900) do not implement the YNCA protocol.
As far as I can tell RX-V2700 is only controllable using the Yamaha serial
protocol described here, over the serial port. RX-V3800 I expect to behave
the same way. RX-V3900 is claimed to implement YNC for network and YSRC for
serial port, and not implement the Yamaha serial protocol described here,
but I have not yet verified this.

Models lower than the 1000 level receivers have never had RS-232C to my knowledge.

Although RX-V2065 implements YNC, on the RS-232 side it implements the
Yamaha serial protocol described here and not YRSC.

## References

http://www.yamaha.com/yec/dealers/dealer_main.htm
