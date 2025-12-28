# Conditional Compilation

The Qmodem source code has a number of conditional compilation directives `IFDEF` and `IFNDEF` that control what features or "modules" are included when Qmodem is compiled.  I'll try to document them here as best I can - mostly by using context clues with surrounding code, so don't take it as 100% gospel.

## Basic
Enables support for the /INT14 command line switch.

This appears in conjunction with `Plus`, `Cross`, and `JNL` and are encapsulated by `INT14`, so I think they're meant to be exclusive conditional directives and not mixed & matched.

---
## BETA
Changes the version # string.

---
## Bundle
Changes the version # string and if defined, will disable all features and output text related to registration or purchase.

---
## Cross
Seems to be related to `Int14`.

Enables support for the /CROSS14 command line switch.

This appears in conjunction with `Basic`, `Plus`, and `JNL` and are encapsulated by `INT14`, so I think they're meant to be exclusive conditional directives and not mixed & matched.

## GG
Appears to restrict Qmodem functionality.  Limits the number of transfer protcols to ASCII and XMODEM.  It also limits the available terminal emulations to TTY, ANSI, and AVATAR.  It also restricts the # of phone book entries to 20 and other limitations.

---
## ISI
Enables support for the ISI multi-port serial board made by MultiTech.

Enables support for the /ISI command line switch, accepts port #, 1-8. (ex. /ISI4)
---

## Int14
Enables support for INT 14 BIOS calls to support serial port access.

If this is defined, one of `Basic`, `Plus`, `Cross`, or `JNL` must also be declared, or compilation will fail.

This also changes the version # identification string.

---
## JNL 
Enables support for the /JNL14 command line switch.

Links the CHECKRIM.OBJ during compilation.

This appears in conjunction with `Basic`, `Plus`, and `Cross` and are encapsulated by `INT14`, so I think they're meant to be exclusive conditional directives and not mixed & matched.

---
## Net
Enables "network" features, but appears to be preliminary.

---
## OVR
Enables special unit includes if Qmodem is compiled with Turbo Pascal Overlays - This should always be defined.

---
## PLUS
Enables support for the /PLUS14 command line switch.

This appears in conjunction with `Basic`, `Cross`, and `JNL` and are encapsulated by `INT14`, so I think they're meant to be exclusive conditional directives and not mixed & matched.

---
## Production
Modifies the version # string and if `Bundle` is not defined, will enable the /REGISTER command line switch.  This is defined by the build batch file.

---
## QLINK
This may enable Q-Link (QuantumLink) support, but I'm not sure.  It does bear further investigation however.

---
## Yakcom & RElink
Appears to allow Qmodem to be branded as a different product.  If declared, the compiler will attempt to include yak\YAKCOM.INC in CONSTANT.PAS.  If RElink is declared, the compiler will attempt to include relink\RELINK.INC.  Note that neither include file was supplied with the source code release.  If neither Yakcom or RElink are declared, QMODEM.INC will be included by default.

---
## UseMouse
Enables mouse support via the Turbo Professional TpMouse unit.

---