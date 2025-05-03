{$F+}
Unit Scripts;

Interface

Uses Qmem,     OpKey,
     Dos,      TPHelp,
     TpCrt,    TPDos,
     TPString, Initial,
     BinFSE,   exitdos,
     Screen,   Comm,
     Procs,    Files,
     Group1;

Procedure Fkey_Script(scrpt : String);
Procedure Script_Edit_Error(error_num : Byte);
Procedure Initialize_Script_Parser;
Procedure Close_Script;
Procedure Get_Next_Token;
Procedure Check_Script_Abort;
Procedure Free_When_Stack;
Procedure Free_Allocated_Script_Pointer;
Procedure Execute_A_Script;
Procedure Get_NoComments;

Var
   Script_Animate,
   ScriptFileText,
   ScriptTextRead : Boolean;
   ScrTEXT        : Text;


Implementation

Uses
   Emuls, Scripts2, Scripts4;


   Procedure Fkey_Script(scrpt : String);
   Var
      Ch : Char;
   Begin
      If Scripting then
         Open_Script(Scrpt)
      Else
         Begin
            If not ExistFile(FullScriptFilename(Scrpt)) then
               Learn(Scrpt)
            Else
               Begin
                  Already_Initialized := False;
                  Scripting := True;
                  Script_to_Open := scrpt;
               End;
         End;
   End;

   Procedure Execute_A_Script;
   Begin
      If Script_to_Open <> '' Then
         Begin
            Open_Script(Script_to_Open);
            If Not Scripting Then Exit;
         End;
      Call_Script_Overlay;
      Set_Colors;
      Home_Status_Msg;
      If Exit_Main Then
         Exit_to_DOS(True, Exit_Main_Ch);
      If ScriptFileText Then
         Get_and_Execute_CloseFile; { close the open file }
      Free_Allocated_Script_Pointer;
      StatusWasOn := True;
      HelpTopic := 0;
      If not ShowSL then
         WritelnT('Script Completed.');
   End;

   Procedure Script_Edit_Error(error_num : Byte); { 1st Overlay }
   Var
      et  : Integer;
      ShortStr : String[160];
   Label
      EditLabel;

      Procedure Script_Error_Msg(error_num : Byte);
      Begin
         Write('Type : ');
         textAttr := qq.menu2;
         Case error_num Of
            0   : WriteLn('Invalid KEYWORD or TOKEN');
            1   : WriteLn('DOWNLOAD Filename expected');
            2   : WriteLn('WORD or LABEL expected');
            3   : WriteLn('STRING length 0');
            4   : WriteLn('STRING expected');
            5   : WriteLn('WORD expected');
            6   : WriteLn('UPLOAD Filename expected');
            7   : WriteLn('INTEGER expected');
            8   : WriteLn('DRIVE Letter A..Z expected');
            9   : WriteLn('SETCOMM Keyword(s) expected');
            10  : WriteLn('SCRIPT Filename not found');
            11  : WriteLn('UPLOAD Filename does not exist');
            12  : WriteLn('RETURN SCRIPT Filename not found');
            13  : WriteLn('Off Screen Coordinates');
            14  : Writeln('Invalid UPLOAD keyword or option');
            15  : Writeln('Invalid DOWNLOAD keyword or option');
            16  : Writeln('Target LABEL cannot be a KEYWORD');
            17  : WriteLn('WORD or STRING expected');
            20  : WriteLn('LABEL not found');
            30  : WriteLn('TURNON Keyword(s) not found');
            31  : WriteLn('GRAPHICS Keyword not found');
            40  : WriteLn('TURNOFF Keywords(s) not found');
            50  : WriteLn('CAPTURE Filename not found');
            51  : WriteLn('LOADFON Filename not found');
            52  : WriteLn('LOADKEY Filename not found');
            53  : WriteLn('LOG Filename not found');
            54  : WriteLn('Invalid SEND keyword');
            70  : WriteLn('ON or OFF parameter expected');
            80  : WriteLn('FLUSH keyword not KBD, COM or ALL');
            90  : WriteLn('Too many WHEN''s defined');
            100 : WriteLn('SCRIPT/GOSUB nested too deep');
            110 : WriteLn('SYSTEM parameter not "Y" or "X"');
            120 : WriteLn('STRING VARIABLE expected');
            131 : WriteLn('STRING not defined');
            140 : WriteLn('FON Filename does not exist');
            150 : WriteLn('FKEY Filename does not exist');
            160 : WriteLn('PORT selection invalid');
            170 : WriteLn('Invalid IF Opcode');
            180 : WriteLn('GETSCR Nested too deep');
            182 : Writeln('SINGLE or REPEAT parameter expected');
            185 : WriteLn('Too many PUSHes');
            186 : WriteLn('Insufficient space for String');
            187 : WriteLn('Insufficient space for Label');
            190 : WriteLn('INTEGER value required for INCR or DECR');
            200 : WriteLn('EGA/VGA value must be 25, 43 or 50');
            210 : WriteLn('Invalid OPENFILE mode');
            211 : WriteLn('FILE already open');
            212 : WriteLn('ERROR opening FILE');
            213 : WriteLn('FILE not open');
            214 : WriteLn('FILE not open for READ');
            215 : WriteLn('FILE not open for WRITE/APPEND');
            216 : WriteLn('ERROR Writing to FILE');
            217 : WriteLn('ERROR Reading from FILE');
            230 : WriteLn('ERROR Opening Script File');
            252 : WriteLn('Invalid Substitute VARIABLE');
            253 : WriteLn('Substitute Line too long');
            254 : WriteLn('Line too long');
            255 : WriteLn('Invalid LABEL or misplaced COLON');
         End;
      End;

   Begin
      If Hosting and (Error_Num = 10) then
         Begin
            OutKey (^M^J'Sorry, that function is not available.');
            Delay(2000);
         End
      Else
         Begin
            SetWindow2(3,9,77,16,' Script Error! ',false);
            Script_Error_Msg(error_num);
            Close_Script;
            Inc(Script_Stack_Pointer);
            Script_Parm_Line := '';
            Fatal_Error := True;
            Scripting := False;
            et := 0;
            If error_num = 20 Then
               Begin
                  If (Script_Timeout_Label = '') And (Script_Goto_Str <> '') Then
                     et := 1            {goto error}
                  Else
                     If (Script_Timeout_Label <> '') And (Script_Goto_Str = '') Then
                        et := 2         {timeout error}
                     Else
                        If (Script_Timeout_Label = Script_Goto_Str) Then
                           et := 2      {timeout error}
                        Else
                           et := 1 {goto error} ;
                  Case et Of
                     1 : WriteLn('       GOTO/GOSUB LABEL = ', Script_Goto_Str);
                     2 : WriteLn('       TIMEOUT LABEL    = ', Script_Timeout_Label);
                  End;
               End;
            If (error_num = 10) or
               (error_num = 254) or
               (error_num = 187) Then Dec(Script_Stack_Pointer);
            If (error_num = 100) Then Dec(Script_Stack_Pointer,2);
            textattr := qq.menu;
            Write  ('File : ');
            textattr := qq.menu2;
            Writeln(Script_Stack[Script_Stack_Pointer].S_Filename);
            textattr := qq.menu;
            Write('Line : ');
            textattr := qq.menu2;
            ShortStr := Parse_Input;
            Writeln(ShortStr);
            EditLabel:
            If ExistFile(Script_Stack[Script_Stack_Pointer].S_Filename) Then
               Begin
                  textattr := qq.menu;
                  gotoxy(1,7);
                  Write('Press any key to Edit file ');
                  CharWord := ReadKeyA;
                  Restore_Screen;
                  FSE(Script_Stack[Script_Stack_Pointer].S_Filename,
                      Last_Good_Token + Token.Position - 1,
                      (*
                      FindByteOffset(Script_Stack[Script_Stack_Pointer].S_Filename,
                                     Script_Stack[Script_Stack_Pointer].Line_Num,
                                     token.Position),
                      *)
                      2,PRLR-1,false);
               End
            Else
               Begin
                  textattr := qq.menu;
                  gotoxy(1,7);
                  Write('Press any key to Exit ');
                  CharWord := ReadKeyA;
                  Restore_Screen;
               End;

            If (error_num = 10) or
               (error_num = 254) Then Inc(Script_Stack_Pointer);
            If (error_num = 100) Then Inc(Script_Stack_Pointer,2);
         End;
      Dec(Script_Stack_Pointer);
   End;

   Procedure Initialize_Script_Parser;

      Procedure Add_Key(Name : str20; ktype : valid_token_type);
      Begin
         Inc(Keyword_Count);
         Keyword_Element[Keyword_Count].key_name := Name;
         Keyword_Element[Keyword_Count].key_type := ktype;
      End;

   Begin
      If Not Already_Initialized Then
         Begin
            Keyword_Count := 0;
            Add_Key('8_BIT'  ,    To_8_BIT);
            Add_Key('ASSIGN',     kw_assign);
            Add_Key('ATWRITE',    kw_atwrite);
            Add_Key('BEEP',       kw_beep);
            Add_Key('BIGDOS',     kw_bigdos);
            Add_Key('BOX',        kw_box);
            Add_Key('BREAK',      kw_break);
            Add_Key('BS_DEL' ,    To_BS_DEL);
            Add_Key('CAPTURE',    kw_capture);
            Add_Key('CASE',       To_CASE);
            Add_Key('CHDIR',      kw_chdir);
            Add_Key('CLOSEFILE',  kw_closefile);
            Add_Key('CLRSCR',     kw_clrscr);
            Add_Key('COLOR',      kw_color);
            Add_Key('COLORBG',    kw_colorbg);
            Add_Key('COLORFG',    kw_colorfg);
            Add_Key('DEBUG',      kw_debug);
            Add_Key('DECR',       kw_decr);
            Add_Key('DELAY',      kw_delay);
            Add_Key('DIAL',       kw_dial);
            Add_Key('DISPLAY',    kw_display);
            Add_Key('DISPLAYLN',  kw_displayln);
            Add_Key('DOORWAY',    To_DOORWAY);
            Add_Key('DOS',        kw_dos);
            Add_Key('DOWNLD',     kw_downld);
            Add_Key('DOWNLOAD',   kw_download);
            Add_Key('DRIVE',      kw_drive);
            Add_Key('ECHO',       To_ECHO);
            Add_Key('EDIT',       kw_edit);
            Add_Key('EGA',        kw_ega);
            Add_Key('EXIST',      kw_exist);
            Add_Key('EXIT',       kw_exit);
            Add_Key('FKEY',       kw_fkey);
            Add_Key('FLUSH',      kw_flush);
            Add_Key('GET',        kw_get);
            Add_Key('GETN',       kw_getn);
            Add_Key('GETNR',      kw_getnr);
            Add_Key('GETR',       kw_getr);
            Add_Key('GETSCR',     kw_getscr);
            Add_Key('GETX',       kw_getx);
            Add_Key('GOSUB',      kw_gosub);
            Add_Key('GOTO',       kw_goto);
            Add_Key('GOTOXY',     kw_gotoxy);
            Add_Key('GRAPHICS',   kw_graphics);
            Add_Key('HANGUP',     kw_hangup);
            {$IfNDef GG}
            Add_Key('HOST',       kw_host);
            {$EndIf}
            Add_Key('IF',         kw_if);
            Add_Key('INCR',       kw_incr);
            Add_Key('INKEY',      kw_inkey);
            Add_Key('LINEFEED',   To_LINEFEED);
            Add_Key('LOADFON',    kw_loadfon);
            Add_Key('LOADKEY',    kw_loadkey);
            Add_Key('LOG',        kw_log);
            Add_Key('MUSIC'  ,    To_MUSIC);
            Add_Key('NOISE'  ,    To_NOISE);
            Add_Key('NOTE',       kw_note);
            Add_Key('ONLINE' ,    To_ONLINE);
            Add_Key('OPENFILE',   kw_OpenFile);
            Add_Key('PAUSE',      kw_pause);
            Add_Key('POP',        kw_pop);
            Add_Key('PORT',       kw_port);
            Add_Key('PRINT'  ,    To_PRINT);
            Add_Key('PUSH',       kw_push);
            Add_Key('PUTSCR',     kw_putscr);
            Add_Key('READFILE',   kw_readfile);
            Add_Key('RETURN',     kw_return);
            Add_Key('SCRIPT',     kw_script);
            Add_Key('SCROLL' ,    To_SCROLL);
            Add_Key('SEND',       kw_send);
            Add_Key('SETCOMM',    kw_setcomm);
            Add_Key('SPLIT'  ,    To_SPLIT);
            Add_Key('STAMP',      kw_stamp);
            Add_Key('STATUSLN',   To_AltMinus);
            Add_Key('STRING',     kw_string);
            Add_Key('SYSTEM',     kw_system);
            Add_Key('TIMEOUT',    kw_timeout);
            Add_Key('TURNOFF',    kw_turn_off);
            Add_Key('TURNON',     kw_turn_on);
            Add_Key('UPLD',       kw_upld);
            Add_Key('UPLOAD',     kw_upload);
            Add_Key('WAITFOR',    kw_wait_for);
            Add_Key('WAITUNTIL',  kw_wait_until);
            Add_Key('WHEN',       kw_when);
            Add_Key('WINDOW',     kw_window);
            Add_Key('WRITE',      kw_write);
            Add_Key('WRITEFILE',  kw_writefile);
            Add_Key('WRITELN',    kw_writeln);
            Add_Key('XON/XOFF',   To_XON_XOFF);

            { Load up the procedural parameter variables now... }

            Keyword_Procedure[Tk_UnRec      ] := Get_and_Execute_Error0;
            Keyword_Procedure[Tk_Word       ] := Get_and_Execute_Error0;
            Keyword_Procedure[Tk_Word_plus  ] := Get_and_Execute_Dummy;
            Keyword_Procedure[Tk_string     ] := Get_and_Execute_Dummy;
            Keyword_Procedure[Tk_end_rec    ] := Get_and_Execute_Dummy;
            Keyword_Procedure[Tk_label      ] := Get_and_Execute_Dummy;
            Keyword_Procedure[Tk_end_file   ] := Get_and_Execute_End_File;

            Keyword_Procedure[Kw_label      ] := Get_and_Execute_Dummy;
            Keyword_Procedure[KW_goto       ] := Get_and_Execute_GoTo;
            Keyword_Procedure[KW_gosub      ] := Get_and_Execute_Gosub;
            Keyword_Procedure[KW_display    ] := Get_and_Execute_Display_False;
            Keyword_Procedure[KW_displayln  ] := Get_and_Execute_DisplayLn;
            Keyword_Procedure[KW_if         ] := Get_and_Execute_If;
            Keyword_Procedure[KW_inkey      ] := Get_and_Execute_InKey;
            Keyword_Procedure[KW_Color      ] := Get_and_Execute_Color;
            Keyword_Procedure[KW_Colorfg    ] := Get_and_Execute_ColorFG;
            Keyword_Procedure[KW_Colorbg    ] := Get_and_Execute_ColorBG;
            Keyword_Procedure[KW_gotoxy     ] := Get_and_Execute_GotoXY;
            Keyword_Procedure[KW_note       ] := Get_and_Execute_Note;
            Keyword_Procedure[KW_atwrite    ] := Get_and_Execute_AtWrite;
            Keyword_Procedure[KW_writeln    ] := Get_and_Execute_Writeln_True;
            Keyword_Procedure[KW_write      ] := Get_and_Execute_Writeln_False;
            Keyword_Procedure[KW_return     ] := Return_to_Previous_Script;
            Keyword_Procedure[KW_wait_for   ] := Get_and_Execute_WaitFor;
            Keyword_Procedure[KW_send       ] := Get_and_Execute_Send;
            Keyword_Procedure[KW_when       ] := Get_and_Execute_When;
            Keyword_Procedure[KW_incr       ] := Get_and_Execute_INCR_True;
            Keyword_Procedure[KW_decr       ] := Get_and_Execute_INCR_False;
            Keyword_Procedure[KW_system     ] := Get_and_Execute_System;
            Keyword_Procedure[KW_timeout    ] := Get_and_Execute_Timeout;
            Keyword_Procedure[KW_delay      ] := Get_and_Execute_Delay;
            Keyword_Procedure[KW_clrscr     ] := Low_Clear_Screen;
            Keyword_Procedure[KW_flush      ] := Get_and_Execute_Flush;
            Keyword_Procedure[KW_loadfon    ] := Get_and_Execute_LoadFON;
            Keyword_Procedure[KW_loadkey    ] := Get_and_Execute_LoadKEY;
            Keyword_Procedure[KW_fkey       ] := Get_and_Execute_FKEY;
            Keyword_Procedure[KW_getscr     ] := Get_and_Execute_GetScr;
            Keyword_Procedure[KW_putscr     ] := Get_and_Execute_PutScr;
            Keyword_Procedure[KW_box        ] := Get_and_Execute_Box;
            Keyword_Procedure[KW_push       ] := Get_and_Execute_Push;
            Keyword_Procedure[KW_pop        ] := Get_and_Execute_Pop;
            Keyword_Procedure[KW_window     ] := Get_and_Execute_Window_False;
            Keyword_Procedure[KW_chdir      ] := Get_and_Execute_ChDir;
            Keyword_Procedure[KW_dial       ] := Get_and_Execute_Dial;
            Keyword_Procedure[KW_download   ] := Get_and_Execute_Download_False;
            Keyword_Procedure[KW_downld     ] := Get_and_Execute_Download_True;
            Keyword_Procedure[KW_dos        ] := Get_and_Execute_DOS;
            Keyword_Procedure[KW_bigdos     ] := Get_and_Execute_BigDOS;
            Keyword_Procedure[KW_drive      ] := Get_and_Execute_Drive;
            Keyword_Procedure[KW_exit       ] := Get_and_Execute_Exit;
            Keyword_Procedure[KW_port       ] := Get_and_Execute_Port;
            Keyword_Procedure[KW_ega        ] := Get_and_Execute_EGA;
            Keyword_Procedure[KW_script     ] := Get_and_Execute_Script;
            Keyword_Procedure[KW_pause      ] := Get_and_Execute_Pause;
            Keyword_Procedure[KW_turn_on    ] := Get_and_Execute_Turn_On;
            Keyword_Procedure[KW_turn_off   ] := Get_and_Execute_Turn_Off;
            Keyword_Procedure[KW_capture    ] := TurnOn_Capture;
            Keyword_Procedure[KW_log        ] := TurnOn_Log;
            Keyword_Procedure[KW_assign     ] := Get_and_Execute_Assign;
            Keyword_Procedure[KW_exist      ] := Get_and_Execute_Exist;
            Keyword_Procedure[KW_OpenFile   ] := Get_and_Execute_OpenFile;
            Keyword_Procedure[KW_readfile   ] := Get_and_Execute_ReadFile;
            Keyword_Procedure[KW_writefile  ] := Get_and_Execute_WriteFile;
            Keyword_Procedure[KW_closefile  ] := Get_and_Execute_CloseFile;
            Keyword_Procedure[KW_upload     ] := Get_and_Execute_Upload_False;
            Keyword_Procedure[KW_upld       ] := Get_and_Execute_Upload_True;
            Keyword_Procedure[KW_setcomm    ] := Get_and_Execute_SetComm;
            Keyword_Procedure[KW_hangup     ] := Get_and_Execute_HangUp;
            Keyword_Procedure[KW_stamp      ] := Get_and_Execute_Stamp;
            Keyword_Procedure[KW_wait_until ] := Get_and_Execute_WaitUntil;
            Keyword_Procedure[KW_beep       ] := Get_and_Execute_Beep;
            Keyword_Procedure[KW_debug      ] := Get_and_Execute_Debug;
            Keyword_Procedure[KW_get        ] := Get_and_Execute_Get_False_True;
            Keyword_Procedure[KW_getr       ] := Get_and_Execute_Get_True_True;
            Keyword_Procedure[KW_getn       ] := Get_and_Execute_Get_False_False;
            Keyword_Procedure[KW_getnr      ] := Get_and_Execute_Get_True_False;
            Keyword_Procedure[KW_getx       ] := Get_and_Execute_Getx;
            Keyword_Procedure[KW_graphics   ] := Get_and_Execute_Graphics;
            Keyword_Procedure[KW_break      ] := Get_and_Execute_Break;
            Keyword_Procedure[KW_edit       ] := Get_and_Execute_Edit;
            {$IfNDef GG}
            Keyword_Procedure[KW_host       ] := Get_and_Execute_Host;
            {$EndIf}
            Keyword_Procedure[KW_string     ] := Get_and_Execute_String;
         End;

      Last_Token.Token_Type := TK_Unrec;
      token.Token_Type := TK_Unrec;
      Fatal_Error := False;

      If Script_Strings_Set = 0 Then
         For x := 1 To 10 Do
            Begin
               SetString(Script_Strings[x].Name, StringToHeap(Long2Str(x - 1)));
               SetString(Script_Strings[x].value, Nil);
               Inc(Script_Strings_Set);
            End;
      If (Script_Parm_Line <> '') Or (Not Already_Initialized) Then
         Begin
            { first use Get_Next_Token to parse the parameter line }
            { note that $'s in parms are converted to ^Z's }
            { Clear the previous values for $0 - $9 }
            For x := 1 To Length(Script_Parm_Line) Do
               If Script_Parm_Line[x] = '$' Then
                  Script_Parm_Line[x] := #26;

            parse_input := TrimTrail(Script_Parm_Line) + ' ';
            parse_length := Length(parse_input);
            parse_start := 1;
            x := 1;
            Repeat
               Get_Next_Token;
               Case token.Token_Type Of
                  tk_word      : SetString(Script_Strings[x].value,
                                           StringToHeap(token.Str_Value));
                  tk_string    : SetString(Script_Strings[x].value,
                                           StringToHeap('"' + token.Str_Value + '"'));
                  tk_label     : SetString(Script_Strings[x].value,
                                           StringToHeap(token.Str_Value + ':'));
                  tk_end_rec,
                  tk_end_file,
                  TK_Unrec     : x := 11;
                  Else           SetString(Script_Strings[x].value,
                                           StringToHeap(token.Str_Value));
               End;
               Inc(x);
            Until x > 10;
         End;

      If Already_Initialized Then
         Begin
            Last_Token.Token_Type := tk_end_rec;
            token.Token_Type := TK_Unrec;
            Fatal_Error := False;
            last_parse_record := False;
            Exit;
         End;

      { Set these things at the beginning of a script }
      Last_Label_Script     := '';
      ScriptFileText        := False;
      Push_n_Pop            := 0;
      Script_Whens          := False;
      Script_Animate        := False;
      CaseSensitive         := False;
      Type_Ahead            := '';
      Last_Token.Token_Type := tk_end_rec;
      token.Token_Type      := TK_Unrec;
      last_parse_record     := False;
      Script_Label_Head     := Nil;

      { Reset the Script Stack }
      For Script_Stack_Pointer := 1 To Max_Script_Stack Do
         Begin
            Script_Stack[Script_Stack_Pointer].S_Filename := '';
            Script_Stack[Script_Stack_Pointer].Record_Num := 0;
         End;

      Script_Stack_Pointer := 0;
      Already_Initialized  := True;
      Script_Parm_Line     := '';
   End;


   Procedure Close_Script;
   Begin
      If Script_File_Open Then
         Begin
            Dec(Script_Stack_Pointer);
            Close(Script_file);
            IO := IoResult;
            Script_File_Open := False;
         End;
   End;

   Procedure Get_Char_String;
   Var End_Ch     : Char;
   Begin
      If Label_Search Then
         Begin
            Inc(parse_start);
            Exit;
         End;
      If parse_input[parse_start] = '"'
         Then End_Ch := '"'
         Else End_Ch := '''';
      token.Token_Type := tk_string;
      token.Str_Value := '';
      Inc(parse_start);
      While (parse_start <= parse_length) And
            (parse_input[parse_start] <> End_Ch) Do
         Begin
            If (parse_input[parse_start] = #255) And
               (parse_input[Succ(parse_start)] In [#255, '''', '"', '$']) Then
               Begin
                  token.Str_Value := token.Str_Value + parse_input[Succ(parse_start)];
                  Inc(parse_start, 2);
               End
            Else
               Begin
                  token.Str_Value := token.Str_Value + parse_input[parse_start];
                  Inc(parse_start);
               End;
         End;
      If parse_input[parse_start] = End_Ch Then
         Inc(parse_start);
   End;                     {Get_Char_String}

   Procedure Get_Keyword_Word_or_Label;
   Var
      tsv            : String;
      x, low_, hi_, mid_ : Integer;
   Begin
      token.Str_Value := '';
      While Not(parse_input[parse_start] In [' ', ',']) Do
         Begin
            token.Str_Value := token.Str_Value + parse_input[parse_start];
            Inc(parse_start);
         End;

      tsv := STUpCase(token.Str_Value);

      { This is where the Binary Search will go for Keywords }

      low_ := 1;
      hi_ := Keyword_Count;
      While (low_ <= hi_) Do
         Begin
            mid_ := (low_ + hi_) Div 2;
            If tsv = Keyword_Element[mid_].key_name Then
               Begin
                  token.Token_Type := Keyword_Element[mid_].key_type;
                  Exit;
               End
            Else
               If tsv < Keyword_Element[mid_].key_name Then
                  hi_ := Pred(mid_)
               Else
                  low_ := Succ(mid_);
         End;

      token.Token_Type := tk_word;
      x := Byte(token.Str_Value[0]);
      If (token.Str_Value[x] = ':') And Not Script_Upload_active Then
         If x = 1 Then
            Script_Edit_Error(255) {just a colon}
         Else
            Begin
               Delete(token.Str_Value, x, 1); {delete the colon}
               token.Token_Type := tk_label;
            End;
   End;                     {Get_Keyword_Word_or_Label}




   Procedure Get_Token;
   Begin                       {Get_Token}
      Token.Token_Type := TK_Unrec;
      While (parse_start <= parse_length)
        And (token.Token_Type = TK_Unrec) Do
         Begin
            token.Position := parse_start;
            Case parse_input[parse_start] Of
               ' ',  ',' : Inc(parse_start);
               '''', '"' : Get_Char_String;
               ';'       : token.Token_Type := tk_end_rec;
               Else        Get_Keyword_Word_or_Label;
            End
         End;                  {while}
      If token.Token_Type = TK_Unrec Then
         token.Token_Type := tk_end_rec;
   End;                        {Get_Token}




   Procedure Get_NoComments;
   Begin                       {Get_NoComments}
      token.Token_Type := TK_Unrec;
      While (parse_start <= parse_length) and
            (token.Token_Type <> TK_End_Rec) Do
         Begin
            token.Position := parse_start;
            Case parse_input[parse_start] Of
               ' ', ','  : Inc(parse_start);
               '''', '"' : Get_Char_String;
               ';'       : token.Token_Type := tk_end_rec;
               Else        Inc(Parse_Start);
            End
         End;                  {while}
      If token.Token_Type = TK_Unrec Then
         token.Token_Type := tk_end_rec;
   End;                        {Get_NoComments}



   Procedure Get_Next_Token;
   Var
      temp_line    : String[254];
      temp_char    : String[1];
      x, y, z      : Integer;
      Temp, dtmp,
      dtmp2        : String;

   Const
      ss = ' [SPACE] Next  [T] Trace  [G] Go  [S] Subst. Line  [O] Orig.Line  [U] Under ';

      Procedure Parse_Substitute;
      Var
         Temp    : String;
         cntl_z  : String[1];
         cntl_zz : String[1];
         x, y    : Integer;

         Procedure Dollars2CtrlZ;
         Var
            x : Word;
         Begin
            Repeat
               x := SearchLeftC(Temp, '$$');
               If x > 0 Then
               Begin
                  Delete(Temp, x, 2);
                  Insert(^Z, Temp, x);
               End;
            Until x = 0;
         End;


         Procedure Check_for_Substitutions;
         Var
            A, B  : Integer;
            Ok    : Boolean;
            s01   : String[4];
            temp2 : String;
         Begin
            If Label_Search Then Exit;
            Ok := False;
            temp2 := STUpCase(Temp);

            If Copy(temp2, Succ(x), 8) = 'PASSWORD' Then
               Begin
                  Delete(Temp, x, 9);
                  Insert(Linked_Password, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'ONLINE' Then
               Begin
                  Delete(Temp, x, 7);
                  If Online Then Insert('"0" = "0"', Temp, x)
                  Else Insert('"0" = "1"', Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 7) = 'OFFLINE' Then
               Begin
                  Delete(Temp, x, 8);
                  If Online Then Insert('"0" = "1"', Temp, x)
                  Else Insert('"0" = "0"', Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 7) = 'SUCCESS' Then
               Begin
                  Delete(Temp, x, 8);
                  If Script_success Then Insert('"0" = "0"', Temp, x)
                  Else Insert('"0" = "1"', Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 4) = 'FAIL' Then
               Begin
                  Delete(Temp, x, 5);
                  If Not Script_success Then Insert('"0" = "0"', Temp, x)
                  Else Insert('"0" = "1"', Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 5) = 'INKEY' Then
               Begin
                  Delete(Temp, x, 6);
                  If Keypressed Or (Type_Ahead <> '') Then Insert('"1" = "1"', Temp, x)
                  Else Insert('"1" = "0"', Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 4) = 'ATTR' Then
               Begin
                  Delete(Temp, x, 5);
                  Insert(Long2Str(TextAttr), Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 4) = 'TIME' Then
               Begin
                  Delete(Temp, x, 5);
                  Insert(TimeS, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 4) = 'DATE' Then
               Begin
                  Delete(Temp, x, 5);
                  Insert(DateS, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 8) = 'PROTOCOL' Then
               Begin
                  Delete(Temp, x, 9);
                  Insert(Linked_Protocol, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 8) = 'NOTEFILE' Then
               Begin
                  Delete(Temp, x, 9);
                  Insert(Linked_NoteFile, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'ULPATH' Then
               Begin
                  Delete(Temp, x, 7);
                  Insert(qq.Upload_path_s, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'DLPATH' Then
               Begin
                  Delete(Temp, x, 7);
                  Insert(qq.Downld_Path_s, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'SCPATH' Then
               Begin
                  Delete(Temp, x, 7);
                  Insert(qq.Script_Path, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'WHEREX' Then
               Begin
                  Delete(Temp, x, 7);
                  Str(WhereX, s01);
                  Insert(s01, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'WHEREY' Then
               Begin
                  Delete(Temp, x, 7);
                  Str(WhereY, s01);
                  Insert(s01, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 8) = 'LAST_ROW' Then
               Begin
                  Delete(Temp, x, 9);
                  Str(Last_Row, s01);
                  Insert(s01, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 8) = 'LAST_COL' Then
               Begin
                  Delete(Temp, x, 9);
                  Str(Last_Col, s01);
                  Insert(s01, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 5) = 'BOARD' Then
               Begin
                  Delete(Temp, x, 6);
                  Insert(Linked_board, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'NUMBER' Then
               Begin
                  Delete(Temp, x, 7);
                  Insert(Linked_number, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 6) = 'SCRIPT' Then
               Begin
                  Delete(Temp, x, 7);
                  Insert(Linked_script_file, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 5) = 'SPEED' Then
               Begin
                  Delete(Temp, x, 6);
                  Insert(Linked_speed, Temp, x);
                  Ok := True;
               End
            Else
            If Copy(temp2, Succ(x), 3) = 'COM' Then
               Begin
                  Delete(Temp, x, 4);
                  Insert(Linked_comm, Temp, x);
                  Ok := True;
               End
            Else
            For A := 1 To Script_Strings_Set Do
               If Copy(temp2, Succ(x),
                       Length(StringFromHeap(Script_Strings[A].Name))) =
                       StringFromHeap(Script_Strings[A].Name) Then
                  Begin
                     If (Byte(Temp[0]) +
                         Length(StringFromHeap(Script_Strings[A].value)) - 2) > 254 Then
                        Script_Edit_Error(253) {sub line to long}
                     Else
                        Begin
                           Delete(Temp, x, Length(StringFromHeap(
                                           Script_Strings[A].Name)) + 1);
                           Insert(StringFromHeap(Script_Strings[A].value),Temp, x);
                           Ok := True;
                           Exit;
                        End;
                  End;

            If Not Ok Then
               Begin
                  Token.Position := x;
                  Script_Edit_Error(252); {invalid substitute}
               End
            Else
               Dollars2CtrlZ;
         End;

      Begin                       { Parse_Substitute }
         Temp := parse_input;
         cntl_zz := #0;

         { change $$ to ^Z }
         Dollars2CtrlZ;

         Repeat
            x := SearchLeftC(Temp, '$');
            If (x > 0) Then
               Begin
                  Check_for_Substitutions;
                  { change #255$ to #0 }
                  Repeat
                     y := SearchLeftC(Temp, #255 + '$');
                     If y > 0 Then
                     Begin
                        Delete(Temp, y, 2);
                        Insert(cntl_zz, Temp, y);
                     End;
                  Until y = 0;
               End;
            If Fatal_Error Then Exit;
         Until x = 0;             { substitute done }

         { replace ^Z with $ }
         Repeat
            x := SearchLeftC(Temp, ^Z);
            If x > 0 Then Temp[x] := '$';
         Until x = 0;

         { replace #0 with #255$ }
         Repeat
            x := SearchLeftC(Temp, cntl_zz);
            If x > 0 Then
               Begin
                  Delete(Temp, x, 1);
                  Insert(#255 + '$', Temp, x);
               End;
         Until x = 0;

         parse_input := TrimTrail(Temp) + ' ';
         parse_length := Byte(parse_input[0]);
      End;                        {Parse_Substitute}

      Procedure Control_Substitute;
      Var
         Temp, Temp2 : String;
         x2          : Char;
         x           : Integer;
      Begin { Control_Substitute }
         Temp2 := '';
         Temp := parse_input;
         X := 1;
         While X <= Length(Temp) do
            begin
               Case Temp[x] of
                  '^' : Begin
                           If x = length(temp) then
                              temp2 := temp2 + '^'
                           Else
                              If temp[x+1] = '^' then
                                 Begin
                                    Temp2 := temp2 + '^^';
                                    Inc(x);
                                 End
                              Else
                                 If Upcase(Temp[x+1]) in ['A'..'_'] then
                                    Begin
                                       temp2 := temp2 + Chr(Ord(temp[x+1]) - 64);
                                       Inc(x);
                                    End
                                 Else
                                    temp2 := temp2 + '^';
                           Inc(x);
                        End;
                  Else
                     Begin
                        temp2 := temp2 + temp[x];
                        Inc(x);
                     End;
               End;
            End;

         parse_input := TrimTrail(Temp2) + ' ';
         parse_length := Byte(parse_input[0]);
      End;                        { Control_Substitute }

   Begin                          {Get_Next_Token}
      If Last_Token.Token_Type = tk_end_rec Then
         Begin
            If last_parse_record Then
               token.Token_Type := tk_end_file
            Else
               Begin
                  Last_Good_Token := TextPos(Script_File);
                  ReadLn(Script_file, parse_input);
                  Script_Stack[Script_Stack_Pointer].Record_Num := TextPos(Script_File);

                  parse_start := 1;
                  parse_length := Byte(parse_input[0]);
                  If Parse_Length > 254 Then
                     Script_Edit_Error(254)  {line to long}
                  Else
                     Begin
                        parse_input := parse_input + ' ';
                        Inc(parse_length);
                     End;
                  Parse_Input := DeTab(Parse_Input,1);
                  If EOF(Script_file) Then
                     last_parse_record := True;
                  If Script_Debug Then
                     dtmp2 := parse_input;
                  If Not Label_Search Then
                     Begin
                        If SearchLeftC(parse_input, #255) > 0 Then
                           Parse_Substitute;
                        If SearchLeftC(parse_input, '$') > 0 Then
                           Parse_Substitute;
                        If SearchLeftC(parse_input, '^') > 0 Then
                           Control_Substitute;
                     End;
                  If Script_Debug Then
                     Begin
                        Push_Status;
                        Push_Window;
                        Window(1, Real_Last_Row, Last_Col, Real_Last_Row);
                        TextAttr := qq.StatusLineColor;
                        ClrScr;
                        If Script_Animate Then
                           Begin
                              dtmp := 'TRACE <<' + dtmp2 + '>>';
                              dtmp2 := '';
                           End
                        Else
                           Begin
                              dtmp  := Pad('DEBUG <<' + dtmp2 + '>>',Last_Col);
                              dtmp2 := Pad('DEBUG <<' + parse_input + '>>',Last_Col);
                           End;
                        If Length(dtmp) > Last_Col Then dtmp[0] := Chr(Last_Col);
                        If Length(dtmp2) > Last_Col Then dtmp2[0] := Chr(Last_Col);
                        FastWrite(dtmp, Real_Last_Row, 2, qq.StatusLineColor);
                        If Script_Animate Then
                           Delay(500)
                        Else
                           Begin
                              Repeat
                                 CH := Upcase(Char(ReadKeyA));
                                 Case Ch of
                                    ' ' : ;
                                    'U' : If not ShowSL then
                                             Begin
                                                Push_Status;
                                                Dec (Save_Status_CNT);
                                                With SSC[Save_Status_CNT] do
                                                   RestoreWindow(c1,r1,c2,r2, False, Save_Status[Save_Status_CNT]);
                                                Delay(2000);
                                                Inc(Save_Status_CNT);
                                                Pop_Status;
                                             End;
                                    'T' : Script_Animate := True;
                                    'G' : Begin
                                             Script_Animate := False;
                                             Script_Debug := False;
                                          End;
                                    'S' : FastWrite(dtmp2, Real_Last_Row, 2, qq.StatusLineColor);
                                    'O' : FastWrite(dtmp,  Real_Last_Row, 2, qq.StatusLineColor);
                                    Else  Begin
                                             Push_Status;
                                             If not ShowSL then
                                                FastWrite(Pad(ss,Last_Col),Real_Last_Row,1,qq.StatusLineColor)
                                             Else
                                                FastWrite(Pad(Copy(ss,1,66),Last_Col),Real_Last_Row,1,qq.StatusLineColor);
                                             Delay(2000);
                                             Pop_Status;
                                          End;
                                 End;
                              Until Ch in [' ','T','G'];
                           End;
                        Pop_Window;
                        Pop_Status;
                        Show_Script_Status_Line;
                     End;
               End;
         End;
      If token.Token_Type <> tk_end_file Then
         Get_Token;
      Last_Token.Token_Type := token.Token_Type;
   End;                           {Get_Next_Token}


   Procedure Check_Script_Abort;
   Var
      CH : Char;
   Begin
      If not KeyPressed then Exit;
      CharWord := ReadKeyNoGrey;
      If Lo(CharWord) = 0 then
         Beep
      Else
         If CharWord = Esc Then
            Begin
               OldShowSL := ShowSL;
               ShowSL := True;
               Push_Status;
               Display_Status(' S-Single Step   T-Trace   G-Go   A-Abort ');
               Repeat
                  CH := Upcase(Char(ReadKeyA));
               Until CH In ['Y', 'S', 'A', 'G', 'T', #13];
               Pop_Status;
               ShowSL := OldShowSL;
               Case CH Of
                  'Y',
                  'A' : Begin
                           Script_Parm_Line := '';
                           If Script_File_Open Then
                              Close_Script;
                           Scripting := False;
                        End;
                  'S' : Begin
                           Script_Debug := True;
                           Script_Animate := False;
                        End;
                  'G' : Begin
                           Script_Debug := False;
                           Script_Animate := False;
                           Show_Script_Status_Line;
                        End;
                  'T' : Begin
                           Script_Debug := True;
                           Script_Animate := True;
                        End;
                  Else  Show_Script_Status_Line;
               End;
            End
         Else
            If Byte(Type_Ahead[0]) < 255 Then
               Type_Ahead := Type_Ahead + Char(CharWord)
            Else
               Beep;
   End;


   Procedure Free_When_Stack;
   Var
      x              : Integer;
   Begin
      For x := 1 To Max_Whens Do
         Begin
            If Script_when_stack[x].recv_string <> Nil Then
               SetString(Script_when_stack[x].recv_string, Nil);
            If Script_when_stack[x].send_string <> Nil Then
               SetString(Script_when_stack[x].send_string, Nil);
         End;
   End;


   Procedure Free_Allocated_Script_Pointer;
   Var
      x : Integer;
      tmp : Script_Label;
   Begin
      For x := 1 To Script_Strings_Set Do
         Begin
            If Script_Strings[x].Name <> Nil Then
               SetString(Script_Strings[x].Name, Nil);
            If Script_Strings[x].value <> Nil Then
               SetString(Script_Strings[x].value, Nil);
         End;
      Script_Strings_Set := 0;

      Free_When_Stack;

      For x := Max_Push_Pops Downto 1 Do
         Push_Pop_Strings[x] := Nil;

      While Script_Label_Head <> NIL do    { Clear all records if any }
         Begin
            tmp := Script_Label_Head^.Next;
            Dispose(Script_Label_Head);
            Script_Label_Head := tmp;
         End;
      Script_Label_Ptr := Nil;

      Already_Initialized := False;

   End;

End.
