# Missing Manufacturer Protocol Documentation

This document tracks Yamaha receiver models that are referenced in the project
but lack protocol specification files in the `protocol/` directory.

## RX-V3900 / RX-Z7 — YNC (Ethernet) / YRSC (RS-232)

These two models share the same protocol. They use YNC for network control
and YRSC for serial control, replacing the "legacy" Yamaha RS-232 protocol
used by all earlier models. The project has the equivalent YNC doc package
for the later Vx73 generation (`protocol/ync/ync-2012/`) but not for the
V3900/Z7 generation.

### Known documents

#### V3900_Z7_Function_Tree_1.0.xls

Function tree spreadsheet with command generator macro. A corrected v1.01
was mentioned on forums but never found publicly.

- Original: `http://www.awe-europe.com/documents/V3900_Z7_Function_Tree_1.0.xls`
- Status: **Dead (404)**
- Wayback: <https://web.archive.org/web/*/http://www.awe-europe.com/documents/V3900_Z7_Function_Tree_1.0.xls>

#### RX-V3900_Z7_ETHERNET_IF_Spec_e_1.0.xls

Ethernet interface specification. Describes the control command communication
method, command format, device numbering, numerical parameters, differences
between models, command receipt timing, and event notification.

- Original: `http://webpix.ca/files/RX-V3900_Z7_ETHERNET_IF_Spec_e_1.0.xls`
- Status: **Dead (timeout)**
- Wayback: <https://web.archive.org/web/*/http://webpix.ca/files/RX-V3900_Z7_ETHERNET_IF_Spec_e_1.0.xls>

#### Crestron RX-Z7 / RX-V3900 Control Module Help

Documents RS-232 setup requirements (RS232C STANDBY = YES, Network Standby ON
on RX-Z7). Written for Crestron integrators.

- Original: `https://applicationmarket.crestron.com/content/Help/Yamaha/yamaha_rx-z7rx-v3900_v2_0_help.pdf`
- Status: **Alive** (PDF, 247 KB)

### Forum threads with protocol details

#### RemoteCentral — Yamaha RX-V3900 RS232 Commands?

Discusses the broken v1.0 macro, references the AWE Europe function tree link.

- URL: <http://www.remotecentral.com/cgi-bin/mboard/rs232-ip/thread.cgi?29>

#### Audioholics — Yamaha RX-V3900 RS232 Serial Commands?

Users shared working YNC-style power commands:
`0,1,*,PUT,Main_Zone(Power_Control(Power=On)),*`
`0,1,*,PUT,Main_Zone(Power_Control(Power=Standby)),*`

- URL: <https://forums.audioholics.com/forums/threads/yamaha-rx-v3900-rs232-serial-commands.94418/>

#### Audioholics — RS232 Serial Control Yamaha RX-V3900 & Z7 problem?

- URL: <https://forums.audioholics.com/forums/threads/rs232-serial-control-yamaha-rx-v3900-z7-problem.78742/>

#### CommandFusion — Controlling Yamaha RX-V3900

References both the function tree and Ethernet IF spec XLS files. Notes
the protocol uses HTTP POST to `/avctrl/ctrl.cgi` with XML payloads.

- URL: <https://groups.google.com/g/commandfusion/c/fo7Oaigcwu4>

#### HARMAN/AMX Forums — yamaha rx-v3900, z7

- URL: <https://proforums.harman.com/amx/discussion/6454/yamaha-rx-v3900-z7>

---

## RX-Z11 / DSP-Z11 — YNC (Ethernet) / YRSC (RS-232)

The RX-Z11 uses the same YRSC/YNC protocol family as the RX-V3900/RX-Z7.
Forum posts confirm "the commands for the Z7 and Z11 are the same."
No protocol specification files exist in the project for this model.

### Known documents

#### Z11 rs control.zip

Attached to the AVS Forum thread below. Contents unknown — likely contains
protocol documentation or command reference.

- Original: attachment on AVS Forum thread (see below)
- Status: **Requires AVS Forum login to download**

#### Yamaha RX-Z11 AMX interface.zip

AMX NetLinx module for the RX-Z11. Also attached to the AVS Forum thread.

- Original: attachment on AVS Forum thread (see below)
- Status: **Requires AVS Forum login to download**

#### RX-Z11 RS232C Protocol document (version 20080310)

Referenced by the RTI Driver Store as the basis for their RX-Z11 driver.
The document itself is not publicly linked.

- RTI driver page: <https://driverstore.rticontrol.com/driver/yamaha-receiver-rx-z11>

### Forum threads with protocol details

#### AVS Forum — RX-Z11/DSP-Z11 RS232 Protocol

The primary community resource. Contains downloadable ZIP files, working
command examples, and checksum calculation details.

Command format: `0,1,LENGTH,PUT,COMMAND,CHECKSUM` followed by CR/LF.
Checksum: take hex sum of bytes from first `0` up to and including the comma
before the checksum field, then convert the low byte to decimal.

Example commands:
- `0,1,47,PUT,Main_Zone(Vol(Lvl(Val=-360,Exp=1,Unit=dB))),15`
- `0,1,27,PUT,Main_Zone(Vol(Mute=On)),135`

- URL: <https://www.avsforum.com/threads/rx-z11-dsp-z11-rs232-protocol.1011766/>

#### HARMAN/AMX Forums — RS232C help please

Notes that Network Standby must be ON for RS-232 to work properly on the
RX-Z11, as confirmed by Yamaha (supplies more power to the RS-232 port).

- URL: <https://proforums.harman.com/amx/discussion/1453/rs232c-help-please>

---

## RX-V3900 / RX-Z7 / RX-Z11 — Yamaha Dealer Site (Historical)

Yamaha historically hosted protocol PDFs and tools on their dealer site.
These pages are long dead but may be captured by the Wayback Machine.

- Original: `http://www.yamaha.com/yec/dealers/dealer_main.htm`
- Wayback: <https://web.archive.org/web/*/http://www.yamaha.com/yec/dealers/dealer_main.htm>

- Original: `http://www.yamaha.com/yec/dealersite/downloads/ds_download.htm`
- Wayback: <https://web.archive.org/web/*/http://www.yamaha.com/yec/dealersite/downloads/ds_download.htm>

- Original: `http://www.yamaha.com/yec/customer/codes/`
- Wayback: <https://web.archive.org/web/*/http://www.yamaha.com/yec/customer/codes/>

---

## Other Missing RS-232 Protocol Specs

These models use the "legacy" Yamaha RS-232 protocol and are documented as
having a serial port, but no protocol specification file exists in `protocol/yamaha/`.

| Model | Year | Notes |
|------------|------|-------|
| RX-V2200 | 2001 | No spec file. Likely shares protocol with RX-V3200. |
| RX-V3300 | 2002 | No spec file. Likely shares protocol with RX-V2300. |
| RX-V3067 | 2010 | Uses YNCA, not legacy RS-232. Covered by RX-A3000 YNCA command list. |
| RX-V2067 | 2010 | Uses YNCA, not legacy RS-232. Covered by RX-A2000 YNCA command list. |
| RX-V1067 | 2010 | Uses YNCA, not legacy RS-232. Covered by RX-A1000 YNCA command list. |
| RX-V1900 | 2009 | Has Standard spec but **missing Extended** spec. |

### HTR models with RS-232 but no dedicated specs

These likely share protocol specs with their RX-V counterparts.

| Model | Year | Probable RX-V equivalent |
|----------|------|--------------------------|
| HTR-5890 | 2004 | RX-V1500 |
| HTR-5990 | 2005 | RX-V1600 |
| HTR-6190 | 2007 | RX-V1800 |
| HTR-6290 | 2009 | RX-V1900 |
| HTR-6295 | 2009 | RX-V1900 |

### YNCA command list coverage

The repo has YNCA command lists for:
- **2010**: RX-A700, RX-A800, RX-A1000, RX-A2000, RX-A3000, RX-V867
- **2011**: RX-A810, RX-A1010, RX-A2010, RX-A3010, RX-V671, RX-V771
- **2012**: RX-A720, RX-A820, RX-A1020, RX-A2020, RX-A3020, RX-V673, RX-V773, HTR-7065
- **Standalone**: RX-A850 (2015), RX-A1040 (2014)

#### Missing YNCA command lists — 2010

| Model | Notes |
|----------|-------|
| RX-V1067 | Likely same commands as RX-A1000 |
| RX-V2067 | Likely same commands as RX-A2000 |
| RX-V3067 | Likely same commands as RX-A3000 |

#### Missing YNCA command lists — 2011

| Model | Notes |
|----------|-------|
| RX-A710 | No RS-232 |
| RX-V871 | |
| RX-V1071 | |
| RX-V2071 | |
| RX-V3071 | |

#### Missing YNCA command lists — 2013

| Model | Notes |
|----------|-------|
| RX-A730 | |
| RX-A830 | |
| RX-A1030 | |
| RX-A2030 | |
| RX-A3030 | |
| RX-V675 | |
| RX-V775 | |
| CX-A5000 | Pre-amplifier/processor |

#### Missing YNCA command lists — 2014

| Model | Notes |
|----------|-------|
| RX-A740 | |
| RX-A840 | |
| RX-A2040 | |
| RX-A3040 | |
| RX-V677 | |
| RX-V777 | |

#### Missing YNCA command lists — 2015

| Model | Notes |
|----------|-------|
| RX-A750 | |
| RX-A1050 | |
| RX-A2050 | |
| RX-A3050 | |
| RX-V679 | |
| RX-V779 | |

#### Missing YNCA command lists — other

| Model | Notes |
|----------|-------|
| RX-V475 | |
| RX-V500D | |
| TSR-5790 | Reportedly uses port 49154 |
| HTR-4065 | |

---

## Additional Resources

### Scribd — Yamaha RS-232 Protocol Overview

Summarizes the Yamaha RS-232 protocol across several models including
synchronous/asynchronous communication models and initialization.

- URL: <https://www.scribd.com/document/460195429/YamahaRS232Notes>

### YNCA Protocol Specification PDF

General YNCA protocol documentation (not model-specific).

- URL: <https://www.sdu.se/pub/yamaha/yamaha-ynca-receivers-protocol.pdf>

### SmartThings Yamaha RX Integration (GitHub)

Supports RX-V2065, RX-V3900, DSP-AX3900, RX-Z7, DSP-Z7 via YNC/XML.

- URL: <https://github.com/KristopherKubicki/device-yamaha-rx>
