{$I TpDEFINE.INC}

Unit Install2;

Interface

Uses
   Dos,       TPString,    TpCrt,      TpDOS,
   TPWindow,  TpEdit,      TPMenu,     Files,
   Screen,    OpKey,
   {$IFDEF UseMouse}
   TpMouse,
   {$ENDIF}
   TpPick,    Initial,     Constant,
   Procs,     Menus,       Comm, Comm2;


Function  Get_Color(num, ColorAttr : Byte) : Byte;
Procedure Set_Blue_Shades;
Procedure Set_Purple_Shades;
Procedure Set_Red_Shades;
Procedure Set_Mono_Shades;
Procedure Set_LCD_Shades;
Procedure Select_Baud_Rate;
Procedure Select_DataBits;
Procedure Select_Emulation;
Procedure Select_Hostmode;
Procedure Select_Parity;
Procedure Select_StopBits;
Procedure Select_Com_Port;
Procedure Edit_CharScroll_Window(Col, Row : Integer; Var x : Integer);
Function  CharScrollStr (x : Integer) : String;
Procedure Pick_and_Set_Modem;
Procedure Pick_and_Set_Colors;


Implementation



Function  Parse_String(S : String) : String;
Var
   x : integer;
   s2 : String;
Begin
   x := 1;
   s2 := '';
   While x <= Length(S) Do
      Begin
         Case S[x] Of
            '^' : If x < Length(S) Then
                     Case S[x + 1] Of
                        '^' : Begin { place this first to trap for ^ }
                                 Inc(x);
                                 s2 := s2 + '^';
                              End;
                        'a'..'z',
                        '@'..
                        '_' : Begin
                                 Inc(x);
                                 s2 := s2 + Chr(Ord(UpCase(S[x])) - 64);
                              End;
                        Else  s2 := s2 + '^';
                     End
                  Else
                     s2 := s2 + '^';
            Else  s2 := s2 + S[x];
         End;                  { case }
         Inc(x);
      End;
   Parse_String := s2;
End;


Procedure PW_ (S : String);
Var
   x     : Integer;
   CH    : Char;
   Skip  : Boolean;
Begin
   x := 1;
   Skip := False;
   While x <= Length(S) Do
      Begin
         Case S[x] Of
            '^' : If x < Length(S) Then
                     Case S[x + 1] Of
                        '^' : Begin { place this first to trap for ^ }
                                 Inc(x);
                                 CH := '^';
                              End;
                        '~' : Begin
                                 Delay(600);
                                 Inc(x);
                                 Skip := True;
                              End;
                        'a'..'z',
                        '@'..
                        '_' : Begin
                                 Inc(x);
                                 CH := Chr(Ord(UpCase(S[x])) - 64);
                              End;
                        Else  CH := '^';
                     End
                  Else
                     CH := '^';
         Else
            CH := S[x];
         End;                  { case }
         If Echo And (Not Split) And (Not Redialing) Then
            Write(Ch);
         If Not Online then
            Delay(5);
         If Skip Then Skip := False
                 Else Write_Byte(CH);
         Inc(x);
      End;
End;


Procedure Parse_Write_Modem(S : String);
Begin
   PW_(S);
End;





   Procedure BuildModemList;
   Var
      rec  : String;
      p, q : ModemListPointer;
      MDF  : String;
      f    : text;
   Begin
      MDF := SearchName(QMODEM_MDF);
      If not ExistFile(MDF) then
         Begin
            Writelnt(' Modem Config Data file '+QMODEM_MDF+' not found ');
            Exit;
         End;
      Assign (f, MDF);
      Reset  (f);
      ModemTotalCount := 0;
      IO := IOresult;
      While not EOF(f) do
         Begin
            Readln(f, rec);
            If (rec[1] = '@') and (Rec <> '') then
               Begin
                  GetMem(p, SizeOf(p^));
                  If p <> NIL then
                     Begin
                        ModemListBuilt := True;
                        Inc(ModemTotalCount);
                        p^.Name := Copy(rec,2,Length(rec)-1);
                        p^.Item := ModemTotalCount;
                        p^.Next := NIL;
                        If MLPhead = NIL then
                           Begin
                              MLPhead := p;
                              q := p;
                           End
                        Else
                           Begin
                              q^.Next := p;
                              q := p;
                           End;
                     End;
               End;
         End;
      Close(f);
      IO := IOResult;
   End;

   Procedure SetupModem(Choice : Word);
   Var
      rec, MDF  : String;
      f         : text;
      x, y, swx, mcx, txx, rsx, Maxbaud : Word;
      sw, tx  : array[1..15] of String[65];
      mc, rs  : array[1..10] of String[40];
      Ch      : Char;
   Const
      BaudList : Array[1..7] of Word = (300,1200,2400,4800,9600,19200,38400);

      Procedure Closing;
      Begin
         TextAttr := qq.Qcolor1[SelectColor];
         GotoXY(1,WhereY);
         Clreol;
         Write (Pad('',20));
         Keycontinue(qq.Qcolor1[SelectColor]);
         Restore_Screen;
      End;


   Begin
      MDF := SearchName(QMODEM_MDF);
      Assign (f, MDF);
      Reset  (f);
      ModemTotalCount := 0;
      HelpTopic := 71;
      x := 0;
      IO := IOresult;
      While not EOF(f) do
         Begin
            Readln(f, rec);
            If rec[1] = '@' then Inc(x);
            If x = Choice then
               Begin
                  FillChar(sw, SizeOf(sw), #0);
                  FillChar(mc, SizeOf(mc), #0);
                  FillChar(tx, SizeOf(tx), #0);
                  FillChar(rs, SizeOf(rs), #0);
                  swx := 0;
                  mcx := 0;
                  txx := 0;
                  rsx := 0;
                  {Now the real config takes place}
                  Readln (f,rec);
                  If Str2Long(Rec, qq.ComSpeed) then; {always assume success}
                  NewSpeed := qq.ComSpeed;
                  Readln (f,rec);
                  qq.Baud_Chng_Before := rec;
                  Readln (f,rec);
                  qq.Baud_Chng_After := rec;
                  Readln (f,rec);
                  If Str2Int(Rec, qq.Dial_Pacing) then; {always assume success}
                  Readln (f,rec);
                  qq.ModmInit := rec;
                  Readln (f,rec);
                  qq.Dial_Prefix := rec;
                  Readln (f,rec);
                  qq.Dial_Postfix := rec;
                  Readln (f,rec);
                  qq.Connect := rec;
                  Readln (f,rec);
                  qq.NoConnect := rec;
                  Readln (f,rec);
                  qq.NoConnect2 := rec;
                  Readln (f,rec);
                  qq.NoConnect3 := rec;
                  Readln (f,rec);
                  qq.NoConnect4 := rec;
                  Readln (f,rec);
                  qq.Cancel_Ch := rec;
                  Readln (f,rec);
                  qq.Modem_Hangup := rec;

     {Ring msg}   Readln (f,rec);
                  qq.Redial_Ring_Msg := rec;
                  qq.Host_Ring_Msg := rec;

     {Host init}  Readln (f,rec);
                  qq.HostInit := rec;

   {Host answer}  Readln (f,rec);
                  qq.Host_Answer := rec;

       {Host OK}  Readln (f,rec);
                  qq.OKmessage := rec;

  {Host OffHook}  Readln (f,rec);
                  qq.HostOffHook := rec;

                  Readln (f,rec);
                  if Rec = '1' then qq.CTSc := 'Y'
                               else qq.CTSc := 'N';
                  Readln (f,rec);
                  if Rec = '1' then qq.LockDTE := False
                               else qq.LockDTE := True;

                  Readln (f,rec);
                  If Str2Int(Rec, qq.DTRdelay) then; {always assume success}


                  qq.NoCTSdrop := False;

                  {switch and other stuff here}

                  Repeat
                     Readln (f, rec);
                     If rec <> '' then
                        Case Rec[1] of
                           '$' : Begin
                                    inc(swx);
                                    sw[swx] := Copy(rec,2,Length(rec)-1);
                                 End;
                           '^' : Begin
                                    inc(mcx);
                                    mc[mcx] := Copy(rec,2,Length(rec)-1);
                                 End;
                           '*' : Begin
                                    inc(txx);
                                    tx[txx] := Copy(rec,2,Length(rec)-1);
                                 End;
                           '%' : Begin
                                    inc(rsx);
                                    rs[rsx] := Copy(rec,2,Length(rec)-1);
                                 End;
                        End;
                  Until EOF(f) or (Rec[1] in ['@','#']) or (rec = '');

                  DCE_Speed := NewSpeed;   {reset to a known value}

                  CloseCom(False,False,False);
                  Init_la_Port;

                  { Do the $ switch text }
                  If swx > 0 then
                     Begin
                        SetWindow1(5, 8, 73, Min(10+swx,24),
                                   qq.Qcolor1[FrameColor],
                                   ' Hardware notes for'+ModemsAvailable(Choice),false);
                        TextAttr := qq.Qcolor1[BodyColor];
                        ClrScr;
                        For x := 1 to swx do Writeln (' ',sw[x]);
                        Closing;
                     End;

                  { Do the % switch text }
                  If rsx > 0 then
                     Begin
                        SetWindow1(5, 8, 73, Min(10+(mcx*2),24),
                                   qq.Qcolor1[FrameColor],
                                   ' Finding Max Baud rate ',false);
                        TextAttr := qq.Qcolor1[BodyColor];
                        ClrScr;
                        Term_Ready(True);
                        Clear_Buffer;
                        MaxBaud := 0;
                        For x := 1 to 7 do
                           Begin
                              NewSpeed := BaudList[x];
                              Init_la_Port;
                              For y := 1 to rsx do
                                 Begin
                                    Writeln ('* Trying ',NewSpeed);
                                    Clear_Buffer;
                                    Parse_Write_Modem(rs[y]);
                                    Delay(500);
                                    While Commpressed do
                                       Begin
                                          MaxBaud := BaudList[x];
                                          Write(Cinkeyz);
                                          delay(5);
                                       End;
                                 End;
                           End;
                        Writeln ('* Maximum Baud Rate ',MaxBaud);
                        NewSpeed := qq.ComSpeed;
                        Init_la_Port;
                        Closing;
                     End;


                  { Do the ^ switch text }
                  If mcx > 0 then
                     Begin
                        SetWindow1(5, 8, 73, Min(10+(mcx*2),24),
                                   qq.Qcolor1[FrameColor],
                                   ' Modem Init Commands ',false);
                        TextAttr := qq.Qcolor1[BodyColor];
                        ClrScr;
                        Term_Ready(True);
                        Clear_Buffer;
                        For x := 1 to mcx do
                           Writeln (mc[x]);
                        Write ('Send these commands to the modem [Y/N] ? ');
                        Ch := Get_Yes_no;
                        Writeln;
                        If Ch = 'Y' then
                           Begin
                              For x := 1 to mcx do
                                 Begin
                                    Parse_Write_Modem(mc[x]);
                                    Delay(750);
                                    While Commpressed do
                                       Begin
                                          Ch := Cinkeyz;
                                          If Ch <> #0 then
                                             Write(Ch);
                                          Delay(5);
                                       End;
                                 End;
                           End;
                        Closing;
                     End;

                  { Do the * switch text }
                  If txx > 0 then
                     Begin
                        SetWindow1(5, 8, 73, Min(10+txx,24),
                                   qq.Qcolor1[FrameColor],
                                   ' Additional notes ',false);
                        TextAttr := qq.Qcolor1[BodyColor];
                        ClrScr;
                        For x := 1 to txx do Writeln (' ',tx[x]);
                        Closing;
                     End;

                  IO := IOResult;
                  Close(f);
                  IO := IOResult;
                  Exit;
               End;
         End;
   End;

   Procedure Pick_and_Set_Modem;
   Var
      q          : ModemListPointer;
      Choice     : Word;
   Begin
      If not ModemListBuilt then
         BuildModemList;
      If not ModemListBuilt then
         {an error occured}
         Exit;

      { show and pick a modem }
      Choice := 1;
      If not PickWindow (@ModemsAvailable,
                         ModemTotalCount,
                         4,9,50,24,
                         True,
                         PickColors,
                         ' Pick a modem to install ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            Begin

               Initialize_Comm_Vars;
               readptr := 0;
               writptr := 0;
               readptr2 := 0;
               writptr2 := 0;

               Init_la_Port;
               Term_Ready(True);
               SetupModem(Choice);
               DropDTR := False;
               Remove_Port;
            End;

      { clear the modem list  }
      While MLPhead <> NIL do
         Begin
            q := MLPhead^.Next;
            FreeMem(MLPhead, SizeOf(MLPhead^));
            MLPhead := q;
         End;
      ModemListBuilt := False;
   End;



   Function  CharScrollStr (x : Integer) : String;
   Begin
      If x = 0 then
         CharScrollStr := 'NONE '
      Else
         CharScrollStr := Chr(x)+' '+Pad(Long2Str(x),3);
   End;


   Function  GetScrollCharSelection(Row, Col, Start : Integer) : Integer;
   Var
      CH : Char;
      Choice     : Word;
      matrix     : Byte;
   Begin
      Choice := Start+1;
      matrix := PickMatrix;
      PickMatrix := 32;
      SetHorizontalPick;
      Push_Status;
      Display_Status (' ARROWS-Select a new Character ');
      If not PickWindow (@CharsAvailable,
                         256,
                         11, Row, 77,Row+4,
                         True,
                         PickColors,
                         ' Character Select Window ',
                         Choice) then Beep
      Else
         If PickCmdNum = PKSSelect then
            GetScrollCharSelection := Choice
         Else
            GetScrollCharSelection := 0;
      PickMatrix := Matrix;
      Pop_Status;
   End;

   Procedure Edit_CharScroll_Window(Col, Row : Integer; Var x : Integer);
   Var
      CH             : Char;
      SaveX          : Integer;
   Begin
      SaveX := x;
      HiddenCursor;
      X := GetScrollCharSelection(Row+1, 4, X);
      If x = 0 then x := SaveX else Dec(x);
   End;


   Function Get_Color(num, ColorAttr : Byte) : Byte;
   Var
      x, y, z : Integer;
      CH      : Char;
      tmp,
      SaveAttr,
      Saveframe,
      Row, Col       : Byte;
      S              : String;
      Mx, My  : Byte;
      {$IFDEF UseMouse}
      Mstatus : ButtonStatus;
      {$ENDIF}

   Label Skip2, ByPass;

      Procedure Update_Picture;
      Var
         x : Word;
      Begin
         Window(38, 4, 79, 23);
         GotoXY(1, 1);
         TextAttr := qq.Qcolor1[BodyColor];
         Clreol;
         FastWrite(' Option 1 ', 4, 38, qq.Qcolor1[SelectColor]);
         FastWrite('ption 2     ption 3', 4, 52, TextAttr);
         FastWrite('O', 4, 51, qq.Qcolor1[HiliteColor]);
         FastWrite('O', 4, 63, qq.Qcolor1[HiliteColor]);
         TextAttr := qq.txtColor;
         Window(38, 5, 79, 23);
         GotoXY(1, 1);
         ClrScr;
         x := Last_Col;
         Last_Col := 49;
         DrawBox3(39, 5, 56, 8, qq.Qcolor1[FrameColor], '');
         ClrScr;
         FastWrite('Field in Edit°°°', 6, 40, qq.editf);
         FastWrite('Not in Edit°°°°°', 7, 40, qq.Qcolor1[BodyColor]);
         Last_Col := x;
         DrawBox3(57, 5, 78,10, qq.HelpColors[1], ' Help Window ');
         TextAttr := qq.HelpColors[2];
         Clrscr;
         FastWrite('Normal text color',6,59,qq.HelpColors[2]);
         FastWrite('Selected Xref'    ,7,59,qq.HelpColors[4]);
         FastWrite('Unselected Xref'  ,8,59,qq.HelpColors[5]);
         FastWrite('Highlite text'    ,9,59,qq.HelpColors[6]);
         DrawBox3(52, 12, 75, 16, qq.WindF, ' Frame Color ');
         TextAttr := qq.Menu;
         ClrScr;
         FastWrite('Primary window text',13, 53,  qq.Menu);
         FastWrite('Secondary text', 14, 53, qq.Menu2);
         FastWrite('Scroll Bar text       ', 15, 53, qq.ScrollBar);
         FastWrite('AT',11,38,qq.txtcolor);
         FastWrite('OK',12,38,qq.txtcolor);
         DrawBox3(42, 18, 75, 21, qq.editw, ' Full Screen Edit ');
         TextAttr := qq.edit1;
         ClrScr;
         FastWrite('Normal Text',19,44,qq.edit1);
         FastWrite('Marked Text',20,44,qq.edit2);
         FastWrite('Information message text', 22, 38, qq.InfoColor);
         FastWrite('°°°° Status Line   Primary  Secondary °°°°', 23, 38, qq.StatusLineColor);
         FastWrite('Secondary', 23, 66, qq.StatusLineColor2);
         SetCrtBorder(qq.Border);
      End;

      Procedure DrawColorChart;
      Var
         x, y : Integer;
      Begin
         For y := 0 To 15 Do
            Begin
               TextAttr := 0;
               Write(' ');
               For x := 0 To 7 Do
                  Begin
                     TextBackGround(x);
                     TextColor(y);
                     Write(' þ ');
                  End;
               TextAttr := 0;
               WriteLn;
            End;
      End;


      Procedure Highlight(Row, Col : Integer);
      Begin
         GotoXY(Col * 3 - 2, Pred(Row));
         TextColor(15);
         If Row < 3 Then TextBackGround(0)
         Else
            If Col < 2 Then TextBackGround(0)
            Else TextBackGround(Col - 2);
         Write('Ú');
         If Row < 3 Then TextBackGround(0)
         Else
            TextBackGround(Col - 1);
         Write('ÄÄÄ');
         If Row < 3 Then TextBackGround(0)
         Else
            If Col > 8 Then TextBackGround(0)
            Else TextBackGround(Col);
         Write('¿');

         GotoXY(Col * 3 - 2, Row);
         If Col < 2 Then TextBackGround(0)
         Else TextBackGround(Col - 2);
         Write('³');
         GotoXY(Col * 3 + 2, Row);
         If Col > 8 Then TextBackGround(0)
         Else TextBackGround(Col);
         Write('³');

         GotoXY(Col * 3 - 2, Succ(Row));
         If Row > 16 Then TextBackGround(0)
         Else
            If Col < 3 Then TextBackGround(0)
            Else TextBackGround(Col - 2);
         Write('À');
         If Row > 16 Then TextBackGround(0)
         Else TextBackGround(Col - 1);
         Write('ÄÄÄ');
         If Row > 16 Then TextBackGround(0)
         Else
            If Col > 8 Then TextBackGround(0)
            Else TextBackGround(Col);
         Write('Ù');
      End;

      Procedure UnHighlight(Row, Col : Integer);
      Begin
         {Upper left corner}
         GotoXY(Col * 3 - 2, Pred(Row));
         If Row >= 3 then
            TextColor(Row - 3);
         If (Row < 3) or (Col < 2) Then TextAttr := 0
                                   Else TextBackGround(Col - 2);
         Write(' ');

         {Upper middle}
         If Row >= 3 then
         TextColor(Row - 3);
         If Row < 3 Then TextBackGround(0)
                    Else TextBackGround(Col - 1);
         If Row < 3 Then Write('   ')
                    Else Write(' þ ');

         {upper right corner}
         If Row >= 3 then
         TextColor(Row - 3);
         If (Row < 3) or (Col > 7) Then TextAttr := 0
                                   Else TextBackGround(Col);
         Write(' ');

         {left center}
         GotoXY(Col * 3 - 2, Row);
         If Row >= 2 then
            TextColor(Row - 2);
         If Col < 2 Then TextAttr := 0 {TextBackGround(0)}
                    Else TextBackGround(Col - 2);
         Write(' ');

         {right center}
         GotoXY(Col * 3 + 2, Row);
         If Row >= 2 then
            TextColor(Row - 2);
         If Col > 7 Then TextAttr := 0 {BackGround(0)}
                    Else TextBackGround(Col);
         Write(' ');

         {Lower left corner}
         GotoXY(Col * 3 - 2, Succ(Row));
         If Row >= 1 then
            TextColor(Row - 1);
         If (Row > 16) or (Col < 2) Then TextAttr := 0
                                    Else TextBackGround(Col - 2);
         Write(' ');

         {lower center}
         If Row >= 1 then
            TextColor(Row-1);
         If Row > 16 Then TextBackGround(0)
                     Else TextBackGround(Col - 1);
         If Row > 16 Then Write('   ')
                     Else Write(' þ ');

         {lower right corner}
         If Row >= 1 then
            TextColor(Row-1);
         If (Row > 16) or (Col > 7) Then TextAttr := 0
            Else TextBackGround(Col);
         Write(' ');
      End;

      Procedure SetRealAttr;
      Begin
         Case NUM Of
            1  : qq.Qcolor1[BodyColor] := tmp;
            2  : qq.Qcolor1[HiliteColor] := tmp;
            3  : qq.Qcolor1[SelectColor] := tmp;
            4  : Begin
                    qq.Qcolor1[FrameColor] := tmp;
                    qq.Qcolor1[HeaderColor] := tmp;
                 End;
            5  : qq.EditF := tmp;
            6  : qq.WindF := tmp;
            7  : qq.Menu := tmp;
            8  : qq.Menu2 := tmp;
            9  : qq.ScrollBar := tmp;
            10 : qq.Border := tmp;
            11 : qq.TxtColor := tmp;
            12 : qq.InfoColor:= tmp;
            13 : Begin
                    qq.StatusLineColor:= tmp;
                    qq.Qcolor1[HelpColor] := tmp;
                 End;
            14 : qq.StatusLineColor2 := tmp;
            15 : qq.HelpColors[1] := tmp;
            16 : qq.HelpColors[2] := tmp;
            17 : qq.HelpColors[4] := tmp;
            18 : qq.HelpColors[5] := tmp;
            19 : qq.HelpColors[6] := tmp;
            20 : qq.Edit1 := tmp;
            21 : qq.Edit2 := tmp;
            22 : qq.Editw := tmp;
         End;
      End;


   Begin
      SaveAttr := ColorAttr;

      {$IFDEF UseMouse}
      If MouseInstalled then
         HideTheMouse;
      {$ENDIF}

      Save_Screen(1, 2, 80, 24);
      TextAttr := qq.Qcolor1[FrameColor];
      Saveframe := TextAttr;
      Display_Status_2(' ARROWS - Move Indicator   ENTER-Accepts   ESC-Exit ');
      S := ColorsAvailable(NUM);
      FrameWindow(5, 5, 32, 24, TextAttr, TextAttr, S);
      Window(6, 6, 31, 23);
      TextBackGround(0);
      ClrScr;
      Window(6, 6, 31, 24);

      {$IFDEF UseMouse}
      If MouseInstalled then
         MouseWindow(8,8,30,23);
      {$ENDIF}

      GotoXY(1, 2);
      HiddenCursor;
      Row := (ColorAttr And 15) + 2; {Make sure they are acceptable}
      Col := ((ColorAttr Shr 4) And 7) + 1;
      DrawColorChart;
      Push_window;
      SetWindow1(37, 3, 80, 24, qq.Qcolor1[FrameColor], ' Sample Screen ',false);
      Update_Picture;
      Window(6, 6, 31, 24);

      HelpTopic := 79;

      Repeat
         Highlight(Row, Col);
         tmp := (Row - 2) + ((Col - 1) Shl 4);
         SetRealAttr;
         Update_Picture;
         Window(6, 6, 31, 24);
         {$IFDEF UseMouse}
         If MouseInstalled then
            Begin
               MouseGotoXY((Col*3-1), Row-1);
               mx := Col;
               my := Row;
               Repeat
                  MouseWhereXY(Mx,My,Mstatus);
               Until KeyPressed or MousePressed or
                     ((Mx div 3)+1 <> Col) or (My+1 <> Row);
            End
         Else
         {$ENDIF}
            Repeat
            Until KeyPressed;

         {$IFDEF UseMouse}
         If MouseInstalled then
            If Keypressed or MousePressed then
               Ch := ReadKeyA
            Else
               Begin
                  If MouseInstalled then
                     Begin
                        UnHighlight(Row, Col);
                        MouseWhereXY(Mx,My,Mstatus);
                        Col := (Mx div 3)+1;
                        Row := My+1;
                     End;
               End
         Else
         {$ENDIF}
            If KeyPressed then
               CharWord := ReadKeyNoGrey;
         If ExtendedChar = x00_Extended Then
            Begin
               ByPass:
               Case CharWord Of
                  {$IFDEF UseMouse}
                  $EF00 : Begin {MouseLeft}
                             MouseWhereXY(Mx,My,Mstatus);
                             Col := (Mx div 3)+1;
                             Row := My+1;
                             CharWord := Enter;
                             Goto Skip2;
                          End;
                  $EE00 : Begin   {MouseRight}
                             CharWord:= Esc;
                             Goto Skip2;
                          End;
                  $ED00 : HelpRoutine(0,nil,79); {MouseBoth}
                  {$ENDIF}

                  F1    : HelpRoutine(0,nil,79);

                  Up    : If Row > 2 Then
                             Begin
                                UnHighlight(Row, Col);
                                Dec(Row);
                             End;
                  Down  : If Row < 17 Then
                             Begin
                                UnHighlight(Row, Col);
                                Inc(Row);
                             End;
                  Left  : If Col > 1 Then
                             Begin
                                UnHighlight(Row, Col);
                                Dec(Col);
                             End;
                  Right : If Col < 8 Then
                              Begin
                                 UnHighlight(Row, Col);
                                 Inc(Col);
                              End;
               End;
               {$IFDEF UseMouse}
               If MouseInstalled then
                  MouseGotoXY((Col*3-1), Row-1);
               {$ENDIF}
               CharWord := 0;
               Skip2:
            End;
      Until (CharWord = Esc) Or (Lo(CharWord) = 13);
      Pop_window;
      NormalCursor;
      Restore_Screen;
      Restore_Screen;
      If CharWord = Esc Then tmp := SaveAttr
                        Else tmp := (Row - 2) + ((Col - 1) Shl 4);
      SetRealAttr;
      SetPickColors;
      SetHelpColors;
      {$IFDEF UseMouse}
      If MouseInstalled then
         Begin
            FullMouseWindow;
            ShowTheMouse;
         End;
      {$ENDIF}
      HelpTopic := 0;
      Get_Color := tmp;
   End;


   Procedure Pick_and_Set_Colors;
   Var
      Choice : Word;
      matrix     : Byte;
   Begin
      { show and pick a modem }
      Choice := 1;
      matrix := PickMatrix;
      PickMatrix := 1;
      SetVerticalPick;
      Repeat
         If not PickWindow (@ColorsAvailable,
                            22,
                            3,5,32,24,
                            True,
                            PickColors,
                            ' Pick a Field to Color ',
                            Choice) then
                               Begin
                                  Beep;
                                  Exit;
                               End
         Else
            If PickCmdNum = PKSSelect then
               Case Choice of
                  1 : qq.Qcolor1[BodyColor]   := Get_Color(1, qq.Qcolor1[BodyColor]);
                  2 : qq.Qcolor1[HiliteColor] := Get_Color(2, qq.Qcolor1[HiliteColor]);
                  3 : qq.Qcolor1[SelectColor] := Get_Color(3, qq.Qcolor1[SelectColor]);
                  4 : qq.Qcolor1[FrameColor]  := Get_Color(4, qq.Qcolor1[FrameColor]);
                  5 : qq.editf                := Get_Color(5, qq.editf);
                  6 : qq.WindF                := Get_Color(6, qq.WindF);
                  7 : qq.Menu                 := Get_Color(7, qq.Menu);
                  8 : qq.menu2                := Get_Color(8, qq.menu2);
                  9 : qq.ScrollBar            := Get_Color(9, qq.ScrollBar);
                 10 : qq.Border               := Get_Color(10,qq.Border);
                 11 : Begin
                         qq.txtColor          := Get_Color(11, qq.txtColor);
                         qqColor              := qq.txtcolor;
                      End;
                 12 : qq.InfoColor            := Get_Color(12, qq.InfoColor);
                 13 : qq.StatusLineColor      := Get_Color(13, qq.StatusLineColor);
                 14 : qq.StatusLineColor2     := Get_Color(14, qq.StatusLineColor2);
                 15 : qq.HelpColors[1]        := Get_Color(15, qq.HelpColors[1]);
                 16 : qq.HelpColors[2]        := Get_Color(16, qq.HelpColors[2]);
                 17 : qq.HelpColors[4]        := Get_Color(17, qq.HelpColors[4]);
                 18 : qq.HelpColors[5]        := Get_Color(18, qq.HelpColors[5]);
                 19 : qq.HelpColors[6]        := Get_Color(19, qq.HelpColors[6]);
                 20 : qq.edit1                := Get_Color(20, qq.edit1);
                 21 : qq.edit2                := Get_Color(21, qq.edit2);
                 22 : qq.editw                := Get_Color(22, qq.editw);
               End;
      Until PickCmdNum = PKSExit;
      PickMatrix := Matrix;
   End;

   Procedure Set_Blue_Shades;
   Begin
      qq.Qcolor1[BodyColor]   := $17;
      qq.Qcolor1[HiliteColor] := $1E;
      qq.Qcolor1[SelectColor] := $71;
      qq.Qcolor1[FrameColor]  := $03;
      qq.Qcolor1[HeaderColor] := $03;
      qq.WindF := $09;
      qq.Menu  := $1E;
      qq.menu2 := $17;
      qq.ScrollBar := $0E;
      qq.Border    := $0;
      qq.txtColor  := $03;
      qq.InfoColor:= $0B;
      qq.StatusLineColor:= $71;
      qq.StatusLineColor2:= $78;
      qq.editf  := $70;
      qq.HelpColors[1] := $1F;
      qq.HelpColors[2] := $17;
      qq.HelpColors[4] := $3F;
      qq.HelpColors[5] := $30;
      qq.HelpColors[6] := $1E;
      qq.edit1 := $57;
      qq.edit2 := $17;
      qq.editw := $5E;
   End;


   Procedure Set_Purple_Shades;
   Begin
      qq.Qcolor1[BodyColor]   := $57;
      qq.Qcolor1[HiliteColor] := $5E;
      qq.Qcolor1[SelectColor] := $75;
      qq.Qcolor1[FrameColor]  := $05;
      qq.Qcolor1[HeaderColor] := $05;
      qq.WindF := $0D;
      qq.Menu  := $5E;
      qq.menu2 := $57;
      qq.ScrollBar := $0D;
      qq.Border    := $0;
      qq.txtColor  := $03;
      qq.InfoColor  := $0D;
      qq.StatusLineColor:= $75;
      qq.StatusLineColor2:= $78;
      qq.editf := $70;
      qq.HelpColors[1] := $3F;
      qq.HelpColors[2] := $37;
      qq.HelpColors[4] := $7F;
      qq.HelpColors[5] := $70;
      qq.HelpColors[6] := $5E;
      qq.edit1 := $17;
      qq.edit2 := $57;
      qq.editw := $1E;
   End;


   Procedure Set_Red_Shades;
   Begin
      qq.Qcolor1[BodyColor]   := $47;
      qq.Qcolor1[HiliteColor] := $4E;
      qq.Qcolor1[SelectColor] := $74;
      qq.Qcolor1[FrameColor]  := $06;
      qq.Qcolor1[HeaderColor] := $06;
      qq.WindF := $0C;
      qq.Menu  := $4E;
      qq.menu2 := $47;
      qq.ScrollBar := $0E;
      qq.Border    := $0;
      qq.txtColor  := $06;
      qq.InfoColor  := $0E;
      qq.StatusLineColor:= $47;
      qq.StatusLineColor2:= $48;
      qq.editf := $70;
      qq.HelpColors[1] := $4F;
      qq.HelpColors[2] := $47;
      qq.HelpColors[4] := $7F;
      qq.HelpColors[5] := $70;
      qq.HelpColors[6] := $4E;
      qq.edit1 := $67;
      qq.edit2 := $07;
      qq.editw := $6E;
   End;


   Procedure Set_Mono_Shades;
   Begin
      qq.Qcolor1[BodyColor] := $70;
      qq.Qcolor1[HiliteColor] := $7F;
      qq.Qcolor1[SelectColor] := $0F;
      qq.Qcolor1[FrameColor] := $70;
      qq.Qcolor1[HeaderColor] := $70;
      qq.WindF := $07;
      qq.Menu := $0F;
      qq.menu2 := $07;
      qq.ScrollBar := $70;
      qq.Border := $00;
      qq.txtColor := $07;
      qq.InfoColor := $0F;
      qq.StatusLineColor:= $70;
      qq.StatusLineColor2:= $78;
      qq.editf := $07;
      qq.HelpColors[1] := $07;
      qq.HelpColors[2] := $07;
      qq.HelpColors[4] := $7F;
      qq.HelpColors[5] := $70;
      qq.HelpColors[6] := $0F;
      qq.edit1 := $0F;
      qq.edit2 := $70;
      qq.editw := $07;
   End;

   Procedure Set_LCD_Shades;
   Begin
      qq.Qcolor1[BodyColor] := $70;
      qq.Qcolor1[HiliteColor] := $07;
      qq.Qcolor1[SelectColor] := $07;
      qq.Qcolor1[FrameColor] := $70;
      qq.Qcolor1[HeaderColor] := $70;
      qq.WindF := $07;
      qq.Menu := $07;
      qq.menu2 := $07;
      qq.ScrollBar := $70;
      qq.Border := $00;
      qq.txtColor := $07;
      qq.InfoColor := $07;
      qq.StatusLineColor:= $7F;
      qq.StatusLineColor2:= $70;
      qq.editf := $07;
      qq.HelpColors[1] := $07;
      qq.HelpColors[2] := $07;
      qq.HelpColors[4] := $7F;
      qq.HelpColors[5] := $70;
      qq.HelpColors[6] := $0F;
      qq.edit1 := $07;
      qq.edit2 := $70;
      qq.editw := $07;
   End;


   Procedure Select_Baud_Rate;
   Var
      x : LongInt;
   Begin
      x := GetBaudSelection(43, 7);
      If x > 0 Then
         qq.ComSpeed := x;
   End;

   Procedure Select_DataBits;
   Begin
      x := GetDBitsSelection(42, 8);
      If x <> 0 then qq.DBits := x;
   End;

   Procedure Select_Emulation;
   Var
      x : Integer;
   Begin
      x := GetEmulationSelection(16, 29);
      If x > 0 then
         qq.emulate_Ch := Chr(Ord('A')-1 + x);
   End;

   Procedure Select_Hostmode;
   Begin
      Inc(qq.HostOpen);
      If qq.HostOpen > 2 Then qq.HostOpen := 0;
   End;

   Procedure Select_Parity;
   Var
      Ch : Char;
   Begin
      Ch := GetParitySelection(42, 9);
      If Ch <> ' ' then
         qq.CParity := Ch;
   End;

   Procedure Select_Com_Port;
   Var
      Ch : Byte;
   Begin
      Ch := GetPortSelection(50, 8);
      If Ch <> 0 then
         qq.CommPort := Ch;
   End;

   Procedure Select_StopBits;
   Begin
      x := GetSBitsSelection(42, 10);
      If x <> 0 then qq.Stop_Bits := x;
   End;

End.
