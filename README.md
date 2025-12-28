# Dedication
I had corresponded with John via his BBS off and on, discussing QModem and BBS software in general.  I was very much looking forward to the QModem source release and was deeply saddened to hear of his sudden death.  I was pleasantly surprised when I heard Aaron had done the source release for QModem some 8 months ago.  I figured the least I could do to honor John's memory was to ensure that it was as easy as possible for anyone to build QModem without any issues.

I dusted off my very rusty Turbo Pascal skills and got to work - the results of that effort are now occupying this repository along with the three other repos that contain the dependencies required to build QModem.

The information that follows is a mix of Aaron's original README.md file and the hack and slash job I performed when adding information about the changes made.  You can find the original source code repo here: [https://github.com/AaronFriel/qmodem-4.51](https://github.com/AaronFriel/qmodem-4.51)

Please report any bugs, etc. related to my work on this repo and not the original QModem repository.

Gene Buckle, December 28th 2025

---

## QModem 4.51 Source Code

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

**[Updated 27Dec25]**<br>
This fork of QModem has been updated to correctly build with either Turbo Pascal 7.0 or Borland Pascal 7.0.  Ensure that your version is patched for the CRT Runtime Error 200 issue.  Turbo Assembler is required to assemble the .ASM files.

Please review the notes in **FIXES.md**.  That document outlines the additional libraries that are required to build QModem, including github links to where they can be obtained.  The remainder of the document outlines what changes were made in order to allow it to compile with Turbo Pascal 7.0

There are two batch files included, `BQ.BAT` and `BQI.BAT`.  They build QModem and the QModem Install program, respectively.  There are notes in each regarding how they're used.  If you're building under DOSBox, you'll need the Z:\SYSTEM directory in your path in order to use the SUBST and/or MOUNT commands.

A new makefile has been created in order to smoothly build the assembly language files - it's called `objcode.mak`.  Examine that file to see how it's used.  The object files that the makefile create are required by both of the build batch files.

The following changes to the structure of the repository have been made:<br>
* The DIST directory contains the original 1992 shareware release of QModem 4.51TD.  It includes documentation and other miscellaneous files used by QModem.  I figured this would be a nice addition to the source code release.
* The SRC\NOSRC directory contains object files that have no matching source code.
* The SRC\OLDBAT directory contains batch files that are no longer used.
* The SRC\OLDOPRO directory contains Object Professional code originally supplied in the source release, but are no longer used.
* The SRC\OLDTPRO directory contains Turbo Professional code originally supplied in the source release, but are no longer used.  Note that the TPMENU.PAS unit in this directory IS used, but is referenced as TPMENU0.PAS.
* The SRC\SCREENS directory contains object files that represent the QModem and QINSTALL.  How these were created is unknown.
* The SRC\TOOLS directory contains code not part of QModem or QINSTALL.  See **TOOLS.md** for a list of these programs and their description.

The file **DEFINES.md** cover all the different conditional compilation options that have been found, as well as a general description of each one.  The only things that must be defined are **OVR** and **PRODUCTION**.  Both of those are defined in the BQ and BQI batch files.


---
## Usage

This repository is for study, education, restoration, and historical curiosity. See the original QModem documentation (not included here) for user guidance. The commands, batch files, and source code reflect MS-DOS conventions and expectations.

---

**John Friel III, 1960–2024**
