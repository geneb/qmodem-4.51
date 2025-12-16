@Echo off
DEL QMODEM.EXE
DEL QMODEM.OVR
TPC QMODEM /B /$O+ /$F+ /DOVR;%1
IF not exist QMODEM.EXE goto Bad
IF not exist QMODEM.OVR goto Bad
Echo Freshening BETA.ZIP...
PKZIP -f N:\BETA\BETA QMODEM.EXE QMODEM.OVR Newtoday
COPY NEWTODAY L:\PCB\BETA\NEWS
Goto Done
:Bad
Echo _
Echo Build BATCH Aborted.
goto quit
:Done
Echo Build BATCH ended successfully.
:Quit
