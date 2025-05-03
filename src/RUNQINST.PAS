UNIT RUNQINST;


INTERFACE

Uses TPInLine,  TpEntry,   Dos,
     TPDos,     TpCrt,
     TPString,  TPWindow,  Initial,
     Screen,    Constant,  Comm2,
     Procs,     Comm,      QShell,
     Batch,     Files;


Const
   InQ = 'InQmodem';


Procedure Run_Qinstall(MustHave : Boolean);
Procedure Reload_Config;
Procedure Load_Config;
Procedure Save_Config;

Procedure Load_INI;
Procedure Save_INI;



IMPLEMENTATION


   Procedure ZapNew43Fields;
   Begin
      With qq Do
         Begin
            StrictColor   := False;
         End;
   End;


   Procedure ZapNew42Fields;
   Begin
      With qq Do
         Begin
            LockDTE := Char(LockDTE) = 'N';
            TimeDateStamp := True;
            HelpColors[1] := $1F;
            HelpColors[2] := $17;
            HelpColors[4] := $3F;
            HelpColors[5] := $30;
            HelpColors[6] := $1E;
            DateStr       := 'mm-dd-yy';
            TimeStr       := 'hh:mm:ss';
            ElapsedStr    := 'hh:mm:ss';
            WriteFBK      := True;

            For x := 1 to 10 do
               Begin
                  If not (Xfer_File_Prompt[x] in ['N','Y']) then
                     Xfer_File_Prompt[x] := 'N';
               End;

            {Fix default Baud Rate}
            ComSpeed := FillerSpeed;

            {Fix Colors in the Alt-N Setup and the status line}
            Qcolor1[HeaderColor]  := Qcolor1[FrameColor];
            qq.Qcolor1[HelpColor] := StatusLineColor;

            {Fix Alt-N/O/T/T}
            TagAdvance := True;

            {Fix Alt-N/V/T/J}
            JumpScroll := True;

            {Fix Alt-N/P/T/x}
            OverWrite     := False;
            SavePartial   := True;
            AutoIncrement := True;
            BEWClear      := True;
            ConnectCycles := 5;

         End;
   End;


   Procedure ZapNew41Fields;
   Begin
      With qq Do
         Begin
            BreakDelay      := 500;
            DTRdelay        := 1000;
            AutoZ           := FALSE;
            EMS_OK          := FALSE;
            UseInt16        := FALSE;
            UseHighSpeed    := False;
            Use16550        := True;
            VideoRestore    := False;
            Host_Ring_Count := 1;
            LineWrap        := True;
            Destruct_BS     := True;
            ENQ             := False;
         End;
   End;

   Procedure ZapNew40Fields;
   Begin
      With qq Do
         Begin
            MaxBuf         := 8;                   { Download Buffer size           }
            ShowStatusLine := True;                 { Set speed from redial window   }
            KeypadEmuls    := 'N';                 { keypad works as in 3.1a }
            Status_Delay   := 300;                 { Status Delay in seconds        }
            Host_Ring_Msg  := 'RING';              { When a RING is detected        }
            Redial_Ring_Msg:= 'RING';              { When a RING is detected        }
            FIFOshell      := 'N';                 { FIFO buffer in Shell           }
            Download_Time  := 10;                  { Additional time delay for xfer's }
            MaxScrollLines := 50;                  { 50 lines             }
            Qcolor1[BodyColor] := $31;
            Qcolor1[HiliteColor] := $3E;
            Qcolor1[SelectColor] := $1F;
            Qcolor1[FrameColor] := $03;
            editf          := $70;
            ScrollBar      := 112;
            edit1          := $07;
            edit2          := $70;
            editw          := $0F;
            HelpColors[1]  := $1F;
            HelpColors[2]  := $17;
            HelpColors[4]  := $3F;
            HelpColors[5]  := $30;
            HelpColors[6]  := $1E;
            CharBeeps      := #13;
            CharANSI       := #14;
            SLC            := #176;
            CharTag        := #251;
            NoteTag        := #240;
            Grow_Window    := True;
            Explode        := True;
            OKMessage      := 'OK';
            HostInit       := 'ATS0=0H0^M';
            Host_Answer    := 'ATA^M';
            HostOpen       := 0;
            HostMaxTime    := 60;
            HostOffHook    := 'ATM0H1^M';
            ExtraOvrBuf    := 20;
            HostPassword   := 'PASSWORD';
            HostShutDown   := 'PASSWORD';
            ASCII_Out_Expand := TRUE;
            ASCII_EOL_Ch     := 10;
            ASCII_Pace_Ch    := 0;
            ASCII_Pace_Speed := 10;
            ASCII_In_Xlate   := False;
            ASCII_Out_Xlate  := False;
            ASCII_In_CR      := 0;
            ASCII_In_LF      := 0;
            ASCII_Out_CR     := 0;
            ASCII_Out_LF     := 0;
         End;
   End;




   Procedure Do_Runtime_Fixups;   {Cleanups between versions...}
   Var
      x : Integer;
   Begin
      For x := 1 To 10 Do
         If qq.Xfer_select_chr[x] = #0 Then
            qq.Xfer_select_chr[x] := ' ';
      If not (Byte(qq.ShowStatusLine) in [0,1]) then
         qq.ShowStatusLine := TRUE;
      If Not(qq.KeypadEmuls In ['N', 'Y']) Then
         qq.KeyPadEmuls := 'N';
      If (qq.HostOpen < 0) Or (qq.HostOpen > 2) Then
         qq.HostOpen := 0;
      If (qq.Status_Delay < 0) Or (qq.Status_Delay > 999) then
         qq.Status_Delay := 200;
      if (qq.edit1 < 1) or (qq.edit1 > 127) then
         qq.edit1 := $07;
      if (qq.edit2 < 1) or (qq.edit2 > 127) then
         qq.edit2 := $70;
      if (qq.editw < 1) or (qq.editw > 127) then
         qq.editw := $0F;
      If qq.ExtraOvrBuf > 256 then
         qq.ExtraOvrBuf := 30;
   End;

   Procedure Load_INI;
   Var
     Go : Boolean;
     fn : string;
   Begin
      fn := SearchName(QMODEM_INI);
      If ExistFile(fn) Then
         Begin
            Assign(INI_file, fn);
            Reset (INI_file);
            IO := IoResult;
            Read(INI_file, INI);
            Go := (IoResult = 0);
            Close(INI_File);
            Erase(INI_File);
            IO := IoResult;
            If Go then
               With INI do Begin
                  {Set to the same parameters}
                  NewSpeed    := ModemSpeed;
                  DCE_Speed   := SerialSpeed;
                  NewDBits    := DBits;
                  NewSBits    := Stop_Bits;
                  NewCparity  := CParity;
                  Echo        := EchoI;
                  Hi_Bit      := HiBitI;
                  Addlf       := AddlfI;
                  Xon_Xoff    := Xon_XoffI;
                  Noise       := NoiseI;
                  Music_flag  := MusicI;
                  Save_Scroll := Save_ScrollI;
                  Prtlog      := PrtLogI;
                  If SplitI then
                     If not Split then
                        SplitScreen;
                  Init_Port;
                  Clear_Buffer;
                  Term_Ready(True);
               End;
         End;
   End;


   Procedure Save_INI;
   Begin
      Assign  (INI_file, SearchName(QMODEM_INI));
      Rewrite (INI_file);
      IO := IoResult;
      With INI do
         Begin
            {$IfDef GG}
               Case Emulation of
                  TTY     : Emulate_Ch := 'A';
                  ANSImode: Emulate_Ch := 'B';
                  AVATAR  : Emulate_Ch := 'C';
               End;
            {$Else}
               Case Emulation of
                  TTY     : Emulate_Ch := 'A';
                  ANSImode: Emulate_Ch := 'B';
                  VT100   : Emulate_Ch := 'C';
                  TVI925  : Emulate_Ch := 'D';
                  Debug_A : Emulate_Ch := 'E';
                  Debug_H : Emulate_Ch := 'F';
                  AVATAR  : Emulate_Ch := 'G';
               End;
            {$EndIf}
            ModemSpeed   := NewSpeed;
            SerialSpeed  := DCE_Speed;
            DBits        := NewDBits;
            Stop_Bits    := NewSBits;
            Cparity      := newCParity;
            EchoI        := Echo;
            HiBitI       := Hi_Bit;
            AddlfI       := Addlf;
            Xon_XoffI    := Xon_Xoff;
            NoiseI       := Noise;
            MusicI       := Music_Flag;
            Save_ScrollI := Save_Scroll;
            PrtlogI      := PrtLog;
            SplitI       := Split;
         End;
      Write(INI_File, INI);
      Close(INI_File);
      IO := IoResult;
   End;

   Procedure Save_Config;
   Begin
      Assign(Config_file, SearchName(QMODEM_CNF));
      Rewrite(Config_file);
      IO := IoResult;
      Write(Config_file, qq);
      IO := IoResult;
      Close(Config_File);
      IO := IoResult;
   End;


   Procedure Load_Config;
   Var
      s : String;
   Begin
      qq.InfoColor:= 7;
      TextAttr := 7;
      S := SearchName(QMODEM_CNF);
      If ExistFile(S) Then
         Begin
            Assign(Config_file, S);
            Reset(Config_file);
            Read(Config_file, qq);
            IO := IoResult;
            If IO <> 0 Then
               Begin
                  ClrScr;
                  Close(Config_file);
                  Erase(Config_file);
                  IO := IoResult;
               End
            Else
               Begin
                  Close(Config_file);
                  If qq.config_version <> config_version_const Then
                     Begin
                        If qq.Config_version < '4.0 ' then
                           ZapNew40Fields;
                        If qq.Config_version < '4.1 ' then
                           ZapNew41Fields;
                        If qq.Config_version < '4.2 ' then
                           ZapNew42Fields;
                        If qq.Config_version < '4.2G' then
                           ZapNew43Fields;
                        Run_Qinstall_Now := True;
                     End
                  Else
                     Do_Runtime_Fixups;
               End;
         End;
      If Not ExistFile(S) Then
         Begin
            Run_Qinstall(True);
         End;

      DirectVideo   := qq.DirectVideo;
      BiosScroll    := qq.JumpScroll;
      CheckSnow     := qq.CheckSnowx = 'Y';
      Xon_Xoff      := qq.Xon_Xoffc = 'Y';
      addlf         := qq.addlfc = 'Y';
      noise         := qq.Noisec = 'Y';
      ShowSL        := qq.ShowStatusLine;
      Explode       := qq.Grow_Window;
      LineWrap      := qq.LineWrap;
      Music_flag    := qq.musicc = 'Y';
      CTS_          := qq.CTSc = 'Y';
      ShareIRQ      := qq.Share_IRQ;
      Set_Base_Colors;
      NewSpeed      := qq.ComSpeed;
      DCE_Speed     := NewSpeed;
      NewSBits      := qq.stop_bits;
      NewDBits      := qq.dbits;
      NewCparity    := qq.Cparity;

      Upload_Path   := qq.Upload_Path_s;
      ScrndumpF     := qq.ScrnDumpF_s;
      CaptureF      := qq.CaptureF_s;
      Downld_Path   := qq.Downld_Path_s;
      Scroll_Sav    := qq.Scroll_Sav_s;
      Log_FileN     := qq.Log_Filename_s;

      { Make sure the Menu Colors are OK }

      If qq.Qcolor1[BodyColor]   = 0 Then qq.Qcolor1[BodyColor] := $31;
      If qq.Qcolor1[HiliteColor] = 0 Then qq.Qcolor1[HiliteColor] := $3E;
      If qq.Qcolor1[SelectColor] = 0 Then qq.Qcolor1[SelectColor] := $1F;
      If qq.Qcolor1[FrameColor]  = 0 Then qq.Qcolor1[FrameColor] := $03;
   End;


   Procedure Reload_Config;
   Begin
      If ExistFile(SearchName(QMODEM_CNF)) Then
         Begin
            Assign(Config_file, SearchName(Qmodem_Cnf));
            Reset(Config_file);
            Read(Config_file, qq);
            Close(Config_file);
            IO := IoResult;
         End;

      If qq.UseInt16 then
         UseEnhancedKbd := EnhancedKbdInstalled
      Else
         UseEnhancedKbd := False;
      LineWrap       := qq.LineWrap;
      DirectVideo    := qq.DirectVideo;
      ScrnDumpF      := qq.Scrndumpf_s;
      CaptureF       := qq.CaptureF_s;
      Log_FileN      := qq.Log_Filename_s;
      Scroll_Sav     := qq.Scroll_Sav_s;
      Upload_Path    := qq.Upload_Path_s;
      Downld_Path    := qq.Downld_Path_s;
      ShareIRQ       := qq.Share_IRQ;
      BiosScroll     := qq.JumpScroll;
      Explode        := qq.Grow_Window;
   End;


Procedure Run_Qinstall(MustHave : Boolean);
Var
   rc : Word;
   SavePort : Byte;
   SaveSpeed : LongInt;
   SaveDBits,
   SaveSBits : Word;
   SaveCParity : Char;
   qi,s : String[64];
Begin
   If ExistOnPath(Qmodem_CNF,s) or ExistOnQmodemPath(Qmodem_CNF,s) then
      Save_Config
   Else
      Begin
         Window(1,1,80,ScreenHeight);
         TextAttr := 15;
         Clrscr;
         Writeln('Please run the program '+_QINSTALL_+' before running '+_QMODEM_+'.');
         Halt;
      End;
   If not ExistOnPath(Qinstall_EXE,qi) then
      Begin
         If not ExistOnQmodemPath(Qinstall_EXE,qi) then
            Begin
               If not MustHave then
                  Begin
                     Beep;
                     Exit;
                  End;
               Window(1,1,80,ScreenHeight);
               TextAttr := 15;
               Clrscr;
               Writeln('The program '+_QINSTALL_+' was not found.  Please check to see');
               Writeln('that the program is in the current directory and run ',JustFilename(ParamStr(0)));
               Writeln('again.');
               Halt;
            End;
      End;
   SavePort    := qq.CommPort;
   SaveSpeed   := NewSpeed;
   SaveCParity := NewCParity;
   SaveDBits   := NewDBits;
   SaveSBits   := NewSBits;
   Push_Status;

   Display_Status(' Loading '+_QINSTALL_+' ');
   {$IfDef ISI}
      rc := MiniShell (qi+' '+InQ+' '+Long2Str(ISI_Port_Count));
   {$Else}
      rc := MiniShell (qi+' '+InQ);
   {$EndIf}
   Display_Status('');
   Pop_Status;

   Reload_Config;

   qq.CommPort := SavePort;
   NewSpeed   := SaveSpeed;
   NewCParity := SaveCParity;
   NewDBits   := SaveDBits;
   NewSBits   := SaveSBits;
   Init_Port;
End;


End.
