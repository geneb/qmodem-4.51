Unit EmulANSI;

Interface

Uses
   TpCrt,
   TPString,
   Initial,
   Comm,
   Comm2,
   Screen,
   Procs,
   EmulDups;


Procedure outkey_ANSI(CH : String; Avatar_ : Boolean);


{*} Implementation {*}

Var
   ex1,ey1 : byte;
   GCh     : Char;
   SaveAttr : Byte;


Procedure outkey_ANSI(CH : String; Avatar_ : Boolean);
   Var
      x1, y1, x  : Integer;
      Chx        : Char;

   Label
      DupeESC, ShowIt;

      Procedure Interpret_Ansi_Codes(CH : Char);
      Var
         z2, x, y, z, Savey        : Integer;
         Tx1,tx2,tx3,tx4,tx5 : byte;
         Temp           : String[3];
      Begin
         Case CH Of
                  {Cursor position report for ESC[6n}

            'n' : Begin
                     ResetColumn;
                     Write_Byte(#27+'['+Long2Str(WhereY)+';'+Long2str(WhereX)+'R');
                  End;

            'M' : ;               { ANSI Music String... Ignore this one }

            'J' : Begin
                     Savey := emul_color;
                     Window(1, 1, Last_Col, Last_Row);
                     Set_Colors;
                     ResetColumn;
                     If (Save_Ansi_Str = '') Or (Asc2int(Save_Ansi_Str) = 0) Then
                        Begin
                           x := WhereX;
                           y := WhereY;
                           Clreol;
                           For z := y + 1 To Last_Row {B_Margin} Do
                              Begin
                                 GotoXY(1, z);
                                 Add_New_Line(WhereYAbs);
                                 Clreol;
                              End;
                           GotoXY(x, y);
                        End
                     Else
                        Case Asc2int(Save_Ansi_Str) Of
                           1  : Begin
                                   x := (WhereY - 1) * Last_Col + WhereX;
                                   GotoXY(1, 1);
                                   z := x;
                                   z2 := WhereYabs;
                                   While Z > 0 do
                                      Begin
                                         Dec(z,80);
                                         If z > 0 then
                                            Add_New_Line(z2);
                                         Inc(z2);
                                      End;
                                   For y := 1 To x Do Write(' ');
                                   Write(^H);
                                End;
                           2  : Clear_Screen;
                           Else Show_Bogus_ANSI(CH);
                        End;
                     Emul_Color := Savey;
                     TextAttr := Savey;
                  End;

            'K' : Begin
                     ResetColumn;
                     Clreol;
                  End;

            's' : Begin
                     ResetColumn;
                     Save_Emul_X := WhereX;
                     Save_Emul_Y := WhereY;
                  End;

            'u' : GotoXY(Save_Emul_X, Save_Emul_Y);

            'H', 'f' : Begin
                          If (Save_Ansi_Str = '') or (Save_Ansi_Str = ';') Then
                             Begin
                                ex1 := 1;
                                ey1 := 1;
                             End
                          Else
                             Begin
                                If Save_Ansi_Str[Length(Save_Ansi_Str)] = ';' Then
                                   Save_Ansi_Str := Save_Ansi_Str + '1';
                                x := SearchLeftC(Save_Ansi_Str, ';');
                                If x = 0 Then
                                   Begin
                                      ex1 := 1;
                                      ey1 := Asc2int2(Save_Ansi_Str);
                                   End
                                Else
                                   If x = 1 Then
                                      Begin
                                         ex1 := Asc2int2(Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0])));
                                         ey1 := 1;
                                      End
                                   Else
                                      Begin
                                         ex1 := Asc2int2(Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0])));
                                         ey1 := Asc2int2(Copy(Save_Ansi_Str, 1, x - 1));
                                      End;
                             End;
                          GotoXY(ex1,ey1);
                       End;

            'D' : Begin
                     If Save_Ansi_Str = '' Then
                        x := 1
                     Else
                        Begin
                           y := Asc2int(Save_Ansi_Str);
                           If y = - 1 Then
                              Show_Bogus_ANSI(CH)
                           Else
                              x := y;
                        End;
                     ResetColumn;
                     If WhereX - x < 1 Then
                        GotoXY(1, WhereY)
                     Else
                        GotoXY(WhereX - x, WhereY);
                  End;

            'C' : Begin
                     If Save_Ansi_Str = '' Then
                        x := 1
                     Else
                        Begin
                           y := Asc2int(Save_Ansi_Str);
                           If y = -1 Then Show_Bogus_ANSI(CH)
                           Else x := y;
                        End;
                     ResetColumn;
                     If WhereX + x > Last_Col Then
                        GotoXY(Last_Col, WhereY)
                     Else
                        GotoXY(WhereX + x, WhereY);
                  End;

            'B' : Begin
                     If Save_Ansi_Str = '' Then
                        x := 1
                     Else
                        Begin
                           y := Asc2int(Save_Ansi_Str);
                           If y = - 1 Then Show_Bogus_ANSI(CH)
                           Else x := y;
                        End;
                     ResetColumn;
                     If WhereY + x > Last_Row Then
                        GotoXY(WhereX, Last_Row)
                     Else
                        GotoXY(WhereX, WhereY + x);
                  End;

            'A' : Begin
                     If Save_Ansi_Str = '' Then
                        x := 1
                     Else
                        Begin
                           y := Asc2int(Save_Ansi_Str);
                           If y = -1 Then
                              Show_Bogus_ANSI(CH)
                           Else
                              x := y;
                        End;
                     ResetColumn;
                     If WhereY - x < 1 Then
                        GotoXY(WhereX, 1)
                     Else
                        GotoXY(WhereX, WhereY - x);
                  End;

            'h' : If SearchLeftC(Save_Ansi_Str, '?') > 0 Then { only accept those with ? }
                     Case Save_Ansi_Str[2] Of
                        '7' : Begin
                                 LineWrap := True;
                                 If WhereX = Last_Col then   {!!4.2G}
                                    LastWas80 := True;       {!!4.2G}
                              End;
                     End;

            'l' : If SearchLeftC(Save_Ansi_Str, '?') > 0 Then { only accept those with ? }
                     Case Save_Ansi_Str[2] Of
                        '7' : LineWrap := False;
                     End;

            'm' : Begin
                     SetEmmColor;
                  End;

         End;
         Save_Ansi_Str[0] := #0;
         Ansi_Mode := No_Esc;
      End;

   Begin                          {Outkey_ANSI}
      For x := 1 To Length(CH) Do
         Begin
            Case Ansi_Mode Of
               No_Esc    : If (CH[x] = #27) or
                              (Avatar_ and (Ch[x] = ^V)) Then
                              Ansi_Mode := Got_Esc
                           Else
                              Begin
                                 If Avatar_ then
                                    Begin
                                       Case CH[x] Of
                                          ^L : Begin
                                                  Emul_Color := 7;
                                                  Set_Colors;
                                                  Clear_Screen;
                                                  Exit;
                                               End;
                                          ^Y : Begin
                                                  If Get_Ch(chx) then
                                                     Begin
                                                        If Get_Ch(GCh) then
                                                           Begin
                                                              y1 := Ord(GCh);
                                                              For x1 := 1 to y1 do
                                                                 EmulsAnsiVT100Disp(Chx);
                                                              Exit;
                                                           End;
                                                     End;
                                               End;
                                       End;
                                    End;
                                 DupeESC:
                                 Case CH[x] Of
                                    ^G : Begin
                                            If Noise then
                                               Begin
                                                  Sound (700);
                                                  Delay (90);
                                                  NoSound;
                                               End;
                                         End;
                                    ^Q,
                                    ^S : If not Xon_Xoff then
                                            Goto ShowIt;
                                    Else
                                       Begin
                                          ShowIt:
                                          EmulsAnsiVT100Disp(Ch[x]);
                                       End;
                                 End;
                              End;

               Got_Esc   : If CH[x] = ^[ then
                              Goto DupeESC Else
                           If CH[x] = '[' Then
                              Ansi_Mode := Got_Esc_B
                           Else
                              If Avatar_ then
                                 Begin
                                    Case CH[x] Of
                                       ^A :  Begin
                                                If Get_Ch(gch) then
                                                   Begin
                                                      Emul_Color := Ord(GCh);
                                                      Set_Colors;
                                                   End;
                                             End;
                                       ^B :  Begin
                                                emul_color := emul_color Or 128;
                                                Set_Colors;
                                             End;
                                       ^C :  If WhereY > 1 then
                                                GotoXY(WhereX,WhereY-1);
                                       ^D :  If WhereY < Last_Row then
                                                GotoXY(WhereX,WhereY+1);
                                       ^E :  If WhereX > 1 then
                                                GotoXY(WhereX-1,WhereY);
                                       ^F :  If WhereX < Last_Col then
                                                GotoXY(WhereX+1,WhereY);
                                       ^G :  ClrEol;
                                       ^H :  Begin
                                                If Get_CH(Gch) then
                                                   Begin
                                                      x1 := Ord(GCh);
                                                      If Get_Ch(GCh) then
                                                         Begin
                                                            y1 := Ord(GCh);
                                                            GotoXY(Min(y1,Last_Col),
                                                                   Min(x1,Last_Row));
                                                         End;
                                                   End;
                                             End
                                       Else  Show_Bogus_ANSI(CH[x]);
                                    End;
                                    Ansi_Mode := No_Esc;
                                 End
                              Else
                                 Begin
                                    Write(#27 + CH[x]);
                                    Ansi_Mode := No_Esc;
                                 End;

               Got_Esc_B : Case CH[x] Of
                              '0'..'9', ';', 'H', 'A', 'B', 'C', 'D', '=', '?', 'M',
                              'f', 'n', 's', 'u', 'J', 'K', 'm', 'h', 'l', 'Z',
                              'S', 'L' :
                                 If ((CH[x] >= '0') And (CH[x] <= '9'))
                                 Or (CH[x] = ';')
                                 Or (CH[x] = '=')
                                 Or (CH[x] = '?') Then
                                    Add_Ch_to_Ansi(CH[x])
                                 Else
                                    Interpret_Ansi_Codes(CH[x]);
                               Else
                                  Show_Bogus_ANSI(CH[x]);
                           End;   { Case }

            End;
         End;
   End;

End.
