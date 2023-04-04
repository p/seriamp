# Integra Protocol Implementation Notes

## Documentation

When reading the protocol documentation, you should read the version that
matches the receiver you are operating on. For example, DTR-50.4 was
added in version 1.23; the closest specification I have is 1.24 and this
document contains DTR-50.4 in the compatibility tables, whereas the
newest version 1.46 does not (it has newer receivers instead).

### Volume

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
