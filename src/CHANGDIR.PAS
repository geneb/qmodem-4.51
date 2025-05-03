Unit ChangDir;

Interface

Uses
   TpCrt,
   TPString,
   Initial,
   Screen,
   Procs,
   TpPick,
   TpDir;

Procedure Chgdir(temp3 : Str64);


Implementation

Procedure Chgdir(temp3 : Str64);
Var
   Temp1,
   temp2 : Str64;
   x, y  : Integer;
   Ch1   : Char;
   OK2   : Boolean;
Begin
   If Scripting then
      Begin
         Script_success := True;
         If temp3 <> '' Then
            Begin
               ChDir(temp3);
               x := IoResult;
               If x <> 0 Then
                  Script_success := False;
            End;
         Exit;
      End;
   Push_Status;
   Display_Status (' ARROWS-Scroll   ENTER-Change Directory   F10-Save   ESC-Exit ');
   GetDir(0,Temp1);
   HelpTopic := 24;
   Temp2 := Addbackslash(Temp1)+'*.*';
   if not AddPickCommand(PKSuser0,1,$4400,$0000) then
      { no error possible here } ;
   SetSnakingPick;
   ShowSizeDateTime := False;
   Repeat
      x := ChangeDirectory(Temp2, 2,2, PRLR-1,6, PickColors);
      Case PickCmdNum of
         PKSuser0 : ;
         PKSexit  : ChDir(Temp1);
      End;
   Until x <> 3;
   Case x of
      0 :  ;
      1 :  Writelnt ('Path not found');
      3 : ;
      4 :  Writelnt ('Insufficient memory');
      5 :  Writelnt ('Won''t fit on screen');
      Else Writelnt ('No subdirectories to pick from');
   End;
   ShowSizeDateTime := True;
   SetVerticalPick;
   Pop_Status;
End;

End.
