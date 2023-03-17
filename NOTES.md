# Implementation Notes

## Broken Serial Interfaces

Different serial interfaces produce different results, both in terms of
correctness and in terms of performance. The below output is obtained by
dumping every string given to a `write` call to the Ruby IO object for the
serial device and every string obtained from a single `read` or `read_nonblock`
call.

Built-in serial interface on Optiplex 5050 SFF communicating with Yamaha
RX-V2500, status command:

    Write: \x11001\x03
    Read: \x12R0178F8
    Read: B@E01900
    Read: 02
    Read: 40005174
    Read: 77340314
    Read: 00000023
    Read: 00000010
    Read: 20001002
    Read: 92828292
    Read: 82928282
    Read: 82800000
    Read: 0
    Read: 14140000
    Read: 00040550
    Read: 12000021
    Read: 00010000
    Read: 00000000
    Read: 00000000
    Read: 00010517
    Read: 70000401
    Read: 0
    Read: FE\x03

But, sometimes the response is missing a number of "lines":

    Write: \x11001\x03
    Read: \x12R0178F8
    Read: B@E01900
    Read: 02
    Read: 00000023
    Read: 00000010
    Read: 20001002
    Read: 92828292
    Read: 82928282
    Read: 0
    Read: 14140000
    Read: 00000000
    Read: 00010517
    Read: FE\x03

Obviously, when the response is missing parts like this it is not usable.
Despite the Optiplex coming with a built-in serial port, in order for
receiver communication to be reliable, the built-in port cannot be used,
and an external USB to serial adapter is required.

## Serial Interface Performance

FTDI FT232-based USB to serial adapter on the same Optiplex 5050 communicating
with the same Yamaha RX-V2500 produces the following I/O chunks:

    Write: \x11001\x03
    Read: \x12R0178F8B@E0190
    Read: 002
    Read: 4
    Read: 00051747734031
    Read: 400000023000000
    Read: 10
    Read: 2000100292828
    Read: 29282928282828
    Read: 000000
    Read: 14140000000
    Read: 40550120000210
    Read: 001000000000000
    Read: 00000000000105
    Read: 17700004010
    Read: FE\x03

Another attempt:

    Write: \x11001\x03
    Read: \x12R0178F8B@
    Read: E0190002
    Read: 40005
    Read: 17477340314000
    Read: 0002300000010
    Read: 200010
    Read: 029282829282928
    Read: 282828000000
    Read: 14140000000405
    Read: 501200002100010
    Read: 00000000000000
    Read: 000000001051770
    Read: 0004010
    Read: FE\x03

Interestingly, while the built-in serial interface always returns the status
response split in the same way (but not split in constant chunks, for example
there are "lines" of 2 and 1 bytes), the FTDI adapter returns the data in
varying chunks. The chunks can also be longer, such that the total number of
read requests for the status response is consistently smaller than the number
of read requests necessary to read the same response using the built-in
serial interface.

Prolific PL2303-based USB to serial adapter on the same Optiplex 5050
communicating with the same Yamaha RX-V2500:

    Write: \x11001\x03
    Read: \x12
    Read: R
    Read: 0
    Read: 1
    Read: 7
    Read: 8
    Read: F
    Read: 8
    Read: B
    Read: @
    Read: E
    Read: 0
    Read: 1
    Read: 9
    Read: 0
    Read: 0
    Read: 0
    Read: 2
    Read: 4
    Read: 0
    Read: 0
    Read: 0
    Read: 5
    Read: 1
    Read: 7
    Read: 4
    Read: 7
    Read: 7
    Read: 3
    Read: 4
    Read: 0
    Read: 3
    Read: 1
    Read: 4
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 2
    Read: 3
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 1
    Read: 0
    Read: 2
    Read: 0
    Read: 0
    Read: 0
    Read: 1
    Read: 0
    Read: 0
    Read: 2
    Read: 9
    Read: 2
    Read: 8
    Read: 2
    Read: 8
    Read: 2
    Read: 9
    Read: 2
    Read: 8
    Read: 2
    Read: 9
    Read: 2
    Read: 8
    Read: 2
    Read: 8
    Read: 2
    Read: 8
    Read: 2
    Read: 8
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 1
    Read: 4
    Read: 1
    Read: 4
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 4
    Read: 0
    Read: 5
    Read: 5
    Read: 0
    Read: 1
    Read: 2
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 2
    Read: 1
    Read: 0
    Read: 0
    Read: 0
    Read: 1
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 1
    Read: 0
    Read: 5
    Read: 1
    Read: 7
    Read: 7
    Read: 0
    Read: 0
    Read: 0
    Read: 0
    Read: 4
    Read: 0
    Read: 1
    Read: 0
    Read: F
    Read: E
    Read: \x03

This USB to serial adapter also behaves correctly (i.e., is not dropping parts
of the data sent by the receiver), but returns the data one byte at a time
requiring many more `read` calls to retrieve responses, especially larger
ones.

Now, you might think that this many `read` calls would take significantly
longer than the much fewer calls that FTDI-based adapters require, but
surprisingly, it actually takes longer to receive the status from the
receiver via an FTDI adapter than via a Prolific adapter. Measuring the
`curl` command to get the status response, it takes 0.92-0.93 seconds via
the FTDI adapter and 0.91-0.92 seconds via the Prolific adapter.

## Serial Interface Identification

If you plan on having multiple serial adapters in a single computer, for
example to control a receiver and an amplifier or to control multiple
receivers, be aware that some USB to serial adapters do not report serial
numbers (at least via `udev`). Among adapters I own, Prolific PL2303-based
ones do not report serial numbers, while FTDI FT232-based ones do.
This means that if a computer has more than one PL2303-based adapter
attached to it, there is no way to know which physical adapter corresponds
to which TTY device.

`udev` rules can match on the manufacturer of the device as well as on
the serial number, if one is provided by the device. For example, I have
the following rules in `/etc/udev/rules.d/91-serial.rules` to map
`/dev/ttySonamp` to the Sonamp amplifer and `/dev/ttyYamaha` to the Yamaha
receiver:

    # FTDI FT232 - Sabrent
    SUBSYSTEM=="tty", ACTION=="add", \
      ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6001", \
      SYMLINK+="ttyYamaha"

    # Prolific PL2303 - Sabrent
    SUBSYSTEM=="tty", ACTION=="add", \
      ATTRS{idVendor}=="067b", ATTRS{idProduct}=="2303", \
      SYMLINK+="ttySonamp"

## Yamaha Volume

For all zones on RX-V1500/RX-V2500, the volume
is adjusted in 0.5 dB increments from -80 dB to 16.5 dB, giving the hex
values the range of 0x27-0xE8.
