Unit EmulDups;   {Routines that are duplicated between Different Emulations}

Interface

Uses
   TpCrt,
   Initial,
   Screen,
   Procs;


Procedure Show_Bogus_ANSI(CH : Char);
Procedure SetEmmColor;


Implementation


Procedure Show_Bogus_ANSI(CH : Char);
Var
   Temp           : String;
   x              : Integer;
Begin
   Temp := #27 + '[' + Save_Ansi_Str + CH;
   For x := 1 To Byte(Temp[0]) Do
      EmulsAnsiVT100Disp(Temp[x]);
   Save_Ansi_Str[0] := #0;
   Ansi_Mode := No_Esc;
End;


Procedure SetEmmColor;
Var
   Temp : String[10];
Begin
   If Save_Ansi_Str = '' Then
      Set_Base_Colors
   Else
      Begin
         Repeat
            x := SearchLeftC(Save_Ansi_Str, ';');
            If x = 1 Then
               Begin
                  Temp := '0';
                  Save_Ansi_Str := Copy(Save_Ansi_Str, 2, Byte(Save_Ansi_Str[0]) - 1);
               End
            Else
               If x <> 0 Then
                  Begin
                     Temp := Copy(Save_Ansi_Str, 1, x - 1);
                     Save_Ansi_Str := Copy(Save_Ansi_Str, x + 1, Byte(Save_Ansi_Str[0]));
                  End
               Else
                  Begin
                     Temp := Save_Ansi_Str;
                     Save_Ansi_Str[0] := #0;
                  End;
            Case Asc2int(Temp) Of
               0  : Set_Base_Colors;
               1  : emul_color := emul_color Or 8;
               4  : emul_color := (emul_color And 119) Or 1;
               5  : emul_color := emul_color Or 128;
               7  : emul_color := $70;
               8  : emul_color := DarkGray;

               30 : emul_color := (emul_color And 248) Or Black;
               31 : emul_color := (emul_color And 248) Or Red;
               32 : emul_color := (emul_color And 248) Or Green;
               33 : emul_color := (emul_color And 248) Or Brown;
               34 : emul_color := (emul_color And 248) Or Blue;
               35 : emul_color := (emul_color And 248) Or Magenta;
               36 : emul_color := (emul_color And 248) Or Cyan;
               37 : emul_color := (emul_color And 248) Or LightGray;

               40 : emul_color := (emul_color And 143) + Black Shl 4;
               41 : emul_color := (emul_color And 143) + Red Shl 4;
               42 : emul_color := (emul_color And 143) + Green Shl 4;
               43 : emul_color := (emul_color And 143) + Brown Shl 4;
               44 : emul_color := (emul_color And 143) + Blue Shl 4;
               45 : emul_color := (emul_color And 143) + Magenta Shl 4;
               46 : emul_color := (emul_color And 143) + Cyan Shl 4;
               47 : emul_color := (emul_color And 143) + LightGray Shl 4;
            End;
         Until Save_Ansi_Str[0] = #0;
      End;
   Set_Colors;
End;


End.