# Serial Port / Adapter Hardware Requirements

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

## Adapter & Cable Considerations

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
