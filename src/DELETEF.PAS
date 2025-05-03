Unit DeleteF;

Interface

Uses TpCrt,
     Initial,
     Screen,
     Files,
     Procs;


Procedure delete_file;


Implementation

   Procedure delete_file;
   Var
      F              : File;
      Name           : String[64];
   Begin
      GetDir(0, Name);
      Name := Get_File_Name(Name, '', '', 3, 'File Delete Allocation',True);
      If Name = '' Then
         Exit
      Else
         Begin
            Setwindow2(9, 15, 71, 19, ' File Delete ',false);
            TextAttr := qq.menu2;
            ClrScr;
            HelpTopic := 21;
            WriteLn(' You are about to delete the following file:');
            TextAttr := qq.Menu;
            WriteLn(' ', Name);
            TextAttr := qq.menu2;
            Write(' Are you SURE ? [Y/N] ');
            Display_Status(' Y-Delete the File   N-Exit ');
            TextAttr := qq.Menu;
            Repeat
               CH := Get_Yes_No;
            Until CH In ['Y', 'N'];
            WriteLn;
            TextAttr := qq.menu2;
            If CH = 'Y' Then
               Begin
                  Assign(F, Name);
                  Erase(F);
                  IO := IoResult;
                  Logit('File ' + Name + ' DELETED.');
                  If QuickLearn then
                     WriteLearn ('DOS     "DEL '+Name+'"');
               End;
            Restore_Screen;
         End;
   End;

End.
