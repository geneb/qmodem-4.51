
Procedure Register_Copy;
Var
   T        : String;
   N, rc, X : Integer;
   DummyStr : String[255];
   DummyLen : Byte absolute DummyStr;
Begin
   Assign(MyCode, QMODEM_EXE); {This is the program's name}
   Reset(MyCode, 1);
   MyCodeSize := FileSize(MyCode); { size in bytes }
   Dec(MyCodeSize,255);
   DummyLen := 255;
   Seek(MyCode,MyCodeSize);
   BlockRead(MyCode,DummyStr[1],255);
   While (Pos(Board_Ptr,DummyStr) = 0) and (MyCodeSize > 0) do
      Begin
         Dec(MyCodeSize,64);
         Seek(MyCode,MyCodeSize);
         BlockRead(MyCode,DummyStr[1],255);
      End;

   If MyCodeSize < 256 then
      Begin
         WriteLn;
         WriteLn('þ Error in Registration Code');
         Cursor_Emul := Cursor_Emul And $FE;
         Halt;
      End;

   Seek(MyCode, MyCodeSize);
   BlockRead(MyCode, Sector_Code, 256);
   Start_Name := Pos(Board_Ptr,DummyStr)+Length(Board_Ptr);
   Start_Reg  := Start_Name + 61;              {4.2G!!}
   Clrscr;                                     {4.2G!!}
   Writeln('þ QMODEM REGISTRATION þ');         {4.2G!!}
   WriteLn('þ Registered to: ', BOARD);
   Write  ('þ Please enter your Registration Name   : ');
   BufLen := 50;
   ReadLn(BOARD);
   Write  ('þ Please enter your Registration Number : ');
   T := '';
   Repeat
      CH := Upcase(Char(ReadKeyA));
      Case CH Of
         '0'..'9' : If Length(T) < 7 Then
                       Begin
                          T := T + CH;
                          Write(CH);
                       End;
         #8, #127 : If Length(T) > 0 Then
                       Begin
                          Write(#8#32#8);
                          T[0] := Chr(Byte(T[0]) - 1);
                       End;
      End;
   Until CH = #13;
   WriteLn;
   Val(T, Reg_Number, rc);
   Check_Reg  := GetReg;
   Garbage[1] := GetReg mod 12;
   Garbage[3] := (GetReg * GetReg) mod 13;
   Garbage[8] := GetReg mod 14;
   If Reg_Number = Check_Reg Then
      Begin
         For N := 0 To Length(BOARD) Do
            Sector_Code[Start_Name + N] := BOARD[N]; {This rev's the Code}
         Sector_Code[Start_Reg] := Chr(Lo(Reg_Number));
         Sector_Code[Start_Reg + 1] := Chr(Hi(Reg_Number));
         For x := 1 to 8 do
            Sector_Code[Start_Reg-11+x] := Chr(Garbage[x]);
         Reset(MyCode, 1);
         Seek(MyCode, MyCodeSize);
         BlockWrite(MyCode, Sector_Code, 256);
         Close(MyCode);
         WriteLn('þ Now registered to : ', BOARD);
         Delay(1000);
         IsRegisteredOK := True;
      End
   Else
      Begin
         IsRegisteredOK := True;
         WriteLn('þ Invalid Registration Number'); {Wrong Number}
         Cursor_Emul := Cursor_Emul And $FE;
         Halt;
      End;
End;

