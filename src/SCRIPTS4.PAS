{$F+}
Unit Scripts4;

Interface

Uses
   ApTimer;

   Procedure Do_ONLINE_Check(x : Integer);
   Procedure Get_and_Execute_Timeout;
   Procedure Get_and_Execute_Drive;
   Procedure Get_and_Execute_ChDir;
   Procedure Get_and_Execute_Edit;
   Procedure Get_and_Execute_Break;
   Procedure Get_and_Execute_SetComm;
   Procedure Get_and_Execute_Flush;
   Procedure Get_and_Execute_HangUp;
   Procedure Get_and_Execute_Dial;
   Procedure Get_and_Execute_WaitUntil;
   Procedure Get_and_Execute_DOS;
   Procedure Get_and_Execute_BigDOS;
   Procedure Get_and_Execute_Beep;
   Procedure Get_and_Execute_Port;
   Procedure Get_and_Execute_System;
   Procedure Get_and_Execute_Push;
   Procedure Get_and_Execute_Pop;
   Procedure Get_and_Execute_Get(Trans, Resend : Boolean);
   Procedure Get_and_Execute_Getx; { Format : GETX [String] [# to get] [EndCh] }
   Procedure Get_and_Execute_InKey;
   Procedure Get_and_Execute_Debug;
   Procedure Get_and_Execute_When;
   Procedure Get_and_Execute_Note;
   Procedure Get_and_Execute_Writeln(cr : Boolean);
   Procedure Get_and_Execute_AtWrite;
   Procedure Get_and_Execute_Window(DrawBox : Boolean);
   Function  ExpandScr(S : String)    : String;
   Procedure Get_and_Execute_Assign;
   Procedure Get_and_Execute_INCR(plus : Boolean);
   Procedure Get_and_Execute_Stamp;
   Procedure Get_and_Execute_If;
   Procedure Get_and_Execute_Delay;
   Procedure Get_and_Execute_Pause;
   Procedure Get_and_Execute_EGA;
   Procedure Get_and_Execute_Display(CRLF : Boolean);
   Procedure Get_and_Execute_GotoXY;
   Procedure Get_and_Execute_Color;
   Procedure Get_and_Execute_ColorBG;
   Procedure Get_and_Execute_ColorFG;
   Procedure Get_and_Execute_GoTo;
   Procedure Get_and_Execute_Script;
   Procedure Get_and_Execute_Gosub;
   Procedure Get_and_Execute_Exist;
   Procedure Get_and_Execute_GetScr;
   Procedure Get_and_Execute_PutScr;
   Procedure Get_and_Execute_OpenFile;
   Procedure Get_and_Execute_CloseFile;
   Procedure Get_and_Execute_ReadFile;
   Procedure Get_and_Execute_WriteFile;
   {$IfNDef GG}
   Procedure Get_and_Execute_Host;
   {$EndIf}
   Procedure Check_for_Whens;
   Procedure Script_Input_Output(test_line : String);
   Procedure Get_and_Execute_WaitFor;
   Procedure Get_and_Execute_Send;
   Procedure Call_Script_Overlay;
   Procedure Get_and_Execute_Download_False;
   Procedure Get_and_Execute_Download_True;
   Procedure Get_and_Execute_Exit;
   Procedure Get_and_Execute_Dummy;
   Procedure Get_and_Execute_Window_False;
   Procedure Get_and_Execute_Box;
   Procedure Get_and_Execute_End_File;
   Procedure Get_and_Execute_DisplayLn;
   Procedure Get_and_Execute_Display_False;
   Procedure Get_and_Execute_Writeln_True;
   Procedure Get_and_Execute_Writeln_False;
   Procedure Get_and_Execute_INCR_False;
   Procedure Get_and_Execute_INCR_True;
   Procedure Get_and_Execute_Upload_True;
   Procedure Get_and_Execute_Upload_False;
   Procedure Get_and_Execute_Get_False_True;
   Procedure Get_and_Execute_Get_True_True;
   Procedure Get_and_Execute_Get_False_False;
   Procedure Get_and_Execute_Get_True_False;
   Procedure Get_and_Execute_Error0;


Implementation

Uses

     Qmem,     TpCrt,    TPString, TPWindow, TPDos,
     Initial,  Comm,     Procs,    EmulANSI, Screen,   Files,
     EmulVT10, Group1,   QDial,    Emuls,    Comm2,    QShell,
     {XpMenu,} Group02,  Menus,    Qega,     BINFSE,   QDosCmd,
     ScrDmp,   DeleteF,  Info,     ChangDir, Baud,     XLate,

     Qdial2,   Scripts,  Scripts2, FKeys,    Downld,   Upld,
     Port,     LogDrv,   ExitDOS,  Scroll,   FoneStuf,

     {$IfNDef GG} Host, {$EndIf}

     Key;


   {$I SCRIPTS5.PAS}

   Procedure Get_and_Execute_Error0;
   Begin
      Script_Edit_Error(0);
   End;

   Procedure Get_and_Execute_Dummy;
   Begin
   End;

   Procedure Get_and_Execute_Get_False_True;
   Begin
      Get_and_Execute_Get(False, True);
   End;

   Procedure Get_and_Execute_Get_True_True;
   Begin
      Get_and_Execute_Get(True, True);
   End;

   Procedure Get_and_Execute_Get_False_False;
   Begin
      Get_and_Execute_Get(False, False);
   End;

   Procedure Get_and_Execute_Get_True_False;
   Begin
      Get_and_Execute_Get(True, False);
   End;


   Procedure Get_and_Execute_Upload_False;
   Begin
      Get_and_Execute_Upload;
   End;

   Procedure Get_and_Execute_Upload_True;
   Begin
      Get_and_Execute_Upload;
   End;

   Procedure Get_and_Execute_INCR_True;
   Begin
      Get_and_Execute_INCR(True);
   End;

   Procedure Get_and_Execute_INCR_False;
   Begin
      Get_and_Execute_INCR(False);
   End;

   Procedure Get_and_Execute_Writeln_True;
   Begin
      Get_and_Execute_Writeln(True);
   End;

   Procedure Get_and_Execute_Writeln_False;
   Begin
      Get_and_Execute_Writeln(False);
   End;

   Procedure Get_and_Execute_DisplayLn;
   Begin
      Get_and_Execute_Display(True);
   End;

   Procedure Get_and_Execute_Display_False;
   Begin
      Get_and_Execute_Display(False);
   End;


   Procedure Get_and_Execute_End_File;
   Begin
      Script_Parm_Line := '';
   End;

   Procedure Get_and_Execute_Box;
   Begin
      Get_and_Execute_Window(True);
   End;

   Procedure Get_and_Execute_Window_False;
   Begin
      Get_and_Execute_Window(False);
   End;


   Procedure Get_and_Execute_Download_False;
   Begin
      Get_and_Execute_Download;
   End;

   Procedure Get_and_Execute_Download_True;
   Begin
      Get_and_Execute_Download;
   End;

   Procedure Get_and_execute_Exit;
   Begin
      Scripting := False;
   End;


   {$IfNDef GG}
   Procedure Get_and_Execute_Host;
   Var
      x : Integer;
      HostRestart : Boolean;
   Begin
      Get_Next_Token;
      If (token.Token_Type = tk_word) and (token.Length > 0) Then
         Begin
            If STUpCase(token.Str_Value) = 'SINGLE' then
               HostViaScript := True
            Else
               If STUpCase(token.Str_Value) <> 'REPEAT' then
                  Begin
                     Script_Edit_Error(182);
                     Exit;
                  End
               Else
                  HostViaScript := False;
            x := HostMode(False);
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
      HostViaScript := False;
      Show_Script_Status_Line;
   End;

   {$EndIf}

   Procedure Get_and_Execute_If;
   Var
      op_            : op_type;
      Found, Ok      : Boolean;
      part1, part2   : String[64];
      opcode         : String[2];
      p1,p2          : LongInt;

      Function Opcode_Ok(T : String; Var O : op_type) : Boolean;
      Begin
         If T = '=' Then
            Begin
               O := op_eq;
               Opcode_Ok := True;
               Exit;
            End;
         If T = '<' Then
            Begin
               O := op_lt;
               Opcode_Ok := True;
               Exit;
            End;
         If T = '>' Then
            Begin
               O := op_gt;
               Opcode_Ok := True;
               Exit;
            End;
         If T = '<=' Then
            Begin
               O := op_le;
               Opcode_Ok := True;
               Exit;
            End;
         If T = '>=' Then
            Begin
               O := op_ge;
               Opcode_Ok := True;
               Exit;
            End;
         If T = '<>' Then
            Begin
               O := op_ne;
               Opcode_Ok := True;
               Exit;
            End;
         Opcode_Ok := False;
         O := op_qq;
      End;

         Procedure Pad_If;
         Var
            End_Ch     : Char;
            c          : Integer;
         Begin
            c := 1;
            while (c < Length(Parse_input)) and not
                  (parse_input[c] In ['''', '"']) do
                  If Parse_input[c] = #255 then Inc(c,2)
                                           else Inc(c);
            If parse_input[c] In ['''', '"'] Then
               Begin
                  end_Ch := Parse_Input[c];
                  inc(c);
                  while (c < Length(Parse_Input)) and
                        (parse_input[c] <> End_ch) do
                     If Parse_input[c] = #255 then Inc(c,2)
                                              else Inc(c);
                  If c < Length(parse_input) then
                     Insert(' ',Parse_input,c);
                  Inc(c,2);
                  while (c < Length(Parse_input)) and not
                        (parse_input[c] In ['''', '"']) do
                     If Parse_input[c] = #255 then Inc(c,2)
                                              else Inc(c);
                  If parse_input[c] In ['''', '"'] Then
                     Begin
                        end_Ch := Parse_Input[c];
                        inc(c);
                        while (c < Length(Parse_Input)) and
                              (parse_input[c] <> End_ch) do
                     If Parse_input[c] = #255 then Inc(c,2)
                                              else Inc(c);
                        If c < Length(parse_input) then
                           Insert(' ',Parse_input,c);
                     End;
               End;
            Parse_Length := Length(Parse_Input);
         End;

         Function Check_Numeric : Boolean;
         Begin
            If Str2Long(trim(Part1), p1) and Str2Long(Trim(Part2), p2) then
               Check_Numeric := True
            Else
              Check_Numeric := False;
         End;

   Begin
    Pad_If;
    Get_Next_Token;
      If (token.Token_Type = tk_word) Or
         (token.Token_Type = tk_string) Then
         Begin
            part1 := STUpCase(token.Str_Value);
            Get_Next_Token;
            If (token.Token_Type = tk_word) And
               (token.Length <= 2) Then
               Begin
                  opcode := token.Str_Value;
                  If Opcode_Ok(opcode, op_) Then
                     Begin
                        Get_Next_Token;
                        If (token.Token_Type = tk_word) Or
                           (token.Token_Type = tk_string) Then
                           Begin
                              part2 := STUpCase(token.Str_Value);
                              {check to see if both are numeric values}
                              Ok := False;
                              If Check_Numeric then
                                 Case op_ Of
                                    op_eq : If p1 =  p2 Then Ok := True;
                                    op_lt : If p1 <  p2 Then Ok := True;
                                    op_gt : If p1 >  p2 Then Ok := True;
                                    op_le : If p1 <= p2 Then Ok := True;
                                    op_ge : If p1 >= p2 Then Ok := True;
                                    op_ne : If p1 <> p2 Then Ok := True;
                                 End
                              Else
                                 Case op_ Of
                                    op_eq : If part1 =  part2 Then Ok := True;
                                    op_lt : If part1 <  part2 Then Ok := True;
                                    op_gt : If part1 >  part2 Then Ok := True;
                                    op_le : If part1 <= part2 Then Ok := True;
                                    op_ge : If part1 >= part2 Then Ok := True;
                                    op_ne : If part1 <> part2 Then Ok := True;
                                 End;
                              If Ok Then
                                 Begin
                                    Get_Next_Token;
                                    If (token.Token_Type = tk_word) Or
                                       (token.Token_Type = tk_label) Then
                                       Begin
                                          Script_Goto_Str := STUpCase(token.Str_Value);
                                          Search_Script;
                                       End
                                    Else
                                       Script_Edit_Error(2);
                                 End;
                           End
                        Else
                           Script_Edit_Error(17);
                     End
                  Else
                     Begin
                        Writeln;
                        Writeln ('Parse_Input > ',Parse_Input);
                        Writeln;
                        Script_Edit_Error(170); { Invalid Opcode }
                     End
               End
            Else
               Begin
                  Writeln;
                  Writeln ('Parse_Input > ',Parse_Input);
                  Writeln;
                  Script_Edit_Error(170); { Invalid Opcode }
               End
         End
      Else
         Script_Edit_Error(17);
      Last_Token.Token_Type := tk_end_rec;
   End;


   Procedure Get_and_Execute_Delay;
   Var
      x : Word;
   Begin
      {If qq.DoRecalibrate then
         DelayCalibrate;}
         
      If Get_Token_Word(x) Then
         Delay(x);
      Last_Token.Token_Type := tk_end_rec;
   End;


   Procedure Get_and_Execute_Pause;
   Var
      x  : Word;
      xx : LongInt;
      Ch : Char;
      ET : EventTimer;
   Begin
      If Get_Token_Word(x) Then
         Begin
            If x < 10 then
               Begin
                  Delay(x);
                  Exit;
               End;
            xx := ((LongInt(x) * 182) div 10000) + 1;
            NewTimer(ET, xx);
            Repeat
               If Keypressed Then
                  Check_Script_Abort;

               If CommPressed Then
                  For x := 1 To 10 Do
                     If CommPressed Then
                        Check_comm_codes;

               If Type_Ahead <> '' Then
                  Begin
                     Ch := Type_Ahead[1];
                     Delete(Type_Ahead, 1, 1);
                     Handle_Key_Pressed(Ch);
                  End;

               If Xon_Xoff Then
                  If Queue_Bytes > Buffer_Low1 Then
                     Begin
                        Buffer_full := True;
                        Dequeue_buffer;
                     End;

            Until TimerExpired(ET) Or
                  (Not Scripting) Or
                  Fatal_Error;
         End;
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_EGA;
   Var
      x : Word;
   Begin
      If Get_Token_Word(x) Then
         Begin
            Case x Of
               25    : Set_Screen_25;
               43,50 : Set_Screen_43;
               Else    Script_Edit_Error(200);
            End;
            Show_Script_Status_Line;
         End;
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_Display(CRLF : Boolean);
   Var
      T : String;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_string Then
         Begin
            If (token.Length > 0) Then
               Case CRLF Of
                  True  : Parse_Write_Con(token.Str_Value+^M^J);
                  False : Parse_Write_Con(token.Str_Value);
               End
            Else
               Script_Edit_Error(3); { string expected }
         End
      Else
         Script_Edit_Error(4);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_GotoXY;
   Var
      x, y : Word;
   Begin
      If Get_Token_Word(x) Then
         If Get_Token_Word(y) Then
            GotoXY(x, y);
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_COLOR;
   Var
      x : Word;
   Begin
      If Get_Token_Word(x) Then
         If x <= 255 Then
            Begin
               qqColor := x;
               emul_color := x;
               Set_Colors;
            End;
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_COLORFG;
   Var
      x : Word;
   Begin
      If Get_Token_Word(x) Then
         If x <= 31 Then
            Begin
               TextColor(x);
               qqColor := TextAttr;
               emul_color := TextAttr;
               Set_Colors;
            End;
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_COLORBG;
   Var
      x : Word;
   Begin
      If Get_Token_Word(x) Then
         If x <= 7 Then
            Begin
               TextBackground(x);
               qqColor := TextAttr;
               emul_color := TextAttr;
               Set_Colors;
            End;
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_GoTo;
   Var
      Found          : Boolean;
   Begin
      Get_Next_Token;
      If IsKeyword(Token.Str_Value) then
         Begin
            Script_Edit_Error(16);
            Exit;
         End;
      If (token.Token_Type = tk_word) Or (token.Token_Type = tk_label) Then
         Begin
            Script_Goto_Str := STUpCase(token.Str_Value);
            Search_Script;
         End
      Else
         Script_Edit_Error(2);
   End;                           { Goto }

   Procedure Get_and_Execute_Script;
   Var
      FileName       : Str64;
   Begin
      If Script_Stack_Pointer = Max_Script_Stack Then
         Script_Edit_Error(100)
      Else
         If Get_and_Check_Next_Token(tk_word, 5) Then
            Begin
               FileName := token.Str_Value;
               Get_Next_Token;
               If (token.Token_Type = tk_string) And
                  (token.Length > 0) Then
                  Begin
                     Script_Parm_Line := token.Str_Value;
                     Open_Script(FileName);
                  End
               Else
                  Begin
                     Script_Parm_Line := '';
                     Open_Script(FileName);
                  End;
            End
   End;                           { Script }

   Procedure Get_and_Execute_Gosub;
   Begin
      If Script_Stack_Pointer = Max_Script_Stack Then
         Script_Edit_Error(100)
      Else
         Begin
            Get_Next_Token;
            If IsKeyword(Token.Str_Value) then
               Begin
                  Script_Edit_Error(16);
                  Exit;
               End;
            If (token.Token_Type = tk_word) Or
               (token.Token_Type = tk_label) Then
               Begin
                  Script_Parm_Line := '';
                  Script_Goto_Str := STUpCase(token.Str_Value);
                  Inc(Script_Stack_Pointer);
                  If Script_Stack_Pointer >= Max_Script_Stack then
                     Begin
                        Script_Edit_Error(100);
                        Exit;
                     End;
                  Script_Stack[Script_Stack_Pointer].S_Filename :=
                     Last_Label_Script;
                  Script_Stack[Script_Stack_Pointer].Record_Num :=
                     Script_Stack[Script_Stack_Pointer-1].Record_Num;
                  Search_Script;
               End
            Else
               Script_Edit_Error(2);
         End;
   End;                           { Script }

   Procedure Get_and_Execute_Exist;
   Var
      t1             : Str64;
   Begin
      Get_Next_Token;
      If (token.Token_Type = tk_word) Then
         Begin
            t1 := STUpCase(token.Str_Value);
            If Exist_Wild(t1) Then
               Begin
                  Get_Next_Token;
                  If (token.Token_Type = tk_word) or
                     (token.Token_Type = tk_Label) Then
                     Begin
                        Script_Goto_Str := STUpCase(token.Str_Value);
                        Search_Script;
                     End
                  Else
                     Script_Edit_Error(2);
               End
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;                           { Exist }

   Procedure Get_and_Execute_GetScr;
   Begin
      If Virt_Win_Ptr < 3 Then
         Save_Screen(1, 1, Last_Col, Last_Row)
      Else
         Script_Edit_Error(180);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_PutScr;
   Begin
      If Virt_Win_Ptr > 0 Then
         Restore_Screen;
      Last_Token.Token_Type := tk_end_rec;
   End;


   Procedure Get_and_Execute_OpenFile;
   Var
      t1, t2         : String;

      Procedure OpenTEXT(m : Byte);
      Begin
         Case m Of
            1 : Begin
                   Reset(ScrTEXT);
                   ScriptTextRead := True;
                End;
            2 : Begin
                   Rewrite(ScrTEXT);
                   ScriptTextRead := False;
                End;
            3 : Begin
                   If Not ExistFile(t1) Then
                      Rewrite(ScrTEXT);
                   Append(ScrTEXT);
                   ScriptTextRead := False;
                End;
         End;
         IO := IoResult;
         ScriptFileText := True;
         If IO <> 0 Then
            Begin
               Script_Edit_Error(212); {error opening file}
               ScriptFileText := False;
            End;
      End;

   Begin
      If ScriptFileText Then
         Begin
            Script_Edit_Error(211);
            Exit;
         End;
      Get_Next_Token;
      If (token.Token_Type = tk_word) Then
         Begin
            t1 := token.Str_Value; {Filename to open}
            Assign(ScrTEXT, t1);
            Get_Next_Token;
            If token.Token_Type = tk_word Then
               Begin
                  t2 := STUpCase(token.Str_Value);
                  If t2 = 'READ' Then OpenTEXT(1)
                  Else
                     If t2 = 'REWRITE' Then OpenTEXT(2)
                     Else
                        If t2 = 'APPEND' Then OpenTEXT(3)
                        Else
                           Script_Edit_Error(210);
               End
            Else
               Script_Edit_Error(5);
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_CloseFile;
   Begin
      If ScriptFileText Then
         Close(ScrTEXT);
      ScriptFileText := False;
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_ReadFile;
   Var
      tmp            : String;
   Begin
      If Not ScriptFileText Then
         Begin
            Script_Edit_Error(213);
            Exit;
         End;
      If Not ScriptTextRead Then
         Begin
            Script_Edit_Error(214);
            Exit;
         End;
      Get_Next_Token;
      If token.Token_Type = tk_word Then
         Begin
            y := Script_string_num(token.Str_Value);
            If y > 0 Then
               Begin
                  If EOF(ScrTEXT) Then
                     tmp := '_EOF_'
                  Else
                     Begin
                        ReadLn(ScrTEXT, tmp);
                        IO := IoResult;
                        If IO <> 0 Then
                           Begin
                              Get_and_Execute_CloseFile;
                              Script_Edit_Error(217);
                              Exit;
                           End;
                     End;
                  tmp := ExpandScr(tmp);
                  SetString(Script_Strings[y].value,
                            StringToHeap(tmp));
                  If Script_Strings[y].value = Nil Then
                     Begin
                        Script_Edit_Error(186);
                        Exit;
                     End;
               End
            Else
               Script_Edit_Error(131)
         End
      Else
         Script_Edit_Error(5);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_WriteFile;
   Begin
      If Not ScriptFileText Then
         Begin
            Script_Edit_Error(213);
            Exit;
         End;
      If ScriptTextRead Then
         Begin
            Script_Edit_Error(215);
            Exit;
         End;
      Get_Next_Token;
      If (token.Token_Type = tk_word) Or
         (token.Token_Type = tk_string) Then
         Begin
            WriteLn(ScrTEXT, Parse_String(token.Str_Value));
            IO := IoResult;
            If IO <> 0 Then
               Begin
                  Get_and_Execute_CloseFile;
                  Script_Edit_Error(216);
               End;
         End
      Else
         Script_Edit_Error(17);
      Last_Token.Token_Type := tk_end_rec;
   End;


   Procedure Check_for_Whens;
   Var
      x    : Integer;
      cch  : Char;
      ts   : String;
   Begin
      If Script_Total_Whens <= 0 then
         Exit;
      If CaseSensitive Then cch := CommCh
                       Else cch := Upcase(CommCh);
      For x := 1 To Script_total_Whens Do
         If Script_when_stack[x].Recv_String_LastChar = cch Then
            Begin
               ts := StringFromHeap(Script_when_stack[x].recv_string);
               If Not CaseSensitive Then ts := STUpCase(ts);
               If LastCommString(Length(ts)) = ts Then
                  Begin
                     If Script_when_stack[x].SLabel Then
                        Begin
                           Script_Goto_Str := StringFromHeap(Script_when_stack[x].send_string);
                           When_Goto := True;
                           Exit;
                        End
                     Else
                        Begin
                           Parse_Write_Modem(StringFromHeap(Script_when_stack[x].send_string));
                           ScriptCount := 0;
                           Exit;
                        End;
                  End;
            End;
   End;

   Procedure Script_Input_Output(test_line : String);
   Label
      wg;
   Var
      KeyCode : Word;
      Found   : Boolean;
      ET      : EventTimer;
      CH      : Char;
   Begin
      If Not CaseSensitive Then
         test_line := STUpCase(test_line);
      Waitfor_LastChar := test_line[Length(test_line)];
      Found := False;
      NewTimer(ET, ((LongInt(Script_TimeOut) * 182) div 10));
      Repeat
         If Keypressed Then
            Begin
               If Type_Ahead <> '' Then { Clear type ahead }
                  Begin
                     Write_Byte(Type_Ahead);
                     If Echo then
                        Write(Type_Ahead);
                     Type_Ahead := '';
                  End;
               If CheckKbd(KeyCode) Then
                  If (Lo(KeyCode) = 27) Or (Lo(KeyCode) = 0) Then
                     Check_Script_Abort
                  Else
                     Begin
                        Ch := Char(ReadKeyNoGrey);
                        If Ch <> #0 Then
                           Begin
                              Write_Byte(Ch);
                              If Echo then
                                 Write(Ch);
                           End;
                     End;
            End;
         If CommPressed Then
            Begin
               Check_comm_codes;
               Screen_mode_check2;
            End;
         If Script_Whens Then
            Begin
               Check_for_Whens;
               If When_Goto Then
                  GoTo wg;
            End;
         If Not CaseSensitive Then
            Begin
               If Upcase(CommCh) = Waitfor_LastChar Then
                  If LastCommString(Length(test_line)) = test_line Then
                     Found := True;
            End
         Else
            Begin
               If CommCh = Waitfor_LastChar Then
                  If LastCommString(Length(test_line)) = test_line Then
                     Found := True;
            End;
         If Queue_Bytes > Buffer_High1 Then
            Begin
               Buffer_full := True;
               If Xon_Xoff Then Write_Byte(^S); { Send XOFF                }
            End;
         If Buffer_full Then
            If Queue_Bytes < Buffer_Low1 Then
               Begin
                  Buffer_full := False;
                  If Xon_Xoff Then Write_Byte(^Q); { Send XON                 }
               End;
      Until TimerExpired(ET) Or
            Found Or
            (Not Scripting);
      If Not Scripting Then
         Exit;
      If Not Found Then
         If Not Keypressed Then
            If Script_Timeout_Label <> '' Then
               Begin
                  Script_Goto_Str := Script_Timeout_Label;
wg:               When_Goto := False;
                  Search_Script;
               End
            Else
               If Scripting Then
                  Begin
                     SetWindow2(3,6,77,10,' Script Timeout ',False);
                     Writeln(' Timeout looking for :');
                     Writeln(' "' + test_line + '"');
                     Write  (' Script halted');
                     Delay(2000);
                     Restore_Screen;
                     Scripting := False;
                     Close_Script;
                  End;
   End;

   Procedure Get_and_Execute_WaitFor;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_string Then
         Begin
            If (token.Length > 0) Then
               Begin
                  ScriptCount := 0;
                  Script_Input_Output(token.Str_Value);
               End
            Else
               Script_Edit_Error(3);
         End
      Else
         Script_Edit_Error(4);
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Get_and_Execute_Send;
   Var
      Hold, Temp1 : String;
      DelayValue : Word;
   Label
      EExit;
   Begin
      Get_Next_Token;
      If token.Token_Type = tk_string Then
         Begin
            If (token.Length > 0) Then
               Begin
                  Hold := Token.Str_Value;
                  Get_Next_Token;
                  If token.token_type = tk_Word then
                     Begin
                        temp1 := StupCase(token.Str_value);
                        If Copy(Temp1,1,5) = 'PACE=' then
                           Begin
                              If Length(temp1) = 5 then
                                 Begin
                                    Script_Edit_Error(54);
                                    Goto EExit;
                                 End
                              Else
                                 If not Str2Word(Copy(temp1,6,4),DelayValue) then
                                    Begin
                                       Script_Edit_Error(54);
                                       Goto EExit;
                                    End;
                              Parse_Write_Modem_Paced(Hold,DelayValue);
                           End
                        Else
                           Script_Edit_Error(54);
                     End
                  Else
                     Parse_Write_Modem(Hold);
                  ScriptCount := 0;
               End
            Else
               Script_Edit_Error(3); { string expected }
         End
      Else
         Script_Edit_Error(4);
      EExit:
      Last_Token.Token_Type := tk_end_rec;
   End;

   Procedure Call_Script_Overlay;
   Begin
      If Not Script_File_Open Then
         Open_Script('');
      Script_total_Whens := 0;
      Online_Check := False;
      Script_Debug := False;
      Script_Upload_active := False;
      ScriptFileText := False;
      Script_timeout := 60;       { 60 seconds }
      Script_Timeout_Label := ''; { Null means Halt the Script }
      If Not Scripting Then Exit;
      Show_Script_Status_Line;
      Repeat
         Check_Script_Abort;
         If Online Then
            Begin
               If Not Last_Online_State Then
                  Start_Online_Timer;
            End
         Else
            If Last_Online_State Then
               Stop_Online_Timer;
         If Fatal_Error Then
            Begin
               Scripting := False;
               Script_Edit_Error(250);
            End
         Else
            If Scripting Then
               Repeat
                  Get_Next_Token;
               Until token.Token_Type <> tk_end_rec;
         If (Not Fatal_Error) And Scripting Then
            Begin
               { process the Token }
               Set_Colors;
               Keyword_Procedure[Token.Token_Type];
            End;
      Until (Not Scripting) Or Fatal_Error Or (token.Token_Type = tk_end_file);
      Close_Script;
      Script_Parm_Line := '';
      Scripting := False;
      While Virt_Win_Ptr > 0 Do
         Restore_Screen;          { Clears any hanging PUTSCR's }
   End;

End.
