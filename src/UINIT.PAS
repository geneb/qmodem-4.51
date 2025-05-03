Unit UINIT;

Interface

Uses
   Qmem, TpCrt, TpDos, Initial, TpWindow;


Procedure Do_Unit_Inits;

Implementation

Procedure Do_Unit_Inits;
Begin
   ValidFileChars := ['''', '{', '}', '@', '!', '#', '$', '%', '&',
                            '(', ')', '*', '-', '.', '?', '^', '_',
                            '`', '0'..'9', 'A'..'Z'];
   CurrentPhone   := 1;
   Compile_date   := ' Compiled 02/21/92';

   {$IFDEF BETA}
      Version              := '4.51 ð BETA TD ð';
      Config_version_const := '4.5';
      Short_Version        := '4.5';
   {$ENDIF}

   {$IfDef Int14}
      Version              := '4.5 Int14';
      Config_version_const := '4.5';
      Short_Version        := '4.5';
   {$ELSE}

      {$IfDef PRODUCTION}
         {$IFDEF BUNDLE}
            Version              := '4.51';
            Config_version_const := '4.5';
            Short_Version        := '4.5';
         {$ELSE}
            Version              := '4.51 Test-Drive';
            Config_version_const := '4.5';
            Short_Version        := '4.5';
         {$ENDIF}
      {$ENDIF}
   {$ENDIF}

   Doorway              := False;
   StartElapsed1        := False;
   Help_Index_Loaded    := False;
   Previous_Save        := False;
   Last_Online_State    := False;
   CaseSensitive        := False;
   QuickLearn           := False;
   FSEHeader            := False;
   Last_Edit            := '';
   Stxt                 := '';
   LearnTxt             := '';

   For x := 1 To Max_Whens Do
      Begin
         Script_when_stack[x].Recv_String := Nil;
         Script_when_stack[x].Send_String := Nil;
      End;

   For x := 1 To Max_Push_Pops Do
      Push_Pop_Strings[x] := Nil;

   For x := 1 To Max_Script_Strings_Set Do
      Begin
         Script_Strings[x].Name  := Nil;
         Script_Strings[x].Value := Nil;
      End;

   For x := 1 To Max_Keyword_Elements Do
      Keyword_Element[x].Key_name := '';

   LinesPerPage := 23;
   Cancel_Allowed := True;
   HFirstName := '';
   HLastName := '';
   HPassword := '';
   Fixed_Rate := False;
   Hosting := False;
   ansi1 := ' ';
   ansi2 := ' ';
   ansi3 := ' ';
   ansi4 := ' ';
   Default_Drive := DefaultDrive;
   Split := False;
   Online_Time := 0;
   Linked_Protocol := ' ';
   Linked_Password := '';
   Linked_Notefile := '';
   Linked_board := '';
   Linked_number := '';
   Linked_script_file := '';
   Linked_speed := '';
   Linked_comm := '';
   transfer := False;
   graphics := False;
   redial := False;
   Hi_Bit := True;
   Help_Last := False;
   save_scroll := True;
   Logging := False;
   Start_Redialer := False;
   Echo := False;
   rootdir := True;
   PrtLog := False;
   Hold_Test := False;
   Hold_Str := '';
   Buffer_full := False;
   Dial_Other_Info := False;
   Save_Ansi_Str := '';
   GetDir(0, StartDir);
   phone_page := 0;
   Force_Exit := False;
   DropDTR := True;
   Scripting := False;

   Already_Initialized := False;
   Online_Check := False;
   Label_Search := False;
   Script_File_Open := False;
   Script_Upload_active := False;
   Script_total_Whens := 0;
   Script_Goto_Str := '';
   Script_Parm_Line := '';
   Exit_Main := False;
   Script_Debug := False;
   When_Goto := False;
   Script_Strings_Set := 0;
End;

End.
