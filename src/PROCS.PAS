{$I TPDEFINE.INC}

Unit PROCS;
{$P+,V-}

Interface

Uses
     {$IFDEF OVR}
     Overlay,
     {$ENDIF}
     {$IFDEF UseMouse}
     TpMouse,
     {$ENDIF}
     Qmem,       Dos,      TpCrt,     TpDos,
     Initial,    TpDate,   Printer2,  TpWindow,
     TpString,   TpInline, TpEntry,   TpEdit,
     Files,      Constant, Screen,    Comm,
     ApTimer;


Procedure Learn(F : String);
Procedure WriteLearn(S : String);

Procedure EmulsAnsiVT100Disp(Ch : Char);

Function  Get_File_Name (Path : String;
                         Name : String;
                         DefExt : String;
                Already_Exist : Integer;
                 Window_Title : String;
                 SearchDir    : Boolean)    : String;


Function  ExpandCtrlString (S:String) : String;
Function  LastCommString(l : Integer) : String;
Function  LastCommStringx(l : Integer) : String;
Function  Slength (s : String; M : Byte) : String;
Function  Max (x, y : LongInt) : LongInt;
Function  Min (x, y : LongInt) : LongInt;
Procedure Add_new_line(here : integer);
Procedure Add_new_Screen;
Procedure Clear_Whole_Screen;
Function  CurrentTimeX : LongInt;
Procedure Low_Clear_Screen;
Procedure Clear_Screen;
Function  Elapsed (Old, New_ : LongInt) : LongInt;
Function  Elapsed_Online(Passed_Time:LongInt) : String;
Function  Free_Space(drive_letter : char) : LongInt;
Function  Get_New_Scroll_Pointer : Scroll_Ptr;
Function  Get_Qmodem_Spec : String;
Function  Get_Yes_No : Char;
Function  Hex (n : Word) : str5;
Function  Hex1(n : Byte) : Str1;
Function  Hex4(n : Word) : str4;
Procedure Home_Status_Msg;
Procedure PrtAt2 (S : String; Row, Col, Attr1, Attr2 : Integer);
Procedure Reset_TabStops;
Procedure SplitScreen;

Function  Script_String_Num(wrd : String) : Integer;

Function  SearchLeftC  (Strg : String; Substr : String) : integer;
Function  SearchLeftUC (Strg : String; Substr : String) : integer;
Procedure SetString (Var p : Pointer; q : Pointer);
Procedure Set_Real_Full_Window;
Procedure Set_Full_Window;
Procedure Start_Online_Timer;
Procedure Stop_Online_Timer;
Procedure Store_Cinkey(Ch : Char);
Procedure Test_Card;
procedure Which_screen;
Procedure Write_x(s : String);
Procedure Write_xmit_time (blocks : LongInt);
Function  L_S_Filename : String;
{$IFDEF UseMouse}
Procedure ShowTheMouse;
Procedure HideTheMouse;
{$ENDIF}
Procedure Dir2;
Procedure Log_toggle(TempF : String; Open_Window : Boolean);
Function  Get_memory_model : Integer;
Procedure Flush_KBD;
Procedure ResetColumn;



Var
   Last_Echo,
   StatusWasOn     : Boolean;




IMPLEMENTATION


Var
   SaveAttr : Byte;


{$IfDef GG}
   Procedure ShowTheDraw(s:String);
   Var
      Image : Array[1..4000] of Byte;
      F : File;
      x : Word;
   Begin
      If Existfile(s) then
         Begin
            Assign(F,s);
            Reset(F,1);
            BlockRead(F,Image,4000,x);
            IO := IOResult;
            If x = 4000 then
               MoveScreen(Image[1],Virtual_Screen^[1],2000);
         End;
   End;
{$EndIf}


Procedure Flush_KBD;
Var
   Ch : Char;
Begin
   While KeyPressed do
      Ch := ReadKey;
End;


Function Get_memory_model : Integer;
Var
   F      : File Of Byte;
   b1, b2 : Byte;
Begin
   Assign(F, SearchName(QMODEM_EXE));
   Reset(F);
   If IoResult <> 0 Then
      Get_memory_model := -1
   Else
      Begin                    { returns the Maximum memory required in K }
         Seek(F, $C);
         Read(F, b1);
         Read(F, b2);          { Convert to K }
         Get_memory_model := (b1 Div 64) + (b2 * 4) - 68;
      End;
   Close(F);
   IO := IoResult;
End;


Procedure Log_toggle(TempF : String; Open_Window : Boolean);
Var
  x              : Integer;
  Ok             : Boolean;
Begin                          { Logging }
  If Logging Then
     Begin                    {turn logging off }
        If QuickLearn then
           WriteLearn('TurnOFF  LOG');
        Logging := False;
        Write(Log_File, ^Z);
        IO := IoResult;
        If IO <> 0 then
           Begin
           Writelnt('I/O error '+Long2Str(IO)+' Writing the Log file');
           Logging := False;
           End;
        Flush(Log_File);
        IO := IoResult;
        If IO <> 0 then
           Begin
           Writelnt('I/O error '+Long2Str(IO)+' Flushing the Log file');
           Logging := False;
           End;
        Close(Log_File);
        IO := IoResult;
        If IO <> 0 then
           Writelnt('I/O error '+Long2Str(IO)+' Closing the Log file');
     End
  Else
     Begin
        Ok := True;
        If Open_Window Then
           If Not Scripting Or (TempF = '') Then
              TempF := Get_File_Name('', Log_FileN, 'LOG', 2,
                                     'Log File Allocation',True);

        If TempF = '' Then Exit;
        If Not ExistFile(TempF) Then
           Begin
              Assign(Log_File, TempF);
              Rewrite(Log_File);
              IO := IoResult;
              If IO = 0 Then
                 Begin
                    Logging := True; { turn it on! }
                    Close(Log_File);
                 End
              Else
                 Begin
                    WritelnT('Error creating the Log file');
                    Ok := False;
                    Logging := False; { turn it off }
                 End;
           End;
        If Ok Then
           Begin
              Logging := True; { turn it on! }
              Log_FileN := FullPathName(TempF);
              Assign(Log_File, Log_FileN);
              Append(Log_File);
              IO := IoResult;
              If IO <> 0 Then
                 Begin
                    Beep;
                    Writelnt('I/O error '+Long2Str(IO)+' Appending the Log file');
                    Logging := False;
                    Exit;
                 End;
           End;
     End;
  If Logging Then
     Begin
        If Not Help_Last Then
           If Open_Window Then
              Writelnt('Logging to ' + TempF + ' ON');
        If QuickLearn then
           WriteLearn('Log      '+TempF);
     End
  Else
     If Not Help_Last Then
        If Open_Window Then
           Writelnt('Logging OFF');
End;

Procedure Dir2;
Var
   Temp2          : String; {[64];}
   Pattern        : String[64];
Begin
   Repeat
      Pattern := Get_File_Name('',qq.AltWPick,'',13, 'View Directory(s) Allocation',False);
      If Pattern <> '' then
         Begin
             HelpTopic := 17;
             {$P+}
            Show_Dir(Pattern, AnyFile, Temp2);
         End;
   Until Pattern = '';
End;

Function Get_File_Name (Path : String;
                        Name : String;
                        DefExt : String;
               Already_Exist : Integer;
                Window_Title : String;
                SearchDir    : Boolean)    : String;
Label
   TryAgain, Exit1;
Var
   Escaped, OK : Boolean;
   Ch          : Char;
   Dfile, tmp  : String;
   Bad_Chars   : Set of Char;
   X, OldHelp  : Integer;
   xf          : File;

Begin
   Push_Window;
   SetWindow2(4,17,76,21,' '+Window_Title+' ',False);
   OldHelp := HelpTopic;
   If Help_Last then
      NormalCursor;
   Dfile := '';
   Bad_Chars :=  ['"' , '/' , '[' , ']' , '|' , '<' , '>' ,
                  '+' , '=' , ';' , ',' , '*' , '?' , #0..#20];
   If Already_Exist = 4 then
      Bad_Chars := Bad_Chars - ['*' , '?'];
   If Already_Exist = 13 then
      Bad_Chars := [];  { allow EVERYTHING! }
   OK := False;
   clrscr;
   TextAttr := qq.Menu2;
   Window (5,18,75,20);
   Display_Status(' Edit File/Pathname   ESC-Exit ');
   Repeat
      TextAttr := qq.Menu;
      Clrscr;
      If Already_Exist = 5 then
         Dfile := AddBackSlash(Path)
      Else
         If Path = '' then
            Dfile := Name
         Else
            Dfile := AddBackSlash(Path)+Name;

      TryAgain:

      { Using TpEntry }
      {
      SetFieldAttr(qq.Menu2);
      SetCursorToEnd(ON);
      SetPromptAttr(qq.Menu);
      SetStringAttr(qq.scrollbar);
      SetCtrlAttr(SwapNibble(qq.ScrollBar));
      SetPadChar('ฐ');
      SetTrimBlanks(ON);
      EditString('> ', 19,6,64, '', 5,Escaped, Dfile);
      SetCursorToEnd(Off);
      }

      { Using TpEdit }
      CursorToEnd := True;
      ForceUpper := True;
      HelpTopic := 5;
      EditSize := 64;
      ReadString('> ', 19,6,64,qq.Menu,qq.scrollbar, SwapNibble(qq.Scrollbar),
                 Escaped, Dfile);

      If Escaped then
         Dfile := '';

      GotoXY(2,3);

      HelpTopic := 93;
      If SearchDir then
         If (Dfile[Length(Dfile)] = '\') Then
            Begin
               If DefExt <> '' then
                  Show_Dir(Dfile+'*.'+DefExt, AnyFile, Dfile)
               Else
                  Show_Dir(Dfile+'*.*', AnyFile, Dfile);
            End
         Else
            If (Pos('*',Dfile) > 0) or
               (Pos('?',Dfile) > 0) then
               Show_Dir(Dfile, AnyFile, Dfile);

      HelpTopic := 5;
      TextAttr := qq.Menu2;
      If Dfile = '' then
         Begin
            Get_File_Name := '';
            GoTo Exit1;
         End
      Else
         If DefExt <> '' then
            If Already_Exist <> 5 then
               Dfile := DefaultExtension(Dfile,DefExt);
      x := 1;
      While x <= Length(DFile) do
         Begin
            If DFile[x] in Bad_Chars then
               Begin
                  Write ('  Invalid character in filename.  Press any key ');
                  Ch := Char(ReadKeyA);
                  GotoXY (1,WhereY);
                  Clreol;
                  Goto TryAgain;
               End;
            Inc(x);
         End;

      tmp := JustFilename(DFile);
      If (tmp <> '') and (tmp[1] = '.') then
         Begin
            Write ('  Invalid DOS filename.  Press any key ');
            Ch := Char(ReadKeyA);
            GotoXY (1,WhereY);
            Clreol;
            Goto TryAgain;
         End;

      If (Dfile[Byte(Dfile[0])] in [':','\']) and ((Already_Exist <> 5) and (Already_Exist <> 13)) then
         Begin
            Write ('  File cannot have '':'' or ''\'' as the last character.  Press any key ');
            Ch := Char(ReadKeyA);
            Ok := False;
         End
      Else
         Case Already_Exist of
            1 : Begin
                   If ExistFile(dfile) then
                      Begin
                         Ok := True;
                         If qq.AutoIncrement then
                            Begin
                               Dfile := IncFileName(Dfile);
                            End
                         Else
                            If not qq.OverWrite then
                               Begin
                                  Write ('  File already exists, overwrite ? ');
                                  If Get_Yes_No = 'Y' then
                                     Begin
                                        Ok := true;
                                        Assign(xf, dfile);
                                        Erase(xf);
                                     End;
                               End;
                      End
                   Else
                      Begin
                         Ok := Test_Create(Dfile);
                         If Not OK then
                            Begin
                               Write ('  Incorrect Drive and/or Path.  Press any key > ');
                               Ch := Char(ReadKeyA);
                            End;
                      End;
                End;
            3 : Begin
                   If not ExistFile(Dfile) then
                      Begin
                         Write ('  File does not exist. Press any key ');
                         Ch := Char(ReadKeyA);
                      End
                   Else
                      Ok := true;
                End;
            5 : Begin
                   Ok := Test_Create(AddBackSlash(Dfile)+'$Q$');
                   If Not OK then
                      Begin
                         Write ('  Invalid Path specified.  Press any key ');
                         Ch := Char(ReadKeyA);
                      End;
                End;
            2, 4, 11, 13 : Ok := True;
            12 : Begin
                    If not ExistFile(Dfile) then
                       Ok := Test_Create(Dfile)
                    Else
                       Ok := True;
                    If Not OK then
                       Begin
                           Write ('  Incorrect Drive and/or Path.  Press any key ');
                           Ch := Char(ReadKeyA);
                        End;
                  End;
            14 : Begin
                   If not ExistFile(dfile) then
                      Begin
                         Write ('  File does not exist, create ? ');
                         If Get_Yes_No = 'Y' then
                            Ok := True;
                      End
                   Else
                      Ok := True;
                 End;
         End; { case }
   until Ok;
   Get_File_Name := Dfile;
Exit1:
   HelpTopic := OldHelp;
   Restore_Screen;
   Pop_Window;
   Set_Colors;
   If Help_Last then
      HiddenCursor;
End;


Procedure Learn;
Var
   Name : String;
Begin
   If QuickLearn Then
      Begin
         WriteLearn ('Exit');
         Close (LearnF);
         IO := IoResult;
         Writelnt ('QuickLearn recording done');
         QuickLearn := False;
         Exit;
      End;
   Push_window;
   If F <> '' Then
      LearnFilename := DefaultExtension(AddBackSlash(qq.Script_Path) + F, 'SCR')
   Else
      LearnFilename := Get_File_Name(qq.Script_Path, '', 'SCR', 12, 'Script Learn Allocation',True);
   If LearnFilename <> '' Then
      Begin
         QuickLearn  := True;
         ScriptCount := 0;
         Assign (LearnF, LearnFilename);
         Rewrite(LearnF);
         IO := IoResult;
         WriteLearn (';');
         WriteLearn (';  QuickLearn Script generated at ' + TimeS + ' on ' + DateS);
         WriteLearn (';  May require editing before use.');
         WriteLearn (';');

         {$IfDef GG}
            Case Emulation of
               TTY            : WriteLearn('Graphics TTY');
               ANSImode       : WriteLearn('Graphics ANSI');
               AVATAR         : WriteLearn('Graphics AVATAR');
            End;
         {$Else}
            Case Emulation of
               TTY            : WriteLearn('Graphics TTY');
               ANSImode       : WriteLearn('Graphics ANSI');
               VT100          : WriteLearn('Graphics VT100');
               TVI925         : WriteLearn('Graphics TVI925');
               DEBUG_A        : WriteLearn('Graphics DEBUG_A');
               DEBUG_H        : WriteLearn('Graphics DEBUG_H');
               AVATAR         : WriteLearn('Graphics AVATAR');
            End;
         {$EndIf}


         If Hi_Bit      then WriteLearn('TurnON   8_BIT')    Else
                             WriteLearn('TurnOFF  8_BIT');

         If Addlf       then WriteLearn('TurnON   LINEFEED')    Else
                             WriteLearn('TurnOFF  LINEFEED');

         If Xon_Xoff    then WriteLearn('TurnON   XON/XOFF')    Else
                             WriteLearn('TurnOFF  XON/XOFF');

         If Noise       then WriteLearn('TurnON   NOISE')    Else
                             WriteLearn('TurnOFF  NOISE');

         If Music_flag  then WriteLearn('TurnON   MUSIC')    Else
                             WriteLearn('TurnOFF  MUSIC');

         If Save_Scroll then WriteLearn('TurnON   SCROLL')    Else
                             WriteLearn('TurnOFF  SCROLL');

         If Prtlog      then WriteLearn('TurnON   PRINT')    Else
                             WriteLearn('TurnOFF  PRINT');

         If Echo        then WriteLearn('TurnON   ECHO')    Else
                             WriteLearn('TurnOFF  ECHO');

         If Split       then WriteLearn('TurnON   SPLIT')    Else
                             WriteLearn('TurnOFF  SPLIT');

         If qq.BS_DEL_Swap = 'Y' then Writelearn('TurnON   BS_DEL') Else
                                      WriteLearn('TurnOFF  BS_DEL');

         If qq.ShowStatusLine    then Writelearn('TurnON   STATUSLN') Else
                                      WriteLearn('TurnOFF  STATUSLN');

         If Doorway              then Writelearn('TurnON   DOORWAY') Else
                                      WriteLearn('TurnOFF  DOORWAY');

         WriteLearn ('');
         WriteLearn ('TimeOut  30     ; Set Waitfor for 30 seconds');
      End;
   Pop_window;
End;


Procedure WriteLearn(S : String);
Begin
   if not QuickLearn then
      Exit;
   WriteLn(LearnF, S);
   IO := IoResult;
   If IO <> 0 Then
      Begin
         Setwindow2(10, 9, 64, 14, 'Recording Error!',false);
         WriteLn(' Error Writing to QuickLearn Script.  File closed.');
         Writeln(' ',LearnFilename);
         Writeln(' Error number ',IO);
         Write  (' ');
         KeyContinue(qq.Menu);
         Restore_Screen;
         Close(LearnF);
         IO := IoResult;
         QuickLearn := False;
      End;
End;




{$IFDEF UseMouse}
Procedure ShowTheMouse;
Begin
   If qq.UseMouse then
      ShowMouse;
End;

Procedure HideTheMouse;
Begin
   If qq.UseMouse then
      HideMouse;
End;
{$ENDIF}


Function  Slength (s : String; M : Byte) : String;
Begin
   If s[0] > Chr(m) then S[0] := Chr(m);
   Slength := S;
End;


Function L_S_Filename : String;
Type
   all_chars = set of #0..#255;
Var
   invalid_chars      : all_chars;
   x1, x2, x, y, z    : Integer;
   temp, temp1, temp2 : String;
   OK                 : boolean;

Begin
   Invalid_Chars := ['.', ' ', '"', '/', '\', '[', ']', ':',
                     '|', '<', '>', '+', '=', ';', ',' ];
   Ok := False;
   for x := Last_Row downto 0 do
      Begin
         FastRead(Last_Col,x,1,Temp);
         Temp1 := ' '+temp;
         Temp2 := temp+' ';
         z := Last_Col-1;
         If (SearchLeftC(Temp,'.') > 1) and (SearchLeftC(Temp,'.') < Last_Col) then
         While z > 0 do
            Begin
               while (temp[z] <> '.') and (z > 0) do dec(z);
               If (z > 1) and (Z < Last_Col) then
                  Begin
                     x1 := 1;
                     while (not (Temp[z + x1] in invalid_chars)) and
                           (x1 < 5) and
                           ((z + x1) <= Last_Col) do Inc(x1);
                     x2 := 1;
                     while (not (Temp[z - x2] in invalid_chars)) and
                           (x2 < 10) and
                           ((z - x2) >= 1) do Inc(x2);
                     If ((x1 - 1) < 4) and ((x1 - 1) > 1) and
                        ((x2 - 1) < 9) and ((x2 - 1) > 1) and
                        (temp1[z-x2+1] in [' ',';']) and (temp2[z+x1] in [' ',';']) then
                        Begin
                           L_S_Filename := STUpCase(copy(temp, z - x2 +1, x1+x2 -1));
                           Exit;
                        End;
                     Dec(z);
                  End;
            End;
      End;
   L_S_Filename := '';
End;

Procedure SplitScreen;
Var
   x : Integer;
Begin
   Add_New_Screen;
   If split then
      Begin
         Emulation := Last_Emulation;
         Echo := Last_Echo;
         Set_Full_Window;
         gotoxy (1,25);
         ClrScr;
         Split := False;
         If QuickLearn then
            Writelearn('TurnOFF  SPLIT');
      End
   Else
      Begin
         Last_Emulation := Emulation;
         Last_Echo      := Echo;
         Emulation      := TTY;
         Echo := False;
         Set_Full_Window;
         Clrscr;
         HiddenCursor;
         Gotoxy (1,Split_Middle_Row);
         TextAttr := qq.WindF;
         Write ('ออ[');
         TextAttr := qq.Menu;
         Write (' Keystrokes Queued 0 ');
         TextAttr := qq.WindF;
         Write (']อออออออ[');
         TextAttr := qq.Menu2;
         Write (' Split Screen ');
         TextAttr := qq.WindF;
         Write (']');
         For X := 1 to (Last_Col - 48) do write ('อ');
         Inx := 1;
         Iny := Split_Middle_Row-1;
         Outx := 1;
         Outy := 1;
         Split_string := '';
         Split := True;
         NormalCursor;
         Set_colors;
         If QuickLearn then
            Writelearn('TurnON   SPLIT');
      End;
End;


Procedure Test_Card;
Var
   x, y : Integer;
Begin
   ReinitCrt;
   Virtual_Screen := Ptr(VideoSegment, 0);
   CheckSnow := qq.CheckSnowx = 'Y';
End;


Procedure Set_Full_Window;
Begin
  SaveCursor(3);
  If (Emulation = VT100) and Decom then
     Begin
        Window (1,T_Margin,Last_Col,B_Margin);
        StoreLastLine := B_Margin;
     End
  Else
     Begin
        Window (1,1,Last_Col,Last_Row);
        StoreLastLine := Last_Row;
     End;
  RestoreCursor(3);
End;


Procedure Set_Real_Full_Window;
Begin
   Window (1,1,Last_Col,Real_Last_Row);
   StoreLastLine := Real_Last_Row;
End;


Procedure Clear_Whole_Screen;
Begin
   Which_Screen;
   NormalCursor;

   If Emulation <> Avatar then
      Emul_Color := qq.TxtColor;

   QQcolor := qq.TxtColor;

   If Emulation in [ANSImode, VT100] then
      If qq.StrictColor then
         Emul_Color := LightGray;

   Set_Base_Colors;

   If Split then
      Clear_Screen
   Else
      Begin
         Set_Full_Window;
         Clear_Screen;
      End;
   Home_Status_Msg;
End;


Procedure Setup_all_Window_Parameters;
Var
   r : Registers;
Begin
  Last_Row := Byte(ScreenHeight);
  Last_Col := Byte(ScreenWidth);

  If (Last_Row < 25) or (Last_Col < 80) or
     (Last_Row < 1) or  (Last_Col < 1)  or
     (Last_Row > 100) or (Last_Col > 250) then
     Begin                              { Check for TOO Small of a screen }
        Writeln;
        Writeln('NOTE: Screen adjusted from ',Last_Row,'x',Last_Col,' to 25x80');
        Writeln('      ScreenHeight:',ScreenHeight:3,'  ScreenWidth:',ScreenWidth:3);
        Writeln('      Video Mode  :',CurrentMode:3, '  Display    : ',CurrentDisplaySt);
        KeyContinue(TextAttr);
        Last_Row := 25;
        Last_Col := 80;
     End;

  { Initialize all window parameters }
  Real_Last_Row := Last_Row;
  Prlr := Pred(Last_Row);
  If qq.ShowStatusLine then
     Begin
        Dec(Last_Row);   { Get ready for Status Row }
        ShowSL := True;
     End
  Else
     ShowSL := False;
  Split_Bottom_Row := Last_Row;
  Split_Middle_Row := Round(Last_Row * 0.85);
End;

Procedure Which_screen;
Begin
   Test_Card;
   Setup_All_Window_Parameters;
   Set_Full_Window;
End;

Procedure Low_Clear_Screen;
Begin
   Case Emulation of
      TVI925   : Clrscr;
      ANSImode : Clrscr;
      Else       If not Split then
                    ClrScr
                 Else
                    Begin
                       Split_Window_Top;
                       Clrscr;
                       Inx := 1;
                       Iny := 1;
                       Set_Split;
                    End;
      End;
End;


Procedure Clear_Screen;
Begin
   Add_New_Screen;
   Low_Clear_Screen;
End;


Function  CurrentTimeX : LongInt;
Var
   R : Registers;
Begin
   With R do
      Begin
         AH := $2C;
         MsDos(R);
         CurrentTimeX := LongInt(CH) * 360000 +
                LongInt(CL) * LongInt(6000) +
                LongInt(DH) * LongInt(100) +
                LongInt(DL);
      End;
End;


Procedure Start_Online_Timer;
Begin
   Online_Time := CurrentTimeX;
   Logit ('Online Timer Started');
   Last_Online_State := True;
End;


Function Elapsed_Online(Passed_Time:LongInt) : String;
Var
   hh,mm,ss : byte;
   T1,t2,t3 : Longint;
Begin
   t1 := CurrentTimeX div 100;
   t2 := Passed_Time div 100;
   t3 := Online_Time div 100;
   If t1 < t3 then
      Begin
         t1 := t1 - t2 + 86400;
         t2 := 0;
      End;
   TimeDiff(t2, t1, hh,mm,ss);
   Elapsed_Online := TimetoTimeString(qq.ElapsedStr,HMStoTime(hh,mm,ss));
End;

Procedure Stop_Online_Timer;
Begin
   If Elapsed_Online (Online_Time) <> TimetoTimeString(qq.ElapsedStr,HMStoTime(0,0,0)) then
      Logit ('Elapsed Online '+Elapsed_Online(Online_Time));
   Last_Online_State := False;
End;


{ Framing Procedures }
Procedure Write_x (s : String);
Var
   X : Integer;
Begin
   For x := 1 to byte(s[0]) do
      Case s[x] of
         #7  : Write (#248);
         #8,
         #10 : Write (#219);
         #13 : Write (#235);
         Else  Write (s[x]);
      End;
End;

Procedure PrtAt (S : String; Row, Col, Attr : Integer);
Var
   C       : Boolean;
   {$IFDEF UseMouse}
   MouseOn : Boolean;
   {$ENDIF}
   xxx     : Integer;
Begin
   {$IFDEF UseMouse}
   MouseOn := MouseInstalled and MouseCursorOn;
   If MouseOn then
      HideTheMouse;
   {$ENDIF}
   FastWrite (s, row, col, Attr);
   {$IFDEF UseMouse}
   If MouseOn then
      ShowTheMouse;
   {$ENDIF}
End;

Procedure PrtAt2 (S : String; Row, Col, Attr1, Attr2 : Integer);
Var
   {$IFDEF UseMouse}
   MouseOn : Boolean;
   {$ENDIF}
   Flex    : FlexAttrs;
Begin
   {$IFDEF UseMouse}
   MouseOn := MouseInstalled and MouseCursorOn;
   If MouseOn then
      HideTheMouse;
   {$ENDIF}
   Flex[0] := Attr1;
   Flex[1] := Attr2;
   FlexWrite(S, Row, Col, Flex);
   {$IFDEF UseMouse}
   If MouseOn then
      ShowTheMouse;
   {$ENDIF}
End;

Procedure Home_Status_Msg;
Var
   A, Out : String;
   b1, b2 : Byte;
Begin
   If CommPressed or Scripting or (not ShowSL) then
      Exit;

   If QuickLearn then
      Begin
         Display_Status (' QuickLearn Recording Active   AltQ-End Recording ');
         Exit;
      End;

   StatusWasOn := True;

   Case CurrStatusLine3 of
      WithBBSInfo : Begin
                       Out := 'Name: '+
                              Pad(Linked_Board,30)+
                              'Number: '+
                              Pad(Linked_Number,21);
                    End;
      WithCommands: Begin
                       Out := 'Quick Commands:  Home Menu  Alt-N Setup  Alt-D Dial  Alt-H Hangup';
                    End;
      WithToggles : Begin
                       Out := Pad(EmulationT(Emulation),7);
                       If Doorway then
                          Begin
                             If Online then Out := Out + 'DOORWAY' Else
                                            Out := Out + 'Doorway';
                          End
                       Else
                          If ComPort_Open_Flag and Online then
                             Out := Out + 'ONLINE '
                          Else
                             Out := Out + 'Offline';
                       If NewSpeed > 57600 then A := '115kb'
                                           Else Str(NewSpeed:5, A);
                       Out := Out + ' '+A;
                       Str(NewDBits:1, A);
                       Out := Out + ' ' + A + NewCparity;
                       Str(NewSBits:1, A);
                       Out := Out + A + '  [Home]=Menu   ';
                       If Echo        then Out := Out + 'HDX' Else
                                           Out := Out + 'FDX';
                       If Hi_Bit      then Out := Out + ' 8'  Else
                                           Out := Out + ' 7';
                       If Addlf       then Out := Out + ' LF' else
                                           Out := Out + ' LF';
                       If Xon_Xoff    then Out := Out + ' X' else
                                           Out := Out + ' X';
                       If Noise       then Out := Out + ' '+qq.CharBeeps else
                                           Out := Out + ' '+qq.CharBeeps+'';
                       If Music_flag  then Out := Out + ' '+qq.CharANSI else
                                           Out := Out + ' '+qq.CharANSI+'';
                       If Capture     then Out := Out + ' CP' else
                                           Out := Out + ' CP';
                       If Logging     then Out := Out + ' LG' else
                                           Out := Out + ' LG';
                       If Save_Scroll then Out := Out + ' ' else
                                           Out := Out + ' ';
                       If Prtlog      then Out := Out + ' PR' else
                                           Out := Out + ' PR';
                    End;
   End;
   Out := Out + '  ';
   If Online then Out := Out + Elapsed_Online (Online_Time) Else
                  Out := Out + TimeS;
   {Display_Status2('  '+Out+' ');}
   Display_Status2(' '+Out+' ');
End;


Function SearchLeftC(Strg:String; Substr:String) : integer;
Begin
   SearchLeftC := POS(SubStr, Strg);
End;

Function SearchLeftUC(Strg : String; Substr : String) : integer;
Begin
   Strg := STUpCase(Strg);
   Substr := STUpCase(SubStr);
   SearchLeftUC := Pos(SubStr, Strg);
End;

Function Elapsed (Old, New_ : LongInt) : LongInt;
Begin
   If New_ < Old then
      New_ := New_ + 8640000;            { Check for midnight wrap }
   Elapsed := New_ - Old;
End;

Function Get_Yes_No : Char;
   Var
      Ch : Char;
Begin
   Repeat
      Ch := Upcase(Char(ReadKeyA));
   Until (Ch = 'Y') or (Ch = 'N');
   Case Ch of
      'Y' : Write ('Yes');
      'N' : Write ('No');
   End;
   Delay (800);
   Get_Yes_No := Ch;
End;

Function Hex1(n : Byte) : Str1;
Var L : string[16];
Begin
   l := '0123456789ABCDEF';
   hex1 := Copy(l,succ(lo(n) and 15),1);
End;

Function Hex4 (n : word) : Str4;
Var L : string[16];
Begin
   l := '0123456789ABCDEF';
   hex4 := copy(l,succ(hi(n) shr 4),1) +
           copy(l,succ(hi(n) and 15),1) +
           copy(l,succ(lo(n) shr 4),1) +
           copy(l,succ(lo(n) and 15),1);
End;

Function Hex (n : Word) : Str5;
Begin
   hex := '$' + Hex4(n);
End;


Procedure Reset_TabStops;
Var
   x : Word;
Begin
   for x := 1 to Last_Col-1 do    {!!!!}
      If x mod 8 = 0 then
         TabStops[x+1] := 1
      Else
         TabStops[x+1] := 0;
End;

Function Script_String_Num (wrd : String) : Integer;
Var
   x : integer;
Begin
   Wrd := STUpCase(wrd);
   For x := 1 to Script_Strings_Set do
      If StringFromHeap(Script_strings[x].Name) = wrd then
         Begin
            Script_String_Num := x;
            Exit;
         End;
   Script_String_Num := -1;
End;

Function Get_New_Scroll_Pointer : Scroll_Ptr;
Var
   P : Scroll_Ptr;
Label
   NoMore;
Begin
   While not GetScrollHeap(SizeOf(P^)) do
      Begin
         If (ScrollFirst^.Next = NIL) or
            (ScrollLast = NIL) then
            Begin
               NoMore:
               Get_New_Scroll_Pointer := NIL;
               Exit;
            End;
         P := ScrollFirst;                    { save the pointer to the top }
         ScrollFirst := ScrollFirst^.Next;    { point first at new top      }
         ScrollFirst^.Prev := NIL;            { reset backwards pointer     }
         FreeScrollHeap(SizeOf(P^));
         If P = NIL then
            Goto NoMore;
         FreeMem(P, SizeOf(P^));
      End;
   GetMem(P, SizeOf(P^));
   Get_New_Scroll_Pointer := P;
End;


Procedure Add_new_line(here : integer);
Var
   p : Scroll_Ptr;
   Temp1,
   Temp2 : Node_line_type;
   x, y : Integer;
   ch : Char;

Begin
   If (Not Save_Scroll) or      { Scroll back turned off }
      (MaxScroll = 0) or        { No memory for Scroll Back }
      (Last_Col > 80) then      { screen wider than 80 columns }
      Exit;

   FastRead(80,Here,1,Temp1);
   ReadAttribute(80,Here,1,Temp2);

   p := Get_New_Scroll_Pointer;
   If p = NIL then
      Exit;
   p^.txtL := Temp1;                { put txt in it               }
   p^.AttL := Temp2;                { and the attributes          }
   p^.Prev := NIL;                  { reset prev pointer          }
   p^.Next := NIL;                  { reset next pointer          }

   If ScrollFirst = NIL then        { starting with a new list    }
      Begin
         ScrollFirst := p;                { assign first to new node    }
         ScrollLast := p                  { assign last to new node too }
      End
   Else                             { adding a node to a list     }
      Begin
         p^.Prev := ScrollLast;           { set prev to last node       }
         ScrollLast^.Next := p;           { set last's next to new node }
         ScrollLast := p                  { set last to new node        }
      End;
End;


Function LastCommString(l : Integer) : String;
Var
   s : String;
   x : integer;
Begin
   x := Min(ScriptCount,L);
   s := '';
   S[0] := Char(X);
   If ReadPtr >= X then
      Move(RingBuf[ReadPtr-X],S[1],X)
   Else
      Begin
         Move(RingBuf[Recv_Buf_Size-(X-ReadPtr)+1],S[1],X-Readptr);
         Move(RingBuf[0],S[Succ(X-Readptr)],Readptr);
      End;
   If not hi_bit then
      for x := 1 to length(s) do
         If byte(s[x]) > 127 then s[x] := Char(Byte(s[x]) and 127);
   If CaseSensitive or QuickLearn then
      LastCommString := s
   Else
      LastCommString := STUpCase(s);
End;

Function LastCommStringx(l : Integer) : String;
Var
   s : String;
   x : integer;
Begin
   x := L;
   s := '';
   S[0] := Char(X);
   If ReadPtr >= X then
      Move(RingBuf[ReadPtr-X],S[1],X)
   Else
      Begin
         Move(RingBuf[Recv_Buf_Size-(X-ReadPtr)+1],S[1],X-Readptr);
         Move(RingBuf[0],S[Succ(X-Readptr)],Readptr);
      End;
   If not hi_bit then
      for x := 1 to length(s) do
         If byte(s[x]) > 127 then s[x] := Char(Byte(s[x]) and 127);
   LastCommStringx := s
End;

Procedure Add_new_Screen;
Var
   y, x : Integer;
   Tmp : String;
Label
   DoSave;
Begin
   If Split then x := Split_Middle_Row-1
            else x := Last_Row;
   While x > 0 do
      begin
         FastRead(ScreenWidth,x,1,tmp);
         If Trim(tmp) <> '' then
            Goto DoSave;
         Dec(x);
      End;

   DoSave:
   For y := 1 to x do
      Add_New_Line(y);
End;

Procedure Store_Cinkey (Ch : Char);
Begin
   If ScriptCount < 255 then
      Inc(ScriptCount);
   If Capture then
      Begin
         Write (Capture_file, Ch);
         IO := IOresult;
         If IO <> 0 then
            Begin
               Writelnt ('IO Error '+Long2Str(IO)+' writing to Capture file');
               Capture := not Capture;
            End
      End;
   If PrtLog then
      Begin
         Write (PrtlogLst, Ch);
         IO := IOresult;
         If IO <> 0 then
            Begin
               Writelnt ('IO Error '+Long2Str(IO)+' writing to Printer');
               PrtLog := False;
               ClosePrinter(PrtlogLst);
            End;
      End;
End;


Function Get_Qmodem_Spec : String;
Var
   Ovr : String;
Begin
   Ovr := GetEnv(_QMODEMUC_);
   If Ovr = '' then
      GetDir(0,Ovr);
   Get_Qmodem_Spec := AddBackSlash(Ovr);
End;


Function free_space(drive_letter : char) : LongInt;
var
  BytesPerCluster, FreeSpace        : LongInt;
  ClustersAvailable, TotalClusters,
  BytesPerSector, SectorsPerCluster : Word;
  dl                                : Byte;
Begin
   drive_letter := upcase(drive_letter);
   case drive_letter of
      'A'..'Z'  : dl := ord(drive_letter)-64;
      Else        dl := 0;
   End;
   If GetDiskInfo(dl, ClustersAvailable, TotalClusters, BytesPerSector,
                      SectorsPerCluster) then
      Begin
         BytesPerCluster := LongInt(SectorsPerCluster) * LongInt(BytesPerSector);
         Free_Space := LongInt(ClustersAvailable) * BytesPerCluster;
      End
   Else
      Free_Space := 0;
End;

Procedure write_xmit_time (blocks : LongInt);
   var
      block_rate,tot_secs,trans_hour,trans_min,trans_sec : real;
   Begin
      block_rate := 1.375*1200/NewSpeed;
      tot_secs := int(blocks*block_rate+1);
      trans_hour := int(tot_secs/3600);
      tot_secs := tot_secs-(trans_hour*3600);
      trans_min := int(tot_secs/60);
      trans_sec := tot_secs-(trans_min*60);
      write (' ');
      If trans_hour < 10 then write ('0'); write (trans_hour:1:0,':');
      If trans_min  < 10 then write ('0'); write (trans_min:1:0,':');
      If trans_sec  < 10 then write ('0'); write (trans_sec:1:0)
   End;

Procedure SetString(Var p : Pointer; q : Pointer);
Begin
   DisposeString(p);
   p := q;
End;


Function  Max (x, y : LongInt) : LongInt;
Begin
   If x > y then Max := x
            else Max := y;
End;

Function  Min (x, y : LongInt) : LongInt;
Begin
   If x < y then Min := x
            else Min := y;
End;


Function ExpandCtrlString (S:String) : String;
Var
   t : String;
   x : Integer;
Begin
   t := '';
   For X := 1 to Length(S) do
      If Byte(S[x]) < 32 then
         t := t + '^'+Chr(Byte(S[x])+64)
      Else
         If S[x] = '^'    then
            t := t + '^^'
         Else
         If S[x] = '$'    then
            t := t + '$$'
         Else
            t := t + S[x];
   ExpandCtrlString := t;
End;


Procedure ResetColumn;
Begin
   y := WhereX;
   If y = Last_Col then
      If LastWas80 then
      Begin
         EmulsAnsiVt100Disp(#13);
         EmulsAnsiVt100Disp(#10);
      End;
End;


Procedure EmulsAnsiVT100Disp(Ch : Char);
Var
   wc : WindowCoordinates;
Begin
   If WhereX = Last_Col then
      Begin
         If LastWas80 then
            If CH <> #13 then
               If CH <> #10 then
                  Begin
                     SaveAttr := TextAttr;
                     TextAttr := LastChAttr;
                     If WhereY = Last_Row then
                        Add_new_line(1);
                     Write(LastCh);
                     TextAttr := SaveAttr;
                  End;

         Case LineWrap of
            False : Case CH of
                       #13 : LastWas80 := False;
                       #10 : LastWas80 := True;
                       Else
                          Begin
                             Pushed := True;
                             StoreWindowCoordinates(wc);
                             Window(wc.xl,wc.yl,wc.xh,wc.yh+2);
                             LastWas80 := True;
                          End;
                    End;
            True  : If Ch <> #10 then Begin
                       Pushed := True;
                       StoreWindowCoordinates(wc);
                       Window(wc.xl,wc.yl,wc.xh,wc.yh+2);
                       LastWas80 := True;
                    End;
         End;
      End;


   If (WhereY = StoreLastLine) and (CH = #10) then
      Add_new_line(1);

   Store_Cinkey (Ch);
   Write (CH);

   If Ch = #13 then
      LastWas80 := False;

   If LastWas80 then
      Begin
         If (WhereX = 1) and (Ch <> #10) then
            Begin
               GotoXY(Last_Col, Pred(WhereY));
               If Not LineWrap then
                  LastWas80 := False;
            End
         Else
            LastWas80 := False;
         LastCh := ReadCharAtCursor;
         LastChAttr := ReadAttrAtCursor;
      End;

  If Pushed then
     Begin
        RestoreWindowCoordinates(wc);
        Pushed := False;
     End;
End;



Begin
   StatusWasOn := True;
End.
