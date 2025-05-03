Program WaitNode;

 (*
  * This will wait until a certain time for DOWNx files to be created.
  * When all the files exist, or the max time expired, it will continue.
  *)


Uses TPCRT, TPDOS, TpString, TPDATE;


Var
   Ch : Char;
   Go : Time;
   ParmMinutes,
   CountDown,
   xx, yy, x,
   Nodes  : Word;

Begin
   If ParamCount < 3 then
      Begin
         Writeln ('Error!  ALL parameters MUST be included.');
         Halt(1);
      End;

   If not Str2Word(ParamStr(1), Nodes) then
      Begin
         Writeln ('Error converting NODES!');
         Halt(1);
      End;

   If Str2Word(ParamStr(2), ParmMinutes) then else ParmMinutes := 10;

   Writeln;
   Writeln('WAITNODE running.');
   Writeln;
   Writeln('o   Looking for ',ParamStr(1), ' Nodes to signal ',ParamStr(3));
   Writeln('o   Or ',ParamStr(2), ' minutes to expire.');
   Writeln('o   Press ESC to Abort with ErrorLevel of 1.');
   Write  ('o   ');

   Go := IncTime(CurrentTime,0,ParmMinutes,0);

   xx := WhereX;
   yy := WhereY;
   HiddenCursor;

   Repeat
      GotoXY(xx,yy);
      CountDown := 0;
      For x := 1 to Nodes do
         Begin
            If ExistFile(Trim(ParamStr(3))+Long2Str(x)) then
               Inc(CountDown);
            Delay(100);
         End;
      Write ('Nodes '+ParamStr(3)+' : ',CountDown);
      Write ('  Execution in ',TimeToTimeString('mm:ss',Go-CurrentTime));
      Clreol;

      If (CurrentTime >= Go) or (CountDown = Nodes) then
         Begin
            Writeln;
            Writeln('o   Normal exit.');
            Go := IncTime(CurrentTime,0,0,20);
            Write  ('o   ');
            xx := WhereX;
            yy := WhereY;
            Repeat
               GotoXY(xx,yy);
               Write ('DOS prompt at ',TimeToTimeString('mm:ss',Go-CurrentTime));
            Until (CurrentTime >= Go) or KeyPressed;
            If KeyPressed then CH := ReadKey;
            NormalCursor;
            Exit;
         End;

      If Keypressed then
         Begin
            Ch := ReadKey;
            If Ch = #27 then
               Begin
                  Writeln;
                  Writeln ('o   Aborted.');
                  NormalCursor;
                  Halt(1);
               End;
         End;

      Delay(6000);
   Until False;
End.
