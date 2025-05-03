Unit Qega;

Interface

Uses
   Dos,       TpCrt,
   Initial,   Comm,
   Procs,     Screen;


Procedure Set_Screen_25;
Procedure Set_Screen_43;


Implementation


   Procedure Set_Screen_25;
   Begin
      If CurrentDisplay < EGA Then Exit;
      textmode(3);
      {SetCrtBorder(qq.Border);}
      Clear_Whole_Screen;
      SetCrtBorder(qq.Border);
      Display_Status('');
   End;

   Procedure Set_Screen_43;
   Begin
      If CurrentDisplay < EGA Then Exit;
      textmode(3 {CurrentMode} + Font8x8);
      Clear_Whole_Screen;
      SetCrtBorder(qq.Border);
      Display_Status('');
   End;


End.
