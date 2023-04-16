# Receiver & Amplifier Serial Control Ruby Library

## Use Cases

The following are some of the uses of seriamp that I have employed in my
home setup.

### Remote Tone Controls

Yamaha receivers do not provide tone control buttons on their remotes, at least
for the main zone. The protocol includes tone control remote IR codes for
second and third zones (but, surprisingly, not for the main zone), therefore
those should in theory be operable via the remote, but not the main zone.
Normally the only way to adjust main zone tone controls is to walk to the
receiver and operate the front panel knobs/buttons.

The extended RS232C protocol however provides commands to alter tone for the
main zone, and can be used to implement remote tone control functionality.

### Night Mode via High Pass Filter

Yamaha receivers provide commands for changing the speaker type (large/small),
bass output (front main/subwoofer/both) and subwoofer crossover frequency.
In a stereo system without a subwoofer, these commands can be combined to
set up a high pass filter at a particular frequency (40-200 Hz). This
is useful to omit the lowest frequencies at night.

## Set Volume Prior To Turn On

Normally the receivers are not responding to control input when they are in
standby (other than to the power button to turn themselves on).
However both Yamaha and Integra receivers can alter their main zone volume
while they are in standby. This permits having the volume clamped to a
sensible range when the receiver is turned on.

Yamaha receivers permit setting Zone 2 and Zone 3 volumes in standby as well,
whereas Integra (at least DTR-50.4) only permits the main zone volume to
be set in standby.

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
