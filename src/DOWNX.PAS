Unit DownX;

Interface

Uses
   Dos,       TpCrt,
   TPString,  Initial,
   Files,     Comm,
   Procs,     Group1,
   XferStuf,  Downld0;

Procedure Download_Xmodem(Use_CRC, Relaxed, Use_1K, Use_G : Boolean);


Implementation


Procedure Download_Xmodem(Use_CRC, Relaxed, Use_1K, Use_G : Boolean);
Label
   EEXit, Er;
Var
   Transfer_Method : Transfer_Type;
Begin
   Get_File_Name_d(dfile, sFilename, 1);
   TextAttr := qq.Menu;
   If dfile = '' Then
      Goto EExit;

   If Not Open_File_d(dfile, InFile) Then
      Goto EExit; { Open was unsuccessful }

   If Use_G then
      Begin
         Transfer_Method := Xmodem_1K_G;
         Logit('++ Protocol : Xmodem-1K/G');
         If QuickLearn then
            WriteLearn('Download F '+dfile);
      End
   Else
      If Use_1K then
         Begin
            Transfer_Method := Xmodem_1K;
            Logit('++ Protocol : Xmodem-1K');
            If QuickLearn then
               WriteLearn('Download O '+dfile);
         End
      Else
         If Use_CRC Then
            Begin
               Transfer_Method := Xmodem_Crc;
               Logit('++ Protocol : Xmodem CRC');
               If QuickLearn then
                  WriteLearn('Download C '+Dfile);
            End
         Else
            If Relaxed then
               Begin
                  Transfer_Method := Xmodem;
                  Logit('++ Protocol : Xmodem Relaxed');
                  If QuickLearn then
                     WriteLearn('Download R '+Dfile);
               End
            Else
               Begin
                  Transfer_Method := Xmodem;
                  Logit('++ Protocol : Xmodem');
                  If QuickLearn then
                     WriteLearn('Download X '+Dfile);
               End;

   Aborted     := False;
   NxBlk       := False;
   Blocknum    := 1;
   Sec         := 1;
   Timeouterr  := 0;
   Ecount      := 0;
   Shortblk    := 0;
   Comperr     := 0;
   Longblk     := 0;
   SOHerr      := 0;
   resenderr   := 0;
   Blocknumerr := 0;
   checksumerr := 0;
   BufCnt      := 0;
   RealSpeed   := 1200;
   Rspeed      := NewSpeed;
   Speed_X     := RealSpeed / Rspeed;

   HiddenCursor;
   Build_Xfer_screen('D');
   Show_NA_Fields;

   If Use_G Then
      Download_Status(dfile, 'Xmodem-1K/G')
   Else
      If Use_1K Then
         Download_Status(dfile, 'Xmodem-1K')
      Else
         If Relaxed Then
            Download_Status(dfile, 'Xmodem Relaxed')
         Else
            If Use_CRC Then
               Download_Status(dfile, 'Xmodem CRC')
            Else
               Download_Status(dfile, 'Xmodem');


   Ok := Send_NAK(Transfer_Method, Aborted);


   If Ok Then                  { Receive the file }
      Begin

         If Transfer_Method = Xmodem Then
            Use_CRC := False
         Else
            Use_CRC := True;

         Repeat
            Show_Errors;

            Get_next_block(Transfer_Method, x, Relaxed);

            If Ecount >= 10 Then
               Aborted := True; { Abort if too many errors}

            If Not Aborted Then   { Check for EOF, CAN or Errors }
               Begin
                  If block[1] = CAN Then
                     GoTo Er   { Cancel the download and erase the file }
                  Else
                     If block[1] = EOT Then
                        Begin
                           Close_File(Transfer_Method);
                           Log_Xfer_d(Longblk, Shortblk, SOHerr, Comperr, Blocknumerr,
                                      Timeouterr, resenderr, checksumerr, Avg_BPS, Effective_PCT);
                        End
                     Else
                        Begin
                           Ok := True;
                           If Use_G then
                              Begin
                                 If Short_Block_OK(x) Then
                                 If Checksum_OK(Xmodem_1K, True) Then
                                 If Not Save_Block(Transfer_Method) Then
                                    GoTo Er;
                              End
                           Else
                              Begin
                                 If Timeout_OK(x) Then
                                 If Short_Block_OK(x) Then
                                 If SOH_OK Then
                                 If Resend_Block_OK Then
                                 If Blocknum_OK Then
                                 If Complement_OK Then
                                 If Checksum_OK(Xmodem_Crc, Use_CRC) Then
                                 If Not Save_Block(Transfer_Method) Then
                                    GoTo Er;
                              End;

                           Figure_BPS(0);

                           If Not Ok Then
                              Error_NAK;

                        End
               End
            Else               { Aborted Aborted download }
               Begin
Er:               Close(InFile);
                  If not qq.SavePartial then
                     Erase(InFile);
                  Wait_For_Clean_Line(True);
                  Clear_buffer;
                  Goto EExit;
               End;
         Until (block[1] = EOT) Or (block[1] = CAN) Or Aborted;
      End
   Else
      Begin
         Close(InFile);
         If not qq.SavePartial then
            Erase(InFile);
         Goto EExit;
      End;
   Script_success := True;
   EExit:
   NormalCursor;
End;

End.
