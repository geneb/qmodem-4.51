Unit DownExt;
{$P+,V-}

Interface

Uses Dos,
     TpCrt,
     TPString,
     Initial,
     Comm,
     Procs,
     Screen,
     Files,
     QShell,
     XferStuf,
     Downld0;

Procedure Download_External(CH : Char; PauseAfter : Boolean);


Implementation



   Procedure Download_External(CH : Char; PauseAfter : Boolean);
   Var
      Temp           : String;
      num, x         : Integer;

   Begin
      Temp := '';
      num := Is_External(CH);

      If qq.Xfer_file_prompt[num] = 'Y' Then
         Get_File_Name_d(dfile, sFilename, 11)
      Else
         dfile := '';

      If (dfile = '') And (qq.Xfer_file_prompt[num] = 'Y') Then
         Exit;

      If QuickLearn then
         WriteLearn('Download '+CH+' '+Dfile);

      Logit('Download Executing ' + qq.xfer_receive_bat[num] + '.');

      Clear_buffer;

      Temp := Temp + Long2Str(NewSpeed)+' '+
                     Long2Str(qq.commport)+' '+
                     Long2Str(DCE_Speed)+' '+
                     StLoCase(dfile);

      rc := Shell(qq.xfer_receive_bat[num] + ' ' + Temp,
                  'Executing ' + qq.xfer_receive_bat[num],
                  ''+'', True, False,False);

      Clear_buffer;

      If rc <> 0 Then
         Begin
            writelnb('Error loading ' + qq.xfer_receive_bat[num] + '.  RC='+Long2Str(RC));
            If PauseAfter Then
               KeyContinue(qq.InfoColor);
            Logit('++ External Batch Failure.');
            Exit;
         End;

      If Scripting then
         Show_Script_Status_Line;

      Sound_Completion;
      Script_success := True;
   End;

End.
