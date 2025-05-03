Unit Port;

Interface

Uses Dos,
   TpCrt,
   TPString,
   Initial,
   Comm,
   Comm2,
   Screen,
   Files,
   Procs,
   Group1,
   {$IFDEF UseMouse}
   TpMouse,
   {$ENDIF}
   Button;


Procedure Change_ComPort(NewPort : Char);


Implementation


   Procedure Change_ComPort(NewPort : Char);
   Type
      all_chars      = Set Of #0..#255;
   Var
      Col, Row, x, y : Integer;
      test_chars     : all_chars;
      ComArray       : Array[1..8] of Boolean;
      xp             : byte;
      ch             : Char;

      {$IFDEF UseMouse}
         Mflag       : Boolean;
      {$ENDIF}

   Label
      EExit;

   Begin
      {$IfDef Int14}
      If Int14 then
         Begin
            WritelnT('Int14 support active, Port cannot change.');
            Exit;
         End;
      {$EndIf}
      PushButtonList;
      test_chars := [#13, #27];
      x := 0;
      xp := 8;
      For xp := 1 to 8 do
         ComArray[xp] := False;

      For xp := 1 to 8 do
         If (ComBaseAddr[xp] <> 0) and (ivIRQ[xp] <> 0) then
            Begin
               ComArray[xp] := True; {There is a port defined here}
               Inc(x);
               test_chars := test_chars + [Chr(Ord('1') + xp - 1)];
            End;

      {$IfDef ISI}
      For xp := 1 to ISI_Port_Count do
         Begin
            test_chars := test_chars + [Chr(Ord('A') + xp - 1)];
            Inc(x);
         End;
      {$EndIf}

      If Not Scripting Then
         Begin
            Setwindow2(24, 2, 58, 7+x, ' Set Communications Port ',false);

            {$IFDEF UseMouse}
               Mflag := MouseInstalled and MouseCursorOn;
            {$ENDIF}

            HelpTopic := 27;
            TextAttr := qq.Menu2;
            Display_Status(' SELECTION-Select new Port   ESC-Exit ');
            Write('    Active Port is ');
            TextAttr := qq.Menu;
            {$IfDef ISI}
            If qq.Use_ISI then
               Write('ISI')
            else
            {$EndIf}
               Write ('COM');
            Write(qq.CommPort);
            x := 0;
            For y := 1 to 8 do
               If ComArray[y] then
                  Begin
                     Inc(x);
                     Ch := Chr(y+Ord('1')-1);
                     AddButton(2+x,2,1,1,qq.Menu,qq.Menu2,
                               Ch+'  COM'+ch+'  Base('+HexW(qq.Base[y])+
                               ') Irq('+HexB(qq.IRQ[y])+')',
                               ord(ch));
                  End;
            {$IfDef ISI}
            For y := 1 to ISI_Port_Count do
               Begin
                  Inc(x);
                  Ch := Chr(y+Ord('A')-1);

                  AddButton(2+x,2,1,1,qq.Menu,qq.Menu2,
                            Ch+'  ISI'+Long2Str(y)+'  Base('+HexW(qq.ISI_Base)+
                            ') Irq('+HexB(qq.ISI_IRQ)+')',
                            Ord(Ch));
               End;
            {$EndIf}

            {$IFDEF UseMouse}
            If MouseInstalled then
               AddButton(x+5,24,2,2,qq.WindF, qq.WindF, '<F1=Help>',$3B00);
            {$ENDIF}

            GotoXY(2,x+4);
            Write ('Your choice : ');

            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  MouseWindow(24,2,58,7+x);
                  If not Mflag then
                     ShowTheMouse;
               End;
            {$ENDIF}

            Repeat
               CheckForAButton(True);
               If KeyPressed then
                  NewPort := Upcase(Char(ReadKeyA));
            Until NewPort In Test_Chars;
            If Ord(Newport) > 27 then
               Begin
                  Write (NewPort);
                  Delay(250);
               End;
         End;
      If NewPort In Test_Chars Then
         Begin
            Case NewPort Of
               '1'..'8' : Begin
                             {$IfDef ISI}
                             If qq.Use_ISI then
                                CloseCom(False, False, False)
                             Else
                             {$EndIf}
                                CloseCom(False, False, True);
                             qq.commport := Ord(NewPort) - Ord('1')+1;

                             {$IfDef ISI}
                             qq.Use_ISI := False;
                             {$EndIf}

                             Initialize_Comm_Vars;
                             Logit('Port COM' + Long2Str(qq.CommPort)+ ': selected.');
                             If QuickLearn then
                                WriteLearn('Port     COM'+Long2Str(qq.CommPort));
                          End;

               {$IfDef ISI}
               'A'..'H' : Begin
                             If not qq.Use_ISI then
                                CloseCom(False, False, False)
                             Else
                                CloseCom(False, False, True);
                             qq.commport := Ord(NewPort) - Ord('A')+1;
                             qq.Use_ISI := True;
                             Initialize_ISI_Vars;
                             Logit('Port ISI' + Long2Str(qq.CommPort)+ ': selected.');
                             If QuickLearn then
                                WriteLearn('Port     ISI'+Long2Str(qq.CommPort));
                          End
               {$EndIf}

               Else  Begin
                        If Not Scripting Then
                           Restore_Screen;
                        Goto EExit;
                     End;
            End;
         End;

      If Not Scripting Then
         Restore_Screen;

      ClearComCounters;
      CTS_ := (qq.CTSc = 'Y');
      Init_Port;
      Term_Ready(True);

      EExit:
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
