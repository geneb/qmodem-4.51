Unit KEY;

Interface

Uses OpKey;

{$I TPDEFINE.INC}

   Procedure Out_Key(Key : Integer);
   Procedure Handle_String_Pressed(s: String);
   Procedure Check_Key_Combo(a : char);
   Procedure Check_Key_Pad (a : char);
   Procedure Display_Char(A : Char);
   Procedure Handle_Split_Char(A : Char);
   Procedure Check_Key_Codes;
   Procedure Handle_Key_Pressed(A : Char);
   Procedure QL_Build_WAITFOR;
   Function  Substitute_on_FKEYS (S : String) : String;

Implementation

Uses
   Dos,      TpCrt,    TpString, TpWindow,
   Initial,  Comm,     Procs,    EmulANSI, Screen,
   EmulVT10, Group1,   QDial,    Emuls,    Comm2,

   {$IFDEF UseMouse}   TpMouse,  {$ENDIF}

   Group02,  Menus,    Qega,     BINFSE,   QDosCmd,
   ScrDmp,   DeleteF,  Info,     ChangDir, Baud,     XLate,
   Qdial2,   Qhelp2,   Qmem,     QShell,   Files,    Batch,
   FKeys,    Downld,   Upld,     Port,     LogDrv,   ExitDOS,
   Scroll,

   {$IfNDef GG}
   Host,
   {$EndIf}

   RunQinst, Scripts;


   Function Substitute_on_FKEYS (S : String) : String;
   Var
      x : Integer;
   Begin
      x := SearchLeftC(S, '$');
      If STUpCase(Copy(S, Succ(x), 8)) = 'PASSWORD' Then
         Begin
            Delete(S, x, 9);
            Insert(Linked_Password, S, x);
         End;
      If S[Length(S)] = '|' then
         S[0] := (Char(Length(S)-1));
      Substitute_on_FKEYS := S;
   End;

   Procedure Out_Key(Key : Integer);
   Var
      rc, x    : Integer;
      Temp, t1 : String;
      tt : Boolean;

   Begin
      If (Key >= 1) and (Key <= 48) then
      Else
      Begin
      If Key < 69 Then
         Key := Key - 58
      Else
         If Key < 94 Then
            Key := Key - 71
         Else
            If Key < 104 Then
               Key := Key - 69
            Else
               If Key < 114 Then
                  Key := Key - 67
               Else
                  If Key < 135 Then
                     Key := Key - 122
                  Else
                     If Key < 137 Then
                        Key := Key - 112
                     Else
                        If Key < 139 Then
                           Key := Key - 102
                        Else
                           If Key < 141 Then
                              Key := Key - 92
                           Else
                              { Check the TANDY f-keys }
                              If Key=152 then Key := 11 Else
                              If Key=153 then Key := 12 Else
                              If Key=162 then Key := 23 Else
                              If Key=163 then Key := 24 Else
                              If Key=172 then Key := 35 Else
                              If Key=173 then Key := 36 Else
                              If Key=182 then Key := 47 Else
                              If Key=183 then Key := 48;
         End;

      If QuickLearn then
         WriteLearn ('FKey     '+Long2Str(Key));

      Temp := Substitute_on_FKEYS(f_keys[Key]);

      If STUpCase(Copy(Temp, 1, 5)) = '@HELP' Then
         Begin
            HelpRoutine(0,NIL,54);
            Exit;
         End;

      If STUpCase(Copy(Temp, 1, 7)) = '@SHELL ' Then
         Begin
            Delete(Temp, 1, 7);
            If Temp <> '' Then
               rc := Shell(Temp+'', ''+'', ''+'', True, True,False);
            Exit;
         End;

      If STUpCase(Copy(Temp, 1, 8)) = '@SHELLX ' Then
         Begin
            Delete(Temp, 1, 8);
            If Temp <> '' Then
               rc := Shell(Temp+'', ''+'', ''+'', True, False,False);
            Exit;
         End;

      If STUpCase(Copy(Temp, 1, 6)) = '@DIAL ' Then
         Begin
            Delete(Temp, 1, 6);
            If Temp <> '' Then
               DIAL(Temp);
            Exit;
         End;

      If STUpCase(Copy(Temp, 1, 7)) = '@SCRIPT' Then
         Begin
            t1 := '';
            Delete(Temp, 1, 8);
            x := 1;
            While (Temp[x] <> ' ') And (x <= Length(Temp)) Do
               Begin
                  t1 := t1 + Temp[x];
                  x := Succ(x);
               End;
            While (Temp[x] = ' ') And (x <= Length(Temp)) Do
               x := Succ(x);
            Delete(Temp, 1, x - 1);
            Script_Parm_Line := Temp;
            Fkey_Script(t1);
            Exit;
         End;

      If STUpCase(Copy(Temp, 1, 5)) = '@EDIT' Then
         Begin
            Temp := Copy(Temp,7,Length(Temp));
            If (qq.Browse_PGM <> '') and (qq.Browse_PGM[1] = '@') then
               ViewFile(temp)
            Else
               FSE(temp,0,2,PRLR-1,TRUE);
            Exit;
         End;

      If STUpCase(Copy(Temp, 1, 6)) = '@STAMP' Then
         Begin
            Logit(Temp);
            Exit;
         End;

      If Not Split Then
         Begin
            If Echo Then
               Write(CH);
            Parse_Write_Modem(Temp);
         End
      Else
         For x := 1 To Byte(Temp[0]) Do
            Handle_Key_Pressed(Temp[x]);
   End;


   Procedure Handle_String_Pressed(s: String);
   Var
      x : Integer;
   Begin
      for x := 1 to Length(s) do
         Handle_Key_Pressed(s[x]);
   End;


   Procedure TempScreenChangeStuff;
   Var
      Tsplit : Boolean;
   Begin
      Tsplit := Split;
      If Split then
         SplitScreen;
      {$IfNDef GG}
      If Emulation = VT100 then
         OutKey(#27'c'); {DEC reset command}
      {$EndIf}
      Set_Full_Window;
      {$IFDEF UseMouse}
      If MouseInstalled then
         FullMouseWindow;
      {$ENDIF}
      Clear_Screen;
      If Tsplit then SplitScreen;
   End;


   Procedure Check_Key_Combo;
   Var
      ss, tt         : Boolean;
      HostStatus     : Integer;
      HostRestart    : Boolean;
      Save_Last_Row  : Integer;
      Save_SL        : Boolean;
      xk             : KeyPointer;
   Const
      sss = 'Send     "';
   Begin
      If QuickLearn Then
         Begin
            QL_Build_WAITFOR;
            If LearnTxt <> '' then
               Begin
                  If qq.SendPace > 0 then
                     WriteLearn(sss + ExpandCtrlString(LearnTxt) +
                                '" PACE='+Long2Str(qq.SendPace))
                  Else
                     WriteLearn(sss + ExpandCtrlString(LearnTxt) + '"');
                  LearnTxt := '';
               End;
            LearnTxt := '';
            ScriptCount := 0;
         End;

      If Doorway Then
         Case A Of
            {Alt-=}#131 : Doorway_Toggle; { Turn Doorway mode off }
                   Else
                      Case ExtendedChar of
                         x00_Extended : Write_Byte (DoorwayLeader + A);
                         xE0_Extended : If qq.E0Doorway then
                                           Write_Byte (DoorwayLeader + #$E0 + A)
                                        Else
                                           Write_Byte (DoorwayLeader + A);
                      End;
         End
      Else
         Begin

            If qq.DoRecalibrate then
               DelayCalibrate;  {Recalibrate the OneMS variable under DV}

            Save_SL := qq.ShowStatusLine;
            ShowSL := True;

            Case A Of
               #126, {Alt-7 for those that Alt-Enter doesn't work}
               #$1C, {IBM Alt-Enter}
               #$8F  {Tandy Alt-Enter}  :
                      Begin
                         Case CurrStatusLine3 of
                            {$IfDef UseMouse}
                               WithToggles    : CurrStatusLine3 := WithCommands;
                               WithCommands   : CurrStatusLine3 := WithBBSInfo;
                               WithBBSInfo    : CurrStatusLine3 := WithToggles;
                            {$Else}
                               WithToggles    : CurrStatusLine3 := WithBBSInfo;
                               WithBBSInfo    : CurrStatusLine3 := WithToggles;
                            {$EndIf}
                         End;
                      End;

      {Alt-=}  #131 : Begin
                         Doorway_Toggle; { Turn Doorway mode ON }
                      End;
      {Alt-1}  #120 : BS_DEL_Switch;
      {Alt-2}  #121 : Begin
                         Add_New_Screen;
                         Set_Screen_25;
                         If QuickLearn then WriteLearn ('EGA      25');
                         TempScreenChangeStuff;
                      End;
      {ALT-3}  #122 : Show_All_Allocations;
      {Alt-4}  #123 : Begin
                         Add_New_Screen;
                         Set_Screen_43;
                         If QuickLearn then WriteLearn ('EGA      43');
                         TempScreenChangeStuff;
                      End;

      {Alt-5}  #124 : Begin
                         If Test_Host_Carrier then
                            Exit;
                         If Split then
                            SplitScreen;
                         Push_Status;
                         If not Save_SL then
                            Begin
                               Dec(Last_Row);
                               Set_Full_Window;
                            End;
                         Clrscr;
                         Writelnb('You are now in HOST mode');
                         Writelnb(CharStr('อ',ScreenWidth));
                         HostRestart := False;
                         HostViaScript := False;
                         Repeat
                            HostStatus := HostMode(HostRestart);
                            Case HostStatus Of
                               1 : Begin
                                      Script_Parm_Line := Hfirstname+' '+
                                                          Hlastname;
                                      Execute_A_Script;
                                   End;
                            End;
                            HostRestart := True;
                         Until (HostStatus = 0) or Exit_Main;
                         If not Save_SL then
                            Begin
                               Inc(Last_Row);
                               Set_Full_Window;
                            End;
                         Clrscr;
                         Writelnb('Sending Modem Initialization');
                         Parse_Write_Modem(qq.ModmInit);
                         Writelnb('You are now in TERMINAL mode');
                         Writelnb(CharStr('อ',ScreenWidth));
                         Pop_Status;
                      End;

      {Alt-6}  #125 : Begin
                         If Get_File_Name_Batch (qq.BatchUL1,
                                                 qq.BatchUL2,
                                                 qq.BatchUL3) then;
                      End;

      {Alt-8}  #127 : Hi_Bit_Toggle;
      {Alt-9}  #128 : Prtlog_toggle;
      {Alt-0}  #129 : Log_toggle('', True);
      {Alt--}  #130 : Begin
                         qq.ShowStatusLine := not qq.ShowStatusLine;
                         If QuickLearn then
                            If qq.ShowStatusLine then WriteLearn('TurnON   STATUSLN')
                                                 else WriteLearn('TurnOFF  STATUSLN');
                         Save_Last_Status := '';
                         Add_New_Screen;
                         Display_Status('');
                      End;
      {^HOME}  #119 : Capture_Toggle('', True);
      {ShTab}  #15  : Addlf_toggle;
      {Alt-Q}  #16  : Learn('');
      {Alt-W}  #17  : Dir2;
      {Alt-E}  #18  : Echo_toggle;
      {Alt-R}  #19  : Begin
                         If QuickLearn then WriteLearn('DOS      "COMMAND"');
                         DOS_Cmd;
                      End;
      {Alt-T}  #20  : Screen_Dump;
      {Alt-Y}  #21  : Delete_File;
      {Alt-U}  #22  : Scroll_Toggle;
      {Alt-I}  #23  : Pgm_Info;
      {Alt-O}  #24  : Chgdir('');
      {Alt-P}  #25  : Change_Baud(' ');
      {Alt-A}  #30  : Xlate_Table;
      {Alt-S}  #31  : SplitScreen;
      {Alt-D}  #32  : Dial('');
      {Alt-F}  #33  : Begin
                         Scripting := True;
                         Script_to_Open := '';
                         Script_Debug := False;
                         Already_Initialized := False;
                         Keyword_Count := 0;
                      End;
      {Alt-G}  #34  : Ansi_toggle(' ');
      {Alt-H}  #35  : Hangup;
      {Alt-J}  #36  : Setfkeys;
      {Alt-K}  #37  : Change_ComPort(' ');
      {Alt-L}  #38  : Log_Drive(' ');
      {Alt-Z}  #44  : Xon_Xoff_Toggle;
      {Alt-X}  #45  : Exit_to_DOS(False, #0);
      {Alt-C}  #46  : Begin
                         Clear_Whole_Screen;
                         If QuickLearn then WriteLearn('ClrScr');
                      End;
      {Alt-V}  #47  : ViewFile('');
      {Alt-B}  #48  : Noise_toggle;
      {Alt-N}  #49  : Run_Qinstall(false);
      {Alt-M}  #50  : ANSI_Music;
      {Fkeys}  #59..#68,           {F1-F10}

               #133..#140,         {F11&F12 all modes}

               #152,#153,
               #162,#163,          {TANDY F11 & F12 keys!}
               #172,#173,
               #182,#183,

               #84..#113 : Begin   {F1-F10 shft, ctrl, alt}
                              Out_Key(Ord(A));
                           End;
      {^End }  #117 : Begin
                         Break;
                         If QuickLearn then WriteLearn('Break');
                      End;
      {Home }  #71  : If Not Help_Last Then
                         HLPmenu;
     {^Uparrow} #141,
     { Uparrow} #72 : Back_Scroll;

      { PgDn}  #81  : DownLoad ('', ' ', Linked_Protocol);
      { PgUp}  #73  : Upload   ('', ' ', Linked_Protocol);
            End; { case }

            Which_Screen;

            ShowSL := qq.ShowStatusLine;

            If Save_SL <> qq.ShowStatusLine then
               Begin
                  ss := Save_Scroll;
                  Save_Scroll := False;
                  Clear_Whole_Screen;
                  If Split then
                     Begin
                        SplitScreen;
                        SplitScreen;
                     End;
                  If Emulation = VT100 then
                     Begin
                        OutKey(#27 + 'c'); {DEC reset command}
                        Clear_Screen;
                     End;
                  Save_Scroll := ss;
               End;
         End;
      IO := IoResult;      {reset any IO errors    }
      HelpTopic := 0;      {reset any hanging Helps}
      NormalCursor;
      Set_Colors;          {reset the colors       }
      StatusWasOn := True; {reset the status line  }
      Home_Status_Msg;     {show the status line   }
      If ShowSL then
         If WhereY = Last_Row+1 then
            Begin
               GotoXY(Last_Col, Last_Row);
               Writeln;
            End;
   End;


   Procedure Check_Key_Pad (a : char);
   Begin
      Case a of
         '*','-','+',#8,#127 : Handle_Key_Pressed(a);
            '7' : Case Emulation of     {Home Cursor}
                     VT100,
                     Avatar,
                     ANSImode : Handle_String_Pressed('[H');
                  End;
            '8' : Case Emulation of     {Cursor up}
                     VT100    : If CursorKeyMode then Handle_String_Pressed('OA')
                                                 else Handle_String_Pressed('[A');
                     TVI925   : Handle_Key_Pressed(^K{#$1B});
                     Avatar,
                     ANSImode : Handle_String_Pressed('[A');
                  End;
            '4' : Case Emulation of     {Cursor Left}
                     VT100    : If CursorKeyMode then Handle_String_Pressed('OD')
                                                 else Handle_String_Pressed('[D');
                     TVI925   : Handle_Key_Pressed(^H{#$18});
                     Avatar,
                     ANSImode : Handle_String_Pressed('[D');
                  End;
            '6' : Case Emulation of     {Cursor Right}
                     VT100    : If CursorKeyMode then Handle_String_Pressed('OC')
                                                 else Handle_String_Pressed('[C');
                     TVI925   : Handle_Key_Pressed(^L{#$1C});
                     Avatar,
                     ANSImode : Handle_String_Pressed('[C');
                  End;
            '2' : Case Emulation of     {Cursor Down}
                     VT100    : If CursorKeyMode then Handle_String_Pressed('OB')
                                                 else Handle_String_Pressed('[B');
                     TVI925   : Handle_Key_Pressed(^V{#$16});
                     Avatar,
                     ANSImode : Handle_String_Pressed('[B');
                  End;
            '3' : Case Emulation of     {Clear Screen}
                     VT100    : Handle_String_Pressed('[H[2J');
                     Avatar,
                     ANSImode : Handle_String_Pressed('[2J');
                  End;
            '1' : Case Emulation of     {Erase EOL}
                     VT100,
                     Avatar,
                     ANSImode : Handle_String_Pressed('[K');
                  End;
            '.' : Case Emulation of     {Delete Line}
                     VT100,
                     Avatar,
                     ANSImode : Handle_Key_Pressed(#127);
                  End;
      End;
   End;

   Procedure Display_Char(A : Char);
   Begin
      Case A Of
         #13  : If Echo Then
                   Begin
                      If AddLf or Split then Writeln
                                        else Write(#13);
                   End
                Else
                   WriteLn;
         #9   : PrtTab;
         ^H,
         #127 : Begin
                   Write(^H);
                   Write(' ');
                   Write(^H);
                End;
         Else   Write(A);
      End;
   End;

   Procedure Handle_Split_Char(A : Char);
   Begin
      Split_Window_Bottom;
      GotoXY(outx, outy);
      If (Byte(Split_String[0]) < 255) Or (A = ^M) Then
         Begin
            If A = ^M Then
               Begin
                  Parse_Write_Modem(Split_String+#13);
                  Split_String := '';
               End
            Else                  { not a CR }
               Begin
                  If Not(A In [#8, #127]) Then
                     Begin
                        If Byte(Split_String[0]) < 254 Then
                           Split_String := Split_String + A
                        Else
                           Exit;
                     End
                  Else
                     If Length(Split_String) > 0 Then
                        Begin
                           Delete(Split_String, Length(Split_String), 1);
                           If WhereX = 1 Then
                              Begin
                                 GotoXY(Last_Col, WhereY - 1);
                                 Write(' ');
                                 GotoXY(Last_Col, WhereY - 1);
                              End
                           Else
                              Display_Char(A);
                        End;
               End;
         End;
      Case A Of
         #8, #127 : ;
      Else
         If Byte(Split_String[0]) < 255 Then
            Display_Char(A);
      End;
      outx := WhereX;
      outy := WhereY;
      Split_Window_Middle;
      GotoXY(23, 1);
      TextAttr := qq.Menu;
      Write(Length(Split_String), ' ');
      TextAttr := qq.WindF;
      Write(']อออ');
      Split_Window_Bottom;
      GotoXY(outx, outy);
      Set_Colors;
   End;

   Procedure QL_Build_WAITFOR;
   Var
     T : String;
     x : Integer;
   Begin
      If (ScriptCount > 0) And (LearnTxt = '') Then
         Begin
            T := Trim(LastCommString(32));
            x := Length(T);
            While (x > 0) And (T[x] In [^@, ^M, ^J]) Do Dec(x);
            While (x > 0) And (Not(T[x] In [^@, ^M, ^J])) Do Dec(x);
            Delete(T, 1, x);
            If Length(T) > 0 Then
               Begin
                  WriteLearn('');
                  WriteLearn('Waitfor  "' + ExpandCtrlString(T) + '"');
                  WriteLearn('Delay    100');
               End;
         End;
   End;


   Procedure Check_Key_Codes;
   Begin
      CharWord := ReadKeyA;
      Case ExtendedChar of
         x00_Extended,
         xE0_Extended : Check_Key_Combo(Char(Hi(CharWord)));
         KeyPad       : If qq.KeypadEmuls = 'Y' then
                           Check_Key_Pad(Char(CharWord))
                        Else
                           Handle_Key_Pressed(Char(CharWord));
         Else           Handle_Key_Pressed(Char(CharWord));
      End;
   End;

   Procedure Handle_Key_Pressed;  { (a : Char);  Forwarded }
   Var
      T : String;
      x : Integer;
   Const
      sss = 'Send     "';
   Begin
      Translate_Out(A);
      If QuickLearn Then
         Begin
            QL_Build_WAITFOR;
            If A = ^M Then
               Begin
                  If qq.SendPace > 0 then
                     WriteLearn(sss + ExpandCtrlString(LearnTxt) + '^M"' +
                                ' PACE='+Long2Str(qq.SendPace))
                  Else
                     WriteLearn(sss + ExpandCtrlString(LearnTxt) + '^M"');
                  LearnTxt := '';
                  ScriptCount := 0;
               End
            Else
               Begin
                  If Length(LearnTxt) >= 64 Then
                     Begin
                        WriteLearn('Send     "' +
                                   ExpandCtrlString(LearnTxt) + '"');
                        LearnTxt := '';
                     End;
                  LearnTxt := LearnTxt + A;
               End;
         End;
      If Split Then
         Handle_Split_Char(A)
      Else
         Begin
            If Echo Then
               Begin
                  Store_Cinkey(A);
                  Display_Char(A);
               End;
            Write_Byte(A);
         End;
   End;

End.
