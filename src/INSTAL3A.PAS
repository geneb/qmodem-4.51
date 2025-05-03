Unit Instal3a;
{See INSTALL.PAS for the High Last used number}

Interface


Uses TpCrt,
     TpMenu,
     Initial,
     Procs,
     Constant;

Procedure BuildPart1;


Implementation

   Procedure BuildPart1;
   Const
      Frame1 : FrameArray = LotusFrame;
      Frame2 : FrameArray = 'ÕÔ¸¾Í³';
      Movement_MSG   = ' Alter the screen color for this area ';
      Select_a       = ' Select a ';
      Shade_of_Color = ' shade of colors';
      Change_the_Default = ' Change the default ';
      Special_Chars  = '  "^~"=.5 second delay, "^M"=ENTER key';

      Possible_Error = ' Message(s) from modem when failing a connect';
      Base_Port      = ' Base Port address (in HEX)';
      IRQ_msg        = ' Interrupt Request (in HEX)';
   Begin
      SubMenu(1, 1, ScreenHeight, Horizontal, Frame2, qq.Qcolor1, ' Setup Menu for '+Config_Version_Const+' ');

         MenuItem(' Video ', 1, 2, 83, ' Change the way '+_Qmodem_+' looks to you');
         SubMenu(2, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');

            MenuItem('Custom colors '  , 1, 1,82 , ' Choose your own color combinations');
            MenuItem('Blue shades'      , 2, 1,221,   Select_a + 'Blue' + Shade_of_Color);
            MenuItem('Purple shades'    , 3, 1,222,   Select_a + 'Purple' + Shade_of_Color);
            MenuItem('Red shades'       , 4, 1,223,   Select_a + 'Red' + Shade_of_Color);
            MenuItem('Monochrome shades', 5, 1,224, ' Use with a Monochrome display');
            MenuItem('LCD Laptop shades', 6, 1,225, ' Use with an LCD Laptop display');
            MenuItem('Toggles '        , 7, 1,85 , ' Video related Toggles');
            SubMenu (5, 11, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(26);
               MenuItem('BIOS video'       , 1, 1,369, ' When ON, BIOS is used.  When OFF, direct screen writes are used');
               MenuItem('Linefeed after CR', 2, 1,372, ' Auto Linefeed toggle');
               MenuItem('Snow checking'    , 3, 1,379, ' Snow checking');
               MenuItem('Growing windows'  , 4, 1,380, ' Growing Windows');
               MenuItem('STatus line'      , 5, 2,381, ' Show the Status line in Terminal mode');
               MenuItem('Destructive bksp' , 6, 1,384, ' When ON, Backspace (^H) will erase, OFF and cursor just moves');
               MenuItem('LIne Wrap'        , 7, 2,385,
                        ' When ON, cursor wraps to next line, OFF stays in Right Col. until CR/LF');
               MenuItem('Video Restore'    , 8, 1,393, ' Enables or disables restoring the Video mode on exit');
               MenuItem('Jump Scroll'      , 9, 1,432, ' When ON, uses BIOS Scroll routines.  OFF uses internal routines');
               {$IFDEF UseMouse}
               MenuItem('Mouse Enable'     ,10, 1,424, ' Enables or disables Using the Mouse (if installed)');
               {$ENDIF}
               MenuItem('Emulation'        ,10, 1,412, ' Change the default Terminal Emulation');
               MenuItem('Strict Color'     ,11, 8,455,
                        ' When ON, ANSI & VT100 resets "white on black".  OFF resets chosen colors');
               PopSubLevel;
            PopSubLevel;

         MenuItem(' Modem ', 10, 2, 78, ' Change the Hardware settings');
         SubMenu(6, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');

            MenuItem('Communication Parameters ', 1, 1,77, ' Change Hardware communications parameters');
            SubMenu(10, 5, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(51);
               MenuItem('A - Default baud rate', 1, 1,228, Change_the_Default + 'Baud rate');
               MenuItem('B - Default data bits', 2, 1,229, Change_the_Default + 'Data bits');
               MenuItem('C - Default parity'   , 3, 1,230, Change_the_Default + 'Parity');
               MenuItem('D - Default stop bits', 4, 1,231, Change_the_Default + 'Stop bits');
               MenuItem('E - Command before baud change', 5,1,232,
                           ' Command(s) sent BEFORE Baud rate change.' + Special_Chars);
               MenuItem('F - Command after baud change', 6, 1,233,
                           ' Command(s) sent AFTER Baud rate change.' + Special_Chars);
               MenuItem('G - Cycle delay', 7, 1,234, ' The delay (in seconds) between each call');
               MenuItem('H - Timeout delay', 8, 1,235, ' The delay (in seconds) before cancelling the call');
               MenuItem('I - Modem command delay', 9, 1,236,
                           ' The delay (in milliseconds) between character transmitted while Offline');
               MenuItem('J - Serial port', 10, 1,237, ' The COM port to use');
               MenuItem('K - Script SEND PACE= delay', 11, 1,454,
                           ' If non-zero, a " PACE=xxxx" is added to each SEND command during QuickLearn');
               PopSubLevel;

            MenuItem('Modem Commands ', 2, 1,76, ' Change modem Result Codes');
            SubMenu(10, 6, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(54);
               MenuItem('Initialization Command', 1,1,239, ' Command to initialize modem.' + Special_Chars);
               MenuItem('Prefix Dial Command', 2, 1,240, ' Command that begins the dial command.  "^~"=.5 second delay');
               MenuItem('Suffix Dial Command', 3, 1,241, ' Command that ends the dial command.' + Special_Chars);
               MenuItem('Connect Message', 4, 1,242, ' Message from modem after connecting');
               MenuItem('1st Error Message', 5, 1,243, Possible_Error);
               MenuItem('2nd Error Message', 6, 1,244, Possible_Error);
               MenuItem('3rd Error Message', 7, 1,245, Possible_Error);
               MenuItem('4th Error Message', 8, 1,246, Possible_Error);
               MenuItem('Abort Dial Command', 9, 1,247, ' Command to abort a call.' + Special_Chars);
               MenuItem('Hangup Command', 10, 1,248, ' Command to hangup the modem.'+Special_Chars);
               MenuItem('Redial Cancel Text', 11, 1, 249, ' Text received from the modem to cancel a Redial session');
               PopSubLevel;

            MenuItem('Port Setup ', 3, 1,74,' Change serial port Base Address and IRQ');
            SubMenu(10, 7, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(23);
               MenuItem('A - COM1 Base', 1, 1,251, Base_Port);
               MenuItem('B - COM2 Base', 2, 1,252, Base_Port);
               MenuItem('C - COM3 Base', 3, 1,253, Base_Port);
               MenuItem('D - COM4 Base', 4, 1,254, Base_Port);
               MenuItem('E - COM5 Base', 5, 1,255, Base_Port);
               MenuItem('F - COM6 Base', 6, 1,256, Base_Port);
               MenuItem('G - COM7 Base', 7, 1,257, Base_Port);
               MenuItem('H - COM8 Base', 8, 1,258, Base_Port);
               MenuItem('I - COM1 IRQ', 9, 1, 259, IRQ_msg);
               MenuItem('J - COM2 IRQ', 10, 1,260, IRQ_msg);
               MenuItem('K - COM3 IRQ', 11, 1,261, IRQ_msg);
               MenuItem('L - COM4 IRQ', 12, 1,262, IRQ_msg);
               MenuItem('M - COM5 IRQ', 13, 1,263, IRQ_msg);
               MenuItem('N - COM6 IRQ', 14, 1,264, IRQ_msg);
               MenuItem('O - COM7 IRQ', 15, 1,265, IRQ_msg);
               MenuItem('P - COM8 IRQ', 16, 1,266, IRQ_msg);
               PopSubLevel;

  {$IfDef ISI}
  If AllowMemoryChange then
     Begin
            MenuItem('ISI Setup ', 4, 1,74,' Change ISI Board Base Address and IRQ');
            SubMenu(10, 8, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(23);
               MenuItem('A - ISI Base', 1, 1,452, 'Base Port of ISI Card (MUST match ISILOAD Command)');
               MenuItem('B - ISI IRQ', 2, 1, 453, 'IRQ of ISI Card (MUST match Board Jumper)');
               PopSubLevel;
     End
  Else
            MenuItem('ISI Setup  ', 4, 0,74,' Cannot change ISI Setup from Alt-N.  Exit and run '+_Qinstall_);
  {$Else}
            MenuItem('reserved ', 4, 0,74,' reserved for future expansion ');
  {$EndIf}

            MenuItem('Quick Modem Config! ', 5, 1,71,' Pick a modem from the list for Quick Installation');

            MenuItem('Toggles ', 6, 1,86, ' Modem related Toggles');
            SubMenu (10, 10, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(28);
               MenuItem('Xon/Xoff flow', 1, 1, 368, ' XON/XOFF Software flow control');
               MenuItem('CTS/RTS flow', 2, 1, 374, ' CTS/RTS Hardware flow control');
               MenuItem('RTS when Writing', 3,10, 375, ' Set the state of the RTS Signal when Writing to Disk');
               MenuItem('FIFO during Shell', 4 , 1, 382, ' Enable the 16550 UART FIFO buffer during Shell');
               MenuItem('Lock DTE Baud Rate', 5, 1, 376, ' When ON, the DTE baud rate is constant');
               MenuItem('High Speed Xmit', 6, 1,391, ' Enables or disables the Interrupt Driven Transmit support');
               MenuItem('16550 UART Enable', 7, 1,392, ' Enables or disables the use of a 16550 UART if detected');
               MenuItem('Init ignores CD', 8, 1,430, ' If ON, the Modem Init String is sent regardless of the Carrier Detect');
               PopSubLevel;
            PopSubLevel;


         MenuItem(' Dirs ', 20, 2,70, ' Change the default Directories');
         SubMenu(16, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(51);
            MenuItem('Upload',    1, 1,269, ' Change default Upload Directory');
            MenuItem('Download',  2, 1,270, ' Change default Download Directory');
            MenuItem('Scripts',   3, 1,271, ' Change default Scripts Directory');
            MenuItem('Swap',      4, 2,426, ' Change default Shell SWAP Directory');
            MenuItem('1st Batch' ,5, 1,441, ' Change default Batch Upload Directory #1');
            MenuItem('2nd Batch' ,6, 1,442, ' Change default Batch Upload Directory #2');
            MenuItem('3rd Batch' ,7, 1,443, ' Change default Batch Upload Directory #3');
            MenuItem('AltW Pick' ,8, 1,447, ' Change default Alt-W Directory and Pick Mask');
            PopSubLevel;

         {$IfNDef GG}
         MenuItem(' Host ', 28, 2,69,' Change Host Mode options');
         SubMenu(15, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(53);
            MenuItem('Type of System'   , 1,1,273, ' [Enter] to toggle  - OPEN, CLOSED or CALLBACK');
            MenuItem('Download Dir'     , 2,1,274, ' Download file directory path');
            MenuItem('Upload Dir'       , 3,1,275, ' Upload file directory path');
            MenuItem('Maximum Time'     , 4,1,276, ' Set the Maximum time (in minutes) per session.  Range 1 - 1440');
            MenuItem('DOS Password'     , 5,2,277, ' Password required to "Shell to DOS" from remote');
            MenuItem('Shutdown Password', 6,1,278, ' Password required to shut System down from remote');
            MenuItem('Init Command'     , 7,1,279, ' Text sent to initialize the modem for calls');
            MenuItem('Answer Command'   , 8,1,280, ' Command to Answer a Call.' + Special_Chars);
            MenuItem('OK Message'       , 9,2,281, ' Response when Init is successful.' + Special_Chars);
            MenuItem('Ring Detect'      ,10,1,282, ' Message from modem when a RING is detected');
            MenuItem('Busy Command'     ,11,1,283, ' Command to place modem Off-Hook for local logon');
            MenuItem('# Rings & Answer' ,12,1,284, ' Number of Rings before the ANSWER.  Min 1, Max 10');
            PopSubLevel;
         {$Endif}
   End;

End.
