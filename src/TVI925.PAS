Unit EmulTVI;

Interface

Uses
   Dos,       TPCrt,
   TPString,  Initial,
   LowProcs,  Comm,
   Procs,     Emullow;

Procedure outkey_TVI925(CH : String);


Implementation


   Procedure outkey_TVI925(CH : String);
   Var
      x              : Integer;

      Procedure Show_Bogus_TVI(CH : Char);
      Begin
         Write('<<' + #27 + CH + '>>');
         Ansi_Mode := No_Esc;
      End;

      Procedure Interpret_Ansi_Codes(CH : Char);
      Var
         x, y, z        : Integer;
         Ch1            : Char;
      Begin
         If CH In ['f', 'g'] Then
            Case CH Of
               'f' : Begin
                        Cmd_Str := '';
                        Repeat
                           Ch1 := Get_Ch;
                           If Ch1 <> #13 Then Cmd_Str := Cmd_Str + Ch1;
                        Until (Ch1 = #13) Or (Length(Cmd_Str) > 79);
                     End;
               'g' : Display_Status(Cmd_Str);
            End
         Else
            Case CH Of
               '?' : Begin
                        Write_Byte(Chr(WhereY + 31) + Chr(WhereX + 31) + #13);
                     End;
               '/' : Begin
                        Write_Byte('0' + Chr(WhereY + 31) + Chr(WhereX + 31) + #13);
                     End;
               '-' : Begin
                        Ch1 := Get_Ch; { Page if implemented }
                        x := Ord(Get_Ch) - 31;
                        y := Ord(Get_Ch) - 31;
                        GotoXY(y, x);
                        Set_Cursor(True);
                     End;
               ')' : Begin
                        emul_color := qq.txtcolor;
                        Set_Colors;
                     End;
               '(' : Begin
                        emul_color := qq.stat;
                        Set_Colors;
                     End;
               'G' : Begin
                        Ch1 := Get_Ch;
                        Case Ch1 Of
                           '0' :
                           Begin
                                    emul_color := 15;
                                 End;
                           '2' : emul_color := emul_color Or 16;
                           '4' :
                           Begin
                                    emul_color := $30;
                                 End;
                        Else
                        Begin
                              emul_color := 15;
                           End;
                        End;
                        Set_Colors;
                     End;
               ^^  : GotoXY(1, 1);
               ^z,
               '+',
               '*' : ClrScr;
               'T' : Clreol;
               'R' : DelLine;
               'E' : InsLine;
               'Y',
               'y' : Begin
                        Save_Emul_X := WhereX;
                        Save_Emul_Y := WhereY;
                        Clreol;
                        If WhereY < 24 Then
                           Begin
                              GotoXY(1, WhereY + 1);
                              For x := 1 To 25 - WhereY Do DelLine;
                              GotoXY(Save_Emul_X, Save_Emul_Y);
                           End;
                     End;
               '=' : Begin
                        Repeat
                        Until CommPressed;
                        y := Ord(Cinkey) - 31;
                        Repeat
                        Until CommPressed;
                        x := Ord(Cinkey) - 31;
                        GotoXY(x, y);
                     End;
               ^H : Begin { Cursor Left }
                       If WhereX - 1 < 1 Then GotoXY(1, WhereY)
                       Else GotoXY(WhereX - 1, WhereY);
                    End;
               ^L : Begin { Cursor Right }
                       If WhereX + 1 > Last_Col Then GotoXY(Last_Col, WhereY)
                       Else GotoXY(WhereX + 1, WhereY);
                    End;
               ^V : Begin { Cursor Down }
                       If WhereY + 1 > 24 Then GotoXY(WhereX, 24)
                       Else GotoXY(WhereX, WhereY + 1);
                    End;
               ^K : Begin { Cursor Up }
                       If WhereY - 1 < 1 Then GotoXY(WhereX, 1)
                       Else GotoXY(WhereX, WhereY - 1);
                    End;
               '#' : Begin
                        {Keyboard_Lock := True;}
                        While Keypressed Do
                           CH := ReadKeyA; { Flush Buffer }
                     End;
               '"' : {Keyboard_Lock := False} ;
            End;
         Save_Ansi_Str[0] := #0;
         Ansi_Mode := No_Esc;
      End;

   Begin                          { Outkey_TVI925 }
      For x := 1 To Length(CH) Do
         Case Ansi_Mode Of
            Got_Esc : Case CH[x] Of
                         '*', '+', '=', 'f', 'g',
                         ')', '(', 'R', 'E', 'T',
                         'Y', 'y', 'G', '"', '#',
                         '?', '-', '/'
                         : Interpret_Ansi_Codes(CH[x]);
                      Else
                         Show_Bogus_TVI(CH[x]);
                      End;        { Case }
         Else
            If CH[x] = #27 Then
               Ansi_Mode := Got_Esc
            Else
               Case CH[x] Of
                  ^H, ^L, ^V, ^K,
                  ^N, ^O, ^Z, ^^: Interpret_Ansi_Codes(CH[x]);
                  Else            Write(Chr(Ord(CH[x]) And 127));
               End;               { Case }
         End;                     { Case }
   End;

End.
