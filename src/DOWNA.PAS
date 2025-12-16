Unit DownA;
{$P+,V-}

Interface

Uses Dos,      TpCrt,   TPString,
     Initial,  Comm,    Files,
     Screen,   Procs,   Group1,
     Comm2,    Downld0,  Emuls;

Procedure Download_ascii;


Implementation

Uses Key;


   Procedure Download_ascii;
   Var
      InFile         : Text;
      CH, Ch1        : Char;
      Temp, Special, Ok, Flow : Boolean;
   Begin
      Special := False;
      Flow := False;
      CH := ' ';
      Ch1 := ' ';
      Get_File_Name_d(dfile, sFilename, 1);
      If dfile = '' Then
         Exit;
      If QuickLearn then
         WriteLearn('Download A '+Dfile);
      Assign(InFile, dfile);
      Rewrite(InFile);
      Push_Status;
      If IOresult = 0 Then
         Begin
            Display_Status(' ASCII DOWNLOAD IN PROGRESS    ESC-Save and Exit ');
            Temp := False;
            Logit('++ Protocol : ASCII');
            clear_buffer;
            Repeat
               If Flow Then
                  Begin
                     If Queue_Bytes + Buffer_High1 < recv_buf_size Then
                        Begin
                           Flow := False;
                           If Xon_Xoff Then Write_Byte(^Q); { send XON }
                        End;
                  End
               Else
                  Begin
                     If Queue_Bytes + Buffer_Low1 > recv_buf_size Then
                        Begin
                           Flow := True;
                           If Xon_Xoff  Then Write_Byte(^S); { send XOFF }
                        End;
                  End;
               If CommPressed Then
                  Begin
                     Ch1 := Cinkeyz;
                     If qq.ASCII_In_Xlate then
                        Ch1 := Chr(qq.Xlate_Table_In[Ord(Ch1)]);
                     If Ch1 <> #0 then
                        Begin
                           Case Ch1 of
                              #10 : Case qq.ASCII_In_LF of
                                       0 : Begin
                                              Write(Infile,#10);
                                              OutKey(#10);
                                           End;
                                       1 : ;
                                       2 : Begin
                                              Write (InFile,#13#10);
                                              OutKey(#13#10);
                                           End;
                                    End;
                              #13 : Case qq.ASCII_In_CR of
                                       0 : Begin
                                              Write(Infile, #13);
                                              OutKey(#13);
                                           End;
                                       1 : ;
                                       2 : Begin
                                              Write (InFile,#13#10);
                                              OutKey(#13#10);
                                           End;
                                    End;
                              Else  Begin
                                       Write(InFile, Ch1);
                                       OutKey(Ch1);
                                    End;
                           End;
                           If IoResult <> 0 Then
                              Begin
                                 Writelnt('Error writing to file.  Possible Disk full.');
                                 Close(InFile);
                                 Exit;
                              End;
                           Temp := True;
                        End;
                  End;
               If Keypressed Then
                  Begin
                     Ch := Char(ReadKeyA);
                     If Ch <> #27 then
                        Handle_Key_Pressed(Ch);
                  End;
            Until (CH = #27) or
                  (Ch1 = ^Z);     { ESC pressed or ^Z received }
            If Temp Then
               Begin
                  Writelnt('File Saved');
                  Close(InFile);
                  Script_success := True;
               End
            Else
               Begin
                  WritelnT('No DATA received.  File not saved');
                  Close(InFile);
                  Erase(InFile);
               End;
         End
      Else
         Begin                    { was an I/O error }
            WritelnT('Error creating the file.  Possible invalid filename or disk full.');
         End;
      Pop_Status;
   End;

End.
