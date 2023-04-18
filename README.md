# Receiver & Amplifier Serial & Network Control Toolkit

Seriamp is a Ruby library plus a collection of utilities and daemons to
control a variety of receivers and amplifiers via serial connection (RS-232)
or network (Ethernet/IP). The primary targets of Seriamp are Yamaha
RS-232C-capable receivers and Sonance Sonamp 875D SE/Mk2 amplifiers, as
those are the models I primarily use, but some code is written for
Yamaha YNCA protocol (usable over both RS-232C and Ethernet) and
Onkyo/Integra/post-2014 Pioneer Elite receivers (which all use the
Integra protocol). While not currently implemented, Seriamp should be
straightforwardly extendable to support Denon and Marantz receivers, and
perhaps with a bit more work the Harman/Kardon ones.

Seriamp features:

- Replaceable low level communication backends (for example,
to support multiple serial port communication libraries in Ruby).
- A command-line tool and a web application for each supported device.
The web application supports optional locking to prevent concurrent use
of the device from multiple clients, which the hardware generally does not
support.
- Command-line tools can route command execution through the respective
web applications.
- Modular architecture that supports multiple protocols/device manufacturers.

## Use Cases

The simplest use case of Seriamp is control of basic functionality of the
supported hardware from a computer - for example, turning the hardware on
and off, and adjusting volume.

The following are some uses of Seriamp that are either less obvious or that
cannot be performed using other control methods (i.e. OEM remote control or
front panel buttons/knobs) that I have employed in my home setup.

### Setup Receivers

Yamaha for some reason likes to change the IR codes for the setup button
and menu navigation buttons rather frequently, and does not place the
equivalent buttons on the front panel of their receivers. This means that
in order to configure their receivers from year 2000 onward, you generally
must have the correct remote for that receiver. The higher tier receivers
in particular can be difficult to get those correct remotes for, since
there may be relatively few units manufactured that use a particular set of
remote codes.

By sending the IR remote codes via Seriamp it is possible, theoretically,
to configure all of these receivers without having the correct remote control.

I succeeded with controlling RX-V1500 in this way but RX-V1800 is ignoring
the commands I've attempted so far.

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

### Set Volume Prior To Turn On

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
