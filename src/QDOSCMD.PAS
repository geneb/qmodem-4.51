Unit QDosCmd;

Interface

Uses
   Initial,
   Constant,
   QShell;


Procedure DOS_Cmd;


Implementation


   Procedure DOS_Cmd;
   Var
      rc : Integer;
   Begin
      rc := Shell(''+'', _Qmodem_+' ®--¯ DOS Shell'+'',
                  'Type EXIT to return to '+_Qmodem_+'!',
                  True, False,False);
   End;

End.
