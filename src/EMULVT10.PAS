Unit EmulVT10;

Interface

Uses
   Dos,
   TpCrt,
   TPString,
   Initial,
   Comm,
   Comm2,
   Procs,
   Screen,
   EmulDups;

Procedure outkey_VT100(CH : String);


Implementation


   Procedure Translate_G(Var CH : Char);
   Var
      xch : Char;
   Begin
      Case CH Of
         #95  : xch := #32;        {_}
         #96  : xch := #04;        {'}
         #97  : xch := #176;       {a}
         #98  : xch := #158;
         #99  : xch := #146;
         #100 : xch := #174;
         #101 : xch := #157;
         #102 : xch := #248;
         #103 : xch := #241;
         #104 : xch := #32;
         #105 : xch := #32;
         #106 : xch := #217;
         #107 : xch := #191;
         #108 : xch := #218;
         #109 : xch := #192;
         #110 : xch := #197;
         #111 : xch := #196;
         #112 : xch := #196;
         #113 : xch := #196;
         #114 : xch := #196;
         #115 : xch := #196;
         #116 : xch := #195;
         #117 : xch := #180;
         #118 : xch := #193;
         #119 : xch := #194;
         #120 : xch := #179;
         #121 : xch := #243;
         #122 : xch := #242;
         #123 : xch := #227;
         #124 : xch := #240;
         #125 : xch := #156;
         #126 : xch := #249;
         Else   xch := CH;
      End;
      CH := xch;
   End;

   Procedure Reset_Term_Colors;
   Begin
      Set_Colors;     {!!4.3A}
   End;

   Procedure Check_DECOM;
   Var
      x,y : word;
   Begin
      x := wherey;
      y := whereyAbs;
      If Not Decom Then
         Begin
            If (WhereYabs >= T_Margin) And (WhereYabs <= B_Margin) Then
               Window(1, T_Margin, Last_Col, B_Margin)
            Else
               If WhereYabs < T_Margin Then
                  Window(1, 1, Last_Col, B_Margin{T_Margin-1})
               Else
                  Window(1, B_Margin+1, Last_Col, Last_Row)
         End;
   End;


   Procedure Set_Full_Screen;
   Begin
      If not Decom then
         Window(1, 1, Last_Col, Last_Row)
   End;


   Procedure Set_Fuller_Screen;
   Begin
      If not Decom then
         Window(1, 1, Last_Col, Last_Row+1);
   End;


   Procedure Interpret_B_Codes(CH : Char);
   Var
      x, y, z, z2    : Integer;
      Savey          : Byte;
      Temp, t1, t2   : String[3];
      xch,xch1,xch2  : Char;
      tmp1           : String;
      tmp1_Len       : Byte absolute tmp1;
      temp2, temp3   : array[1..255] of byte;
   Begin
      Check_DECOM;
      Case CH Of
         ^D,
         ^E  : Begin
                  ResetColumn;
                  x := WhereX;
                  WriteLn;
                  If CH = ^D Then
                     GotoXY(x, WhereY);
               End;

         '~' : Begin
                  ResetColumn;
                  If (WhereYabs = T_Margin) Or (WhereYabs = 1) Then
                     InsLine
                  Else
                     GotoXYabs(WhereXabs, WhereYabs - 1);
               End;

         'M' : Begin
                  ResetColumn;
                  Set_Full_Screen;
                  x := 0;
                  If Save_Ansi_Str = '' Then
                     x := 1
                  Else
                     Begin
                        y := Asc2int(Save_Ansi_Str);
                        If y = -1 Then Show_Bogus_ANSI(CH)
                                  Else x := y;
                     End;
                  While X > 0 do
                     Begin
                        DelLine;
                        Dec(x);
                     End;
               End;

         'L' : Begin
                  ResetColumn;
                  Set_Full_Screen;
                  x := 0;
                  If Save_Ansi_Str = '' Then
                     x := 1
                  Else
                     Begin
                        y := Asc2int(Save_Ansi_Str);
                        If y = -1 Then Show_Bogus_ANSI(CH)
                                  Else x := y;
                     End;
                  While X > 0 do
                     Begin
                        InsLine;
                        Dec(x);
                     End;
               End;


         'P' : Begin
                  z := 0;
                  If Save_Ansi_Str = '' Then
                     z := 1
                  Else
                     Begin
                        y := Asc2int(Save_Ansi_Str);
                        If y = -1 Then Show_Bogus_ANSI(CH)
                                  Else z := y;
                     End;
                  While z > 0 do
                     Begin
                        MoveScreen (Virtual_Screen^[(WhereYabs-1) * 160 + WhereXabs*2],
                                    Virtual_Screen^[(WhereYabs-1) * 160 + WhereXabs*2-2],
                                    (Last_Col-WhereXabs));
                        FastWrite(' ', WhereYabs, Last_Col, qqColor);
                        Dec(z);
                     End;
               End;

         '#' : Begin
                  If Get_Ch(Ch) then
                     Case Ch of
                        '8' : Begin {fill screen with 'E'}
                                 x := WhereXabs;
                                 y := WhereYabs;
                                 Push_Window;
                                 Window(1,1,Last_Col, Last_Row);
                                 TextChar := 'E';
                                 Clrscr;
                                 Pop_Window;
                                 GotoXYabs(x,y);
                              End;
                     End;
               End;

         '_' : Begin
                  If Get_Ch(xCh1) then
                     If Get_Ch(xCh2) then
                        GotoXY(Ord(xCh2)-31,Ord(xCh1)-31);
               End;

         '!' : Begin
                  T_Margin := 1;
                  B_Margin := Real_Last_Row;
                  If qq.ShowStatusLine then
                     Dec(B_Margin);
                  Newline  := False;
                  Decom    := False;
                  G0_Mode  := True;
                  G0_Graphics := False;
                  G1_Graphics := False;
                  Do_Graphics := False;
                  CursorKeyMode := False;
                  LineWrap := qq.LineWrap;
                  Reset_Tabstops;
                  Reset_Term_Colors;
               End;

         ')' : Begin
                  If Get_Ch(Ch) then
                     Begin
                        If CH = '0' Then
                           Begin
                              G1_Graphics := True;
                              If Not G0_Mode Then
                                 Do_Graphics := True;
                           End
                        Else
                           Begin
                              G1_Graphics := False;
                              If Not G0_Mode Then
                                 Do_Graphics := False;
                           End;
                     End;
               End;

         '(' : Begin
                  If Get_Ch(Ch) then
                     Begin
                        If CH = '0' Then
                           Begin
                              G0_Graphics := True;
                              If G0_Mode Then
                                 Do_Graphics := True;
                           End
                        Else
                           Begin
                              G0_Graphics := False;
                              If G0_Mode Then
                                 Do_Graphics := False;
                           End
                     End
               End;

         'n' : If Asc2int(Save_Ansi_Str) = 5 Then
                  Write_Byte(#27 + '[0n')
               Else
                  If Asc2int(Save_Ansi_Str) = 6 Then
                     Begin
                        ResetColumn;
                        Str(WhereYabs, t1);
                        Str(WhereXabs, t2);
                        Write_Byte(#27 + '[' + t1 + ';'+t2 + 'R');
                     End;

         'J' : Begin
                  Savey := emul_color;
                  Set_Full_Screen;
                  Reset_Term_Colors;
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
                  Savey := emul_color;
                  ResetColumn;
                  Reset_Term_Colors;
                  If (Save_Ansi_Str = '') Or (Asc2int(Save_Ansi_Str) = 0) Then
                     Clreol
                  Else
                     Case Asc2int(Save_Ansi_Str) Of
                        1 : Begin
                               x := WhereX;
                               GotoXY(1, WhereY);
                               For y := 1 To x Do Write(' ');
                               Write(^H);
                            End;
                        2 : Begin
                               GotoXY(1, WhereY);
                               Clreol;
                            End;
                        Else Show_Bogus_ANSI(CH);
                     End;
                  Emul_Color := Savey;
                  TextAttr := Savey;
            End;

         's',
         '7' : Begin
                  ResetColumn;
                  Save_Emul_X := WhereXabs;
                  Save_Emul_Y := WhereYabs;
                  xx_c := emul_color;
                  Save_Graphics := Do_Graphics;
               End;

         'u',
         '8' : Begin
                  Set_Full_Screen;
                  GotoXYabs(Save_Emul_X, Save_Emul_Y);
                  emul_color := xx_c;
                  Do_Graphics := Save_Graphics;
                  Set_Colors;
               End;

         'c' : Write_Byte(#27 + '[?1;0c'); { Device Attributes }

         'H', 'f' : Begin
                       Set_Full_Screen;
                       If (Save_Ansi_Str = '') Or (Save_Ansi_Str = ';') Then
                          GotoXY(1, 1)
                       Else
                          Begin
                             If Save_Ansi_Str[Length(Save_Ansi_Str)] = ';' Then
                                Save_Ansi_Str := Save_Ansi_Str + '1';
                             x := SearchLeftC(Save_Ansi_Str, ';');
                             If x = 0 Then
                                GotoXY(1, Max(1,Asc2int2(Save_Ansi_Str)))
                             Else
                                If x = 1 Then
                                   GotoXY(Max(1,Asc2int2(Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0])))), 1)
                                Else
                                   GotoXY(Max(1,Asc2int2(Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0])))),
                                          Max(1,Asc2int2(Copy(Save_Ansi_Str, 1, x - 1))));
                          End;
                    End;

         'r' : Begin { Set Scrolling Region }
                  If (Save_Ansi_Str = '') Or (Save_Ansi_Str = ';') Then
                     Begin
                        T_Margin := 1;
                        B_Margin := Last_Row;
                     End
                  Else
                     Begin
                        If Save_Ansi_Str[Length(Save_Ansi_Str)] = ';' Then
                           Save_Ansi_Str := Save_Ansi_Str + '1';
                        x := SearchLeftC(Save_Ansi_Str, ';');
                        If x = 0 Then
                           Begin
                              T_Margin := Asc2int(Save_Ansi_Str);
                              B_Margin := Last_Row;
                           End
                        Else
                           If x = 1 Then
                              Begin
                                 T_Margin := 1;
                                 B_Margin := Asc2int(Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0])));
                              End
                           Else
                              Begin
                                 T_Margin := Asc2int(Copy(Save_Ansi_Str, 1, x - 1));
                                 B_Margin := Asc2int(Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0])));
                              End;
                     End;
                  If B_Margin = 0 then B_Margin := Last_Row;
                  If T_Margin = 0 then T_Margin := 1;
                  Set_Full_Screen;
                  GotoXY(1,1);
               End;

         'D' : Begin
                  Set_Full_Screen;
                  x := 0;
                  If Save_Ansi_Str = '' Then
                     x := 1
                  Else
                     Begin
                        y := Asc2int(Save_Ansi_Str);
                        If y = 0 then y := 1;
                        If y = -1 Then Show_Bogus_ANSI(CH)
                                  Else x := y;
                     End;
                  ResetColumn;
                  If WhereX - x < 1 Then GotoXY(1, WhereY)
                                    Else GotoXY(WhereX - x, WhereY);
               End;

         'C' : Begin
                  Set_Full_Screen;
                  x := 0;
                  If Save_Ansi_Str = '' Then
                     x := 1
                  Else
                     Begin
                        y := Asc2int(Save_Ansi_Str);
                        If y = 0 then y := 1;
                        If y = -1 Then Show_Bogus_ANSI(CH)
                                   Else x := y;
                     End;
                  ResetColumn;
                  If WhereX + x > Last_Col Then GotoXY(Last_Col, WhereY)
                                           Else GotoXY(WhereX + x, WhereY);
               End;

         'B' : Begin
                  Set_Full_Screen;
                  x := 0;
                  If Save_Ansi_Str = '' Then
                     x := 1
                  Else
                     Begin
                        y := Asc2int(Save_Ansi_Str);
                        If y = 0 then y := 1;
                        If y = - 1 Then Show_Bogus_ANSI(CH)
                                   Else x := y;
                     End;
                  ResetColumn;
                  If WhereY + x > Last_Row Then GotoXY(WhereX, Last_Row)
                                           Else GotoXY(WhereX, WhereY + x);
               End;

         'A' : Begin
                  Set_Full_Screen;
                  x := 0;
                  If Save_Ansi_Str = '' Then
                     x := 1
                  Else
                     Begin
                        y := Asc2int(Save_Ansi_Str);
                        If y = 0 then y := 1;
                        If y = -1 Then Show_Bogus_ANSI(CH)
                                   Else x := y;
                     End;
                  ResetColumn;
                  If WhereY - x < 1 Then GotoXY(WhereX, 1)
                                    Else GotoXY(WhereX, WhereY - x);
               End;

         'm' : Begin
                  SetEmmColor;
               End;

         'h' : If SearchLeftC(Save_Ansi_Str, '?') > 0 Then { only accept those with ? }
                  Begin
                     Save_Ansi_Str := Copy(Save_Ansi_Str,2,Length(Save_Ansi_Str)-1);
                     Repeat
                        x := SearchLeftC(Save_Ansi_Str, ';');
                        If x = 1 Then
                           Begin
                              Temp := '0';
                              Save_Ansi_Str := Copy(Save_Ansi_Str, 2, Byte(Save_Ansi_Str[0]) - 1);
                           End
                        Else
                           If x <> 0 Then
                              Begin
                                 Temp := Copy(Save_Ansi_Str, 1, x - 1);
                                 Save_Ansi_Str := Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0]));
                              End
                           Else
                              Begin
                                 Temp := Save_Ansi_Str;
                                 Save_Ansi_Str[0] := #0;
                              End;
                        Case Asc2int(Temp) Of
                           1 : CursorKeyMode := True;
                           6 : Decom := True;
                           7 : Begin
                                  LineWrap := True;
                                  If WhereX = Last_Col then
                                     LastWas80 := True;
                               End;
                           20: Newline := True;
                        End;
                     Until Save_Ansi_Str[0] = #0;
                  End;

         'l' : If SearchLeftC(Save_Ansi_Str, '?') > 0 Then
                  { only accept those with ? }
                  Begin
                     Save_Ansi_Str := Copy(Save_Ansi_Str,2,Length(Save_Ansi_Str)-1);
                     Repeat
                        x := SearchLeftC(Save_Ansi_Str, ';');
                        If x = 1 Then
                           Begin
                              Temp := '0';
                              Save_Ansi_Str := Copy(Save_Ansi_Str, 2, Byte(Save_Ansi_Str[0]) - 1);
                           End
                        Else
                           If x <> 0 Then
                              Begin
                                 Temp := Copy(Save_Ansi_Str, 1, x - 1);
                                 Save_Ansi_Str := Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0]));
                              End
                           Else
                              Begin
                                 Temp := Save_Ansi_Str;
                                 Save_Ansi_Str[0] := #0;
                              End;
                        Case Asc2int(Temp) Of
                           1 : CursorKeyMode := False;
                           6 : Decom := False;
                           7 : LineWrap := False;
                           20: Newline := False;
                        End;
                     Until Save_Ansi_Str[0] = #0;
                  End;

         '*' : Begin
                  ResetColumn;
                  TabStops[WhereX] := 1;
               End;

         'g' : Begin
                  ResetColumn;
                  If (Save_Ansi_Str = '') Or (Save_Ansi_Str = '0') Then
                     TabStops[WhereX] := 0
                  Else
                     If (Save_Ansi_Str = '3') Then
                        For x := 1 To Last_Col Do TabStops[x] := 0;
               End;
         {'?' : Last dummy arg for large CASE }

      End;
      Save_Ansi_Str[0] := #0;
      Ansi_Mode := No_Esc;
   End;

   Procedure outkey_VT100(CH : String);
   Var
      y, x   : Integer;
      Savey  : Byte;
      wc         : WindowCoordinates;

   Label
      DupeESC, ShowIt;

   Begin                          {Outkey_VT100}
      For x := 1 To Length(CH) Do
         Begin
            Case Ansi_Mode Of
               No_Esc    : Begin
                              DupeESC:
                              Check_Decom;
                              Case CH[x] Of
                                 #27,
                                 #155 : Ansi_Mode := Got_Esc;
                                 #8   : Interpret_B_Codes('D');
                                 #9   : PrtTab;
                                 ^Q,
                                 ^S   : If not Xon_Xoff then
                                           Goto ShowIt;
                                 #10  : If (WhereYAbs > B_Margin) and
                                           (WhereYabs = Last_Row) Then
                                           { do nothing }
                                        Else
                                           Begin
                                              Savey := Emul_Color;
                                              Reset_Term_Colors;
                                              If Newline Then
                                                 Begin
                                                    EmulsAnsiVT100Disp(#13);
                                                    EmulsAnsiVT100Disp(Ch[x]);
                                                 End
                                              Else
                                                 EmulsAnsiVT100Disp(Ch[x]);
                                              Emul_Color := Savey;
                                              TextAttr := Savey;
                                           End;
                                 ^O   : Begin
                                           If G0_Graphics Then Do_Graphics := True
                                                          Else Do_Graphics := False;
                                           G0_Mode := True;
                                        End;
                                 ^N   : Begin
                                           If G1_Graphics Then Do_Graphics := True
                                                          Else Do_Graphics := False;
                                           G0_Mode := False;
                                        End;
                                 ^G   : Begin
                                           If Noise then
                                              Begin
                                                 Sound (700);
                                                 Delay (90);
                                                 NoSound;
                                              End;
                                        End;
                              Else
                                 Begin
                                    ShowIt:

                                    If CH[x] = #127 Then
                                       CH[x] := #8;

                                    If Do_Graphics Then
                                       Translate_G(CH[x]);

                                    EmulsAnsiVT100Disp(Ch[x]);

                                 End;
                              End;
                           End;

               Got_Esc   : Begin
                              If CH[x] = ^[ then
                                 Goto DupeESC;
                              Check_DECOM;
                              Case CH[x] Of
                                 'D' : Interpret_B_Codes('');
                                 'E' : Interpret_B_Codes('');
                                 'M' : Interpret_B_Codes('~');
                                 'c' : Interpret_B_Codes('!');
                                 'Z' : Interpret_B_Codes('c');
                                 'H' : Interpret_B_Codes('*');
                                 'Y' : Interpret_B_Codes('_');
                                 'F', 'G' : ;
                                 'A'..'C',
                                 'H'..'K',
                                 '7', '8', '<', '=', '>', 'N', 'O',
                                 '(', ')', '#',
                                 '\' : Interpret_B_Codes(CH[x]);
                                 '[' : Ansi_Mode := Got_Esc_B;
                              Else
                                 Begin
                                    Write(#27 + CH[x]);
                                    Ansi_Mode := No_Esc;
                                 End;
                              End;
                           End;

               Got_Esc_B : Begin
                              Case CH[x] Of
                              '0'..'9', ';', 'H', 'A', 'B', 'C', 'D', '=', '?', 'M',
                              'c', 'q', 'x', 'r', 'y', 'n', 'h', 'g', 'i', 'L',
                              'f', 'R', 's', 'u', 'J', 'K', 'm', 'h', 'l', 'R',
                              '@', 'P' :
                                 If ((CH[x] >= '0') And (CH[x] <= '9')) Or
                                 (CH[x] = '?') Or (CH[x] = ';') Then
                                    Add_Ch_to_Ansi(CH[x])
                                 Else
                                    Interpret_B_Codes(CH[x]);
                              Else
                                 Show_Bogus_ANSI(CH[x]);
                              End;
                           End;

            End;
         End;
   End;

End.
