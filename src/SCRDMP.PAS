Unit ScrDmp;

Interface

Uses
   TPDos,
   TpCrt,
   Initial,
   Procs,
   Screen,
   Files,
   Constant,
   TPString;

Procedure screen_dump;


Implementation


Procedure screen_dump;
Var
   Temp   : String;
   TempF  : String[128];
   Ok     : Boolean;
   x      : Integer;

   Procedure Error_writing;
   Begin
      WritelnT('Error saving ' + TempF + '.');
      Close(Screen_File);
   End;

Begin
   Ok := True;
   TempF := Get_File_Name('', ScrndumpF, 'DMP', 12,
                          'Screen Dump File Allocation',True);
   If TempF = '' Then Exit;
   If Not Test_Create_And_Keep(TempF) then
      Exit;
   Assign(Screen_File, TempF);
   Append(Screen_File);
   IO := IoResult;
   If IO = 0 Then
      Begin
         IO := IoResult;
         If (IO <> 0) or (not TimeDateStamper(Screen_File)) Then
            Begin
               Error_writing;
               Exit;
            End;
         For x := 1 To Last_Row Do
            Begin
               FastRead(Last_Col, x, 1, Temp);
               Temp := TrimTrail(Temp);
               WriteLn(Screen_File, Temp);
               IO := IoResult;
               If IO <> 0 Then
                  Begin
                     Error_writing;
                     Exit;
                  End;
            End;
         Write(Screen_File, ^z);
         Close(Screen_File);
         WritelnT('Screen saved to ' + TempF);
      End
   Else
      WritelnT('Error saving the Screen Dump file.');
End;

End.
