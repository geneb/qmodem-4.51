Unit Upld0;

Interface

Uses
   Dos,      TpCrt,    TpWindow, TpString,
   Qcrcs,    OpKey,    Initial,  Batch,
   Files,    Screen,   Comm,     Procs,
   Comm2,    XferStuf, ApTimer;


Procedure Comp_CRC(Bytes, offset : Word);
Function  Send_Header_U(Transfer_Method : Transfer_Type;
                        dfile : String;
                        WaitForResponse : Boolean) : Boolean;
Procedure Get_The_Filename_u(typ    : Integer;
                             FName  : String;
                             Search : Boolean);
Procedure Show_Status(Num, NumBase, Fsize : LongInt);
Function  Get_NAK(Tran : Transfer_Type; Relaxed : Boolean) : Boolean;
Procedure Check_xonxoff(CH : Char);
Function  Check_Comm_Cancel : Boolean;
Procedure Status_Msg(num : Integer);
Function  Get_next_block(Var Blocks : Word) : Boolean;
Procedure Send_Block(num : Integer);
Procedure Send_EOT(really, Complete : Boolean);
Function  Get_Block_Response(Relaxed : Boolean) : Char;
Function  InitialSetup(Protocol : Transfer_Type; { who's making the call}
                       Batch    : Boolean; { is this batch ?         }
                       Var FName : String
                       )        : Boolean; { Success or Fail         }



Implementation


(*
  InitialSetup : Group setup Function to combine code from the different
                 upload modules.

  return codes : True  -  Successful;
                 False -  Failed;
*)

      Function InitialSetup(Protocol  : Transfer_Type; { who's making the call}
                            Batch     : Boolean; { is this batch ?         }
                            Var FName : String
                            )         : Boolean; { Success or Fail         }
      Label
         Ciao;
      Begin
         If Not Batch Then
            Get_The_Filename_u(3, FName,True) { don't allow them }
         Else
            If not (Scripting or Hosting) then
               If not Get_File_Name_Batch('','','') { allow wildcards  }
                  Then goto Ciao
               Else
            Else
               Dfile := Fname;

         If Batch then
            If BatchHead <> NIL then
               Begin
                  Dfile := BatchHead^.Bname;
                  Fname := DFile;
               End
            Else
               Dfile := '';

         If dfile = '' Then
            Begin
               Ciao:
               InitialSetup := False;
               Exit;
            End;

         HiddenCursor;

         If Batch Then
            Begin
               UpBpath := JustPathname(FName);
               {FindFirstD(dfile, Archive + ReadOnly, UpFList);}
               FindFirst(dfile, Archive + ReadOnly, UpFList);
               If DosError <> 0 Then
                  GoTo Ciao;
            End;

         Case Protocol Of
            Zmodem      : Begin
                             Build_Xfer_Screen('U');
                             Show_Protocol('ZMODEM');
                             Logit('++ Protocol : Zmodem');
                          End;
            Ymodem_G    : Begin
                             Build_Xfer_Screen('U');
                             Show_Protocol('Ymodem/G Batch');
                             Logit('++ Protocol : Ymodem/G');
                          End;
            Xmodem_1K_G : Begin
                             Build_Xfer_Screen('U');
                             Show_Protocol('Xmodem-1K/G');
                             Logit('++ Protocol : Xmodem-1K/G');
                             If QuickLearn then
                                WriteLearn('Upload   F '+dfile);
                          End;
            Ymodem      : Begin
                             Build_Xfer_Screen('U');
                             Show_Protocol('Ymodem Batch');
                             Logit('++ Protocol : Ymodem');
                          End;
            Xmodem_Crc  : Begin
                             Build_Xfer_Screen('U');
                             Show_Protocol('Xmodem CRC');
                             Logit('++ Protocol : Xmodem CRC');
                             If QuickLearn then
                                WriteLearn('Upload   C '+dfile);
                          End;
            Xmodem      : Begin
                             Build_Xfer_Screen('U');
                             Show_Protocol('Xmodem');
                             Logit('++ Protocol : Xmodem');
                             If QuickLearn then
                                WriteLearn('Upload   X '+dfile);
                          End;
            Xmodem_1K   : Begin
                             Build_Xfer_Screen('U');
                             Show_Protocol('Xmodem-1K');
                             Logit('++ Protocol : Xmodem-1K');
                             If QuickLearn then
                                WriteLearn('Upload   O '+dfile);
                          End;
         End;
         InitialSetup := True;
      End;                        {InitialSetup}


   Procedure Comp_CRC(Bytes, offset : Word);
   Var
      x : Word;
   Begin
      CRC := 0;
      For x := offset To Bytes Do
         UpdCRC(Byte(block[x]));
      block[Pred(Bytes)] := Chr(Hi(CRC));
      block[Bytes] := Chr(Lo(CRC));
   End;


  Function  Send_Header_U(Transfer_Method : Transfer_Type;
                          dfile : String;
                          WaitForResponse : Boolean) : Boolean;
   Var
      x, y : LongInt;
      C    : Char;
      Temp : String[20];
      S    : LongInt;
      Size : String;
      F    : File;
      ET   : EventTimer;
   Begin
      FillChar(block, 133, #0);   { Blank out Block }
      block[1] := SOH;
      block[2] := #0;
      block[3] := #255;
      If dfile <> '' Then
         Begin
            Temp := JustFilename(dfile);
            Move(Temp[1], block[4], Byte(Temp[0]));
            Assign(F, dfile);
            Reset(F, 1);
            S := FileSize(F);
            Close(F);
            Size := Long2Str(S) + ' ';
            Move(Size[1], block[5 + Byte(Temp[0])], Length(Size));
         End;
      Comp_CRC(133, 4);
      y := 1;
      Status_Msg(7);              {Sending Header}
      Repeat
         Clear_buffer;
         For x := 1 To 133 Do
            Write_Byte(block[x]);
         If Not WaitForResponse Then  {Ymodem G won't need to wait!}
            Begin
               Delay(500);
               Send_Header_U := True;
               Exit;
            End;
         NewTimerSecs(ET,10);
         Repeat
         Until CommPressed Or Keypressed Or TimerExpired(ET);
         Inc(y);
         C := #0;
         If CommPressed Then
            C := Cinkeyz
         Else
            If Keypressed Then
               Begin
                  If ReadKeyA = Esc then
                     C := NAK;
               End;
      Until (C In ['G', 'C', ACK, NAK, CAN]) Or (y > 10);
      If C In ['C', ACK, 'G'] Then
         Begin
            Send_Header_U := True;
         End
      Else
         Begin
            Send_Header_U := False;
         End;
   End;

   Procedure Get_The_Filename_u(typ    : Integer;
                                FName  : String;
                                Search : Boolean);
   Begin
      If Scripting or Hosting Then
         dfile := FName
      Else
         Begin
            dfile := Get_File_Name(AddBackSlash(Upload_Path),
                                   FName, '', typ,
                                   'Upload File Allocation',Search);
            If dfile <> '' Then
               Upload_Path := Last_Path(dfile, Upload_Path);
         End;
      Logit('Upload File ' + dfile);
   End;


   Procedure Show_Status(Num, NumBase, Fsize : LongInt);
   Var
      x              : LongInt;
   Begin
      HiddenCursor;
      Figure_BPS(Fsize);
      Show_Blocks_Rcvd(BlockNum); {really sent in this case}
      Show_Bytes_Rcvd(NumBase);       {same for this one}
      If Stamp_Taken Then
         Show_Time_Elapsed(Elapsed_Online(Time_));
      Show_Error_Count(T_Errors);
      If Num > 0 then
         Begin
            x := trunc(((Min(num, Fsize)*1.0) / Fsize) * 100.0) Div 2;
            Show_Gas_Gauge(x);
         End;
   End;

   Function Get_NAK(Tran : Transfer_Type; Relaxed : Boolean) : Boolean;
   Var
      xx, tt   : LongInt;
      InByte,
      InByte2,
      CH, Rcvd : Char;
      ET       : EventTimer;
   Begin
      InByte2 := #0;
      Status_Msg(6);              {Waiting for NAK}
      Case Tran Of
         Xmodem     : InByte := NAK;
         Xmodem_1K,
         Ymodem     : Begin
                         InByte := 'C';
                         InByte2 := NAK;
                      End;
         Xmodem_1K_G,
         Ymodem_G   : InByte := 'G';
         Xmodem_Crc : InByte := 'C';
      End;                        { case }
      If Relaxed Then
         xx := 120
      Else
         xx := 60;
      tt := (xx + qq.Download_Time);
      NewTimerSecs(ET, tt);
      Repeat
         Rcvd := #255;
         If Keypressed Then
            Begin
               If ReadKeyA = Esc then
                  Rcvd := CAN;
            End
         Else
            If CommPressed Then
               Rcvd := Cinkeyz;

      Until (Rcvd = InByte) Or    { A perfect match   }
            (Rcvd = InByte2) Or   { A perfect match   }
            TimerExpired(ET) Or
            (Rcvd = CAN);         { A Cancel received }

      If TimerExpired(ET) Then
         Write_Byte(^x^x); { Cancel the Upload }

      Status_Msg(99);             {clear it}

      If (Rcvd = InByte) Or (Rcvd = InByte2) Then
         Get_NAK := True
      Else
         Get_NAK := False;
   End;


   Procedure Check_xonxoff(CH : Char);
   Var
      Ch1            : Char;
      xoff           : Boolean;
   Begin
      xoff := False;
      If CH = #19 Then
         Begin
            xoff := True;
            Repeat
               Repeat
               Until CommPressed Or Keypressed;
               If CommPressed Then
                  Begin
                     Ch1 := Cinkeyz;
                     If Ch1 = #17 Then
                        xoff := False;
                  End
               Else
                  If Keypressed Then
                     Begin
                        Ch1 := Char(ReadKeyA);
                        If Ch1 = #17 Then
                           xoff := False;
                     End;
            Until Not xoff;
         End;
   End;

   Function Check_Comm_Cancel : Boolean;
   Var
      CH : Char;
   Begin
      Ch := Cinkeyz;
      Check_Comm_Cancel := (Ch = ^X);
   End;

   Procedure Status_Msg(num : Integer);
   Begin
      Case num Of
         1  : StatusMsg('TRANSFER CANCELLED BY SENDER');
         2  : StatusMsg('ZERO BYTES IN FILE');
         3  : StatusMsg('DISK READ ERROR');
         4  : StatusMsg('TRANSFER CANCELLED BY RECEIVER');
         5  : StatusMsg('FILE TOO LARGE');
         6  : StatusMsg('WAITING FOR NAK');
         7  : StatusMsg('SENDING HEADER');
         8  : StatusMsg('SENDING EOT');
         9  : StatusMsg('SUCCESS');
         10 : StatusMsg('FILE OPEN ERROR');
         11 : StatusMsg('TRANSFER CANCELLED, BAD LINE');
         99 : StatusMsg('');
      End;
      Case num Of
         1, 2, 3, 4,
         5, 10, 11  : Begin
                         Delay(4000);
                         Logit('++ Upload Cancelled.');
                      End;
      End;
   End;

   Function Get_next_block(Var Blocks : Word) : Boolean;
   Var
      Num_Read       : Integer;
   Begin
      BlockRead(InFile, YBlock, Blocks, Num_Read);
      Blocks := Num_Read;
      Get_next_block := IoResult = 0;
   End;

   Procedure Send_Block(num : Integer);
   Begin
      Time_Stamp;
      While (Buffer_Size - BytesQueuedOut < num) and (not Aborted) do
         If Keypressed Then
            Aborted := Check_Keyboard or Aborted;
      If not Aborted then
         Write_Byte3(block, num);
   End;

   Procedure Send_EOT(Really, Complete : Boolean);
   Var
      x, I : Integer;
      CH   : Char;
      ET   : EventTimer;
   Begin
      Close(InFile);
      IO := IoResult;
      I := 0;
      CH := ' ';
      If Really Then
         Repeat
            Status_Msg(8);        {Sending EOT}
            Delay(500);
            Write_Byte(EOT);
            Inc(I);
            NewTimerSecs(ET, 10);
            Repeat
            Until CommPressed Or
                  Keypressed Or
                  TimerExpired(ET);
            If CommPressed Then
               Begin
                  CH := Cinkeyz;
                  If CH = CAN Then
                     Status_Msg(4);
               End;
            If Check_Keyboard then
               Begin
                  Aborted := True;
                  CH := CAN;
                  Status_Msg(11);
               End;
         Until (CH In ['C', ACK, CAN]) Or (I = 6);
      If (CH In ['C', ACK]) Or (Not really) Then
         Begin
            Log_BPSStuff;
            If Complete then
               Begin
                  Status_Msg(9);        {Success}
                  Sound_Completion;
               End;
         End;
   End;

   Function Get_Block_Response(Relaxed : Boolean) : Char;
   Var
      CH      : Char;
      TimeOut : LongInt;
      Ok      : Boolean;
      ET      : EventTimer;
   Begin
      If Relaxed Then
         TimeOut := 30 + qq.Download_Time
      Else
         TimeOut := 10 + qq.Download_Time;
      NewTimerSecs(ET, TimeOut);
      Repeat
         If CommPressed Then
            Begin
               CH := Cinkeyz;
               If CH In [ACK, NAK, CAN, 'C'] Then
                  Begin
                     Get_Block_Response := CH;
                     Exit;
                  End
            End;
         If Keypressed Then
            Aborted := Check_KeyBoard or Aborted;
      Until TimerExpired(ET) Or Aborted;
      Get_Block_Response := ' ';
   End;

End.
