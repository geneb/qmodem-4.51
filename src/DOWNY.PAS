Unit DownY;

Interface

Uses
   Dos,      TpCrt,
   TPString, Initial,
   Files,    Comm,
   Comm2,    Qcrcs,
   Procs,    Group1,
   XferStuf, Downld0;

Procedure Download_Ymodem(Relaxed, Gmode : Boolean);


Implementation


   Procedure Download_Ymodem(Relaxed, Gmode : Boolean);
   Label
      EExit, Er, realdone, Topp;
   Var
      Header_Err     : Integer;
      UsePath        : String;
      F : File of Byte;

   Begin
      TextAttr := qq.Menu;

      Transfer_Method := Xmodem_1K;
      RealSpeed := 1200;
      Rspeed := NewSpeed;
      Speed_X := RealSpeed / Rspeed;
      If Gmode Then tm := Ymodem_G
               Else tm := Ymodem;

      If Scripting or Hosting Then
         UsePath := JustPathname(sFilename)
      Else
         Begin
            UsePath := Get_File_Name(Downld_Path, '', '',
                                     5, 'Download Path Allocation',False);
            If UsePath = '' Then Goto EExit;
            Downld_Path := UsePath;
         End;

     If QuickLearn then
        If Gmode then
           WriteLearn('Download G '+UsePath)
        Else
           WriteLearn('Download Y '+UsePath);

      Build_Xfer_screen('D');
      HiddenCursor;

      If Gmode Then
         Logit('Batch Download Protocol : Ymodem/G')
      Else
         Logit('Batch Download Protocol : Ymodem');

Topp:

      Tot_K := 0;

      Aborted     := False;   NxBlk      := False;   Blocknum    := 1;
      Sec         := 1;       Timeouterr := 0;       Ecount      := 0;
      Shortblk    := 0;       Comperr    := 0;       Longblk     := 0;
      SOHerr      := 0;       resenderr  := 0;       Blocknumerr := 0;
      checksumerr := 0;       BufCnt     := 0;

      Ok := Send_NAK(tm, Aborted);
      { Send out Ymodem NAKs }
      If Not Ok Then
         Goto EExit;

      Header_Err := 0;
      Ok := False;
      Repeat
         StatusMsg('READING HEADER');
         Get_next_block(Xmodem_1K, x, False);
         If block[1] = CAN Then
            Goto Er;   { Cancel the download and erase the file }
         If (Blocknum = 1) And (block[2] = #0) And (CRC = 0) Then
            Begin
               { open the file }
               If Not Gmode Then
                  Write_Byte(ACK);
               x1 := 4;
               dfile := '';
               While block[x1] <> #0 Do
                  Begin
                     dfile := dfile + Upcase(block[x1]);
                     Inc(x1);
                  End;
               Dfile := IBMFilenameFix(dfile);
               If Aborted then
                  Goto EExit;
               If dfile = '' Then
                  Goto RealDone;
               Clear_Status_Fields;

               dfile := Addbackslash(UsePath)+CleanPathName(dfile);
               If Not Open_File_d(dfile, InFile) Then
                  Begin
                     Write_Byte(^X^X^X^X^X^X^H^H^H^H^H^H);
                     StatusMsg('CANNOT CREATE FILE');
                     Delay(1000);
                     Goto EExit;
                  End;

               If Gmode Then
                  Download_Status(dfile, 'Ymodem/G Batch')
               Else
                  Download_Status(dfile, 'Ymodem Batch');

               LDFile := STUpCase(JustFilename(dfile));

               ExpectedSize := 0;
               If block[Succ(x1)] = #0 Then {no filesize passed}
                  ShowPct := False
               Else
                  Begin
                     ShowPct := GetFileSize(Succ(x1));
                     Show_Blocks_Total(BlockSize2(ExpectedSize,1024));
                     Show_Bytes_Total(ExpectedSize);
                  End;
               Ok := True;
            End
         Else
            Begin
               If Header_Err > 5 Then
                  Begin
                     { Invalid Ymodem Header }
                     Error_Msg_d(6);
                     Goto EExit;
                  End
               Else
                  Begin
                     Inc(Header_Err);
                     clear_buffer;
                     Write_Byte(NAK);
                  End;
            End;
      Until Ok;

      Ok := Send_NAK(tm, Aborted);
      { Send out Ymodem NAKs }

      Logit('++ Filename ' + dfile);
      If Ok Then                  { Receive the file }
         Begin
            StatusMsg('');
            Stamp_Taken := False;
            Repeat
               Show_Errors;

               Get_next_block(Xmodem_1K, x, False);

               If Ecount >= 10 Then
                  Aborted := True;   { Abort if too many errors}

               If Not Aborted Then   { Check for EOF, CAN or Errors }
                  Begin
                     If block[1] = CAN Then
                        Goto Er   { Cancel the download and erase the file }
                     Else
                        If block[1] = EOT Then
                           Begin
                              Close_File(Ymodem);
                              If ShowPct then
                                 Begin
                                    Assign(f, AddBackSlash(UsePath) + LDfile);
                                    Reset(f);
                                    Seek(F,ExpectedSize);
                                    Truncate(f);
                                    Close(f);
                                    IO := IOResult;
                                 End;
                              Log_Xfer_d(Longblk, Shortblk, SOHerr, Comperr,
                                         Blocknumerr, Timeouterr, resenderr,
                                         checksumerr, Avg_BPS, Effective_PCT);
                           End
                        Else
                           Begin
                              Good := True;
                              Ok := True;
                              If Gmode Then
                                 Begin
                                    If SOH_OK and
                                       Checksum_OK(Xmodem_1K, True) and
                                       Short_Block_OK(x) Then
                                       Good := Save_Block(Xmodem_1K_G)
                                    Else
                                       Begin
                                          Error_Msg_d(5);
                                          Goto Er;
                                       End;
                                 End
                              Else
                                 Begin
                                    If Timeout_OK(x) Then
                                    If Short_Block_OK(x) Then
                                    If SOH_OK Then
                                    If Resend_Block_OK Then
                                    If Blocknum_OK Then
                                    If Complement_OK Then
                                    If Checksum_OK(Xmodem_1K, True) Then
                                       Good := Save_Block(Xmodem_1K);
                                 End;

                              Figure_BPS(ExpectedSize);

                              If Not Good Then Goto Er;

                              If Not Ok Then Error_NAK;
                           End
                  End
               Else               { Aborted Aborted download }
                  Begin

Er:                  Close(InFile);
                     If not qq.SavePartial then
                        Erase(InFile);
                     IO := IOResult; { in case the file was not open yet...}
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
      Goto Topp;

      RealDone:

      StatusMsg('SUCCESS');
      Delay(300);

      Sound_Completion;
      Script_success := True;

      EExit:
      NormalCursor;
   End;

End.
