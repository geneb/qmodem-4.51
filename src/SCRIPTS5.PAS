{$F+}

   Procedure Do_ONLINE_Check(x : Integer);
   Begin
      If Not Online And Online_Check Then
         Begin
            SetString(Script_Strings[x].value, StringToHeap(OffLineString));
            If Script_Strings[x].value = Nil Then
               Script_Edit_Error(186);
         End;
   End;


   Procedure Get_and_Execute_Timeout;
   Var
      x : Word;
   Begin
      If Get_Token_Word(x) Then
         Begin
            Script_Timeout := x;
            Get_Next_Token;
            If token.Token_Type In [tk_word, tk_label] Then
               Script_Timeout_Label := STUpCase(token.Str_Value)
            Else
               Script_Timeout_Label := ''; { Null means Halt the Script }
         End;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_Drive;
   Var
      x              : Integer;
   Begin
      Get_Next_Token;
      If token.Token_Type In [tk_word, tk_label] Then
         If (token.Str_Value[1] In ['a'..'z', 'A'..'Z']) Then
            Log_Drive(Upcase(token.Str_Value[1]))
         Else
            Script_Edit_Error(8)
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_ChDir;
   Begin
      Get_Next_Token;
      If token.Token_Type In [tk_word, tk_label] Then
         Chgdir(token.Str_Value)
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_Edit;
   Begin
      Get_Next_Token;
      If token.Token_Type In [tk_word] Then
         If (qq.Browse_PGM <> '') and (qq.Browse_PGM[1] = '@') then
            ViewFile(token.Str_Value)
         Else
            FSE (token.Str_Value,0,2,Pred(Last_Row),false)
      Else
         If (qq.Browse_PGM <> '') and (qq.Browse_PGM[1] = '@') then
            ViewFile('')
         Else
            FSE ('',0,2,Pred(Last_Row),false);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_Break;
   Begin
      Break;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_SetComm;
   Var
      x              : Integer;
      Ok             : Boolean;
      newstr         : String;
   Begin
      Ok := True;
      newstr := '';
      Repeat
         Get_Next_Token;
         If token.Token_Type = tk_word Then
            Begin
               token.Str_Value := STUpCase(token.Str_Value);
               If token.Str_Value = '110'    Then newstr := newstr + 'A' Else
               If token.Str_Value = '300'    Then newstr := newstr + 'B' Else
               If token.Str_Value = '1200'   Then newstr := newstr + 'C' Else
               If token.Str_Value = '2400'   Then newstr := newstr + 'D' Else
               If token.Str_Value = '4800'   Then newstr := newstr + 'E' Else
               If token.Str_Value = '9600'   Then newstr := newstr + 'F' Else
               If token.Str_Value = '19200'  Then newstr := newstr + 'G' Else
               If token.Str_Value = '38400'  Then newstr := newstr + 'H' Else
               If token.Str_Value = '57600'  Then newstr := newstr + 'I' Else
               If token.Str_Value = '115200' Then newstr := newstr + 'J' Else
               If token.Str_Value = 'EVEN'   Then newstr := newstr + 'K' Else
               If token.Str_Value = 'ODD'    Then newstr := newstr + 'L' Else
               If token.Str_Value = 'NONE'   Then newstr := newstr + 'N' Else
               If token.Str_Value = 'MARK'   Then newstr := newstr + 'M' Else
               If token.Str_Value = 'SPACE'  Then newstr := newstr + 'O' Else
               If token.Str_Value = '7'      Then newstr := newstr + 'P' Else
               If token.Str_Value = '8'      Then newstr := newstr + 'Q' Else
               If token.Str_Value = '1'      Then newstr := newstr + 'R' Else
               If token.Str_Value = '2'      Then newstr := newstr + 'S' Else
                  Begin
                     Script_Edit_Error(9);
                     Exit;
                  End;
                  {newstr := newstr + token.Str_Value;}
            End;
      Until token.Token_Type = tk_end_rec;
      For x := 1 To Byte(newstr[0]) Do
         If Not(newstr[x] In ['A'..'S']) Then
            Ok := False;
      If Ok Then
         Change_Baud(newstr)
      Else
         Begin
            Script_Edit_Error(9);
            Exit;
         End;
   End;                           { SetComm }

   Procedure Get_and_Execute_Flush;
   Var
      Ok             : Boolean;

      Procedure Flush_Keyboard;
      Begin
         Flush_KBD;
         Type_Ahead := '';
         token.Token_Type := tk_end_rec;
      End;

      Procedure Flush_COM;
      Begin
         clear_buffer;
         token.Token_Type := tk_end_rec;
      End;

   Begin
      Ok := True;
      Repeat
         Get_Next_Token;
         If token.Token_Type = tk_word Then
            Begin
               token.Str_Value := STUpCase(token.Str_Value);
               If token.Str_Value = 'ALL' Then
                  Begin
                     Flush_Keyboard;
                     Flush_COM;
                  End
               Else
                  If token.Str_Value = 'KBD' Then
                     Flush_Keyboard
                  Else
                     If token.Str_Value = 'COM' Then
                        Flush_COM
                     Else
                        Begin
                           Script_Edit_Error(80);
                           token.Token_Type := tk_end_rec;
                        End;
            End;
      Until token.Token_Type = tk_end_rec;
   End;                           { Flush }

   Procedure Get_and_Execute_HangUp;
   Begin
      Hangup;
      Script_success := Not Online;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;                           { HangUp }

   Procedure Get_and_Execute_Dial;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_string Then
         If (token.Length > 0) Then
            Begin
               Fonenum := token.Str_Value;
               Dial(Fonenum);
               Show_Script_Status_Line;
            End
         Else
            Script_Edit_Error(3)
      Else
         Script_Edit_Error(4);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { Dial }

   Procedure Get_and_Execute_WaitUntil;
   Var
      Row, Col       : Integer;
   Begin                          { WaitUntil }
      If Get_and_Check_Next_Token(tk_word, 5) Then
         Begin
            WriteLn;
            TextAttr := qq.InfoCOlor;
            Write('Script waiting till ', token.Str_Value, '  Time : ');
            TextAttr := qqColor;
            Col := WhereX;
            Row := WhereY;
            HiddenCursor;
            Repeat
               Delay(150);
               GotoXY(Col, Row);
               Write(TimeS);
               If Keypressed Then
                  Check_Script_Abort;
            Until (Not Scripting) Or (TimeS = token.Str_Value);
            NormalCursor;
            WriteLn;
            Screen_mode_check2;
         End;
      Last_Token.Token_Type := tk_end_rec;
   End;


   Procedure Get_and_Execute_DOSX;
   Var
      RC : Integer;
   Begin
      Get_Next_Token;
      If Token.Token_Type = tk_string Then
         Begin
            If (token.Length > 0) Then
               Begin
                  Save_Screen(1, 1, Last_Col, Real_Last_Row);
                  RC := Shell(token.Str_Value+'', ''+'', ''+'', False, False,False);
                  Init_Port;
                  Term_Ready(True);
                  Restore_Screen;
               End
            Else
               Script_Edit_Error(3);
         End
      Else
         Script_Edit_Error(4);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { DOS }

   Procedure Get_and_Execute_DOS;
   Var
      SaveOptimum : Boolean;
   Begin
      SaveOptimum := qq.MaxShell;
      qq.MaxShell := False;
      Get_and_Execute_DOSX;
      qq.MaxShell := SaveOptimum;
   End;

   Procedure Get_and_Execute_BigDOS;
   Begin
      Get_and_Execute_DOSX;
   End;


   Procedure Get_and_Execute_Beep;
   Var
      x : Word;
   Begin
      If Get_Token_Word(x) Then
         Begin
            Sound(x);
            Delay(150);
            NoSound;
         End;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_Port;
   Begin
      Get_Next_Token;
      If (token.Token_Type = tk_word) And
         (token.Length = 4) then
         Begin
            token.Str_Value := STUpCase(token.Str_Value);
            If Copy(Token.Str_Value,1,3) = 'COM' then
               Begin
                  If token.Str_Value[4] In ['1'..'8'] Then
                     Change_ComPort(token.Str_Value[4]);
               End
            Else
               If Copy(Token.Str_Value,1,3) = 'ISI' then
                  Begin
                     If token.Str_Value[4] In ['1'..'8'] Then
                        Change_ComPort(Chr(
                                       Ord('1')-
                                       Ord(token.Str_Value[4])+
                                       Ord('A')
                                       ));
                  End
               Else
                  Script_Edit_Error(160);
         End
      Else
         Script_Edit_Error(160);
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_System;
   Var
      Ch : Char;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_word Then
         Begin
            Ch := Upcase(token.Str_Value[1]);
            If Ch In ['Y', 'X'] Then
               Begin
                  Scripting := False;
                  Exit_Main := True;
                  Exit_Main_Ch := Ch;
               End
            Else
               Script_Edit_Error(110); { SYSTEM parm not Y or X }
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { System }

   Procedure Get_and_Execute_Push;
   Var
      P  : Pointer;
   Begin
      Get_Next_Token;
      If (token.Token_Type = tk_word) Or
         (token.Token_Type = tk_string) Then
         Begin
            If Push_n_Pop < Max_Push_Pops Then
               Begin
                  Inc(Push_n_Pop);
                  P := StringToHeap(token.Str_Value);
                  If P <> Nil Then
                     SetString(Push_Pop_Strings[Push_n_Pop], P)
                  Else
                     Script_Edit_Error(186);
               End
            Else
               Script_Edit_Error(185);
         End
      Else
         Script_Edit_Error(17);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_Pop;
   Var
      x              : Integer;
   Begin
      Get_Next_Token;
      If (token.Token_Type = tk_word) Then
         Begin
            x := Script_string_num(token.Str_Value);
            If x > 0 Then
               Begin
                  If Push_n_Pop > 0 Then
                     Begin
                        SetString(Script_Strings[x].value, Push_Pop_Strings[Push_n_Pop]);
                        Push_Pop_Strings[Push_n_Pop] := Nil;
                        Dec(Push_n_Pop);
                     End
                  Else
                     SetString(Script_Strings[x].value, Nil);
               End
            Else
               Script_Edit_Error(120);
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_Get(Trans, Resend : Boolean);
   Var
      CH          : Char;
      y, x, x2,
      Total_Chars : Word;
      Temp        : String;
      TempX       : Byte Absolute Temp;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_word Then
         Begin
            x := Script_string_num(token.Str_Value);
            If x >= 0 Then
               Begin
                  If Get_Token_Word(x2) Then
                     Total_Chars := x2
                  Else
                     Begin
                        Script_Edit_Error(7); { not an integer ?! }
                        Exit;
                     End;
                  y := 0;
                  Temp[0] := #0;
                  Set_Colors;
                  CH := #32;
                  Repeat
                     If (CommPressed And Trans) Or
                         Keypressed Or (Type_Ahead <> '') Then
                        Begin
                           If CommPressed And Trans Then
                              CH := Cinkeyz
                           Else
                              If Type_Ahead <> '' Then
                                 Begin
                                    CH := Type_Ahead[1];
                                    Delete(Type_Ahead, 1, 1);
                                 End
                              Else
                                 Begin
                                    Check_Script_Abort;
                                    CH := #0;
                                 End;
                           Case CH Of
                              #0 : ;
                              #10, #13 : Begin
                                            WriteLn;
                                            SetString(Script_Strings[x].value,
                                                      StringToHeap(Temp));
                                            If Script_Strings[x].value = Nil Then
                                               Begin
                                                  Script_Edit_Error(186);
                                                  Exit;
                                               End;
                                            If Trans And Resend Then
                                               Write_Byte(^M^J);
                                         End;
                              #8, #127 : If y > 0 Then
                                            Begin
                                               Write(CH);
                                               Write(' ');
                                               Write(CH);
                                               Dec(y);
                                               If Trans And Resend Then
                                                  Write_Byte(CH);
                                               If Temp[Byte(Temp[0])] In ['''', '"', '$'] Then
                                                  Dec(Tempx);
                                               Dec(Tempx);
                                            End;
                              #255,
                              '''',
                              '"',
                              '$' : If y < Total_Chars Then
                                       Begin
                                          Write(CH);
                                          If Trans And Resend Then
                                             Write_Byte(CH);
                                          Temp := Temp + #255 + CH;
                                          Inc(y);
                                       End;

                           Else     If y < Total_Chars Then
                                       Begin
                                          Write(CH);
                                          If Trans And Resend Then
                                             Write_Byte(CH);
                                          Temp := Temp + CH;
                                          Inc(y);
                                       End;
                           End;
                        End;
                  Until Not Scripting Or (CH In [#10, #13]) Or
                  (Not Online And Online_Check);
                  Do_ONLINE_Check(x);
               End
            Else
               Script_Edit_Error(120); { String Parameter Expected }
         End
      Else
         Script_Edit_Error(120);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { GetStr }

   Procedure Get_and_Execute_Getx; { Format : GETX [String] [# to get] [EndCh] }
   Var
      EndCh, CH   : Char;
      y, x, x2,
      Total_Chars : Word;
      Temp        : String;
      TempLen     : Byte absolute Temp;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_word Then
         Begin
            x := Script_string_num(token.Str_Value);
            If x >= 0 Then
               Begin
                  If Get_Token_Word(x2) Then
                     Total_Chars := x2
                  Else
                     Begin
                        Script_Edit_Error(7); { not an integer ?! }
                        Exit;
                     End;
                  Get_Next_Token;
                  If (token.Token_Type = tk_word) Or
                     (token.Token_Type = tk_string) Then
                     EndCh := token.Str_Value[1]
                  Else
                     Begin
                        Script_Edit_Error(17);
                        Exit;
                     End;
                  y := 0;
                  TempLen := 0;
                  Set_Colors;
                  CH := #32;
                  Repeat
                     If CommPressed Or Keypressed Or (Type_Ahead <> '') Then
                        Begin
                           If CommPressed Then
                              CH := Cinkeyz
                           Else
                              If Type_Ahead <> '' Then
                                 Begin
                                    CH := Type_Ahead[1];
                                    Delete(Type_Ahead, 1, 1);
                                 End
                              Else
                                 Begin
                                    Check_Script_Abort;
                                    CH := #0;
                                 End;

                           If CH = EndCh Then
                              Begin
                                 SetString(Script_Strings[x].value,
                                           StringToHeap(Temp));
                                 If Script_Strings[x].value = Nil Then
                                    Script_Edit_Error(186);
                                 Exit;
                              End;
                           If Ch <> #0 then
                              OutKey(CH);
                           Case CH Of
                              #0, #10, #13 : ;
                              #8,
                              #127 : If y > 0 Then
                                        Begin
                                           Dec(y);
                                           If Temp[Byte(Temp[0])] In ['''', '"', '$'] Then
                                              Dec(TempLen);
                                           Dec(TempLen);
                                        End;
                              '''',
                              '"',
                              '$'  : If y < Total_Chars Then
                                        Begin
                                           Temp := Temp + #255 + CH;
                                           Inc(y);
                                        End;
                           Else
                              If y < Total_Chars Then
                                 Begin
                                    Temp := Temp + CH;
                                    Inc(y);
                                 End;
                           End;
                        End;
                  Until Not Scripting Or
                        (CH In [#10, #13]) Or
                        (y = Total_Chars) Or
                        (Not Online And Online_Check);
                  SetString(Script_Strings[x].value, StringToHeap(Temp));
                  If Script_Strings[x].value = Nil Then
                     Script_Edit_Error(186);
                  Do_ONLINE_Check(x);
               End
            Else
               Script_Edit_Error(120); { String Parameter Expected }
         End
      Else
         Script_Edit_Error(120);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { GetX }

   Procedure Get_and_Execute_InKey;
   Var
      CH       : Char;
      y, x, x2 : Integer;
      Temp     : String[2];
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_word Then
         Begin
            x := Script_string_num(token.Str_Value);
            If x >= 0 Then
               Begin
                  CH := #0;
                  Temp := '';
                  Repeat
                     If CommPressed Or Keypressed Or (Type_Ahead <> '') Then
                        Begin
                           If CommPressed Then
                              CH := CinkeyZ
                           Else
                              If Type_Ahead <> '' Then
                                 Begin
                                    CH := Type_Ahead[1];
                                    Delete(Type_Ahead, 1, 1);
                                 End
                              Else
                                 Begin
                                    Check_Script_Abort;
                                    CH := #0;
                                 End;
                        End;
                  Until Not Scripting Or (CH <> #0) Or
                  (Not Online And Online_Check);
                  If Ch in ['''','"','$',#255] then
                     Temp := Temp + #255 + CH
                  Else
                     Temp := Temp + CH;
                  SetString(Script_Strings[x].value, StringToHeap(Temp));
                  If Script_Strings[x].value = Nil Then
                     Begin
                        Script_Edit_Error(186);
                        Exit;
                     End;
                  Do_ONLINE_Check(x);
               End
            Else
               Script_Edit_Error(120); { String Parameter Expected }
         End
      Else
         Script_Edit_Error(120);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { Inkey }

   Procedure Get_and_Execute_Debug;
   Var
      T  : String;
      CH : Char;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_word Then
         Begin
            T := STUpCase(token.Str_Value);
            If (T = 'ON') Or (T = 'OFF') Then
               Begin
                  Script_Animate := False;
                  If T = 'ON' Then Script_Debug := True
                  Else Script_Debug := False;
               End
            Else
               Script_Edit_Error(70);
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { Debug }


   Procedure Get_and_Execute_When;
   Var
      t1, t2 : String;
   Begin
      If Script_total_Whens <= Max_Whens Then
         Repeat
            Get_Next_Token;
            If (token.Token_Type = tk_string)
            And (token.Length > 0)
            And (Script_total_Whens < Max_Whens) Then
               Begin
                  t1 := token.Str_Value;
                  Get_Next_Token;
                  If IsKeyword(Token.Str_Value) then
                     Begin
                        Script_Edit_Error(16);
                        Exit;
                     End;
                  If token.Token_Type In [tk_string, tk_word] Then
                     Begin
                        t2 := token.Str_Value;
                        Inc(Script_total_Whens);
                        Script_Whens := True;
                        If CaseSensitive then
                           Script_when_stack[Script_total_Whens].Recv_String_LastChar :=
                           t1[Length(t1)]
                        Else
                           Script_when_stack[Script_total_Whens].Recv_String_LastChar :=
                           UpCase(t1[Length(t1)]);
                        SetString(Script_when_stack[Script_total_Whens].recv_string,
                                  StringToHeap(t1));
                        SetString(Script_when_stack[Script_total_Whens].send_string,
                                  StringToHeap(t2));
                        If (Script_when_stack[Script_total_Whens].recv_string = Nil) Or
                           (Script_when_stack[Script_total_Whens].send_string = Nil) Then
                           Begin
                              Script_Edit_Error(186);
                              Exit;
                           End;
                     End;

                  If token.Token_Type = tk_string Then
                     Begin
                        If token.Length > 0 Then
                           Begin
                              Script_when_stack[Script_total_Whens].SLabel := False;
                              token.Token_Type := tk_end_rec;
                              Exit;
                           End
                        Else
                           Script_Edit_Error(3); { String length 0 error }
                        If token.Token_Type = tk_end_rec Then
                           Script_Edit_Error(4); { String expected error }
                        token.Token_Type := tk_end_rec;
                     End
                  Else
                     If token.Token_Type = tk_word Then
                        Begin
                           Script_when_stack[Script_total_Whens].SLabel := True;
                           token.Token_Type := tk_end_rec;
                           Exit;
                        End;
               End
            Else
               Begin
                  If token.Token_Type = tk_end_rec Then
                     Begin
                        Script_total_Whens := 0;
                        Script_Whens := False;
                        {clear any stored on the Heap}
                        Free_When_Stack;
                        Exit;
                     End;
                  If Script_total_Whens = Max_Whens Then
                     Begin
                        Script_Edit_Error(90);
                        Last_Token.Token_Type := tk_end_rec;
                        Exit;
                     End;
                  If token.Token_Type = tk_string Then
                     Script_Edit_Error(3) { String length 0 error }
                  Else
                     Script_Edit_Error(4); { String expected error }
                  token.Token_Type := tk_end_rec;
               End;
         Until token.Token_Type = tk_end_rec;
   End;                           { When }

   Procedure Get_and_Execute_Note;
   Begin
      Get_NoComments;
      parse_input := Copy(parse_input, 1, token.Position - 1);
      parse_input := Trim(parse_input);
      Delete(Parse_input, 1, 5);
      Screen_Mode_Check;
      If WhereX > 1 Then
         WriteLn;
      Parse_Write_Con(parse_input+^M^J);
      If Capture Then
         Begin
            WriteLn(Capture_File, parse_input);
            IO := IoResult;
            If IO <> 0 Then
               Begin
                  WriteLn;
                  Writelnb('Error writing to Capture file');
                  Writelnb('Capture file closed');
                  Capture := False;
               End;
         End;
      If Split Then
         set_split;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_Writeln(cr : Boolean);
   Var
      T : String;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_string Then
         Begin
            If (token.Length > 0) Then
               Begin
                  T := token.Str_Value;
                  If cr Then T := T + ^M^J;
                  If Online Then
                     Parse_Write_Modem(T);
                  OutKey(T);{Parse_Write_Con(T);}
               End
            Else
               Script_Edit_Error(3); { string expected }
            Last_Token.Token_Type := tk_end_rec {closes the current record } ;
         End
      Else
         Script_Edit_Error(4);
   End;

   Procedure Get_and_Execute_AtWrite;
   Var
      T         : String;
      c1, r1,
      atr, tatr : Word;
   Begin
      If Get_Token_Word(c1) Then
         If Get_Token_Word(r1) Then
            If Get_Token_Word(atr) Then
               If (c1 <= Last_Col) And
                  (r1 <= Last_Row) Then
                  Begin
                     Get_Next_Token;
                     If token.Token_Type = tk_string Then
                        Begin
                           If (token.Length > 0) Then
                              Begin
                                 Push_window;
                                 Window(1, 1, Last_Col, Last_Row);
                                 GotoXY(c1, r1);
                                 tatr := TextAttr;
                                 TextAttr := atr;
                                 T := token.Str_Value;
                                 Parse_Write_Con(token.Str_Value);
                                 TextAttr := tatr;
                                 Pop_window;
                              End
                           Else
                              Script_Edit_Error(3); { string expected }
                        End
                     Else
                        Script_Edit_Error(3) { string expected }
                  End
               Else
                  Script_Edit_Error(13); { Off Screen Coordinates }
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;


   Procedure Get_and_Execute_Window(DrawBox : Boolean);
   Var
      c1, r1, c2, r2, x : Word;
   Begin
      If Get_Token_Word(c1) Then
         If Get_Token_Word(r1) Then
            If Get_Token_Word(c2) Then
               If Get_Token_Word(r2) Then
                  If (c1 < 81) And (c1 < c2) And
                     (r1 < 61) And (r1 < r2) And
                     (c2 < 81) And (r2 < 61) Then
                     Begin
                        If DrawBox then
                           Begin
                              DrawBox3(c1, r1, c2, r2,qqColor, '');
                              Window(c1 + 1, r1 + 1, c2 - 1, r2 - 1);
                           End
                        Else
                           Begin
                              Window(c1, r1, c2, r2);
                              GotoXY(1, 1);
                           End;
                        NormalCursor;
                     End;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;                           { Window }


   Function ExpandScr(S : String)    : String;
   Var
      T : String;
      x : Integer;
   Begin
      T := '';
      x := 1;
      While x <= Length(S) Do
         Begin
            If S[x] In ['''', '"', '$'] Then
               T := T + #255 + S[x]
            Else
               If S[x] = #255 then
                  T := T + #255 + #255
               Else
                  T := T + S[x];
            Inc(x);
         End;
      ExpandScr := T;
   End;

   Procedure Get_and_Execute_Assign;
   Var
      y              : Integer;
   Begin
      Get_Next_Token;
      If (token.Token_Type = tk_word) Then
         Begin
            y := Script_string_num(token.Str_Value);
            If y > 0 Then
               Begin
                  Get_Next_Token;
                  If (token.Token_Type = tk_word) Or
                     (token.Token_Type = tk_string) Then
                     Begin
                        token.Str_Value := ExpandScr(token.Str_Value);
                        SetString(Script_Strings[y].value,
                                  StringToHeap(token.Str_Value));
                        If Script_Strings[y].value = Nil Then
                           Begin
                              Script_Edit_Error(186);
                              Exit;
                           End;
                     End
                  Else
                     Script_Edit_Error(17)
               End
            Else
               Script_Edit_Error(131)
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { Assign }

   Procedure Get_and_Execute_INCR(plus : Boolean);
   Var
      y, rc, z       : Integer;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_word Then
         Begin
            y := Script_string_num(token.Str_Value);
            If y > 0 Then
               Begin
                  Val(StringFromHeap(Script_Strings[y].value), z, rc);
                  If rc = 0 Then
                     Begin
                        If plus Then
                           Begin
                              If z < 32767 Then Inc(z)
                              Else z := 0;
                           End
                        Else
                           Begin
                              If z > 0 Then Dec(z)
                              Else z := 32767;
                           End;
                        SetString(Script_Strings[y].value,
                                  StringToHeap(Long2Str(z)));
                        If Script_Strings[y].value = Nil Then
                           Begin
                              Script_Edit_Error(186);
                              Exit;
                           End;
                     End
                  Else
                     Script_Edit_Error(190)
               End
            Else
               Script_Edit_Error(131)
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { Assign }

   Procedure Get_and_Execute_Stamp;
   Var
      x              : Integer;
   Begin
      Get_NoComments;
      Parse_input := Trim(Copy(parse_input, 1, token.Position - 1));
      Logit(parse_input);
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;
