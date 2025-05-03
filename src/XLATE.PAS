Unit XLate;

Interface

Uses Dos,      TpCrt,
     Initial,  TpEdit,
     Comm,     Screen,
     Files,    Procs,
     Constant, OpKey,
     Group1;

Procedure xlate_table;


Implementation

Var
   escape            : Boolean;


   Function Save_Change_Prompt : Boolean;
   Begin
      Sound(40);
      Setwindow2(15, 6, 65, 8, ' Warning! ',false);
      Write(' Changes have been made.  Save them [Y/N] ? ');
      TextAttr := qq.menu2;
      NormalCursor;
      Delay(250);
      NoSound;
      Save_Change_Prompt := (Get_Yes_No = 'Y');
      Restore_Screen;
   End;

   Procedure Save_Xlate;
   Var
      f : File;
   Begin
      Assign(F, SearchName(QMODEM_CNF));
      Reset(F,1);
      Seek(F,$5C1);  {go to the Input Xlate position}
      BlockWrite(F,qq.Xlate_Table_In,256);
      Seek(F,$70D);  {go to the Output Xlate position}
      BlockWrite(F,qq.Xlate_Table_Out,256);
      Close(F);
      IO := IoResult;
   End;

   Procedure Reload_Xlate;
   Begin
      Assign(Config_file, SearchName(QMODEM_CNF));
      Reset(Config_file);
      Read(Config_file, qq);
      Close(Config_file);
      IO := IoResult;
   End;


   Procedure xlate_table;
   Var
      x1, x2, y1, y2, Current, offset, rc : Integer;
      change         : Boolean;
      Temp           : String[3];

      Procedure MoveUp;
      Begin
         If Current = 0 Then Current := 127
         Else Dec(Current);
      End;

      Procedure MoveDown;
      Begin
         If Current = 127 Then Current := 0
         Else Inc(Current);
      End;

      Procedure MoveLeft;
      Begin
         If Current < 16 Then Current := Current + 112
         Else Current := Current - 16;
      End;

      Procedure MoveRight;
      Begin
         If Current > 111 Then Current := Current - 112
         Else Current := Current + 16;
      End;

      Procedure Main_1;
      Begin
         Display_Status(' ARROWS-Movement   S-Swap   SPACEBAR-Change   F10-Save  ESC-Exit ');
      End;

      Procedure Main_2;
      Begin
         Display_Status(' Enter the new value, 0 will Strip the Character ');
      End;

      Function RV(I : Boolean; x : Integer) : Byte;
      Begin
         If I Then RV := qq.Xlate_Table_In[x]
         Else RV := qq.Xlate_Table_Out[x];
      End;


      Procedure Xlate_Table_Fix(InTable : Boolean);
      Var
         Temp           : String[3];
         CH             : Char;

         Procedure displayit(value, hilo : Integer);
         Var
            Temp           : Integer;
            S1, S2         : String[3];
            CH             : String[1];
         Begin
            If value > 127 Then
               Temp := value - 128
            Else
               Temp := value;
            x1 := Trunc(Temp / 16 + 1) * 9 - 5;
            y1 := (Temp Mod 16) + 5;
            Str(value:3, S1);
            Str(RV(InTable, value):3, S2);
            If (value <> RV(InTable, value)) And
            ((Current + offset <> value) Or (hilo = 0)) Then
               FastWrite(' ' + S1 + '-' + S2 + ' ', y1, x1, qq.Menu)
            Else
               If hilo = 1 Then
                  FastWrite('[' + S1 + '-' + S2 + ']', y1, x1, qq.Menu)
               Else
                  FastWrite(' ' + S1 + '-' + S2 + ' ', y1, x1, qq.Menu2);
            FastWrite(Chr(value), 4, 36, qq.Menu);
            FastWrite(Chr(RV(InTable, value)), 4, 55, qq.Menu);
            TextAttr := qq.Menu;
         End;

         Procedure display_screen;
         Var
            x2             : Integer;
         Begin
            For x2 := 0 To 127 Do
               displayit(x2 + offset, 0);
         End;

      Begin                       {xlate_table}
         HiddenCursor;
         Offset := 0;
         If InTable Then Setwindow2(1, 3, 80, 24, ' INPUT Strip/Replace Table ',false)
                    Else Setwindow2(1, 3, 80, 24, ' OUTPUT Strip/Replace Table ',false);
         Current := 0;
         Change := False;
         ClrScr;
         FastWrite('In Character | |  Out Character | |', 4, 22, qq.Menu2);
         Display_screen;
         Displayit(Current + Offset, 1);
         Main_1;
         HelpTopic := 7;
         Repeat
            CharWord := ReadKeyNoGrey;
            Displayit(Current + Offset, 0);
            Case CharWord Of
               Esc   : If Change Then
                          Begin
                             Change := Save_Change_Prompt;
                             If Change Then Save_Xlate
                                       Else Reload_Xlate;
                          End;
               F10   : Begin
                          Save_Xlate;
                          CharWord := Esc;
                       End;
               Up    : MoveUp;
               Left  : MoveLeft;
               Right : MoveRight;
               Down  : MoveDown;
               Else    Case Upcase(Char(CharWord)) of
                          'S' : Begin
                                   Display_Status(' SWAPPING ');
                                   If offset = 0 Then offset := 128
                                                 Else offset := 0;
                                   Display_screen;
                                   Main_1;
                                End;
                          ' ' : Begin
                                   Displayit(Current + offset, 1);
                                   Main_2;
                                   GotoXY(25, 19);
                                   TextAttr := qq.Menu;
                                   Write('Enter new value for ', Current + offset, ' > ');
                                   NormalCursor;
                                   q := 0;
                                   ReadInteger('', 22, 51, 3,
                                               TextAttr, TextAttr,
                                               0, 255, Escape, q);
                                   If Not Escape Then
                                      Begin
                                         If InTable Then
                                            qq.Xlate_Table_In[Current + offset] := q
                                         Else
                                            qq.Xlate_Table_Out[Current + offset] := q;
                                         Change := True;
                                      End;
                                   HiddenCursor;
                                   GotoXY(1, 19);
                                   Clreol;
                                   Main_1;
                                End;
                       End;
            End;
            Displayit(Current + offset, 1);
         Until CharWord = Esc;
         Restore_Screen;
         NormalCursor;
      End;


   Begin                          {xlate_table}
      Repeat
         Setwindow2(25, 5, 55, 13, ' Table Selection ',false);
         Display_Status(' Select the Strip/Replace Translate Table to Edit   ESC-Exit ');
         HelpTopic := 4;
         WriteLn;
         WriteLn('    Select Table to Edit');
         WriteLn;
         Write('         1 ');
         TextAttr := qq.menu2;
         WriteLn('-  INPUT');
         TextAttr := qq.Menu;
         Write('         2 ');
         TextAttr := qq.menu2;
         WriteLn('-  OUTPUT');
         WriteLn;
         TextAttr := qq.Menu;
         Write('  Your Choice ? ');
         Repeat
            CH := Char(ReadKeyA);
         Until CH In ['1', '2', #27];
         Restore_Screen;
         Case CH Of
            '1' : Xlate_Table_Fix(True);
            '2' : Xlate_Table_Fix(False);
         End;
      Until CH = #27;
   End;

End.
