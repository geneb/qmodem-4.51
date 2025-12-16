@Echo Off
Echo Insert a 3.5 inch Disk1 to be Zapped for 4.3
Echo >Con
Pause
@If exist b:\qinstall.exe Echo ----
@If exist b:\qinstall.exe Echo Copying...
@If exist b:\qinstall.exe Echo ----
@If exist b:\qinstall.exe copy f:\qinstall.exe b:\

zap
