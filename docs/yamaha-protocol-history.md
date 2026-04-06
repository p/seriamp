# Yamaha Control Protocol History

## Protocol Timeline

### Legacy RS-232 (2000-2009)

- Transport: Serial only (RS-232, 9600/8/N/1)
- Hardware: RX-V1000 through RX-V2065, RX-Z1, RX-Z9, and corresponding
  HTR models with serial ports
- Format: STX/ETX framed ASCII commands
- One of two protocol variants: "Standard" (basic remote control commands)
  and "Extended" (deeper configuration like EQ, speaker setup, etc.)
- Seriamp module: `yamaha`

### YNC / YRSC (2008-2009)

- Transport: HTTP + XML (YNC, network) / RS-232 (YRSC, serial)
- Hardware: RX-V3900, RX-Z7, RX-Z11 (only ~4 models total)
- Format: XML commands like `Main_Zone(Power_Control(Power=On))` with
  length field and decimal checksum
- Transitional protocol between legacy RS-232 and YNCA
- These models do NOT support the legacy RS-232 protocol
- RX-V2065 implements YNC over network but uses legacy RS-232 on serial
- Seriamp: not implemented

### YNCA — Yamaha Network Control Application (2010-~2017)

- Described as "an aliased and simplified form of YNC" — simple text
  commands instead of YNC's verbose XML
- Transport: RS-232 or TCP port 50000
- Hardware: RX-A*00 through RX-A*50 (Aventage), RX-V867 through RX-V779,
  and corresponding HTR/TSR models
- Format: Simple text commands like `@MAIN:VOL=-30.0\r\n`
- Only one connection at a time; feedback requires holding the connection open
- Also defined for serial port on higher-end models that have one
- Default network port: 50000
- Seriamp module: `ynca`

### YXC — Yamaha Extended Control (~2015-present)

- Transport: HTTP REST API on port 80
- Hardware: All MusicCast-branded devices (receivers, soundbars,
  wireless speakers, etc.)
- Format: `http://device/YamahaExtendedControl/v1/group/command`
- No authentication
- Current spec: v2.00 (~2018), no successor announced
- "MusicCast" is the consumer branding; YXC is the protocol
- Seriamp: not implemented

## Equalizer Access by Protocol

Each successive protocol has exposed less EQ control than the one before.

| Protocol | EQ type | Bands | Frequency | Q | Gain | Per-channel |
|----------|---------|-------|-----------|---|------|-------------|
| Legacy RS-232 Extended | GEQ | 7 | Fixed | No | Yes | Yes |
| Legacy RS-232 Extended | PEQ | 7 | 25 choices | Yes | Yes | Yes |
| YNC/YRSC | Unknown | | | | | |
| YNCA | Tone only | 2 (bass/treble) | No | No | Yes | No |
| YXC | 3-band EQ | 3 (low/mid/high) | No | No | Yes | No |

- Legacy RS-232 Extended: Full per-channel graphic EQ (7 bands, fixed
  frequencies, gain only) on models like RX-V1500/RX-V1800. Full parametric
  EQ (7 bands, selectable frequency from 25 options, adjustable Q, adjustable
  gain, per-channel) on models like RX-V2700. RX-V2500 has PEQ hardware but
  it is not accessible via RS-232 (GUI only).
- YNCA: Only exposes bass/treble tone controls (`@MAIN:TONEBASS`,
  `@MAIN:TONETREBLE`), range +-6.0 dB in 0.5 dB steps.
- YXC: `setEqualizer` API with mode, low, mid, high parameters. Gain only,
  no frequency or Q control. Slightly better than YNCA but far less capable
  than legacy RS-232 Extended.
- The receivers themselves still have full PEQ internally (used by YPAO
  auto-calibration), but the network protocols do not expose it.
- PEQ via RS-232 is a 2000+ series feature only (RX-V2600 probably,
  RX-V2700 confirmed). The 1000-series has GEQ only. RX-V2500 has PEQ
  but does not expose it over serial.

## Speaker Distance / Delay

| Protocol | Read | Write |
|----------|------|-------|
| Legacy RS-232 Extended | Yes | Yes |
| YNC/YRSC | Unknown | Unknown |
| YNCA | No | No |
| YXC | No | No |

The YXC spec has a `speaker_settings` field in `getFeatures` but it is
marked "Reserved" — Yamaha considered exposing speaker configuration via
YXC but did not. Speaker distance is only adjustable via the on-screen
menu, the web setup UI, or YPAO auto-calibration.

## Web Setup UI

Modern Yamaha receivers (MusicCast era) have a built-in web interface at
`http://<receiver-ip>/Setup/` that is separate from both the YXC API and
the AV Setup Guide mobile app.

This web UI provides full read-write access to:
- Parametric EQ: 7 bands per speaker, 4 per subwoofer
  - Frequency: 1/3 octave increments, 15.6 Hz to 16 kHz (newest firmware)
  - Gain: -20 to +6 dB in 0.5 dB steps
  - Q: 0.5 to 10
- Speaker distance/delay per channel
- Speaker levels
- YPAO PEQ Data Copy (copy auto-calibration results to manual for editing)
- DSP parameters

This is a human-facing web page, not a programmatic API. It is not
documented in the YXC spec. The actual receiver hardware has gotten more
capable over time (more EQ bands, lower frequency range, finer resolution),
but the documented control APIs (YNCA, YXC) do not expose these features.

## Receiver Manager

Yamaha's official Windows tool for reading/writing full receiver
configuration over RS-232. Distributed per-model (e.g. `RcvMgr2700`).
Removed from Yamaha's website.

Features:
- Upload/download entire receiver configuration including YPAO PEQ data
- Save/restore as files (text format, XML for RX-V3900)
- Access to parameters not available in on-screen menus
- Slow: 5-10 minutes over 9600 baud

Known versions for: RX-V1700, RX-V1800, RX-V1900, RX-V2600, RX-V2700,
RX-V3800, RX-V3900, RX-V1067/2067/3067, RX-Z7, RX-Z11.

Modern replacement: AV Setup Guide mobile app (far less capable, no PEQ).

## Overlap and Compatibility Notes

- Pre-2010 receivers with both serial and network ports (RX-V2700, RX-V3800)
  use legacy RS-232 only — they do NOT implement YNC or YNCA over network.
- RX-V3900 introduced YNC/YRSC and dropped legacy RS-232 entirely.
- The 2010 generation (Vx067, Aventage x000) was the first to use YNCA.
- ~2015-2017 was a transition from YNCA to YXC (MusicCast). It is claimed
  that MusicCast receivers do not support YNCA, but this is unverified.
- Some models in the transition period may support both protocols.

## Protocol Specs in This Repository

- Legacy RS-232: `protocol/yamaha/` — PDFs and XLS for ~20 models
- YNC/YRSC: `protocol/ync/` — overview docs, Vx73 function tree and
  Ethernet IF spec, command samples
- YNCA: `protocol/ynca/` — command lists for 2010-2012 models (text + HTML),
  standalone files for RX-A850 and RX-A1040, protocol spec PDF
- YXC: `protocol/yxc/` — API spec PDFs (basic v1.00/1.10/2.00,
  advanced v1.00/2.00)
