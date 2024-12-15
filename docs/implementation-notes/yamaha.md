# Yamaha Protocol Implementation Notes

## Serial Protocol

In order for the receiver to respond, the RTS bit must be set on the wire.
Setting this bit requires a 5-wire cable. I have some RS232 to 3.5 mm cables
which aren't usable with Yamahas.

Linux appears to automatically set the RTS bit upon opening the serial port,
thus setting it explicitly may not be needed.

To monitor serial communications under Linux, I used
[slsnif](https://github.com/aeruder/slsnif) which I found via
[this summary of serial port monitoring tools](https://serverfault.com/questions/112957/sniff-serial-port-on-linux).

## RS232 vs RS232C

The RS232 standard has had several revisions, the most recent one being
RS232C. Thus, technically, the standard is in fact called "RS232C",
but practically the "C" can be omitted because any equipment that speaks
RS232 would be speaking RS232C.

Seriamp omits the "C" for brevity and always uses "RS232" to refer to the
protocol.

## Yamaha Timeout

The manual specifies that commands should be responded to in 500 ms and to
retry after this timeout elapsed. However in my environment (RX-V1500/1800/2500)
the status command takes 850 ms to complete, thus the timeout must be set to
at least one second.

## Yamaha Status in Standby

The receiver is very frequently not responding to the "ready" command.
The documentation mentions retrying this command but in my experience the
first time this command is sent to a RX-V1500 which is in standby it is
*always* igored.

Documentation for Onkyo/Pioneer receivers provides an explanation for
this behavior: when the receiver is in standby mode and it receives serial
communication, the transmission wakes up the CPU but is not processed.
The next transmission, received after a small delay, will be processed by
the now running CPU.

## Commands in Standby

Some or all commands, when receiver is in standby, respond with a NULL byte
("\0") as the response. Meaning, the command does in fact receive a response,
meaning this response (at least in theory) could be handled and command
retried (or status checked) immediately without waiting for the timeout to
expire.

## Yamaha Volume in Standby

Yamaha receivers I have (RX-V1500, RX-V2500, RX-V1800)
respond to volume changes while in standby. While the volume knob is
doing nothing while in standby, sending volume commands via RS232 does
alter the volume when the receiver is subsequently turned on.
As far as I can tell this behavior is not documented.

Some of the other parameters are not changeable in standby - for example,
input name and pure direct setting.

## Volume Increments

For all zones on RX-V1500/RX-V2500, the volume
is adjusted in 0.5 dB increments from -80 dB to 16.5 dB, giving the hex
values the range of 0x27-0xE8.

## Volume Up & Down

When RX-V1500 receiver volume up/down commands over serial, these are
interpreted the same way as remote volume up/down buttons, namely:
the first command displays the current volume on the front panel while
making no change to the level, the second and subsequent commands (in a short
interval) actually change the volume. This behavior is obviously
problematic when the receiver is controlled by multiple clients
simultaneously. RX-V1700 and newer changes the volume level with every up/down
remote command received over the serial port.

Higher level models (RX-V2x00/RX-V3x00) mirror the behavor of RX-V1x00 of the
same generation.

## Custom OSD Message

RX-V1500 shows this message on the front panel.

RX-V2700 does not show this message on the front panel. If the receiver
is in pure direct mode, the front panel momentarily turns on but it
lacks any message output on the main 2 lines (which is a condition that is
not attainable via remote control/front panel operations).
When pure direct is off, nothing appears to happen on the front panel.

## Python Buffering

While testing with Python, I ran into [this issue](https://bugs.python.org/issue20074) -
to open a TTY in Python, buffering must be disabled.

## Lack of Value

Some fields have a value of "---" returned by the receiver, presumably to
indicate a lack of value in that position (for example, bit rate for
analog input). Seriamp returns such values as `nil`.

## Input Rename

Seriamp uses the term "label" to refer to user-provided input name,
because the receiver continues to refer to its inputs by their canonical
names throughout the API responses and the only place where the user-supplied
label even shows up is just in the operation to retrieve this label.

## Commands in Pure Direct Mode

Some commands, for example selecting a DSP program, are not applicable in
Pure Direct mode. When Pure Direct mode is enabled, these commands are
accepted by the receiver but are ignored and do not produce a response.

## RX-V1500 Graphic Equalizer

The RX-V1500 extended protocol specification states that "channel EQ"
(which is the graphics equalizer) has 13 bands.
In reality, RX-V1500 only recognizes 7 bands (63, 160, 400, 1000,
2500, 6300, 16000 Hz - every other frequency listed in the protocol
specification is not recognized).

As such, RX-V1500 does not have a more powerful equalizer than the later
RX-V1xxx models.

RX-V2500 has a parametric equalizer that is not accessible at all via
the RS232 protocol, thus I don't know what hardware those other bands
would actually be implemented by. Perhaps this functionality was
implemented in RX-V2400 or some earlier 2000 or higher level model
before parametric equalizer was added?

## RX-V1500 and Older Sleep Status

Protocol documentation states that for RX-V1500 and older receivers, the
status returns sleep values as 0, 2, 3, 4, 5 instead of 0, 1, 2, 3, 4 as in
newer receivers. This seems to be a documentation bug (or perhaps some older
receivers did in fact skip 1, but RX-V1500 does not). At least on RX-V1500
the status response appears to be identical to the one on RX-V1700.

## Naming Deviations

- "format" in the status output (e.g. PCM) is called "audio format" in seriamp
because bare "format" often means output format of text, etc.
