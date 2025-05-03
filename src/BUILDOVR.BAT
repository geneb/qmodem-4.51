@Echo Off
DEL QMODEM.EXE > NUL
DEL QMODEM.OVR > NUL
TPC Qmodem %1 %2 %3 %4 %5 /$O+ /$F+
If not exist Qmodem.EXE goto Bad
If not exist Qmodem.OVR goto Bad
goto done
:Bad
Echo _
Echo Build BATCH Aborted.
goto quit
:Done
Echo Build BATCH ended successfully.
:Quit
