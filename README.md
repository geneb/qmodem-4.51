# QModem 4.51 Source Code

The source code release of **QModem 4.51**, an MS-DOS telecommunications program authored by John Friel III (1960–2024). This source snapshot reflects the state of QModem "Test-Drive" edition, version 4.51, as it existed in early 1992. The release is presented in the hope it may prove valuable as a historical artifact, for telecommunications enthusiasts, retrocomputing hobbyists, or anyone interested in the inner workings of a classic DOS comms package.

QModem was a widely-used terminal communications program for MS-DOS, supporting a rich array of modem protocols, scripting, user customization, modem auto-configuration, and even a "Host Mode" for basic BBS-like operation.

---

## Historical Overview

**QModem** was developed throughout the 1980s and early 1990s as a competitor to programs such as Procomm, Telix, and others. It provided robust support for:

- Many modem speeds and hardware types (8250, 16450, 16550 UARTs, and special hardware)
- Internal and external file transfer protocols: XMODEM, YMODEM, ZMODEM, and user-defined protocol support via external drivers
- Full-screen dialing directory (the `.FON` phonebook)
- Extensive scripting and automation via its built-in script language
- In-program configuration via a full-featured setup menu (`Alt-N`)
- ANSI/VT100/TTY/Avatar terminal emulations
- Host Mode: a mini BBS server included in the client!
- Scrollback buffer, split screen terminal
- Mouse support, custom keyboard macros, and more

---

## File Layout and Project Structure

This repository contains the complete Turbo Pascal source code, as well as supporting assembler, batch, and utility files.

### Main Directories and Files

- **.PAS** — Turbo Pascal source files implementing the main program, modules, and utilities
- **.ASM** — x86 assembler routines for performance-critical sections and hardware interfacing
- **.BAT** — DOS batch files for building, testing, and packaging
- **.OBJ, .INC** — Included binaries and Pascal include files
- **.KEY, .FON, .CNF, etc.** — Sample data, key, configuration, or phonebook files

Significant modules include:

- `QMODEM.PAS` — Main entry point
- `QMMAIN.PAS` — Main application logic
- `INITIAL.PAS` — Global configuration, terminal, and comm settings
- `COMM.PAS` / `COMM2.PAS` — Serial communications support
- `DOWNLD*.PAS` / `UPLD*.PAS` — File transfer protocol implementations
- `TP*`, `OP*` — Support code, likely Turbo Professional or custom libraries
- `HOST.PAS` — Host Mode/BBS functionality
- `FONESTUF.PAS`, `QDIAL.PAS`, etc. — Dialing directory and phonebook features
- `SCRIPTS*.PAS` — Script engine and automation
- `INSTALL*.PAS`, `QINSTALL.PAS`, `RUNQINST.PAS` — On-disk configuration and setup utility

---

## Building QModem

**This is a historical codebase.** QModem 4.51 targets MS-DOS using Turbo Pascal 5.x/6.0, with Turbo Professional and potentially other Borland or third-party libraries.

### Potential Build Approaches

- **Turbo Pascal 5.5/6.0** (MS-DOS or DOSBox): This is almost certainly the original toolchain. If you have a copy, opening `QMODEM.PAS` as the project and compiling (after possibly setting appropriate memory and overlay paths) may work. Some makefiles or batch files, e.g. `BUILD.BAT`, may be helpful, but will need adaptation to your environment.

- **TP/BP Emulation or Cross-Compilers**: [Free Pascal](https://www.freepascal.org/) includes some support for Turbo Pascal compatibility, but differences are likely extensive (including use of inline assembler, overlays, and third-party libraries).

- **Turbo Professional & Dependencies**: Many of the `TP*` units (e.g. `TpDos`, `TpCrt`, etc.) are from the [Turbo Professional library](https://en.wikipedia.org/wiki/Turbo_Professional). You'll need the corresponding TPUs and sources for your compiler version.

- **Manual Assembly of .ASM Files**: Assembler files need to be assembled (e.g. with TURBO assembler or MASM) and linked or compiled as .OBJ for use with Turbo Pascal.

- **Overlay Management**: Note the project extensively uses Borland/Turbo Pascal overlays (`.OVR` files, see `OVR01.INC` and overlay units). Disk layout and path settings for overlays must be matched as the original program expects.

#### Build Scripts

Several build-automation batch files are included, such as:

- `BUILD.BAT`
- `BUILDOVR.BAT`
- `BUG.BAT`
- `DEBUGOVR.BAT`

Inspect and adapt these scripts as necessary for your own environment.

### Modernization Caveats

- **No supported modern environment** targets this code directly. Efforts to port or run on anything but MS-DOS/Turbo Pascal 5.x/6.x are purely experimental and will require code and/or dependency adaptation.
- **Third-party libraries** (Turbo Professional, OpKey, possibly others) are required.
- **Hardware-dependence**: Much code assumes direct access to PC hardware, BIOS, and serial port interrupts.
- **Overlay management**: The overlay system (`OVERLAY.PAS`, etc.) must be supported as originally intended.

---

## Usage

This repository is for study, education, restoration, and historical curiosity. See the original QModem documentation (not included here) for user guidance. The commands, batch files, and source code reflect MS-DOS conventions and expectations.

---

**John Friel III, 1960–2024**
