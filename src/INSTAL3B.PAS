Unit Instal3b;


   { Look in INSTALL for Last High number }


Interface


Uses
   TpCrt,
   TPMenu0, {old v5.11 version of TpMenu }
   Initial,
   Constant,
   Procs;

Procedure BuildPart2;


Implementation

   Procedure BuildPart2;
   Const
      Frame1 : FrameArray = LotusFrame;
      Frame2 : FrameArray = 'ÕÔ¸¾Í³';
      Set_Initial    = ' Set initial state of the ';
      Change_Ext_Protocol = ' Modify external protocol ';
      Select_Char    = ' Select character';
      Protocol       = ' Protocol';
      Upload_BAT     = ' Upload BAT';
      Download_BAT   = ' Download BAT';
      Filename_Prompt= ' Filename Prompt';
      Close_The_Port = ' Close COM Port';
      SCtxt          = ' Enter new Select character.  Must be UNIQUE! ';
      PRtxt          = ' Enter the name of the protocol.  1-12 characters ';
      UBtxt          = ' Enter the name of the Upload BATCH filename ';
      DBtxt          = ' Enter the name of the Download BATCH filename ';
      FPtxt          = ' Requires a filename when Downloading [Y/N] ? ';
   Begin
      MenuItem(' Protocols ', 36, 2, 68, ' Change the External Protocols');
      SubMenu(35, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
         MenuWidth(21);

         {$IfNDef GG}

         MenuItem('0 -', 1, 1, 67, Change_Ext_Protocol);
         SubMenu(30, 5, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char    , 1, 1, 287, SCtxt);
            MenuItem(Protocol       , 2, 1, 288, PRtxt);
            MenuItem(Upload_BAT     , 3, 1, 289, UBtxt);
            MenuItem(Download_BAT   , 4, 1, 290, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 291, FPtxt);
            PopSubLevel;
         MenuItem('1 -', 2, 1, 292, Change_Ext_Protocol);
         SubMenu(30, 6, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 293, SCtxt);
            MenuItem(Protocol, 2, 1, 294, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 295, UBtxt);
            MenuItem(Download_BAT, 4, 1, 296, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 297, FPtxt);
            PopSubLevel;
         MenuItem('2 -', 3, 1, 298, Change_Ext_Protocol);
         SubMenu(30, 7, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 299, SCtxt);
            MenuItem(Protocol, 2, 1, 300, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 301, UBtxt);
            MenuItem(Download_BAT, 4, 1, 302, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 303, FPtxt);
            PopSubLevel;
         MenuItem('3 -', 4, 1, 304, Change_Ext_Protocol);
         SubMenu(30, 8, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 305, SCtxt);
            MenuItem(Protocol, 2, 1, 306, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 307, UBtxt);
            MenuItem(Download_BAT, 4, 1, 308, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 309, FPtxt);
            PopSubLevel;
         MenuItem('4 -', 5, 1, 310, Change_Ext_Protocol);
         SubMenu(30, 9, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 311, SCtxt);
            MenuItem(Protocol, 2, 1, 312, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 313, UBtxt);
            MenuItem(Download_BAT, 4, 1, 314, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 315, FPtxt);
            PopSubLevel;
         MenuItem('5 -', 6, 1, 316, Change_Ext_Protocol);
         SubMenu(30, 10, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 317, SCtxt);
            MenuItem(Protocol, 2, 1, 318, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 319, UBtxt);
            MenuItem(Download_BAT, 4, 1, 320, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 321, FPtxt);
            PopSubLevel;
         MenuItem('6 -', 7, 1, 322, Change_Ext_Protocol);
         SubMenu(30, 11, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 323, SCtxt);
            MenuItem(Protocol, 2, 1, 324, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 325, UBtxt);
            MenuItem(Download_BAT, 4, 1, 326, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 327, FPtxt);
            PopSubLevel;
         MenuItem('7 -', 8, 1, 328, Change_Ext_Protocol);
         SubMenu(30, 12, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 329, SCtxt);
            MenuItem(Protocol, 2, 1, 330, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 331, UBtxt);
            MenuItem(Download_BAT, 4, 1, 332, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 333, FPtxt);
            PopSubLevel;
         MenuItem('8 -', 9, 1, 334, Change_Ext_Protocol);
         SubMenu(30, 13, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 335, SCtxt);
            MenuItem(Protocol, 2, 1, 336, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 337, UBtxt);
            MenuItem(Download_BAT, 4, 1, 338, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 339, FPtxt);
            PopSubLevel;
         MenuItem('9 -', 10, 1, 340, Change_Ext_Protocol);
         SubMenu(30, 14, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(35);
            MenuItem(Select_Char, 1, 1, 341, SCtxt);
            MenuItem(Protocol, 2, 1, 342, PRtxt);
            MenuItem(Upload_BAT, 3, 1, 343, UBtxt);
            MenuItem(Download_BAT, 4, 1, 344, DBtxt);
            MenuItem(Filename_Prompt, 5, 1, 345, FPtxt);
            PopSubLevel;

         {$EndIf} {GG}

         MenuItem('ASCII Options ',11, 1, 66, ' Set ASCII Transfer Options');
         SubMenu(52, 11, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuItem('Receive ', 1, 1, 65, ' ASCII Receive Options');
            SubMenu(40, 13, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(38);
               MenuItem('Use INPUT Translate Table', 1, 1, 348,
                        ' Translate in-coming characters with the INPUT Translate Table');
               MenuItem('Carriage Return Handling', 2, 1, 349,
                        ' NONE,  STRIP (remove from stream)  or  ADD LF (after each CR)');
               MenuItem('LineFeed Handling', 3, 1, 350,
                        ' NONE,  STRIP (remove from stream)  or  ADD CR (before each LF)');
               PopSubLevel;
            MenuItem('Transmit ', 2, 1, 64, ' ASCII Transmit Options');
            SubMenu(40, 14, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(39);
               MenuItem('Use OUTPUT Translate Table', 1, 1, 352,
                        ' Translate out-going characters with the OUTPUT Translate Table');
               MenuItem('Carriage Return Handling', 2, 1, 353,
                        ' NONE,  STRIP (remove from stream)  or  ADD LF (after each CR)');
               MenuItem('LineFeed Handling', 3, 1, 354,
                        ' NONE,  STRIP (remove from stream)  or  ADD CR (before each LF)');
               MenuItem('Pacing Speed', 4, 1, 355,
                        ' Delay (in milliseconds) to wait between each character sent');
               MenuItem('pAcing Character', 5, 2, 356,
                        ' Character (in decimal) before sending one line of text');
               MenuItem('Blank Line Expansion', 6, 1, 357,
                        ' Blank lines ('''') changed to one SPACE '' '' before sending');
               MenuItem('End of Line Character', 7, 1,358,
                        ' Character (in decimal) that designates the EOL, usually 13(CR) or 10(LF)');
               PopSubLevel;
            PopSubLevel;
         MenuItem('Toggles ',12, 1, 41, ' Set Internal Protocol Transfer Options');
         SubMenu(32, 16, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(33);
            MenuItem('Overwrite Files', 1, 1,434,
                     ' Allow Download protocols to overwrite existing files without warning');
            MenuItem('Auto-Increment Filename', 2, 1,435,
                     ' When ON and Overwrite set OFF, Filename will change to prevent Overwrite');
            MenuItem('Save Partials', 3, 1,436,
                     ' When ON, aborted downloads will be saved instead of deleted');
            MenuItem('Clear Batch Screen', 4, 1,438,
                     ' When ON, the Batch Entry Window will be cleared after a batch transfer');
            MenuItem('Zmodem Autostart', 5, 1,389, ' When ON, '+_Qmodem_+' will start Zmodem download automatically');
            PopSubLevel;
         PopSubLevel;

      MenuItem(' Files ', 50, 2, 70, ' Change the default Filenames and Directories');
      SubMenu(26, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
         MenuWidth(51);
         MenuItem('Online Help', 1, 1, 360, ' Set Online Help Filename and Directory');
         MenuItem('Screen Dump', 2, 3, 361, ' Set Screen Dump Filename and Directory');
         MenuItem('Capture',     3, 1, 362, ' Set Capture Filename and Directory');
         MenuItem('Log',         4, 1, 363, ' Set Session Log Filename and Directory');
	 MenuItem('BackScroll',  5, 1, 364, ' Set BackScroll Filename and Directory');
         MenuItem('View',        6, 1, 365,
		  ' Set View/Edit Program/Path   Internal Editor [@FSE]  External [@EDITOR]');
         MenuItem('Printer',     7, 1, 446, ' Set Printer Device or Filename.  ie: PRN, LPT1, LPT2, C:\SAVEPRT.TXT');
         MenuItem('Time/Date Stamp', 8,1,451,' Stamp Screen Dump, Capture and Backscroll files with Time/Date header');
         PopSubLevel;


      MenuItem(' Options ', 60, 2, 62, ' Change optional parameters for "fine tuning"');
      SubMenu(53, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
         MenuWidth(24);
	 MenuItem('Toggles ', 1, 1, 61, ' Change the defaults that can be Toggled');
         SubMenu (47, 5, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(29);
	    MenuItem('Beeps & Bells',        1, 1, 371, Set_Initial + 'Speaker');
	    MenuItem('ANSI Music',           2, 1, 373, Set_Initial + 'ANSI Music support');
	    MenuItem('DEL/^H Backspace',     3, 1, 377, ' Set the mode of the Backspace key.  OFF=^H  ON=DEL');
	    MenuItem('Auto-Start LOG',       4, 2, 378, ' Turn LOGing on when '+_Qmodem_+' is started');
	    MenuItem('Keypad emulation',     5, 1, 383, ' With NUMLOCK ON, Keypad keys send Terminal Emulation esc codes');
	    MenuItem('ENQ response',         6, 1, 386, ' When ON, the Alt-F12 macro text is sent when ^E is received');
	    MenuItem('Guard Alt-H',          7, 1, 429, ' When ON, the Alt-H Hangup asks to confirm');
	    MenuItem('0xE0 Doorway Codes',   8, 1, 448,
                     ' When ON, 0xE0 codes are enabled for enhanced 101 keyboards in Doorway mode');
            MenuItem('Alt-D FON Book ',     9, 7, 102, ' Change the defaults that can be Toggled in the FON book');
            SubMenu (49, 15, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(29);
               MenuItem('Tag Advance',        1, 1, 431, ' When ON, tagging an entry in Alt-D advances the Scrollbar');
               MenuItem('AutoStart',          2, 1, 437, ' When ON, '+_Qmodem_+' starts up in the Alt-D Menu');
               MenuItem('Clear tags on FKey', 3, 1, 440, ' When ON, an FKey Tag Dial will do a UNTAG command before tagging');
               MenuItem('Write FBK file',     4, 1, 450,
                        ' When ON, changes to the FON book result in an FBK Backup written to disk');
               PopSubLevel;
            PopSubLevel;
         MenuItem('Runtime Parms ', 2, 1, 60, ' Setup Runtime Command line Parameters');
         SubMenu (51, 6, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(27);
            MenuItem('EMS for Overlays', 1, 1,388, ' ON - '+_Qmodem_+' will try to use EMS.  OFF - No EMS will be used');
            MenuItem('Int16 Enable', 2, 1,390, ' Enables or disables Enhanced 101-key keyboard support');
            MenuItem('Share IRQ''s', 3, 1,427, ' Enables or disables Sharing Interrupts');
            MenuItem('Optimum Shell',4, 1,428, ' Enables or disables Maximum memory during all Shell operation');
            MenuItem('-- Disk Shell',5, 4,445, ' Enables or disables using a Disk to store the memory image during Shell');
            MenuItem('Calibrate DELAY',6, 1,444, ' When ON, the internal timer is recalibrated periodically');
            PopSubLevel;
  If AllowMemoryChange then
     Begin
         MenuItem('Memory ', 3, 1,59,' Set Memory Requirements');
         SubMenu(50, 7, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(30);
            MenuItem('Lines of Scroll-back', 1, 1, 395, ' Total lines for Scroll-back.  Range 0 - 1000');
            MenuItem('Download Buffer'     , 2, 1, 398, ' Set the Download Buffer Blocks.  Range 8 - 240');
            MenuItem('Overlay Buffer (K)'  , 3, 1, 399, ' Set additional Overlay Buffer allocation (in K).  Range 0 - 200');
            PopSubLevel;
     End
  Else
         MenuItem('memory ', 3, 0,59,' Cannot change Memory options from Alt-N.  Exit and run '+_Qinstall_);

         MenuItem('Sounds ', 4, 1,58,' Change Tones for Upload, Download, and Connection');
         SubMenu(56, 8, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(24);
            MenuItem('Connect tones ', 1, 1,401,'');
            SubMenu(62,10, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(13);
               MenuItem('1 -', 1, 1,402, ' Set Tone 1.  Range 0 - 9999');
               MenuItem('2 -', 2, 1,403, ' Set Tone 2.  Range 0 - 9999');
               MenuItem('3 -', 3, 1,404, ' Set Tone 3.  Range 0 - 9999');
               MenuItem('Max', 4, 1,439, ' Maximum number of cycles of the Connect Tones.  Range 0 - 999');
               PopSubLevel;
            MenuItem('Upload tone'  , 2, 1,405, ' Set Upload tone.  Range 0 - 9999');
            MenuItem('Download tone', 3, 1,406, ' Set Download tone.  Range 0 - 9999');
            PopSubLevel;
         MenuItem('Delays ', 5, 1,57,' Change Timing Delays');
         SubMenu(56, 9, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuWidth(23);
            MenuItem('Status window', 1, 1,408,
                     ' Set Status window duration (in hundredths of a second).  Range 0 - 999');
            MenuItem('File transfers' , 2, 1,409, ' Set added timeout value (in seconds).  Range 0 - 999');
            MenuItem('BREAK timing'   , 3, 1,410, ' Set the BREAK delay (in milliseconds).  Range 0 - 2000');
            MenuItem('DTR timing'     , 4, 1,411, ' Set the DTR drop delay (in milliseconds).  Range 0 - 2000');
            PopSubLevel;
         MenuItem('Characters ', 6, 1, 49, ' Miscellaneous display characters you can customize');
         SubMenu(52, 10, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
            MenuItem('Beeps & Bells', 1, 1, 415,
                     ' Character in Status Line when ON.  Default ''' + #13 + '''.');
            MenuItem('ANSI Music', 2, 1, 416,
                     ' Character in Status Line when ON.  Default ''' + #14 + '''.');
            MenuItem('Status Line Filler        ', 3, 1, 417,
                     ' Character used as filler in the Status Line.  Default ''°''.');
            MenuItem('Phone Book Tag', 4, 1, 418,
                     ' Character to show Tagged entries.  Default ''û''.');
            MenuItem('Notes Tag', 5, 1, 419,
                     ' Character to show Attached Notes in Phone Book.  Default ''ð''.');
            MenuItem('Date Mask',   6, 1, 413,
                     ' String definition used in all Date fields.  Default ''mm-dd-yy''.');
            MenuItem('Time Mask',   7, 1, 414,
                     ' String definition used in all Time fields.  Default ''hh:mm:ss''.');
            MenuItem('Elapsed Mask',8, 1, 449,
                     ' String definition used in Elapsed Time fields.  Default ''hh:mm:ss''.');
            PopSubLevel;
         PopSubLevel;

      {$IfDef Net}
      If Administration then
         Begin
            MenuItem(' Network ', 60, 2, 62, ' Network Administration');
            SubMenu(55, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
               MenuWidth(24);
               MenuItem('Filler',        1, 1, 555, 'Net Stuff');
               MenuItem('Filler',        2, 2, 555, 'Net Stuff');
               MenuItem('Filler',        3, 3, 555, 'Net Stuff');
            PopSubLevel;
         End;
      {$EndIf}

      MenuItem(' Exit ', 73, 2,56,' Abandon changes  -or-  Save & Exit');
      SubMenu(65, 3, ScreenHeight, Vertical, Frame2, qq.Qcolor1, '');
         MenuItem('Save Changes', 1, 1, 422, ' Save changes to Disk and Exit');
         MenuItem('Abandon', 2, 1, 421, ' Do NOT save changes to Disk and Exit');
         PopSubLevel;
      PopSubLevel;
   End;

End.
