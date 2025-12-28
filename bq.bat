@echo off
REM SUBST U: C:\LANG\BP\UNITS
REM MOUNT U: C:\LANG\BP\UNITS
CD SRC
SET MAINDIR=U:
SET TPUDIR=%MAINDIR%\TPRO;%MAINDIR%\OPRO;%MAINDIR%\APRO\SRC
SET TPUDIR=%TPUDIR%
SET INCDIR=%TPUDIR%
SET OBJDIR=%TPUDIR%;%MAINDIR%\OPROOBJ
REM This command line will re-compile the TurboPower code as well as Qmodem.
REM BPC QMODEM -B -$O+ -$F+ -U%TPUDIR% -O%OBJDIR% -I%INCDIR% -DOVR;PRODUCTION
REM This command line will "make" the code base, compiling only those things that have changed
REM since the last compile.
BPC QMODEM -M -$O+ -$F+ -U%TPUDIR% -O%OBJDIR% -I%INCDIR% -DOVR;PRODUCTION
CD ..
