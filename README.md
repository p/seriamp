# Receiver & Amplifier Serial Control Ruby Library

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
