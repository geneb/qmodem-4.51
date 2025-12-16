Unit Group02;

Interface

{$I TPDEFINE.INC}

Uses
   Qmem,      Dos,   Stack5,

   {$ifdef OVR}      OvrStart, {$endif}
   {$ifdef UseMouse} TPMouse,  {$endif}

   TPDos,     TpCrt,     TpPick,    TpDir,
   TPString,  TPWindow,  Initial,   {OpEnhkbd,}
   Comm,      Procs,     Screen,    Group1,
   FoneStuf,  Files,     Constant,  Printer2,
   Music,     QDial,     Comm2;

Const
   ForceHost : Boolean = False;



Procedure BS_DEL_Switch;
Procedure Echo_toggle;
Procedure Scroll_toggle;
Procedure Hi_Bit_Toggle;
Procedure Addlf_toggle;
Procedure Noise_toggle;
Procedure Prtlog_toggle;
Procedure Xon_Xoff_Toggle;
Procedure ANSI_Music;
Procedure Doorway_toggle;
Procedure Setup3;
Procedure Hangup;
Procedure Show_Ready_Msg;
Procedure Capture_Toggle(TempF : String; CloseOnly : Boolean);

{$IfNDef Bundle}
Procedure Register_Copy;
{$EndIf}

Function  Test_Host_Carrier : Boolean;
Procedure Check_Host_Hangup_Routine;
Procedure Parse_Command_Line;
Procedure Clear_All_ScrollBack;

Var
   Qinstall_Init_Done : Boolean;


Implementation

{$ifdef JNL}
   Function CheckRIM : WORD; External;
   {$L CHECKRIM}
{$endif}

Procedure Parse_Command_Line;
   Var
      Pause : Boolean;
      v,x   : word;
      Temp  : String;
      First : Boolean;
      {$ifdef JNL}
         FoundNCS : Boolean;
         RRim     : Boolean;
      {$endif}

   Begin
      Window(1,1,ScreenWidth,ScreenHeight);
      Pause := False;
      First := False;
      AutoHost := False;
      GetRegC := False;
      Auto_Script_Name := '';
      Auto_Script := False;
      Restart_Invoked := False;
      Override_Port := False;

      {$ifdef Int14}
         Int14 := False;
         {$ifdef JNL}
            RRim := True;
            v := CheckRIM;
         {$endif}
      {$endif}

      For X := 1 to ParamCount do
         Begin
            Temp := STUpCase(ParamStr(x));

            {$ifdef Production}
               {$IfNDef Bundle}
                  If (Temp = 'REGISTER') or (Temp = '/REGISTER') Then
                     Register_Copy Else
               {$EndIf}
            {$EndIf}

            If Temp = '/STATS' Then
               InitStats := True Else

            If (Copy(Temp,1,4) = '/COM') and                     {4.2F!!}
               (Length(Temp)=5) and                              {4.2F!!}
               (Temp[5] in ['1'..'8']) Then                      {4.2F!!}
               Begin                                             {4.2F!!}
                  Override_Port := True;                         {4.2F!!}
                  Override_Port_Num := Ord(Temp[5])-Ord('1')+1;  {4.2F!!}
                  {$ifdef ISI}                                   {4.2F!!}
                     qq.Use_ISI := False;                        {4.2F!!}
                  {$endif}                                       {4.2F!!}
               End Else                                          {4.2F!!}

            {$ifdef ISI}                                         {4.2F!!}
            If (Copy(Temp,1,4) = '/ISI') and                     {4.2F!!}
               (Length(Temp)=5) and                              {4.2F!!}
               (Temp[5] in ['1'..'8']) Then                      {4.2F!!}
               Begin                                             {4.2F!!}
                  Override_Port := True;                         {4.2F!!}
                  Override_Port_Num := Ord(Temp[5])-Ord('1')+1;  {4.2F!!}
                  qq.Use_ISI := True;                            {4.2F!!}
               End Else                                          {4.2F!!}
            {$endif}                                             {4.2F!!}

            {$ifdef Int14}
               {$ifdef Cross}
                  If Temp = '/CROSS14' Then
                     Begin
                        Int14 := True;
                        SetupInt1C;
                        RAL := $FF;
                        RAH := $C1;
                        Int14BIOS;
                        If RAL <> 0 then
                           Begin
                              Writeln ('Please load NETDEV before starting Qmodem.');
                              Halt;
                           End
                        Else
                           CTS_ := True;
                     End Else
               {$endif Cross}

               {$ifdef JNL}
                  If Temp = '/JNL14' Then
                     Begin
                        If v <> 0 then
                           RRim := False;

                        Int14 := True;
                        SetupInt1C;
                        CTS_ := True;
                     End Else
               {$endif JNL}

               {$ifdef Plus}
                  If Temp = '/PLUS14' Then
                     Begin
                        Int14 := True;
                        SetupInt1C;
                        CTS_ := True;
                     End Else
               {$endif Plus}

               {$ifdef Basic}
                  If Temp = '/INT14' Then
                     Begin
                        Int14 := True;
                        SetupInt1C;
                        CTS_ := True;
                     End Else
               {$endif Basic}

            {$endif}

            If Temp = '/HOST' Then
               AutoHost := True Else

            If Temp = '/R' Then
               Restart_Invoked := True Else

            If Copy(Temp,1,3) = '/S=' Then
               Begin
                  Auto_Script := True;
                  Auto_Script_Name := Copy(Temp, 4, Length(Temp) - 3);
               End Else

            If Copy(Temp,1,9) = '/VEGAVGA=' Then
               SetVEGAVGA(Copy(Temp,10,Length(Temp)-9)) Else

            If Copy(Temp,1,5) = '/VGA=' Then
               SetVGA(Copy(Temp,6,Length(Temp)-5)) Else

            {$ifdef ALPHA}
            If Copy(temp,1,3) = '/?=' Then
               GetRegC := Str2Word(Copy(Temp, 4, Length(Temp) - 3),CGetreg) Else
            {$endif}

            Begin
               If not First then
                  Begin
                     Write ('Cmd line option(s) ');
                     First := True;
                     Pause := True;
                  End
               Else
                  Write (', ');
               Write('"',TEMP,'"');
            End;
         End;
      If Pause then
         Begin
            Writeln(' not recognized.');
            Delay(4000);
         End;
      {$ifdef Int14}
         {$ifdef JNL}
         If not RRim then
            Begin
               Writeln ('Please load the INT14 RRIM before starting Qmodem with the /INT14 Switch.');
               Halt;
            End;
         If v <> 0 then
            Begin
               Writeln ('Please load the NCA RRIM before starting Qmodem.');
               Halt;
            End;
         {$endif}
      {$endif}

   End;



Function Test_Host_Carrier : Boolean;
var
   Ch : Char;
Begin
   If Online Then
      Begin
         Setwindow2(11, 11, 70, 14, ' Warning!  Carrier Detected! ',false);
         TextAttr := qq.Menu;
         Display_Status(' Y-Start HOST anyway   N-Return to TERMINAL Mode ');
         Writeln(' You are either ONLINE or your modem is set incorrectly.');
         Write  (' Are you sure you want to start the HOST ? [Y/N] ');
         Repeat
            CH := Upcase(Char(ReadKeyA));
         Until CH In ['Y', 'N',#27];
         Restore_Screen;
         Test_Host_Carrier := Ch <> 'Y';
      End
   Else
      Test_Host_Carrier := False;
End;

Procedure Check_Host_Hangup_Routine;
Var
   x : Word;
Begin
   If Online Then
      Begin
         x := 0;
         While (x < 3) and Online do
            Begin
               Delay(3000);
               If not Online then
                  Exit;
               HangupPrim;
               Inc(x);
            End;
         Setwindow2(11, 11, 71, 17, ' Warning!  Host did not drop Carrier! ',false);
         TextAttr := qq.Menu;
         Writeln(' The Modem did not hangup when it should have!  Check your');
         Writeln(' Alt-N/M/M/H (Hangup) string to be sure it will hangup and');
         Writeln(' drop the current call.');
         Writeln;
         Write  (' Attempting Hangup command again...  Any key to ABORT > ');
         Repeat
            Delay(1000);
            Hangupprim;
            Delay(1000);
         Until (not Online) or KeyPressed;
         If KeyPressed then
            Begin
               ForceHost := True;
               Ch := Char(ReadKeyA);
            End;
         Restore_Screen;
      End;
End;


Procedure BS_DEL_Switch;
Begin
  If qq.BS_DEL_Swap = 'Y' Then
     Begin
        Writelnt('Backspace is ^H');
        qq.BS_DEL_Swap := 'N';
        If QuickLearn then
           Writelearn ('TurnOFF  BS_DEL');
     End
  Else
     Begin
        Writelnt('Backspace is DEL');
        qq.BS_DEL_Swap := 'Y';
        If QuickLearn then
           Writelearn ('TurnON   BS_DEL');
     End
End;

Procedure Echo_toggle;
Begin
  If Split then Exit;
  Echo := Not Echo;
  If Echo Then Writelnt('Half Duplex')
          Else Writelnt('Full Duplex');
  If QuickLearn then
     If Echo then WriteLearn('TurnON   ECHO')
             else WriteLearn('TurnOFF  ECHO');
End;

Procedure Doorway_toggle;
Begin
  Doorway := Not Doorway;
  If Doorway Then Writelnt('Doorway ON')
             Else Writelnt('Doorway OFF');
  If QuickLearn then
     If Doorway then WriteLearn('TurnON   DOORWAY')
                else WriteLearn('TurnOFF  DOORWAY');
End;

Procedure Scroll_toggle;
Begin
  save_scroll := Not save_scroll;
  If save_scroll Then Writelnt('Scroll Back ON')
                 Else Writelnt('Scroll Back OFF');
  If QuickLearn then
     If Save_Scroll then WriteLearn('TurnON   SCROLL')
                    else WriteLearn('TurnOFF  SCROLL');
End;

Procedure Hi_Bit_Toggle;
Begin
  Hi_Bit := Not Hi_Bit;
  If Hi_Bit Then Writelnt('Hi-Bit ON')
            Else Writelnt('Hi-Bit OFF');
  If QuickLearn then
     If Hi_Bit then WriteLearn('TurnON   8_BIT')
               else WriteLearn('TurnOFF  8_BIT');
End;

Procedure Addlf_toggle;
Begin
  addlf := Not addlf;
  If addlf Then Writelnt('Add LF ON')
           Else Writelnt('Add LF OFF');
  If QuickLearn then
     If AddLf then WriteLearn('TurnON   LINEFEED')
              else WriteLearn('TurnOFF  LINEFEED');
End;

Procedure Noise_toggle;
Begin
  noise := Not noise;
  If noise Then Writelnt('Beeps & Bells ON')
           Else Writelnt('Beeps & Bells OFF');
  If QuickLearn then
     If Noise then WriteLearn('TurnON   NOISE')
              else WriteLearn('TurnOFF  NOISE');
End;

Procedure Prtlog_toggle;
Begin
   PrtLog := Not PrtLog;
   If PrtLog Then Writelnt('Printer ON')
             Else Writelnt('Printer OFF');
   If PrtLog Then OpenPrinter(PrtlogLst, qq.PrinterID)
             Else ClosePrinter(PrtlogLst);
   If QuickLearn then
      If PrtLog then WriteLearn('TurnON   PRINT')
                else WriteLearn('TurnOFF  PRINT');
End;

Procedure Xon_Xoff_Toggle;
Begin
  Xon_Xoff := Not Xon_Xoff;
  If Xon_Xoff Then Writelnt('Xon/Xoff ON')
              Else Writelnt('Xon/Xoff OFF');
  If QuickLearn then
     If Xon_Xoff then WriteLearn('TurnON   XON/XOFF')
                 else WriteLearn('TurnOFF  XON/XOFF');
End;

Procedure ANSI_Music;
Begin
  Music_flag := Not Music_flag;
  If Music_flag Then Writelnt('Music ON')
                Else Writelnt('Music OFF');
  If QuickLearn then
     If Music_Flag then WriteLearn('TurnON   MUSIC')
                   else WriteLearn('TurnOFF  MUSIC');
End;

Procedure Setup3;
Var
   s : String;
   f : File;
   {$ifdef ISI}
      Save_ISI : Boolean;
   {$endif}
Begin
   Readptr  := 0;
   Writptr  := 0;
   Readptr2 := 0;
   Writptr2 := 0;

   {$ifdef ISI}
      If (qq.ISI_BASE > 0) and (qq.ISI_IRQ > 0) then
         Begin
            Save_ISI := qq.Use_ISI;
            qq.Use_ISI := True;
            Init_la_Port;
            Remove_Port;
            qq.Use_ISI := Save_ISI;
         End
      Else
         qq.Use_ISI := False;
   {$endif}

   If Override_Port then
      qq.Commport := Override_Port_Num;

   Initialize_Comm_Vars;

   SetPickColors;
   SetHelpColors;
   SetVerticalPick;
   TpDir.ShowSizeDateTime := True;
   TpPick.PickSrch := StringPickSrch;

   {Remove the QMODEM.$$$ if it exists}
   S := qq.SwapDirectory + QMODEM_SWP;
   If ExistFile(s) then
      Begin
         Assign(f,s);
         Erase(f);
      End;
End;

Procedure Hangup;
Var
   Ch : Char;
Begin
   If not (Scripting or Hosting) and qq.GuardHangup then
      Begin
         SetWindow2(27, 11, 53, 13, ' Hangup ',false);
         HelpTopic := 35;
         TextAttr  := qq.Menu;
         Display_Status(' Y-Hang Up the Connection   N-Exit ');
         Write (' Hangup Modem? [Y/n] ');
         Repeat
            Ch := Upcase(Char(ReadKeyA));
         Until Ch In ['Y', 'N', #27, #13];
         If Ch = #13 then Ch := 'Y';
         TextAttr := qq.Menu;
         Case CH Of
            'Y' : Write('Yes');
            'N',
            #27 : Write('No');
         End;
         Delay(400);
         Restore_Screen;
      End;
   If (Ch = 'Y') or Scripting or Hosting or (not qq.GuardHangup) then
      Begin
         Screen_Mode_Check;
         Logit('Hangup Command entered');
         Writelnt('Sending Hang-Up command');
         HangupPrim;
         If Split Then set_split;
         If QuickLearn then
            WriteLearn('HangUp');
      End;
End;


Procedure Setup_Memory_Allocations;
Begin
   Getmem(Buffer01, qqmaxbuf * 128);
   If Buffer01 = NIL then
      Begin
         Writeln('Error allocating DOWNLOAD Buffer!');
         Keycontinue(TextAttr);
      End;
End;


Procedure Clear_All_ScrollBack;
Var
   P : Scroll_Ptr;
Begin
   While {(CurrentScrollHeap > 0) and} (ScrollFirst <> Nil) Do
      Begin
         P := ScrollFirst;
         ScrollFirst := ScrollFirst^.Next;
         FreeScrollHeap(SizeOf(P^));
         Freemem(P, SizeOf(P^));
      End;
   ScrollFirst := Nil;
   ScrollLast := Nil;
End;


Procedure Show_Ready_Msg;
Var
   Ch : Char;
   x, TotalMS : Word;

   Procedure Scroll_Mem;
   Var
      P : Scroll_Ptr;
      x : LongInt;
   Begin
      If InitStats then
         Write('Scroll-Back lines available : ');
      x := 0;
      Clear_All_ScrollBack;
      While (MaxAvail > 1024*27) and
            (x < qq.MaxScrollLines) and
            GetScrollHeap(SizeOf(P^)) do
         Begin
            GetMem(P, SizeOf(P^));
            If P <> NIL then
               Begin
                  P^.Prev := Nil;           { reset prev pointer          }
                  P^.Next := Nil;           { reset next pointer          }
                  If ScrollFirst = Nil Then { starting with a new list    }
                     ScrollFirst := P       { assign first to new node    }
                  Else                      { adding a node to a list     }
                     Begin
                        P^.Prev := ScrollLast; { set prev to last node       }
                        ScrollLast^.Next := P; { set last's next to new node }
                     End;
                  ScrollLast := P;         { set last to new node        }
                  Inc(x);
               End
         End;
      If InitStats then
         Writeln(x);
      Clear_All_ScrollBack;
      qqMaxScrollHeap := LongInt(x) * 170;
      MaxScroll := x;
      DoScrollBack := True;
   End;

   Procedure Do_Modm_Init;
   Begin
      Delay(500);
      Clear_Buffer;
      Parse_Write_Modem(qq.ModmInit);
      Delay(500);
   End;

Begin
   Setup3;
   {$IfNDef Bundle}
      If not IsRegisteredOK then
         Begin
            Window(1, 1, ScreenWidth, ScreenHeight);
            ClrScr;
            Halt;
         End;
   {$EndIf}

   Music_Set;

   Writelnb(_Qmodem_+' ' + version + Compile_Date);
   Writelnb(CopyrightString);
   {$IfNDef Bundle}
   Writelnb('Registered to : ' + BOARD);
   {$EndIf}

   Init_Port;
   Clear_Buffer;
   Term_ready(True);

   TextAttr := qq.InfoColor;
   qqMaxBuf := qq.MaxBuf;

   Setup_Memory_Allocations;
   Scroll_Mem;
   NormalCursor;

   TextAttr := qq.InfoColor;

   {$IfNDef Int14}
   If Not (B8250
           or B16450
           or B16550
           or B16550A
           {$ifdef ISI}
              or qq.Use_ISI
           {$endif}
           ) then
     Writeln ('Error determining UART, possible failure or incorrect Port selected')
   Else
      If InitStats then
      Begin
        {$ifdef ISI}
        If qq.Use_ISI then
           Begin
              If ISI_Port_Count > 0 then
                 Writeln ('ISI ',ISI_Port_Count,' Port installed')
              Else
                 Writeln ('Error determining ISI Port Count');
           End
        Else
        {$endif}
           If B8250 or B16450 then
              Begin
                 If B8250 then Write('8250') else Write('8250A/16450');
                 Writeln (' UART detected');
              End
           Else
              If B16550 or B16550A then
                 Begin
                    Write('16550');
                    If B16550A then Write('A');
                    Writeln(' UART detected and FIFO enabled');
                 End;
      End;
  {$endif}

  {$ifdef UseMouse}
   If qq.UseMouse then
      If not MouseInstalled then
         If InitStats then
            Writeln ('No Mouse driver detected');
  {$endif}

   If InitStats then
      {If EnhancedKBDinstalled then
         WriteLn ('Enhanced KBD detected');}

   {$ifdef OVR}
      OVRproblem;
   {$endif}

   (* 
   If not qq.DoRecalibrate then
      Begin
         TotalMS := 0;
         For x := 1 to 5 do
            Begin
               DelayCalibrate;
               Inc(TotalMS,OneMS);
            End;
         OneMS := TotalMS div 5;
      End;
   *)
   
   If Restart_Invoked Then
      Writelnb('/R Restart, Modem Init not sent')
   Else
      If qq.ModmInit <> '' then
         Begin
            If Not Online or qq.IgnoreCD Then
               Do_Modm_Init
            Else
               If not Auto_Script then
                  Begin
                     Write ('CARRIER DETECTED, Send modem initialization [Y/N] ? ');
                     Ch := Get_Yes_No;
                     If UpCase(Ch) = 'Y' then
                        Do_Modm_Init;
                     Writeln;
                  End;
         End;
End;


Procedure Capture_Toggle(TempF : String; CloseOnly : Boolean);
Var
   Ok : Boolean;
Begin                          {Capture}
   If Capture Then
      Begin                    {turn capture off }
         Capture := False;
         Writelnt('Capture File Closed');
         {Writeln (Capture_File, '');}
         Write   (Capture_File, ^Z);
         Close   (Capture_File);
         IO := IoResult;
         If QuickLearn then WriteLearn('TurnOFF  Capture');
         If CloseOnly Then Exit;
      End;
   Ok := True;
   If Not Scripting Then
      TempF := Get_File_Name('', CaptureF, 'CAP', 2,
                             'Capture File Allocation',True);
   Screen_Mode_Check;
   If TempF = '' Then Exit;
   CaptureF := TempF;
   If Not ExistFile(TempF) Then
      Begin
         Assign(Capture_File, TempF);
         SetTextBuf(Capture_File,CapFileBuf);
         Rewrite(Capture_File);
         IO := IoResult;
         If IO = 0 Then
            Close(Capture_File)
         Else
            Begin
               WriteLn;
               Writelnb('Error creating the Capture file');
               Writelnb('Probable cause: invalid filename');
               Ok := False;
               Capture := False; { turn it off }
            End;
      End;
   If Ok Then
      Begin
         Capture := True;      { turn it on! }
         Assign(Capture_File, TempF);
         SetTextBuf(Capture_File,CapFileBuf);
         Append(Capture_File);
         IO := IoResult;
         If (IO <> 0) or (not TimeDateStamper(Capture_File)) Then
            Begin
               WriteLn;
               Writelnb('Error appending to Capture file');
               Writelnb('Probable cause: invalid filename');
               Capture := False;
            End;
      End;
   Screen_Mode_Check;
   If Capture Then
      Begin
         IO := IoResult;
         If Not Help_Last Then
            Writelnt('Capture ON');
         If QuickLearn then WriteLearn('Capture  '+TempF);
      End
   Else
      If Not Help_Last Then
         Writelnt('Capture OFF');
   If Split Then
      set_split;
End;


{$IfNDef Bundle}
Procedure Register_Copy;
Var
   T        : String;
   N, rc, X : Integer;
   DummyStr : String[255];
   DummyLen : Byte absolute DummyStr;
Begin
   Assign(MyCode, QMODEM_EXE); {This is the program's name}
   Reset(MyCode, 1);
   MyCodeSize := FileSize(MyCode); { size in bytes }
   Dec(MyCodeSize,255);
   DummyLen := 255;
   Seek(MyCode,MyCodeSize);
   BlockRead(MyCode,DummyStr[1],255);
   While (Pos(Board_Ptr,DummyStr) = 0) and (MyCodeSize > 0) do
      Begin
         Dec(MyCodeSize,64);
         Seek(MyCode,MyCodeSize);
         BlockRead(MyCode,DummyStr[1],255);
      End;

   If MyCodeSize < 256 then
      Begin
         WriteLn;
         WriteLn('þ Error in Registration Code');
         Cursor_Emul := Cursor_Emul And $FE;
         Halt;
      End;

   Seek(MyCode, MyCodeSize);
   BlockRead(MyCode, Sector_Code, 256);
   Start_Name := Pos(Board_Ptr,DummyStr)+Length(Board_Ptr);
   Start_Reg  := Start_Name + 61;              {4.2G!!}
   Clrscr;                                     {4.2G!!}
   Writeln('þ QMODEM REGISTRATION þ');         {4.2G!!}
   WriteLn('þ Registered to: ', BOARD);
   Write  ('þ Please enter your Registration Name   : ');
   BufLen := 50;
   ReadLn(BOARD);
   Write  ('þ Please enter your Registration Number : ');
   T := '';
   Repeat
      CH := Upcase(Char(ReadKeyA));
      Case CH Of
         '0'..'9' : If Length(T) < 7 Then
                       Begin
                          T := T + CH;
                          Write(CH);
                       End;
         #8, #127 : If Length(T) > 0 Then
                       Begin
                          Write(#8#32#8);
                          T[0] := Chr(Byte(T[0]) - 1);
                       End;
      End;
   Until CH = #13;
   WriteLn;
   Val(T, Reg_Number, rc);
   Check_Reg  := GetReg;
   Garbage[1] := GetReg mod 12;
   Garbage[3] := (GetReg * GetReg) mod 13;
   Garbage[8] := GetReg mod 14;
   If Reg_Number = Check_Reg Then
      Begin
         For N := 0 To Length(BOARD) Do
            Sector_Code[Start_Name + N] := BOARD[N]; {This rev's the Code}
         Sector_Code[Start_Reg] := Chr(Lo(Reg_Number));
         Sector_Code[Start_Reg + 1] := Chr(Hi(Reg_Number));
         For x := 1 to 8 do
            Sector_Code[Start_Reg-11+x] := Chr(Garbage[x]);
         Reset(MyCode, 1);
         Seek(MyCode, MyCodeSize);
         BlockWrite(MyCode, Sector_Code, 256);
         Close(MyCode);
         WriteLn('þ Now registered to : ', BOARD);
         Delay(1000);
         IsRegisteredOK := True;
      End
   Else
      Begin
         WriteLn('þ Invalid Registration Number'); {Wrong Number}
         Cursor_Emul := Cursor_Emul And $FE;
         Halt;
      End;
End;
{$EndIf}


End.
