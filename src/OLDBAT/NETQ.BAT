NetDev
NetDev /Open > nul
If Errorlevel 1 goto No_Modem
Qmodem /Cross14
NetDev /Close > nul
:No_Modem
NetDev /Disable > nul
