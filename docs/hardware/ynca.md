# Yamaha YNCA

This protocol is implemented by 2010 and newer Yamaha receivers that have a
network port. The following devices should be compatible:

- Aventage receivers (RX-Axxx)
- RX-V671, RX-V871, RX-V1071, RX-V2071, RX-V3071 and newer
- RX-V500D
- TSR-5790 (reportedly uses port 49154)
- HTR-4065

Over time Yamaha has been adding networking functionality
to lower tier models, for example it is present in RX-V867, RX-V671 and RX-V475.

The following earlier models that have a network port do NOT implement YNCA:

- RX-V2700 (verified)
- RX-V3800
- RX-V3900 (these should implement YNC/YSRC instead)

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
