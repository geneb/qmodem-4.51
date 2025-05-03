{$F+}
Unit Scripts2;

Interface

Uses
      Qmem,        TpCrt,
      TPDos,       TPString,
      TPEdit,      Batch,
      Initial,     Procs,
      Group1,      Scripts,
      fonestuf,    Files,
      Screen,      QDial,
      Downld,      Upld,
      FKeys,
      Emuls,       Group02;

Procedure Open_Script(script_name : Str64);
Function  Get_and_Check_Next_Token(tk         : valid_token_type;
                                   Word_error : Integer) : Boolean;
Function  Get_Token_Word(Var x : Word) : Boolean;
Procedure Return_to_Previous_Script;
Procedure Search_Script;
Procedure Get_and_Execute_Turn_On;
Procedure Get_and_Execute_Turn_Off;
Procedure Get_and_Execute_String;
Procedure Get_and_Execute_Graphics;
Procedure TurnOn_Capture;
Procedure TurnOn_Log;
Procedure get_and_Execute_LoadFON;
Procedure get_and_Execute_LoadKEY;
Procedure get_and_Execute_FKEY;
Procedure Get_and_Execute_Download;
Procedure Get_and_Execute_Upload;
Function  IsKeyword (s:String) : Boolean;
Function  Locate_All_Labels : Boolean;


Implementation
Uses Key;

   Function IsKeyword (s:String) : Boolean;
   Var
      x, low_, hi_, mid_ : Integer;
   Begin
      { Binary Search for Keywords }
      s := STUpCase(s);
      low_ := 1;
      hi_ := Keyword_Count;
      While (low_ <= hi_) Do
         Begin
            mid_ := (low_ + hi_) Div 2;
            If s = Keyword_Element[mid_].key_name Then
               Begin
                  IsKeyword := True;
                  Exit;
               End
            Else
               If s < Keyword_Element[mid_].key_name Then
                  hi_ := Pred(mid_)
               Else
                  low_ := Succ(mid_);
         End;
      IsKeyword := False;
   End;


   Procedure Open_Script(script_name : Str64);
   Var
      Escaped, Save_SL, Active   : Boolean;
   Begin
      If script_name <> '' Then
         script_name := STUpCase(FullScriptFilename(script_name));
      Active := False;
      If Script_File_Open Then
         Begin
            Close(Script_file);
            IO := IoResult;
            Script_File_Open := False;
            Active := True;
         End;
      If script_name = '' Then
         Begin
            TextAttr := qq.menu2;
            If Active Then
               WriteLn('NOTE: Previous Script ended.');
            Repeat
               Save_SL := ShowSL;
               Push_Status;
               ShowSL := True;
               script_name := Get_File_Name(qq.Script_Path, '', 'SCR',
                                            3, 'Script File Allocation',True);
               Pop_Status;
               ShowSL := Save_SL;
               If script_name = '' Then
                  Begin
                     Scripting := False;
                     Exit;
                  End;
            Until ExistFile(script_name);
            Setwindow2(4, 17, 76, 22, ' Script File Execution ',False);
            Display_Status(' Enter optional script parameters, space separated   ESC-Exit ');
            TextAttr := qq.menu2;
            ClrScr;
            WriteLn(' Script to execute :');
            Write(' ');
            TextAttr := qq.Menu;
            WriteLn(script_name);
            TextAttr := qq.menu2;
            If Script_Parm_Line = '' Then
               Begin
                  WriteLn(' Enter Script Parameters (if any)');
                  HelpTopic    := 40;
                  EditSize := 64;
                  ForceUpper := False;
                  ReadString('',21,6,64,0,qq.menu,qq.menu2,Escaped,Script_Parm_Line);
                  If Escaped then
                     Begin
                        Scripting := False;
                        Restore_Screen;
                        Exit;
                     End;
               End;
            Restore_Screen;
            HelpTopic := 0;
            Set_Colors;
         End;
      Initialize_Script_Parser;
      Curr_Script_Name := JustFilename(script_name);
      If Not existFile(script_name) Then
         Begin
            ScriptT := STUpCase(Script_Name);
            If Script_Stack_Pointer = 0 then
               Begin
                  Inc(Script_Stack_Pointer);
                  Script_Stack[Script_Stack_Pointer].S_Filename := script_name;
                  Script_Stack[Script_Stack_Pointer].Record_Num := 0;
               End;
            Script_Edit_Error(10); { File not Found }
            Scripting := False;
            Exit;
         End;
      Inc(Script_Stack_Pointer);
      If Script_Stack_Pointer >= Max_Script_Stack then
         Begin
            Script_Edit_Error(100);
            Exit;
         End;

      If Script_Name = '' Then
         Begin
            Script_Edit_Error(186);
            Exit;
         End;
      Script_Stack[Script_Stack_Pointer].S_Filename := script_name;
      Script_Stack[Script_Stack_Pointer].Record_Num := 0;
      Assign(Script_file, script_name);
      Reset(Script_file);
      IO := IoResult;
      If IO <> 0 then
         Begin
            Script_Edit_Error(230);
         End
      Else
         Begin
            If Locate_All_Labels then
               Begin
                  Script_File_Open := True;
                  Scripting := True;
                  Show_Script_Status_Line;
               End;
         End;
   End;

   Function Get_and_Check_Next_Token(tk : valid_token_type;
                             Word_error : Integer) : Boolean;
   Var
      Ok : Boolean;
   Begin
      Ok := False;
      Get_Next_Token;
      Case tk Of
         tk_word : If Token.Token_Type = tk Then
                      Ok := True
                   Else
                      Script_Edit_Error(Word_error);
         Tk_Word_plus : If Token.Token_Type = tk_word Then
                           If Token.Length > 0 Then
                              Ok := True
                           Else
                              Script_Edit_Error(3)
                        Else
                           Script_Edit_Error(1);
      End;
      Get_and_Check_Next_Token := Ok;
   End;

   Function Get_Token_Word(Var x : Word) : Boolean;
   Var
      Ok : Boolean;
   Begin
      Ok := False;
      Get_Next_Token;
      If (Token.Token_Type = tk_word) and (Token.Str_Value[1] <> '-') Then
         Begin
            If Str2Word(Token.Str_Value, x) then
               Ok := True
            Else
               Script_Edit_Error(7);
         End
      Else
         Script_Edit_Error(7);
      Get_Token_Word := Ok;
   End;

   Procedure Return_to_Previous_Script;
   Var
      Temp,
      script_name : String;
      x, y        : Word;
      tpos, xpos  : LongInt;

   Begin
      Close_Script;
      If Script_Stack_Pointer = 0 Then
         Scripting := False
      Else
         Begin
            script_name := Script_Stack[Script_Stack_Pointer].S_Filename;
            If Not existFile(script_name) Then
               Begin
                  Script_Edit_Error(12); { RETURN File not Found }
                  Scripting := False;
                  Exit;
               End;
            Assign(Script_file, script_name);
            Reset(Script_file);
            IO := IoResult;
            Curr_Script_Name := STUpCase(JustFilename(script_name));
            Show_Script_Status_Line;
            Script_File_Open := True;
            last_parse_record := False;
            xPos := Script_Stack[Script_Stack_Pointer].Record_Num;
            If not Locate_All_Labels then Exit;
            Script_Stack[Script_Stack_Pointer].Record_Num := xPos;
            OK := TextSeek(Script_File, xPos);
            Last_Token.Token_Type := tk_end_rec;
         End;
   End;

   Procedure Search_Script;
   Var
      debug_active   : Boolean;
      CH             : Char;
      NewLabel       : String[64];
      tmp            : Script_Label;
      temp           : String;
      x              : word;
   Begin
      debug_active := Script_Debug;
      Script_Debug := False;

      { First, see if the Label Exists...}

      NewLabel := STUpCase(Script_Goto_Str);
      tmp := Script_Label_Head;
      If tmp <> NIL then
         While (tmp <> NIL) and (NewLabel <> tmp^.Name) do
            tmp := tmp^.Next;
      If tmp = Nil then
         Script_Edit_Error(20)
      Else
         Begin
            { We have the Label and know where it is! }

            OK := TextSeek(Script_File, tmp^.LineNo);
            Script_Stack[Script_Stack_Pointer].Record_Num := tmp^.LineNo;

            Token.Token_Type := tk_end_rec;
            Last_Token.Token_Type := tk_end_rec;
            Last_Parse_Record := False;
         End;
      Script_Debug := debug_active;
   End;

   Function Locate_All_Labels : Boolean;
   Var
      Tmp        : Script_Label;
      LineCount  : Word;
      Ch         : Char;
      ot, olt    : Token_Record;
      Debug_Active : Boolean;
   Begin
      If Last_Label_Script = Script_Stack[Script_Stack_Pointer].S_Filename then
         Begin
            Locate_All_Labels := True;
            Exit;
         End
      Else
         Last_Label_Script := Script_Stack[Script_Stack_Pointer].S_Filename;
      Debug_Active := Script_Debug;
      Label_Search := True;
      Script_Debug := False;
      ot := Token;
      Olt := Last_Token;
      {Writeln('-- Locating Labels for ',Last_Label_Script,' --');}
      While Script_Label_Head <> NIL do    { Clear all records if any }
         Begin
            tmp := Script_Label_Head^.Next;
            Dispose(Script_Label_Head);
            Script_Label_Head := tmp;
         End;
      Script_Label_Ptr := Nil;
      Reset(Script_File);
      IO := IoResult;
      Fatal_Error := False;
      Repeat
         Get_Next_Token;
         If (Token.Token_Type = tk_label) Then
            Begin
               New(tmp);
               If tmp <> NIL then
                  Begin
                     tmp^.Name   := STUpCase(Token.Str_Value);
                     tmp^.LineNo := TextPos(Script_File);
                     tmp^.Next   := Nil;
                     If Script_Label_Head = NIL then
                        Begin
                           Script_Label_Ptr  := Tmp;
                           Script_Label_Head := Tmp;
                        End
                     Else
                        Begin
                           Script_Label_Ptr^.Next := Tmp;
                           Script_Label_Ptr       := Tmp;
                        End;
                  End
               Else
                  Begin
                     Script_Edit_Error(187);   {Insufficient space for label}
                     Locate_All_Labels := False;
                     Exit;
                  End;
            End;
         If Token.Token_Type <> tk_end_file then
            begin
               Token.Token_Type := tk_end_rec;
               Last_Token.Token_Type := tk_end_rec;
            End;
      Until Token.Token_Type = tk_end_file;
      If Fatal_Error then
         Begin
            Locate_All_Labels := False;
            Exit;
         End;
      Token := Ot;
      Last_Token := Olt;
      Last_Parse_Record := False;
      Script_Stack[Script_Stack_Pointer].Record_Num := 0;
      Reset(Script_file);
      IO := IOResult;
      If IO <> 0 Then
         Begin
            WriteLn;
            WriteLn('ERROR in Locate Labels - IOResult = ', IO);
            CharWord := ReadKeyA;
         End;
      Script_Debug := Debug_Active;
      Label_Search := False;
      Locate_All_Labels := True;
   End;

   Procedure Dummy_01;
   Begin
      Save_Last_Status := '';
      Add_New_Screen;
      Display_Status('');
      Which_Screen;
      Clear_Whole_Screen;
      If Split then
         Begin
            SplitScreen;
            SplitScreen;
         End;
   End;


   Procedure Get_and_Execute_Turn_On;
   Var
      Found : Boolean;
   Begin
      Found := True;
      Repeat
         Get_Next_Token;
         Case Token.Token_Type of
            To_DOORWAY : If Not Doorway Then Doorway_toggle;
            To_ALTMINUS: If Not qq.ShowStatusLine then
                            Begin
                               qq.ShowStatusLine := True;
                               Dummy_01;
                            End;
            To_ECHO    : If Not Echo Then Echo_toggle;
            To_SPLIT   : If Not Split Then SplitScreen;
            To_LINEFEED: If Not addlf Then Addlf_toggle;
            To_NOISE   : If Not noise Then Noise_toggle;
            To_8_BIT   : If Not Hi_Bit Then Hi_Bit_Toggle;
            To_XON_XOFF: If Not Xon_Xoff Then Xon_Xoff_Toggle;
            To_MUSIC   : If Not Music_flag Then ANSI_Music;
            To_PRINT   : If Not PrtLog Then Prtlog_toggle;
            To_BS_DEL  : If Not(qq.BS_DEL_Swap = 'Y') Then BS_DEL_Switch;
            To_ONLINE  : If Not Online_Check Then Online_Check := True;
            To_SCROLL  : If Not save_scroll Then Scroll_toggle;
            To_CASE    : CaseSensitive := True;
            Else         If Token.Token_Type <> tk_end_rec then
                            Begin
                               Script_Edit_Error(30);
                               Exit;
                            End;
         End
      Until Token.Token_Type = tk_end_rec;
      If Not Found Then
         Script_Edit_Error(30);
   End;                           { Turn_On }

   Procedure Get_and_Execute_Turn_Off;
   Var
      Found : Boolean;
   Begin
      Found := True;
      Repeat
         Get_Next_Token;
         Case Token.Token_Type of
            To_DOORWAY : If Doorway Then Doorway_toggle;
            To_ALTMINUS: If qq.ShowStatusLine then
                            Begin
                               qq.ShowStatusLine := False;
                               Dummy_01;
                            End;
            To_ECHO    : If Echo Then Echo_toggle;
            To_SPLIT   : If Split Then SplitScreen;
            To_LINEFEED: If AddLF Then Addlf_toggle;
            To_NOISE   : If Noise Then Noise_toggle;
            To_8_BIT   : If Hi_Bit Then Hi_Bit_Toggle;
            To_XON_XOFF: If Xon_Xoff Then Xon_Xoff_Toggle;
            To_MUSIC   : If Music_flag Then ANSI_Music;
            To_PRINT   : If PrtLog Then Prtlog_toggle;
            To_BS_DEL  : If (qq.BS_DEL_Swap = 'Y') Then BS_DEL_Switch;
            To_ONLINE  : If Online_Check Then Online_Check := False;
            To_SCROLL  : If save_scroll Then Scroll_toggle;
            To_CASE    : CaseSensitive := False;
            kw_capture : Begin
                            If Capture Then
                               Capture_Toggle('', True);
                         End;
            kw_log     : Begin
                            If Logging Then
                               Log_toggle('', False);
                         End;
            Else         If Token.Token_Type <> tk_end_rec then
                            Begin
                               Script_Edit_Error(40);
                               Exit;
                            End;
         End
      Until Token.Token_Type = tk_end_rec;
      If Not Found Then
         Script_Edit_Error(40);
   End;                           { Turn_Off }

   Procedure Get_and_Execute_String;
   Var
      T              : String;
      x              : Integer;
   Begin
      If Script_Strings_Set = Max_Script_Strings_Set Then Exit;
      Repeat
         Get_Next_Token;
         If IsKeyword(Token.Str_Value) then
            Begin
               Script_Edit_Error(16);
               Exit;
            End;
         If Token.Token_Type = tk_word Then
            Begin
               T := STUpCase(Token.Str_Value);
               Inc(Script_Strings_Set);
               SetString(Script_Strings[Script_Strings_Set].Name,
                         StringToHeap(T));
               If Script_Strings[Script_Strings_Set].Name = Nil Then
                  Begin
                     Script_Edit_Error(186);
                     Exit;
                  End;
               SetString(Script_Strings[Script_Strings_Set].value, Nil);
            End;
      Until (Token.Token_Type = tk_end_rec) Or
      (Max_Script_Strings_Set = Script_Strings_Set);
   End;

   Procedure Get_and_Execute_Graphics;
   Begin
      Get_Next_Token;
      If Token.Token_Type = tk_word Then
         Begin
            If not Set_Emulation_ST(Token.Str_Value) then
               Script_Edit_Error(31);
         End;
      Last_Token.Token_Type := tk_end_rec;
   End;                           { Graphics }

   Procedure TurnOn_Capture;
   Var
      Found          : Boolean;
      T              : String;
   Begin
      Found := False;
      Repeat
         If Get_and_Check_Next_Token(tk_word, 50) Then
            Begin
               Found := True;
               T := STUpCase(Token.Str_Value);
               Capture_Toggle(T, False);
               Last_Token.Token_Type := tk_end_rec;
               Exit;
            End;
      Until (Token.Token_Type = tk_end_rec) Or Not Found;
   End;

   Procedure TurnOn_Log;
   Var
      Found          : Boolean;
      T              : String;
   Begin
      Found := False;
      Repeat
         If Get_and_Check_Next_Token(tk_word, 53) Then
            Begin
               Found := True;
               T := STUpCase(Token.Str_Value);
               If Logging then
                  Log_toggle('', False);
               Log_toggle(T, False);
               Last_Token.Token_Type := tk_end_rec;
               Exit;
            End;
      Until (Token.Token_Type = tk_end_rec) Or Not Found;
   End;

   Procedure get_and_Execute_LoadFON;
   Var
      Found          : Boolean;
      T              : String;
   Begin
      Found := False;
      Repeat
         If Get_and_Check_Next_Token(tk_word, 51) Then
            Begin
               Found := True;
               T := STUpCase(Token.Str_Value);
               If existFile(T) Then
                  Begin
                     Load_Phone_Dir(T);
                     FON_Filename := T;
                     Last_Token.Token_Type := tk_end_rec;
                     Exit;
                  End
               Else
                  Begin
                     Script_Edit_Error(140);
                     Exit;
                  End;
            End;
      Until (Token.Token_Type = tk_end_rec) Or Not Found;
   End;

   Procedure get_and_Execute_LoadKEY;
   Var
      Found          : Boolean;
      T              : String;
   Begin
      Found := False;
      Repeat
         If Get_and_Check_Next_Token(tk_word, 52) Then
            Begin
               Found := True;
               T := STUpCase(Token.Str_Value);
               If existFile(T) Then
                  Begin
                     Load_Fkeys(T);
                     FKEY_Filename := T;
                     Last_Token.Token_Type := tk_end_rec;
                     Exit;
                  End
               Else
                  Begin
                     Script_Edit_Error(150);
                     Exit;
                  End;
            End;
      Until (Token.Token_Type = tk_end_rec) Or Not Found;
   End;

   Procedure get_and_Execute_FKEY;
   Var
      x : Word;
   Begin
      If Get_Token_Word(x) Then
         If (x >= 1) And (x <= 48) Then
            Begin
               Out_Key(x);
               Last_Token.Token_Type := tk_end_rec;
            End
         Else
            Script_Edit_Error(7); { not in range 1-40 }
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_Download;
   Var
      FName            : Str64;
      temp1            : String;
      x                : Integer;
      Protocol         : Char;
      ASCII_In_Xlate   : Boolean;
      ASCII_In_CR,
      ASCII_In_LF      : Byte;  {0,1,2}
   Label
      EExit;
   Begin
      If Get_and_Check_Next_Token(tk_word, 5) Then
         Begin
            Protocol := Token.Str_Value[1];
            Case Protocol Of
               'A' : Begin
                        ASCII_In_Xlate  := qq.ASCII_In_Xlate;
                        ASCII_In_CR     := qq.ASCII_In_CR;
                        ASCII_In_LF     := qq.ASCII_In_LF;

                        Get_Next_Token;
                        If Token.Token_Type <> tk_word Then
                           Begin
                              Script_Edit_Error(1);
                              Exit;
                           End;
                        FName := Token.Str_Value;

                        {
                          parse options

                          ASCII_In_Xlate  :=  XLATE=[ON/OFF]
                          ASCII_In_CR     :=  CR=[NONE/STRIP/ADDLF]
                          ASCII_In_LF     :=  LF=[NONE/STRIP/ADDCR]
                        }

                        Repeat
                           Get_Next_Token;
                           If Token.Token_Type = tk_word Then
                              Begin
                                 temp1 := STUpCase(Token.Str_Value);

                                 If Copy(Temp1,1,6) = 'XLATE=' then
                                    Begin
                                       If Length(temp1) < 8 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             temp1 := Copy(temp1,7,3);
                                             If Temp1 = 'ON' then
                                                qq.ASCII_In_Xlate := True
                                             Else
                                                If Temp1 = 'OFF' then
                                                   qq.ASCII_In_Xlate := False
                                                Else
                                                   Begin
                                                      Script_Edit_Error(15);
                                                      Goto EExit;
                                                   End;
                                          End;
                                    End Else

                                 If Copy(Temp1,1,3) = 'CR=' then
                                    Begin
                                       If Length(temp1) < 7 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             temp1 := Copy(temp1,4,5);
                                             If Temp1 = 'NONE' then
                                                qq.ASCII_In_CR := 0
                                             Else
                                                If Temp1 = 'STRIP' then
                                                   qq.ASCII_In_CR := 1
                                                Else
                                                   If Temp1 = 'ADDLF' then
                                                      qq.ASCII_In_CR := 2
                                                   Else
                                                      Begin
                                                         Script_Edit_Error(15);
                                                         Goto EExit;
                                                      End;
                                          End;
                                    End Else

                                 If Copy(Temp1,1,3) = 'LF=' then
                                    Begin
                                       If Length(temp1) < 7 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             temp1 := Copy(temp1,4,5);
                                             If Temp1 = 'NONE' then
                                                qq.ASCII_In_LF := 0
                                             Else
                                                If Temp1 = 'STRIP' then
                                                   qq.ASCII_In_LF := 1
                                                Else
                                                   If Temp1 = 'ADDCR' then
                                                      qq.ASCII_In_LF := 2
                                                   Else
                                                      Begin
                                                         Script_Edit_Error(15);
                                                         Goto EExit;
                                                      End;
                                          End;
                                    End;
                              End;
                        Until Token.Token_Type <> tk_Word;

                        { Get Prompt character }
                        Download(FName,  { Filename              }
                                 'A',    { ASCII protocol        }
                                 ' ');   { dummy variable        }

                        EExit:
                        qq.ASCII_In_Xlate  := ASCII_In_Xlate;
                        qq.ASCII_In_CR     := ASCII_In_CR;
                        qq.ASCII_In_LF     := ASCII_In_LF;

                     End;            {Ascii}
               Else
                  Begin
                     { Now see if the protocol is external, and if so
                       see if we need to ask for a filename...}
                     Num := Is_External(Protocol);
                     (*
                     If ((Num > 0) and (qq.Xfer_File_Prompt[Num] <> 'Y')) or
                        ((Num = 0) and (Protocol in ['Y','G','Z'])) then
                           Begin
                              Token.Token_Type := tk_word;
                              Token.Str_Value := 'Passed_in_header';
                           End
                        Else*)

                     Get_Next_Token;
                     If Token.Token_Type <> tk_word Then
                        Script_Edit_Error(1)
                     Else
                        DownLoad(Token.Str_Value, Protocol, ' ');
                  End;
            End;
         End;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

   Procedure Get_and_Execute_Upload;
   Var
      FName            : Str64;
      Menu1            : Char;
      temp1            : String;
      x                : Integer;
      ASCII_Pace_Ch    : Byte;
      ASCII_Pace_Speed : Integer;
      ASCII_Out_Xlate  : Boolean;
      ASCII_Out_CR,
      ASCII_Out_LF     : Byte;  {0,1,2}
      ASCII_Out_Expand : Boolean;
      ASCII_EOL_Ch     : Byte;
   Label
      ContUp, ContinuedBatch, EExit;
   Begin
      Script_Upload_active := True;
      Get_Next_Token;
      If Token.Token_Type = tk_word Then
         Begin
            menu1 := Upcase(Token.Str_Value[1]); {transfer method}
            Case menu1 Of
               'A' : Begin
                        ASCII_Pace_Ch    := qq.ascii_Pace_Ch;
                        ASCII_Pace_Speed := qq.ASCII_Pace_Speed;
                        ASCII_Out_Xlate  := qq.ASCII_Out_Xlate;
                        ASCII_Out_CR     := qq.ASCII_Out_CR;
                        ASCII_Out_LF     := qq.ASCII_Out_LF;
                        ASCII_Out_Expand := qq.ASCII_Out_Expand;
                        ASCII_EOL_Ch     := qq.ASCII_EOL_Ch;

                        Get_Next_Token;
                        If Token.Token_Type <> tk_word Then
                           Begin
                              Script_Edit_Error(6);
                              Exit;
                           End;
                        FName := Token.Str_Value;

                        { See if it exists }
                        If Not existFile(FName) Then
                           Begin
                              Script_Edit_Error(11);
                              Exit;
                           End;

                        {parse options}
                        { ASCII_Pace_Ch    :=  PACECH=[char]
                          ASCII_Pace_Speed :=  PACESPEED=[nnnn]
                          ASCII_Out_Xlate  :=  XLATE=[ON/OFF]
                          ASCII_Out_CR     :=  CR=[NONE/STRIP/ADDLF]
                          ASCII_Out_LF     :=  LF=[NONE/STRIP/ADDCR]
                          ASCII_Out_Expand :=  EXPAND=[ON/OFF]
                          ASCII_EOL_Ch     :=  EOLCH=[char]
                        }
                        Repeat
                           Get_Next_Token;
                           If Token.Token_Type = tk_word Then
                              Begin
                                 temp1 := STUpCase(Token.Str_Value);

                                 If Copy(Temp1,1,7) = 'PACECH=' then
                                    Begin
                                       If (Length(temp1) <> 8) and
                                          (Length(temp1) <> 11) then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          If Length(Temp1) = 8 then
                                             qq.ASCII_Pace_Ch := Ord(Temp1[8])
                                          Else
                                             If (Length(Temp1) = 11) and (STUpCase(Copy(Temp1,8,4))='NONE') then
                                                qq.ASCII_Pace_Ch := 0
                                             Else
                                                Begin
                                                   Script_Edit_Error(14);
                                                   Goto EExit;
                                                End;
                                    End Else

                                 If Copy(Temp1,1,10) = 'PACESPEED=' then
                                    Begin
                                       If Length(temp1) = 10 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          If not Str2Int(Copy(temp1,11,4),qq.ASCII_Pace_Speed) then
                                             Begin
                                                Script_Edit_Error(14);
                                                Goto EExit;
                                             End;
                                    End Else

                                 If Copy(Temp1,1,6) = 'XLATE=' then
                                    Begin
                                       If Length(temp1) < 8 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             temp1 := Copy(temp1,7,3);
                                             If Temp1 = 'ON' then
                                                qq.ASCII_Out_Xlate := True
                                             Else
                                                If Temp1 = 'OFF' then
                                                   qq.ASCII_Out_Xlate := False
                                                Else
                                                   Begin
                                                      Script_Edit_Error(14);
                                                      Goto EExit;
                                                   End;
                                          End;
                                    End Else

                                 If Copy(Temp1,1,7) = 'EXPAND=' then
                                    Begin
                                       If Length(temp1) < 9 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             temp1 := Copy(temp1,8,3);
                                             If Temp1 = 'ON' then
                                                qq.ASCII_Out_Expand:= True
                                             Else
                                                If Temp1 = 'OFF' then
                                                   qq.ASCII_Out_Expand:= False
                                                Else
                                                   Begin
                                                      Script_Edit_Error(14);
                                                      Goto EExit;
                                                   End;
                                          End;
                                    End Else

                                 If Copy(Temp1,1,3) = 'CR=' then
                                    Begin
                                       If Length(temp1) < 7 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             temp1 := Copy(temp1,4,5);
                                             If Temp1 = 'NONE' then
                                                qq.ASCII_Out_CR := 0
                                             Else
                                                If Temp1 = 'STRIP' then
                                                   qq.ASCII_Out_CR := 1
                                                Else
                                                   If Temp1 = 'ADDLF' then
                                                      qq.ASCII_Out_CR := 2
                                                   Else
                                                      Begin
                                                         Script_Edit_Error(14);
                                                         Goto EExit;
                                                      End;
                                          End;
                                    End Else

                                 If Copy(Temp1,1,3) = 'LF=' then
                                    Begin
                                       If Length(temp1) < 7 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             temp1 := Copy(temp1,4,5);
                                             If Temp1 = 'NONE' then
                                                qq.ASCII_Out_LF := 0
                                             Else
                                                If Temp1 = 'STRIP' then
                                                   qq.ASCII_Out_LF := 1
                                                Else
                                                   If Temp1 = 'ADDCR' then
                                                      qq.ASCII_Out_LF := 2
                                                   Else
                                                      Begin
                                                         Script_Edit_Error(14);
                                                         Goto EExit;
                                                      End;
                                          End;
                                    End Else

                                 If Copy(Temp1,1,5) = 'EOLCH=' then
                                    Begin
                                       If Length(temp1) <> 6 then
                                          Begin
                                             Script_Edit_Error(14);
                                             Goto EExit;
                                          End
                                       Else
                                          Begin
                                             If not Str2Int(Copy(temp1,7,3),x) then
                                                Begin
                                                   Script_Edit_Error(14);
                                                   Goto EExit;
                                                End
                                             Else
                                                qq.ASCII_EOL_Ch := x;
                                          End;

                                    End;
                              End;
                        Until Token.Token_Type <> tk_Word;

                        { Get Prompt character }
                        Upload(FName,  { Filename              }
                               'A',    { ASCII protocol        }
                               ' ');   { dummy variable        }

                        EExit:
                        qq.ASCII_Pace_Ch    := ASCII_Pace_Ch;
                        qq.ASCII_Pace_Speed := ASCII_Pace_Speed;
                        qq.ASCII_Out_Xlate  := ASCII_Out_Xlate;
                        qq.ASCII_Out_CR     := ASCII_Out_CR;
                        qq.ASCII_Out_LF     := ASCII_Out_LF;
                        qq.ASCII_Out_Expand := ASCII_Out_Expand;
                        qq.ASCII_EOL_Ch     := ASCII_EOL_Ch;

                     End;            {Ascii}

               Else     { Was not ASCII as a selection character }
                  Begin
                     Get_Next_Token;
                     If Token.Token_Type <> tk_word Then
                        Script_Edit_Error(6)
                     Else
                        Begin
                           FName := Token.Str_Value;
                           If not (menu1 in ['Z','Y','G']) then
                              Goto ContUp;
                           If Is_External(menu1) > 0 then
                              Goto ContUp;
                           ClearBatchNames(false,true);  {Clear the old list if any}
                           Repeat
                              ContinuedBatch:
                              FName := Token.Str_Value;
                              If FName = '_' then
                                 Begin
                                    Get_Next_Token;
                                    Get_Next_Token;
                                    If Token.Token_Type = tk_word then
                                       Goto ContinuedBatch;
                                 End
                              Else
                                 If Exist_Wild(FName) Then
                                    AddBatchName(JustPathName(Fname),
                                                 JustFileName(Fname));
                              Get_Next_Token;
                           Until Token.Token_Type <> tk_word;
                           ContUp:
                           Upload(FName, menu1, ' ');
                        End
                  End
            End;                  {Case}
         End
      Else
         Script_Edit_Error(5);
      Script_Upload_active := False;
      Last_Token.Token_Type := tk_end_rec {closes the current record } ;
   End;

End.
