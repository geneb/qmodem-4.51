Unit Menus;

Interface

Uses
   TpCrt,     TpString,  TpEdit,    TpDate,
   TpPick,    Initial,   Procs,     TpEntry,
   Files,     BinFSE,    Screen,    TPInline;


Var
   ReviseNumber   : Integer;


Function  GetSortSelection(Col, Row : Integer) : Integer;
Function  GetParitySelection(Col, Row : Integer) : Char;
Function  GetPortSelection(Col, Row : Integer) : Byte;
Function  GetBaudSelection(Col, Row : Integer) : LongInt;
Function  GetSBitsSelection(Col, Row : Integer) : Integer;
Function  GetDBitsSelection(Col, Row : Integer) : Integer;
Function  GetCRSelection(Col, Row : Integer) : Byte;
Function  GetLFSelection(Col, Row : Integer) : Byte;
Function  GetEmulationSelection(Row, Col : Integer) : Integer;
Function  NewReviseFonEntry(IsRevise: Boolean) : Boolean;  {!!4.2G}
Procedure NewGetPrefixes;
Procedure Edit_Integer_Window(c1, r1      : Byte;
                               Wide       : Byte;
                               NLo, NHi   : Integer;
                               Var I      : Integer);
Procedure Edit_LongInt_Window(c1, r1      : Byte;
                               Wide       : Byte;
                               NLo, NHi   : LongInt;
                               Var I      : LongInt);

Function  Edit_String_Window_UC(c1, r1       : Byte;
                                Wide         : Byte;
                                ScreenWide   : Byte;
                                Var S        : String) : Boolean;

Function  Edit_String_Window_Mixed(c1, r1       : Byte;
                                   Wide         : Byte;
                                   ScreenWide   : Byte;
                                   Var S        : String) : Boolean;

Procedure Edit_String_Window2(c1, r1       : Byte;
                              Wide         : Byte;
                              ScreenWide   : Byte;
                              Var S        : String);


Implementation


Var
   Zmenu, Emenu : Menu;
   Zkey,  Ekey  : MenuKey;
   Ohelp : word;
Const
   Frame2 : FrameArray = 'ีิธพอณ';


   Procedure Edit_Integer_Window(c1, r1   : Byte;
                                 Wide     : Byte;
                                 NLo, NHi : Integer;
                                 Var I    : Integer);
   Var
      Escaped        : Boolean;
   Begin
      ClearFirstChar := True;
      EditSize := Wide;
      ReadInteger('', Succ(r1), c1 + 2, Wide,
                  0,
                  qq.editf,
                  NLo, NHi,
                  Escaped, I);
      FastWrite(PadCh(Long2Str(I), ' ', Wide), Succ(r1), c1 + 2, qq.Qcolor1[SelectColor]);
      ClearFirstChar := False;
   End;

   Procedure Edit_LongInt_Window(c1, r1   : Byte;
                                 Wide     : Byte;
                                 NLo, NHi : LongInt;
                                 Var I    : LongInt);
   Var
      Escaped        : Boolean;
   Begin
      ClearFirstChar := True;
      EditSize := Wide;
      ReadLongInt('', Succ(r1), c1 + 2, Wide,
                  0,
                  qq.editf,
                  NLo, NHi,
                  Escaped, I);
      FastWrite(PadCh(Long2Str(I), ' ', Wide), Succ(r1), c1 + 2, qq.Qcolor1[SelectColor]);
      ClearFirstChar := False;
   End;

   Function Edit_String_Window_UC(c1, r1         : Byte;
                                  Wide           : Byte;
                                  ScreenWide     : Byte;
                                  Var S          : String) : Boolean;
   Var
      Escaped        : Boolean;
      SaveUpper      : Boolean;
   Begin
      Edit_String_Window_UC := True;
      EditSize := ScreenWide;
      SaveUpper := ForceUpper;
      ForceUpper := TRUE;
      ReadString('', Succ(r1), c1 + 2, Wide, 0,
                 qq.editf,
                 qq.Qcolor1[HiliteColor],
                 Escaped, S);
      If Escaped Then
         Edit_String_Window_UC := False;
      ForceUpper := SaveUpper;
      FastWrite(PadCh(Slength(S, ScreenWide), 'ฐ', ScreenWide), Succ(r1), c1 + 2, qq.Qcolor1[SelectColor]);
   End;


   Function Edit_String_Window_Mixed(c1, r1         : Byte;
                                     Wide           : Byte;
                                     ScreenWide     : Byte;
                                     Var S          : String) : Boolean;
   Var
      Escaped   : Boolean;
      SaveUpper : Boolean;
   Begin
      Edit_String_Window_Mixed := True;
      EditSize := ScreenWide;
      SaveUpper := ForceUpper;
      ForceUpper := False;
      ReadString('', Succ(r1), c1 + 2, Wide, 0,
                 qq.editf,
                 qq.Qcolor1[HiliteColor],
                 Escaped, S);
      If Escaped Then
         Edit_String_Window_Mixed := False;
      ForceUpper := SaveUpper;
      FastWrite(PadCh(Slength(S, ScreenWide), 'ฐ', ScreenWide), Succ(r1), c1 + 2, qq.Qcolor1[SelectColor]);
   End;

   Procedure Edit_String_Window2(c1, r1         : Byte;
                                 Wide           : Byte;
                                 ScreenWide     : Byte;
                                 Var S          : String);
   Var
      Escaped        : Boolean;
      SaveUpper      : Boolean;
   Begin
      EditSize := ScreenWide;
      SaveUpper := ForceUpper;
      ForceUpper := False;
      ReadString('', Succ(r1), c1 + 2, Wide, 0,
                 qq.editf,
                 qq.Qcolor1[HiliteColor],
                 Escaped, S);
      If Escaped Then
         S := '';
      ForceUpper := SaveUpper;
      FastWrite(PadCh(Slength(S, ScreenWide), 'ฐ', ScreenWide), Succ(r1), c1 + 2, qq.Qcolor1[SelectColor]);
   End;


   Function  GetBaudSelection(Col, Row : Integer) : LongInt;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      If not PickWindow (@BaudsAvailable,
                         10,
                         Col, Row, Col+9,Row+11,
                         True,
                         PickColors,
                         ' Baud ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            Begin
               Case Choice of
                  1 : GetBaudSelection := 110;
                  2 : GetBaudSelection := 300;
                  3 : GetBaudSelection := 1200;
                  4 : GetBaudSelection := 2400;
                  5 : GetBaudSelection := 4800;
                  6 : GetBaudSelection := 9600;
                  7 : GetBaudSelection := 19200;
                  8 : GetBaudSelection := 38400;
                  9 : GetBaudSelection := 57600;
                 10 : GetBaudSelection :=115200;
               End;
            End
         Else
            GetBaudSelection := 0;
   End;


   Function  GetParitySelection(Col, Row : Integer) : Char;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      If not PickWindow (@ParitysAvailable,
                         5,
                         Col, Row, Col+10,Row+Succ(5),
                         True,
                         PickColors,
                         ' Parity ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            Case Choice of
               1 : GetParitySelection := 'N';
               2 : GetParitySelection := 'E';
               3 : GetParitySelection := 'O';
               4 : GetParitySelection := 'M';
               5 : GetParitySelection := 'S';
            End
         Else
            GetParitySelection := ' ';
   End;


   Function  GetPortSelection(Col, Row : Integer) : Byte;
   Var
      CH : Char;
      z,y,x, Choice : Word;
   Begin
      Choice := 1;
      x := 0;
      for y := 1 to 8 do
         if qq.irq[y] <> 0 then Inc(x);
      {$IfDef ISI}
      Inc(x,ISI_Port_Count);
      {$EndIf}
      If not PickWindow (@PortsAvailable,
                         x,
                         Col, Row, Col+29,Row+x+1,
                         True,
                         PickColors,
                         ' Ports ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            Begin
               z := 0;                      {4.2F!!}
               for y := 1 to 8 do
                  If qq.irq[y] <> 0 then
                     Begin
                        Inc(z);             {4.2F!!}
                        If z = Choice then  {4.2F!!}
                           Begin
                              {$IfDef ISI}
                              qq.Use_ISI := False;
                              {$EndIf}
                              GetPortSelection := y;
                              Exit;
                           End;
                     End;
               {$IfDef ISI}
               Choice := Choice - (x - ISI_Port_Count);
               For y := 1 to ISI_Port_Count do
                  If y = Choice then
                     Begin
                        GetPortSelection := y;
                        qq.Use_ISI := True;
                        Exit;
                     End;
               {$EndIf}
            End
         Else
            GetPortSelection := 0;
   End;


   Function  GetDBitsSelection(Col, Row : Integer) : Integer;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      If not PickWindow (@DBitsAvailable,
                         2,
                         Col, Row, Col+10,Row+Succ(2),
                         True,
                         PickColors,
                         'Dbits',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            Case Choice of
               1 : GetDBitsSelection := 8;
               2 : GetDBitsSelection := 7;
            End
         Else
            GetDBitsSelection := 0;
   End;


   Function  GetSBitsSelection(Col, Row : Integer) : Integer;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      If not PickWindow (@SBitsAvailable,
                         2,
                         Col, Row, Col+10,Row+Succ(2),
                         True,
                         PickColors,
                         'Sbits',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            GetSBitsSelection := Choice
         Else
            GetSBitsSelection := 0;
   End;

   Function  GetSortSelection(Col, Row : Integer) : Integer;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      Display_Status (' NUMBER-Pick a method to Sort By   ESC-Exit ');
      If not PickWindow (@SortAvailable,
                         3,
                         Col, Row, Col+31,Row+Succ(3),
                         True,
                         PickColors,
                         ' Sort FON By: ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            GetSortSelection := Choice
         Else
            GetSortSelection := 0;
   End;


   Function  GetCRSelection(Col, Row : Integer) : Byte;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      If not PickWindow (@CRAvailable,
                         3,
                         Col, Row, Col+10,Row+Succ(3),
                         True,
                         PickColors,
                         '',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            GetCRSelection := Choice
         Else
            GetCRSelection := 0;
   End;

   Function  GetLFSelection(Col, Row : Integer) : Byte;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      If not PickWindow (@LFAvailable,
                         3,
                         Col, Row, Col+10,Row+Succ(3),
                         True,
                         PickColors,
                         '',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            GetLFSelection := Choice
         Else
            GetLFSelection := 0;
   End;

Var
   ScrapFON : Phone_Type;

   {$F+}
   procedure DisplayHelpPrompt(var ESR : ESrecord);
     {-Display a help prompt for the current field}
   var
     S : string[80];
   Const
      m = '               [F10] Save   [ESC] Abort ';
      n = '   [F2] Pick   [F10] Save   [ESC] Abort ';
      o = '   [F2] Edit   [F10] Save   [ESC] Abort ';
   begin
     case ESR.CurrentID of
        00 : S := Pad(' Change the NAME field',32) + m;
        01 : S := Pad(' Change the Telephone number',32) + m;
        02 : S := Pad(' Change the Password',32) + m;
        03 : S := Pad(' Change the Linked Script',32) + o;
        04 : Begin
                S := Pad(' Change the Baud rate',32) + n;
                If (ScrapFON.ComSpeed < 110) or
                   (ScrapFON.ComSpeed > 115200) then
                    ScrapFON.ComSpeed := 0;
             End;
        05 : S := Pad(' Change the Data bits - 7/8',32) + m;
        06 : S := Pad(' Change the Parity',32) + n;
        07 : S := Pad(' Change the Stop bits - 1/2',32) + m;
        08 : S := ' Change Duplex - (H)alf / (F)ull' + m;
        09 : S := Pad(' Change the Transfer Protocol',32) + m;
        10 : S := Pad(' Change the Last Call date',32) + m;
        11 : S := Pad(' Change the Times On',32) + m;
     end;
     Display_Status(S);
   end;
   {$F-}


   {Field Edit ESR Template}

   Function NewReviseFonEntry(IsRevise: Boolean) : Boolean;   {!!4.2G}
   Var
      FESR : ESrecord;
      ExitCommand : EStype;
      X,Y, OldHelp : Integer;
      OK : Boolean;                                        {!!4.2G}
      xl : LongInt;
      Scrap : Phone_Type;
   Label
      Restart;
   Begin
      OK := False;
      Push_Window;
      ScrapFON := Phone_Dir^[ReviseNumber];

      If IsRevise then                                     {!!4.2G}
         SetWindow2(19,6,61,19,' Revise Entry ', False)    {!!4.2G}
      Else                                                 {!!4.2G}
         SetWindow2(19,6,61,19,' Insert Entry ', False);   {!!4.2G}
      FastWrite ('F1 Help',19,52, qq.Windf);

      {                               Screen Layout

      1---+----10---+----20---+----30---+----40---+----50---+----60---+----70
                             ีอออออออออออออ Revise Entry ออออออออออออออธ
                             ณ Name        Sub Line 7              HST ณ
                             ณ Number      233-6035ฐฐฐฐฐฐฐฐฐฐฐ         ณ
                             ณ Password    ฐฐฐฐฐฐฐฐฐฐฐฐฐฐ              ณ
                             ณ Script      SYSOP2ฐฐฐฐฐฐ                ณ
                             ณ Baudrate    19200                       ณ
                             ณ Databits    8                           ณ
                             ณ Parity      None                        ณ
                             ณ Stopbits    1                           ณ
                             ณ Duplex      F                           ณ
                             ณ Protocol    F                           ณ
                             ณ LastCall    03-05-90                    ณ
                             ณ Times On    2402                        ณ
                             ิอออออออออออออออออออออออออออออออออออออออออพ

      }

      {<F10> Alternate DONE key}
      If not AddEntryCommand(ESuser0, 1, $4400, 0) then ;

      {<F2> Pop up a Pick Window}
      If not AddEntryCommand(ESuser1, 1, $3C00, 0) then ;

      InitESrecord(FESR);
      SetFieldAttr(qq.Menu2);
      SetPromptAttr(qq.Menu);
      SetStringAttr(qq.scrollbar);
      SetCtrlAttr(SwapNibble(qq.ScrollBar));
      SetPadChar('ฐ');
      SetPreEditPtr (FESR, @DisplayHelpPrompt);
      SetTrimBlanks(ON);

      AddStringField(FESR, 'Name',      1, 2, '', 1, 14, 27, 2, NIL,
                           ScrapFON.Name);


      AddStringField(FESR, 'Number',    2, 2, CharStr('!',19), 2, 14, 19, 2, NIL,
                           ScrapFON.Number);

      AddStringField(FESR, 'Password',  3, 2, '', 3, 14, 14, 2, NIL,
                           ScrapFON.Password);

      AddStringField(FESR, 'Script',    4, 2, CharStr('!',12), 4, 14, 12, 2, NIL,
                           ScrapFON.Script_File);

      AddLongField  (FESR, 'Baud Rate', 5, 2, '999999', 5, 14, 2,0,115200,
                           ScrapFON.ComSpeed);

      AddIntField   (FESR, 'Data Bits', 6, 2, '9',6, 14, 2, 7, 8,
                           ScrapFON.dbits);

      UserSet1 := ['E','O','N','M','S'];
      ForceCaseUser['1'] := UpperCase;
      AddCharField  (FESR, 'Parity',    7, 2, '1',7, 14, 2, 'N','N',
                           ScrapFON.Parity);

      AddIntField   (FESR, 'Stop Bits', 8, 2, '9',8, 14, 2, 1, 2,
                           ScrapFON.Sbits);

      UserSet2 := ['F','H'];
      ForceCaseUser['2'] := UpperCase;
      AddCharField  (FESR, 'Duplex',    9, 2, '2',9, 14, 2, 'F','F',
                           ScrapFON.Echo1);

      AddCharField  (FESR, 'Protocol', 10, 2, '!',10,14, 2, ' ',' ',
                           ScrapFON.Default_Protocol);

      AddDateField(FESR, 'Last Call',11, 2, qq.DateStr,11, 14, 2,0,0,
                           ScrapFON.Last_Connect);

      AddLongField  (FESR, 'Times On' ,12, 2, '99999', 12 ,14, 2,0,99999,
                           ScrapFON.Times_Called);


      SetEntryWindow(FESR,20,7,60,18, False, qq.Menu, qq.Windf);
      FESR.CurrentID := 0;
      ReStart:
      ExitCommand := EditScreen(FESR, FESR.CurrentID, False);
      If ExitCommand = ESuser1 then
         Begin
            Case FESR.CurrentID of
               3 : Begin
                      If ScrapFON.Script_File <> '' then
                         FSE(FullScriptFilename(ScrapFON.Script_file),
                             0,2,Pred(Last_Row),false);
                   End;

               4 : Begin
                      xl := GetBaudSelection(40,8);
                      If xl <> 0 then
                         ScrapFON.ComSpeed := xl;
                   End;
               6 : Begin
                      Ch := GetParitySelection(40,12);
                      If Ch <> ' ' then
                         ScrapFON.Parity := Ch;
                   End;
            End;
            Goto Restart;
         End;
      If ExitCommand <> ESQuit then
         Begin
            Phone_Dir^[ReviseNumber] := ScrapFON;
            OK := True;                              {!!4.2G}
         End;

      DisposeEditScreen(FESR);

      Restore_Screen;
      Pop_Window;
      NewReviseFonEntry := OK;                       {!!4.2G}
   End;



   Procedure NewGetPrefixes;
   Var
      PESR : ESrecord;
      ExitCommand : EStype;
      X  : Integer;
      Sav : Array[1..10] Of String[30];
   Begin
      Push_Window;

      For x := 1 To 10 Do sav[x] := Prefix[x];
      SetWindow2(20,5,56,16,' Revise Prefixes ', False);
      Display_Status(' Edit Prefix Characters   F10-Save   ESC-Exit with no changes ');
      FastWrite ('F1 Help',16,48, qq.Windf);

      {<F10> Alternate DONE key}
      If not AddEntryCommand(ESuser0, 1, $4400, 0) then ;

      InitESrecord(PESR);
      SetFieldAttr(qq.Menu2);
      SetPromptAttr(qq.Menu);
      SetStringAttr(qq.scrollbar);
      SetCtrlAttr(SwapNibble(qq.ScrollBar));
      SetPadChar('ฐ');

      SetAutoAdvance(Off);
      For x := 1 to 10 do
         AddStringField(PESR, Char(Ord('A')+X-1), x, 2, '', x, 5, 30, 8,
                              NIL, Prefix[x]);
      SetAutoAdvance(On);

      SetEntryWindow(PESR,21,6,55,15, False, qq.Menu, qq.Windf);
      PESR.CurrentID := 0;
      ExitCommand := EditScreen(PESR, PESR.CurrentID, False);

      If ExitCommand = ESQuit then
         For x := 1 To 10 Do Prefix[x] := sav[x] ;

      DisposeEditScreen(PESR);

      Restore_Screen;
      Pop_Window;
   End;


   Function  GetEmulationSelection(Row, Col : Integer) : Integer;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      { show and pick an Emulation }
      If not PickWindow (@EmulationsAvailable,
                         TotalEmulations,
                         Col, Row, Col+15,Row+Succ(TotalEmulations),
                         True,
                         PickColors,
                         ' Emulations ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            GetEmulationSelection:= Choice
         Else
            GetEmulationSelection := 0;
   End;

   {$F+}
   Function ComSetupsAvailable(Item : Word) : String;
   Begin
      Case Item of
         1 : ComSetupsAvailable := ' 110    Baud ';
         2 : ComSetupsAvailable := ' 300    Baud ';
         3 : ComSetupsAvailable := ' 1200   Baud ';
         4 : ComSetupsAvailable := ' 2400   Baud ';
         5 : ComSetupsAvailable := ' 4800   Baud ';
         6 : ComSetupsAvailable := ' 9600   Baud ';
         7 : ComSetupsAvailable := ' 19200  Baud ';
         8 : ComSetupsAvailable := ' 38400  Baud ';
         9 : ComSetupsAvailable := ' 57600  Baud ';
        10 : ComSetupsAvailable := ' 115720 Baud ';
        11 : ComSetupsAvailable := ' Even   Parity ';
        12 : ComSetupsAvailable := ' Odd    Parity ';
        13 : ComSetupsAvailable := ' No     Parity ';
        14 : ComSetupsAvailable := ' Mark   Parity ';
        15 : ComSetupsAvailable := ' Space  Parity ';
        16 : ComSetupsAvailable := ' 7      Data Bits ';
        17 : ComSetupsAvailable := ' 8      Data Bits ';
        18 : ComSetupsAvailable := ' 1      Stop Bits ';
        19 : ComSetupsAvailable := ' 2      Stop Bits ';
      End;
   End;
   {$F-}

   Function  ComSetupSelection : Integer;
   Var
      CH : Char;
      Choice     : Word;
   Begin
      Choice := 1;
      If not PickWindow (@ComSetupsAvailable,
                         19,
                         10, 2, 31,22,
                         True,
                         PickColors,
                         ' Pick a new Setting ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            ComSetupSelection := Choice
         Else
            ComSetupSelection := 0;
   End;

End.
