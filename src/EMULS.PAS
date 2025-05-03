Unit Emuls;

Interface

Uses
   TpDos,      TpCrt,    TpString,  Initial,    Procs,
   Constant,   Screen,   Files,     EmulANSI,   QDial,
   EmulVT10,   EmulTVI,  EmulDBug,  Button,     FKeys,

   {$IfDef UseMouse}
      TpMouse,
   {$EndIf}

   DownExt,    TPZ;

Procedure Set_Emulation_Up(Ch:Char; LoadK : Boolean);
Procedure Ansi_Toggle(Ch : Char);
Procedure Load_Key_File_Em(Em : Emulation_Mode);
Procedure OutKey(Ch : String);
Function  Set_Emulation_ST(T : String) : Boolean;
Function  EmulToEmulStr(em : Emulation_Mode) : String;


Implementation


Function Set_Emulation_ST(T : String) : Boolean;
Var
   OK : Boolean;
Begin
   OK := True;  {assume success}
   T := STUpCase(T);
   If T = 'TTY'     Then ansi_toggle('A') Else
   If T = 'ANSI'    Then ansi_toggle('B') Else
   If T = 'VT100'   Then ansi_toggle('C') Else
   If T = 'TVI925'  Then ansi_toggle('D') Else
   If T = 'DEBUG_A' Then ansi_toggle('E') Else
   If T = 'DEBUG_H' Then ansi_toggle('F') Else
   If T = 'AVATAR'  Then ansi_toggle('G') Else
      OK := False;
   Set_Emulation_ST := Ok;
End;


Function EmulToEmulStr(em : Emulation_Mode) : String;
Var
   s : String;
Begin
   s := '';
   Case Em of
      TTY      : S := 'TTY';
      ANSImode : S := 'ANSI';
      VT100    : S := 'VT100';
      TVI925   : S := 'TVI925';
      DEBUG_A  : S := 'DEBUG_A';
      DEBUG_H  : S := 'DEBUG_H';
      AVATAR   : S := 'AVATAR';
      {$IfDef QLink}
      QLINK    : S := 'QLINK';
      {$EndIf}
   End;
   EmulToEmulStr := S;
End;


   Procedure Ansi_Toggle(Ch : Char);
   Var
      M : Integer;
      {$IFDEF UseMouse}
      Mflag : Boolean;
      {$ENDIF}
   Begin
      If Not Scripting Then
         Begin
            If Split Then
               Begin
                  Writelnt('Cannot change Terminal Emulation from Split Screen mode.');
                  Exit;
               End;
            Push_Status;
            PushButtonList;
            Display_Status(' LETTER-Select an Emulation   ESC-Exit ');

            Setwindow2(24, 7, 58, 12+TotalEmulations, ' Set Emulation ',false);
            {$IFDEF UseMouse}
            Mflag := MouseInstalled and MouseCursorOn;
            {$ENDIF}
            HelpTopic := 34;
            TextAttr := qq.Menu2;
            Write(' Active Emulation is ');
            TextAttr := qq.Menu;
            Write(EmulationT(Emulation));
            For y := 1 to TotalEmulations do
               Begin
                  Ch := Chr(y+Ord('1')-1);
                  AddButton(2+y,12,1,1,qq.Menu,qq.Menu2,
                            Ch+'  '+EmulationT(Emulation_Mode(y-1)),
                            ord(ch));
               End;
            {$IFDEF UseMouse}
            If MouseInstalled then
               AddButton(TotalEmulations+5,24,2,2,qq.WindF, qq.WindF, '<F1=Help>',$3B00);
            {$ENDIF}
            GotoXY(2,TotalEmulations+4);
            Write ('Your choice : ');
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  MouseWindow(24,7,58,12+TotalEmulations);
                  If not Mflag then
                     ShowTheMouse;
               End;
            {$ENDIF}
            Ch := #0;
            Repeat
               CheckForAButton(True);
               If KeyPressed then
                  Ch := Char(ReadKeyA);
            Until Ch In [#27,'1'..Chr(TotalEmulations-1+ord('1'))];
            If Ord(Ch) > 27 then
               Begin
                  Write (Ch);
                  Delay(250);
               End;
            If Not Scripting Then
               Restore_Screen;

            PopButtonList;
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  FullMouseWindow;
                  If not Mflag then
                     HideTheMouse;
               End;
            {$ENDIF}

            M := Ord(Ch)-Ord('1')+1;
            {M := GetEmulationSelection(Last_Row-TotalEmulations-2, 2);}
            Pop_Status;
         End
      Else
         M := Ord(Ch) - Ord('A')+1;

      {$IfDef GG}

         Case M Of
            1 : Begin
                   Emulation := TTY;
                   If QuickLearn then
                      WriteLearn('Graphics TTY');
                End;

            2 : Begin
                   Emulation := ANSImode;
                   If QuickLearn then
                      WriteLearn('Graphics ANSI');
                End;

            3 : Begin
                   Emulation := AVATAR;
                   Emul_Color := 7;
                   If QuickLearn then
                      WriteLearn('Graphics AVATAR');
                End;

      {$Else}

         Case M Of
            1 : Begin
                   Emulation := TTY;
                   If QuickLearn then
                      WriteLearn('Graphics TTY');
                End;

            2 : Begin
                   Emulation := ANSImode;
                   If QuickLearn then
                      WriteLearn('Graphics ANSI');
                End;

            3 : Begin
                   Emulation := VT100;
                   If QuickLearn then
                      WriteLearn('Graphics VT100');
                   OutKey(#27'c'); {DEC reset command}
                End;

            4 : Begin
                   Emulation := TVI925;
                   If QuickLearn then
                      WriteLearn('Graphics TVI925');
                End;

            5 : Begin
                   Emulation := DEBUG_A;
                   If QuickLearn then
                      WriteLearn('Graphics DEBUG_ASCII');
                End;

            6 : Begin
                   Emulation := DEBUG_H;
                   If QuickLearn then
                      WriteLearn('Graphics DEBUG_HEX');
                End;

            7 : Begin
                   Emulation := AVATAR;
                   Emul_Color := 7;
                   If QuickLearn then
                      WriteLearn('Graphics AVATAR');
                End;

      {$EndIf}



         Else Exit;
      End;

      Load_Key_File_Em(Emulation);
      Reset_Tabstops;
      Which_Screen;
      Set_Colors;
      Clear_Screen;
      Ansi_Mode := No_Esc;
      LastWas80 := False;
      LineWrap  := qq.LineWrap;
      Pushed    := False;
   End;

   Procedure Load_Key_File_Em(Em : Emulation_Mode);
   Var
      tmp : String[128];
      T : String[7];
   Begin
      T := EmulToEmulStr(Em);
      Tmp := SearchName(T+'.KEY');
      If Tmp = FKEY_Filename then Exit;
      If ExistFile(Tmp) Then
         Load_Fkeys(Tmp)
      Else
         Begin
            If FKEY_Filename = SearchName(QMODEM_KEY) then
               Exit;
            Load_Fkeys(SearchName(QMODEM_KEY));
            Tmp := SearchName(QMODEM_KEY);
         End;
      If not Scripting then
         WritelnT('Key File '+Tmp+' loaded.');
      FKEY_Filename := Tmp;
   End;

   Procedure Set_Emulation_Up(Ch:Char; LoadK : Boolean);
   Begin
      {$IfDef GG}
         Case Ch Of
            'A' : Emulation := TTY;
            'B' : Emulation := ANSImode;
            'C' : Emulation := AVATAR;
            Else  Emulation := ANSImode;
         End;
      {$Else}
         Case Ch Of
            'A' : Emulation := TTY;
            'B' : Emulation := ANSImode;
            'C' : Begin
                     Emulation := VT100;
                     OutKey(#27 + 'c');
                  End;
            'D' : Emulation := TVI925;
            'E' : Emulation := DEBUG_A;
            'F' : Emulation := DEBUG_H;
            'G' : Emulation := AVATAR;
            Else  Emulation := ANSImode;
         End;
      {$EndIf}


      If LoadK then
         Load_Key_File_Em(Emulation);
   End;


   Procedure OutKey(Ch : String);
   Var
      x : Integer;
      IsExt, OK : Boolean;
   Label
      SkipIt;
   Begin
      {$IfDef QLink}
      If Ch = #255 then
         If LastCommStringx(4) = AutoQLink then
            Begin
               Write(^H^H^H#32#32#32^H^H^H);
               QLinkMode := True;
               Exit;
            End;
      {$EndIf}

      If (qq.AutoZ and
          (
           ((Ch = ^X) and (LastCommStringx(6) = AutoZmodem)) or
           ((Ch = '0') and (LastCommStringx(6) = AutoZmodem2))
          )
         ) and
         (not Scripting) and (not Hosting) then
            Begin
               IsExt := False;
               Write(^H^H^H^H^H#32#32#32#32#32^H^H^H^H^H);
               For x := 1 To qq.Total_Xfers Do
                  If qq.Xfer_select_chr[x] = 'Z' then
                     IsExt := True;
               If IsExt then
                  Download_External('Z',True)
               else
                  OK := Zmodem_Receive(True);
               Exit;
            End;

      If (Ch = ^E) and qq.ENQ then
         Begin
            Parse_Write_Modem(F_Keys[48]);
            Exit;
         End;

      If Emulation = ANSImode Then outkey_ANSI  (Ch, False) Else
      If Emulation = AVATAR   Then outkey_ANSI  (Ch, True)  Else
      If Emulation = VT100    Then outkey_VT100 (Ch)        Else
      If Emulation = TVI925   Then outkey_TVI925(Ch)        Else
      If Emulation = DEBUG_A  Then outkey_DEBUG (Ch)        Else
      If Emulation = DEBUG_H  Then
         Begin                          {Outkey_DBUG}
            For x := 1 To Length(CH) Do
               Begin
                  Store_Cinkey(Ch[x]);
                  Write ('[',HexB(Ord(ch[x])),']');
               End
         End Else
      For x := 1 To Length(Ch) Do
         Begin
            If Split then
               Begin
                  Screen_Mode_Check;
                  If (WhereY = Split_Middle_Row-1) then
                     If (WhereX = Last_Col) or (CH[x] = #10) then
                        Add_new_line(1);
               End
            Else
               Begin
                  If (WhereX = Last_Col) or (CH[x] = #10) then
                     If (WhereY = Last_Row) then
                        Add_new_line(1);
               End;
            If Ch[x] in [^Q,^S] then
               If Xon_Xoff then
                  Goto SkipIt;
            Store_Cinkey(Ch[x]);
            Write(Ch[x]);

            SkipIt:
         End;
      Set_Split;
   End;

End.
