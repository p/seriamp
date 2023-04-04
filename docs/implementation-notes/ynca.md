# Yamaha YNCA Protocol Implementation Notes

## YNCA Remote Codes

I thought that the YNCA remote code feature (`@SYS:REMOTECODE=xxxxxxxx`)
would permit sending what the Yamaha serial protocol calls "remote commands",
but this appears to not be the case: the serial protocol remote commands are
4 characters long and the remote codes expected by YNCA are 8 characters long.
I have been unable to locate any codes that would work.

## YNCA Volume

The parser for volume level, at least in the RX-A710 that I tested with,
is absolutely braindamaged. Witness the following table of the input and
the receiver's interpretation of it:

| Command         | Response        |
| --------------- | --------------- |
| @MAIN:VOL=-80.0 | @MAIN:VOL=-80.0 |
| @MAIN:VOL=-80.  | @MAIN:VOL=-8.0  |
| @MAIN:VOL=-80   | @MAIN:VOL=-8.0  |
| @MAIN:VOL=-8    | @UNDEFINED      |
| @MAIN:VOL=-11.1 | @UNDEFINED      |
| @MAIN:VOL=-11.0 | @MAIN:VOL=-11.0 |
| @MAIN:VOL=-11   | @UNDEFINED      |
| @MAIN:VOL=-10   | @MAIN:VOL=-1.0  |
| @MAIN:VOL=+10   | @UNDEFINED      |
| @MAIN:VOL=.10   | @MAIN:VOL=1.0   |
| @MAIN:VOL=.1    | @UNDEFINED      |

You can see that instead of a normal numeric parser it assumes that the
input is in a particular format (floating-point value with a decimal separator)
and only bothers looking for specific values in specific positions.
Having the volume set to -8 dB when -80 dB was intended can not only fry
speakers in a hurry but also cause hearing damage. Well done, Yamaha.

Seriamp attempts to format the volume values in the protocol layer to guard
against the receiver exploding equipment and ears.
