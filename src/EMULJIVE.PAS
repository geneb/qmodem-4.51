Unit EmulJIVE;

Interface
Uses TPCrt,
     Initial,
     Comm,
     Procs,
     Emullow;


Procedure outkey_JIVE(CH : String);


Implementation


   Procedure Show_Bogus_JIVE(CH : Char);
   Var
      Temp           : String;
      x              : Integer;
   Begin
      Temp := #27 + '[' + Save_ANSI_Str + CH;
      For x := 1 To Byte(Temp[0]) Do
         Begin
            Store_Cinkey(Temp[x]);
            Write(Temp[x]);
         End;
      Save_ANSI_Str[0] := #0;
      ANSI_Mode := No_Esc;
   End;


   Procedure outkey_JIVE(CH : String);
   Var
      x              : Integer;

      Procedure Interpret_JIVE_Codes(CH : Char);
      Var
         x, y, z        : Integer;
         Temp           : String[3];
      Label
         Out;
      Begin
         Case CH of
            ' ' :
                  If LastCommStringx(3) = '.  ' then
                     Begin
                        If random(7)=1 then Begin
                           Case Random(5) of
                              0 : Write (' What it is, Mama!  ');
                              1 : Write (' Ah be baaad...  ');
                              2 : Write (' Man!  ');
                              3 : Write (' Slap mah fro!  ');
                              4 : Write (' ''S coo'', bro.  ');
                           End;
                        End
                        Else goto Out
                     End Else
                  If LastCommStringx(4) = 'per ' then Write(^H^H'uh'' ') else
                  If LastCommStringx(3) = 'er ' then Write(^H^H'a'' ') else
                  If LastCommStringx(4) = 'ing ' then Write(^H''' ') else
                  If LastCommStringx(2) = 'r ' then Write(^H''' ') else
                  If LastCommStringx(3) = ' a ' then Write(^H'some ') else
                  goto out;
            'r' :
                  If LastCommStringx(2) = 'or' then Write('''') else
                  If LastCommStringx(5) = ' your' then Write(^H^H^H'yo''') else
                  goto out;
            'o' :
                  If LastCommStringx(3) = ' to' then Write('''') else
                  goto out;
            'e' :
                  If LastCommStringx(8) = ' and the' then Write(^H^H'da damn') else
                  If LastCommStringx(4) = ' the' then Write(^H^H'de') else
                  If LastCommStringx(5) = ' file' then Write(^H^H^H'stash') else
                  If LastCommStringx(3) = 'The' then Write(^H^H'De') else
                  If LastCommStringx(6) = ' these' then Write(^H^H^H^H'dese') else
                  If LastCommStringx(5) = ' some' then Write(^H^H^H'a') else
                  If LastCommStringx(4) = 'name' then Write(^H^H^H'dojigger') else
                  goto out;
            's' :
                  If LastCommStringx(3) = ' is' then Write(^H'be') else
                  goto out;
            't' :
                  If LastCommStringx(5) = ' just' then Write(^H^H^H'plum') else
                  goto out;
            'l' :
                  If LastCommStringx(5) = ' will' then Write(^H^H^H'gots''ta') else
                  goto out;
            'n' :
                  If LastCommStringx(4) = 'tion' then Write(^H^H^H'shun') else
                  goto out;
            'h' :
                  If LastCommStringx(5) = ' path' then Write(^H^H^H'alley') else
                  If LastCommStringx(4) = 'path' then Write(^H^H^H'pad') else
                  goto out;
            'm' :
                  If LastCommStringx(5) = ' from' then Write(^H^H^H'fum') else
                  If LastCommStringx(7) = ' program' then Write(^H^H^H^H^H^H'honky code') else
                  goto out;
            'f' :
                  If LastCommStringx(3) = ' of' then Write(^H'uh') else
                  goto out;
            'p' :
                  If LastCommStringx(2) = 'up' then Write(^H'down') else
                  goto out;
            'x' :
                  If LastCommStringx(3) = ' ex' then Write(^H'''es') else
                  goto out;
            'd' :
                  If LastCommStringx(6) = ' board' then Write(^H^H^H^H'bo''d') else
                  goto out;
            {':' : Write(', dig dis:');}
            Else
               Begin
                  Out:
                  Store_Cinkey(Ch);
                  Write(CH);
               End
         End
      End;


      Procedure Interpret_ANSI_Codes(CH : Char);
      Var
         x, y, z        : Integer;
         Temp           : String[3];
      Begin
         Case CH Of
            'M' : ;               { ANSI Music String... Ignore this one }
            'J' : If Asc2int(Save_ANSI_Str) = 2 Then ClrScr
                  Else Show_Bogus_JIVE(CH);
            'K' : Clreol;
            's' : Begin
                     Save_Emul_X := WhereX;
                     Save_Emul_Y := WhereY;
                  End;
            'u' : GotoXY(Save_Emul_X, Save_Emul_Y);
            'H', 'f' : If (Save_ANSI_Str = '') or (Save_ANSI_Str = ';') Then
                          GotoXY(1, 1)
                       Else
                          Begin
                             If Save_ANSI_Str[Length(Save_ANSI_Str)] = ';' Then
                                Save_ANSI_Str := Save_ANSI_Str + '1';
                             x := SearchLeftC(Save_ANSI_Str, ';');
                             If x = 0 Then
                                GotoXY(1, Asc2int2(Save_ANSI_Str))
                             Else
                                If x = 1 Then
                                   GotoXY(Asc2int2(Copy(Save_ANSI_Str, x + 1, Byte(Save_ANSI_Str[0]))), 1)
                                Else
                                   GotoXY(Asc2int2(Copy(Save_ANSI_Str, x + 1, Byte(Save_ANSI_Str[0]))),
                                          Asc2int2(Copy(Save_ANSI_Str, 1, x - 1)));
                          End;
            'D' : Begin
                     If Save_ANSI_Str = '' Then x := 1
                     Else
                     Begin
                        y := Asc2int(Save_ANSI_Str);
                        If y = - 1 Then Show_Bogus_JIVE(CH)
                        Else x := y;
                     End;
                     If WhereX - x < 1 Then GotoXY(1, WhereY)
                     Else GotoXY(WhereX - x, WhereY);
                  End;
            'C' : Begin
                     If Save_ANSI_Str = '' Then x := 1
                     Else
                     Begin
                        y := Asc2int(Save_ANSI_Str);
                        If y = - 1 Then Show_Bogus_JIVE(CH)
                        Else x := y;
                     End;
                     If WhereX + x > Last_Col Then GotoXY(Last_Col, WhereY)
                     Else GotoXY(WhereX + x, WhereY);
                  End;
            'B' : Begin
                     If Save_ANSI_Str = '' Then x := 1
                     Else
                     Begin
                        y := Asc2int(Save_ANSI_Str);
                        If y = - 1 Then Show_Bogus_JIVE(CH)
                        Else x := y;
                     End;
                     If WhereY + x > Last_Row Then GotoXY(WhereX, Last_Row)
                     Else GotoXY(WhereX, WhereY + x);
                  End;
            'A' :
            Begin
                     If Save_ANSI_Str = '' Then x := 1
                     Else
                     Begin
                        y := Asc2int(Save_ANSI_Str);
                        If y = - 1 Then Show_Bogus_JIVE(CH)
                        Else x := y;
                     End;
                     If WhereY - x < 1 Then GotoXY(WhereX, 1)
                     Else GotoXY(WhereX, WhereY - x);
                  End;
            'm' : If Save_ANSI_Str = '' Then
                     Begin
                        emul_color := LightGray;
                     End
                  Else
                     Begin
                        Repeat
                           x := SearchLeftC(Save_ANSI_Str, ';');
                           If x <> 0 Then
                              Begin
                                 Temp := Copy(Save_ANSI_Str, 1, x - 1);
                                 Save_ANSI_Str := Copy(Save_ANSI_Str, x + 1, Byte(Save_ANSI_Str[0]));
                              End
                           Else
                              Begin
                                 Temp := Save_ANSI_Str;
                                 Save_ANSI_Str[0] := #0;
                              End;
                           Case Asc2int(Temp) Of
                              0 : emul_color := LightGray;
                              1 : emul_color := emul_color Or 8;
                              4 : emul_color := (emul_color And 119) Or 1;
                              5 : emul_color := emul_color Or 128;
                              7 : Emul_Color := $70;
                              8 : emul_color := DarkGray;
                              30 : emul_color := (emul_color And 248) Or Black;
                              31 : emul_color := (emul_color And 248) Or Red;
                              32 : emul_color := (emul_color And 248) Or Green;
                              33 : emul_color := (emul_color And 248) Or Brown;
                              34 : emul_color := (emul_color And 248) Or Blue;
                              35 : emul_color := (emul_color And 248) Or Magenta;
                              36 : emul_color := (emul_color And 248) Or Cyan;
                              37 : emul_color := (emul_color And 248) Or LightGray;

                              40 : emul_color := (emul_color And 143) + Black Shl 4;
                              41 : emul_color := (emul_color And 143) + Red Shl 4;
                              42 : emul_color := (emul_color And 143) + Green Shl 4;
                              43 : emul_color := (emul_color And 143) + Brown Shl 4;
                              44 : emul_color := (emul_color And 143) + Blue Shl 4;
                              45 : emul_color := (emul_color And 143) + Magenta Shl 4;
                              46 : emul_color := (emul_color And 143) + Cyan Shl 4;
                              47 : emul_color := (emul_color And 143) + LightGray Shl 4;
                           End;
                        Until Save_ANSI_Str[0] = #0;
                        Set_Colors;
                     End;
         End;
         Save_ANSI_Str[0] := #0;
         ANSI_Mode := No_Esc;
      End;

   Begin                          {Outkey_JIVE}
      For x := 1 To Length(CH) Do
         Begin
            Case ANSI_Mode Of
               Got_Esc : If CH[x] = '[' Then
                            ANSI_Mode := Got_Esc_B
                         Else
                            Begin
                               Write(#27 + CH[x]);
                               ANSI_Mode := No_Esc;
                            End;

               Got_Esc_B : Case CH[x] Of
                              '0'..'9', ';', 'H', 'A', 'B', 'C', 'D', '=', '?', 'M',
                              'f', 'R', 'n', 's', 'u', 'J', 'K', 'm', 'h', 'l' :
                                 If ((CH[x] >= '0') And (CH[x] <= '9'))
                                 Or (CH[x] = ';')
                                 Or (CH[x] = '=')
                                 Or (CH[x] = '?') Then
                                    Add_Ch_to_ANSI(CH[x])
                                 Else
                                    Interpret_ANSI_Codes(CH[x]);
                           Else
                              Show_Bogus_JIVE(CH[x]);
                           End;   { Case }

            Else If CH[x] = #27 Then
                  ANSI_Mode := Got_Esc
               Else
                     Case CH[x] Of
                        ^G : Begin
                                Sound(600);
                                Delay(90);
                                NoSound;
                             End;
                        Else Interpret_JIVE_Codes(CH[x]);
                  End;
            End;                  { Case }
         End;
   End;

End.
