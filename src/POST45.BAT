@Echo Off
Del Qmodem.exe
Del Qmodem.ovr
Del Qinstall.exe
TPCX /B Qmodem
if not exist Qmodem.exe goto QmodemFail
TPCX /B Qinstall
if not exist Qinstall.exe goto QinstallFail
attrib -R m:\wc30\virgin45
copy qmodem.exe m:\wc30\virgin45
copy qmodem.ovr m:\wc30\virgin45
pklite -e Qinstall.exe
copy Qinstall.exe m:\wc30\virgin45
copy newtoday m:\wc30\virgin45
copy newtoday l:\wc30\msg\v45.imp
attrib +R m:\wc30\virgin45
Goto Done
:QmodemFail
Echo.
Echo Qmodem Compile Failed!
Goto Done
:QinstallFail
Echo.
Echo Qinstall Compile Failed!
:Done


