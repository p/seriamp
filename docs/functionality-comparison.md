
# Functionality Comparison

- *Subwoofer crossover frequency*: settable in Yamaha receivers, not settable
in Onkyo/Integra receivers.
- *Speaker configuration (small/large)*: settable in Yamaha receivers, not
settable in Onkyo/Integra receivers.
- *Bass destination (front speakers/subwoofer)*: settable in Yamaha receivers,
not settable in Onkyo/Integra receivers.
- *Volume*: main zone volume is settable in Yamaha and Onkyo/Integra receivers
while the receiver is in standby.

## Yamaha Receiver Notes

### RX-V1*00 / HTR-**90 RS-232 Support

The 1000 level receivers, and the HTR receivers that are roughly equivalent
to the 1000 series RX-V receivers, have alternated with having and not
having a serial port on them. The following models have the serial port:

- RX-V1000, RX-V1500, RX-V1600, RX-V1700, RX-V1800, RX-V1900
- HTR-5890, HTR-5990, HTR-6190, HTR-6290

The following models are missing the serial port:

- RX-V1200, RX-V1300, RX-V1400
- HTR-5490, HTR-5590, HTR-5790, HTR-6090

It's strange how the port disappears and reappears on these models from
one year to the next.

### RX-V2500

This model provides "parametric EQ", as opposed to the "graphic EQ" on
RX-V1500. Pparametric EQ permits moving the bands, however the
lowest band cannot go below 150 Hz and the highest band cannot go above 13 kHz,
and also change the Q of each band.
Parametric EQ is only displayed on the attached TV; whereas in RX-V1500
setup menu there is an option for graphic EQ, in the RX-V2500 setup menu
that is displayed on the front panel of the receiver there is no equalizer
option at all, and this setting is only available via the GUI.

For RX-V2500, the parametric EQ is not adjustable via RS-232.
This is remedied in RX-V2600 and newer models.

### RX-V2700

This model cannot be controlled from the network. It does not implement YNC
or YNCA protocols, and does not have a web server.
Programmatic configuration can only be performed via RS-232.

### RX-V3800

I expect that just like RX-V2700, this model cannot be controlled via the
network. RX-V3900 introduced YNC and YRSC protocols, these are not implemented
in RX-V3800.

### RX-V3900

This model implements YNC and YRSC protocols. It also no longer implements
the "legacy" Yamaha RS-232 protocol that all other pre-2010 receivers with
a serial port support.

The YRSC protocol, unlike the legacy RS-232 protocol, does not appear to
have any provision to notify the controller of state changes in the
receiver (e.g., volume being altered). Such a notification mechanism
exists in the YNC protocol, but an RX-V3900 receiver with a working RS-232
port and a broken network port has no way to notify controller of state
changes.

### Power Ratings & Transformers

Every 1000 through 4000 level receiver, from RX-V1000 through RX-V3900,
claims on the back of it to consume "500 watts" of power. At the same time
output ratings have climbed steadily, from 110 watts/channel in RX-V1000
to 140 watts/channel in RX-V3900. I don't know how accurate either the
output power or the power consumption ratings are, but the different models
are using different transformers, and visually transformer in RX-V3900
appears to be larger than the one in RX-V1500.
