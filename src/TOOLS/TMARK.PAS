Program TMark(Input, Output);

Uses TPCRT, TPDOS, tpcmdlin, TpString, TPDATE;

Var
   s,t   : String;
   i,io,
   x,y   : integer;
   f     : text;
Begin
   i := 0;
   SlashChar := '-';
   t := GetArgString(i,true,true);
   s := GetArgString(i,true,true);
   If s = '' then
      s := 'Tmark Stamp';
   Assign (f,t);
   If not ExistFile(t) then
      Begin
         ReWrite(f);
         Write(f,'');
         Close(f);
      End;
   IO := IOResult;
   Write('TMARK - ');
   x := WhereX;
   y := WhereY;
   Repeat
      GotoXY(x,y);
      Delay(250);
      Append(F);
      IO := IOResult;
      If IO <> 0 then
         Begin
            Write('IO Error: ',IO, ' WAIT...');
            Clreol;
         End;
   Until (IO = 0) or KeyPressed;
   Clreol;
   Writeln (TodayString('mm/dd/yy'),'  ',CurrentTimeString('hh:mm:ss'),'  ',s);
   Writeln (F,TodayString('mm/dd/yy'),'  ',CurrentTimeString('hh:mm:ss'),'  ',s);
   Close(F);
   IO := IOResult;
End.
