Unit LogDrv;

Interface

Uses
   Dos,       TpCrt,
   Initial,   Comm,
   Screen,    Files,
   Procs,     Group02;

Procedure Log_Drive(Ch : Char);


Implementation


   Procedure Log_Drive(Ch : Char);
   Var
      Ok             : Boolean;

   Begin
      Script_success := True;
      Setwindow2(29, 11, 52, 14, ' Change Log Drive ',false);
      HelpTopic := 38;
      TextAttr := qq.menu2;
      ClrScr;
      WriteLn;
      Ch := Upcase(Ch);
      Display_Status(' A thru Z-Select New Drive   ESC-Exit ');
      Repeat
         ClrScr;
         Write(' Logged Drive is  : ');
         TextAttr := qq.Menu;
         WriteLn(Default_Drive);
         TextAttr := qq.menu2;
         Write(' Enter new Drive  : ');
         If Not Scripting Then
            Repeat
               Ch := Upcase(Char(ReadKeyA));
            Until Ch In ['A'..'Z', #27]
         Else
            If Not(Ch In ['A'..'Z']) Then
               Begin
                  Script_success := False;
                  Exit;
               End;
         If Ch In ['A'..'Z'] Then
            Begin
               TextAttr := qq.Menu;
               Write(Ch);
               Delay(500);
               If QuickLearn then
                  WriteLearn('Drive    '+ Upcase(Ch));
               Ok := Log_new_drive(Ch);
               If Not Ok Then
                  Begin
                     If Scripting Then
                        Begin
                           Script_success := False;
                           Ok := True;
                        End
                     Else
                        Writelnt('Invalid Drive, try again.');
                  End
               Else
                  Begin
                     Default_Drive := Ch;
                     Logit('Default Drive now ' + Ch + ':');
                  End
            End
         Else
            Ok := True;
      Until Ok;
      Restore_Screen;
   End;

End.
