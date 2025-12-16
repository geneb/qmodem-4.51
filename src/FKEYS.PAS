Unit FKeys;
{$P+,V-}

Interface

Uses
   Qmem,      TpCrt,
   TPDos,     TPString,
   TpInline,  TPEntry,
   Initial,   Procs,
   Constant,
   Files,     Screen;


Procedure Load_Prefix;
Procedure Setfkeys;
Procedure load_fkeys(FName : String);


Implementation


Var
   Enames1 : Array[1..12] of String[72];


   Procedure load_fkeys(FName : String);
   Var
      x, y           : Integer;
      Ok             : Boolean;
      OldCursorEmulation : Byte;
      Key_File       : Text;

   Begin
      Assign(Key_File, FName);
      If QuickLearn then
         WriteLearn('LoadKEY  '+FName);
      If Not ExistFile(FName) Then
         Begin
            Rewrite(Key_File);
            Writeln(Key_File,'@HELP');
            For x := 1 To 47 Do
               Begin
                  F_keys[x] := '';
                  WriteLn(Key_File, '');
                  IO := IoResult;
                  If IO <> 0 Then
                     Begin
                        Writelnb('IO error creating Function Key file ' + FName + '.');
                        Writelnb('Probable causes: Disk FULL.');
                        For y := 1 To 48 Do
                           F_keys[y] := '';
                        Exit;
                     End
               End;
            Close(Key_File);
            IO := IoResult;
         End
      Else
         Begin
            Reset(Key_File);
            For x := 1 To 48 Do
               Begin
                  If EOF(Key_File) Then
                     f_keys[x] := ''
                  Else
                     ReadLn(Key_File, f_keys[x]);
               End;
            Close(Key_File);
            IO := IoResult;
         End;
   End;

   Procedure save_fkeys;
   Var
      x              : Integer;
      Key_File       : Text;
   Begin
      Assign(Key_File, FKEY_Filename);
      Rewrite(Key_File);
      IO := IoResult;
      For x := 1 To 48 Do
         WriteLn(Key_File, f_keys[x]);
      IO := IoResult;
      Close(Key_File);
      IO := IoResult;
   End;




   Procedure EditFKeyScreen(y : integer);
   Var
      FESR : ESrecord;
      ExitCommand : EStype;
      X, Num, OldHelp : Integer;
      xs : String[13];
      OK : Boolean;

      maxlen : integer;
      workstr : string;

   Begin

   {                                  Screen Layout

   1---+----10---+----20---+----30---+----40---+----50---+----60---+----70---+--

    ÕÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ Function Key Assignment ÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¸
    ³         Definitions for Normal F-keys                                      ³
    ³F1  @Help°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°°° ³
    ³F2  @Edit                                                                   ³
    ³F3  $PASSWORD^M                                                             ³
    ³F4  ^M                                                                      ³
    ³F5  AT M0H1^M                                                               ³
    ³F6  AT M1H0^M                                                               ³
    ³F7  @Script Dial!                                                           ³
    ³F8  @Script CallHome                                                        ³
    ³F9  @Script Logerror                                                        ³
    ³F10 $Password^M                                                             ³
    ³F11 @STAMP testing 1, 2, 3!                                                 ³
    ³F12 @Shell L Z:\DL\*.CAP                                                    ³

    }

      num := y * 12 - 11;
      For x := 1 To 12 Do
         Enames1[x] := F_Keys[num-1+x];



      {<F10> Alternate DONE key}
      If not AddEntryCommand(ESuser0, 1, $4400, 0) then ;

      InitESrecord(FESR);
      SetFieldAttr(qq.Menu2);
      SetPromptAttr(qq.Menu);
      SetStringAttr(qq.scrollbar);
      SetCtrlAttr(qq.Scrollbar+128);
      SetPadChar('°');
      SetTrimBlanks(OFF);
      For x := 1 to 12 do
         Begin
            AddStringField(FESR, 'F'+Pad(Long2Str(x),2), x+3, 3,
                           '', x+3, 7, 72, HelpTopic,
                           NIL,
                           Enames1[x]);
         End;

      ExitCommand := EditScreen(FESR, 0, False);
      DisposeEditScreen(FESR);

      If (ExitCommand = ESuser0) or (ExitCommand = ESdone) then
         Begin
            For x := 1 To 12 Do
               F_Keys[num-1+x] := TrimTrail(Enames1[x]);
            Save_FKeys;
         End;

   End;



   Procedure Load_Prefix;
   Var
      x, y : Integer;
      Ok   : Boolean;
   Begin
      Assign(Prefix_File, SearchName(QMODEM_PRE));
      If Not ExistFile(SearchName(QMODEM_PRE)) Then
         Begin
            Rewrite(Prefix_File);
            For x := 1 To 10 Do
               Begin
                  WriteLn(Prefix_File, '');
                  Prefix[x] := '';
               End;
            Close(Prefix_File);
            IO := IoResult;
         End
      Else
         Begin
            Reset(Prefix_File);
            For x := 1 To 10 Do
               Begin
                  ReadLn(Prefix_File, Prefix[x]);
                  y := IoResult;
                  If y <> 0 Then
                     Begin
                        For y := x To 10 Do Prefix[y] := '';
                     End;
               End;
            Close(Prefix_File);
         End;
      IO := IoResult;
   End;

   Procedure Setfkeys;
   Var
      xx, x, y, keynum, Code : Integer;
      Done           : Boolean;


      Procedure Get_Ctrl_Str(y : Integer);
      Begin
         Display_Status(' Edit Function Key Entries    F10-Save    ESC-Exit with no changes');
         TextAttr := qq.Menu;
         WriteLn;
         WriteLn(' Valid Edit Keys    :   INS - Insert mode Toggle      - Field Up');
         WriteLn('                        DEL - Delete Character        - Field Down');
         WriteLn('                           - Character Left         ^ - Word Left');
         WriteLn('                          ' + #26 + ' - Character Right        ^' + #26 + ' - Word Right');
         Write(' Special Characters :    ^M = [ENTER]                ^~ = « second delay');
         EditFKeyScreen(y);
      End;

      Procedure Show_str(Len : Integer; S : String);
      Begin
         Write(Copy(S, 1, Len));
      End;

      Procedure Show_Summary;
      Var
         x, y           : Integer;
      Begin
         TextAttr := qq.Menu;
         Window(3, 3, 78, 21);
         ClrScr;
         WriteLn('     Normal             Shift              Ctrl               Alt');
         For y := 1 To 4 Do
            Begin
               For x := 1 To 12 Do
                  Begin
                     GotoXY(19 * (y - 1) + 1, (y * 12 - 12 + x) - 12 * (y - 1) + 1);
                     TextAttr := qq.Menu;
                     Write('F', x, ' ');
                     If x < 10 Then Write(' ');
                     TextAttr := qq.menu2;
                     Show_str(14, f_keys[y * 12 - 12 + x]);
                     WriteLn;
                  End;
            End;
         WriteLn;

      End;

      Procedure Load_New_FKEY;
      Var
         Temp, dfile    : String;
         x              : Integer;

      Begin
         Temp := FKEY_Filename;
         dfile := Get_File_Name('', AddBackslash(JustPathname(FKEY_Filename)),
                                'KEY', 14, 'Function Key File Allocation',True);
         If dfile = '' Then
            FKEY_Filename := Temp
         Else
            Begin
               FKEY_Filename := STUpCase(dfile);
               TextAttr := qq.Menu;
               load_fkeys(dfile);
               Logit('New KEY file ' + dfile);
            End;
      End;


   Begin
      Setwindow2(2, 2, 79, 22, ' Function Key Assignment ',false);
      Done := False;
      Repeat
         HelpTopic := 10;
         Display_Status(' 1,2,3,4-Display/Edit   ESC-Exit ');
         Show_Summary;
         WriteLn(' Key File is ' + FKEY_Filename);
         WriteLn;
         TextAttr := qq.menu2;
         WriteLn(' 1 - Normal   2 - Shift   3 - Ctrl   4 - Alt   L - Load    ESC - Exit');
         FastWrite('1', 19, 4, qq.Menu);
         FastWrite('2', 19, 17, qq.Menu);
         FastWrite('3', 19, 29, qq.Menu);
         FastWrite('4', 19, 40, qq.Menu);
         FastWrite('L', 19, 50, qq.Menu);
         FastWrite('ESC', 19, 62, qq.Menu);
         WriteLn;
         Write(' Your Choice ? ');
         Repeat
            CH := Upcase(Char(ReadKeyA));
         Until CH In ['1'..'4', #27, 'L'];
         If CH = 'L' Then
            Load_New_FKEY
         Else
            If Not(CH In ['L', #27]) Then
               Begin
                  HelpTopic := 11;
                  ClrScr;
                  GotoXY(10, 1);
                  Write('Definitions for ');
                  Case CH Of
                     '1' : WriteLn('Normal F-keys');
                     '2' : WriteLn('Shift F-keys');
                     '3' : WriteLn('Ctrl F-keys');
                     '4' : WriteLn('Alt F-keys');
                  End;            {case}
                  y := Ord(CH) - Ord('1') + 1;
                  For x := 1 To 12 Do
                     Begin
                        TextAttr := qq.Menu;
                        Write('F', x, ' ');
                        If x < 10 Then Write(' ');
                        TextAttr := qq.menu2;
                        Show_str(71, f_keys[y * 12 - 12 + x]);
                        WriteLn;
                     End;
                  Get_Ctrl_Str(y);
                  For x := 1 To 48 Do
                     If f_keys[x] = ' ' Then
                        f_keys[x] := '';
                  CH := #0;
               End;
      Until CH In ['5', #27];
      Restore_Screen;
   End;


End.
