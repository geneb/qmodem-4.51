Unit ExitDOS;

Interface

Uses Dos,      TpCrt,    TPString,

     {$IFDEF UseMouse}
     TpMouse,
     {$ENDIF}

     TPWindow,  Initial,  Screen,
     Qinit,     Comm,     Procs,
     Group1,    Group02,  FoneStuf,
   Constant,
     Button,    RunQinst;

Procedure Exit_to_DOS(Ask : Boolean; Exit_Ch : Char);


Implementation


   Procedure Exit_to_DOS(Ask : Boolean; Exit_Ch : Char);
   Var
      {$IFDEF UseMouse}
      Mflag : Boolean;
      {$ENDIF}
      Ch : Char;
   Begin
      If Not Ask Then
         Begin
            Ch := ' ';
            {$IFDEF UseMouse}
            Mflag := MouseInstalled and MouseCursorOn;
            {$ENDIF}
            PushButtonList;
            Setwindow2(26, 11, 56, 13, ' Exit '+_Qmodem_+' ',false);
            HelpTopic := 29;
            TextAttr := qq.Menu;
            GotoXY(3, 1);
            Display_Status(' Y-Drop DTR and Exit   N-Return to TERMINAL Mode   X-Leave DTR Up and Exit ');
            Write('Are you sure? [Y/n/x] ');
            AddButton(1,18,1,1, qq.Menu, qq.Menu2, 'Y', Ord('Y'));
            AddButton(1,20,1,1, qq.Menu, qq.Menu2, 'n', Ord('N'));
            AddButton(1,22,1,1, qq.Menu, qq.Menu2, 'x', Ord('X'));
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  AddButton(2,20,2,2,qq.WindF, qq.WindF, '<F1=Help>',$3B00);
                  LMouseWindow;
                  If not Mflag then
                     ShowTheMouse;
               End;
            {$ENDIF}
            Repeat
               CheckForAButton(True);
               If KeyPressed then
                  CH := Upcase(Char(ReadKeyA));
            Until CH In ['Y', 'N', 'X',#27,#13];     {4.2F!!}
            Case CH Of
               'Y',#13 : Write('Yes');               {4.2F!!}
               'N',#27 : Write('No');
               'X' : Write('X');
            End;
            Delay(400);
            Restore_Screen;
         End
      Else
         CH := Exit_Ch;
      If CH In ['Y', 'X', #13] Then                  {4.2F!!}
         Begin
            Cursor_Emul := Cursor_Emul And $FE;
            If Capture Then
               Capture_Toggle('', True);
            If QuickLearn Then
               Begin
                  WriteLearn ('System   '+Ch);
                  Learn('');
               End;
            If Last_Online_State Then
               Stop_Online_Timer;
            If Logging Then
               Log_toggle('', False);
            If Online then
               Save_INI;
            If CH = 'X' Then DropDTR := False
                        Else DropDTR := True;
            Write_FON_File;
            SetCrtBorder(0);
            Leave := True;
         End;
      PopButtonList;
      {$IFDEF UseMouse}
      If MouseInstalled then
         Begin
            FullMouseWindow;
            If not Mflag then
               HideTheMouse;
         End;
      {$ENDIF}
   End;

End.
