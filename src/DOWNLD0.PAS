Unit Downld0;

Interface
Uses
   TpCrt,     TPDos,     TPWindow,  TPString,
   Screen,    Files,     Comm,      Procs,
   Comm2,     Qcrcs,     XferStuf,  Initial,
   ApTimer;


Function  Save_Data_Block(BufCount : Integer) : Integer;
Procedure Close_File(Transfer_Method : Transfer_Type);
Function  Send_NAK(Var Transfer_Method : Transfer_Type;
                   Var Aborted : Boolean) : Boolean;
Procedure Get_next_block(Transfer_Method : Transfer_Type;
                         Var dd          : Integer;
                         Relaxed         : Boolean);
Function  Short_Block_OK(x : Integer)   : Boolean;
Function  SOH_OK : Boolean;
Function  Timeout_OK(x : Integer)   : Boolean;
Function  Resend_Block_OK : Boolean;
Function  Blocknum_OK : Boolean;
Function  Complement_OK : Boolean;
Function  Checksum_OK(Transfer_Method : Transfer_Type; Use_CRC : Boolean) : Boolean;
Function  Save_Block(transfer : Transfer_Type) : Boolean;
Procedure Error_NAK;
Procedure Wait_For_Clean_Line(SendCANS : Boolean);
Procedure CRCBLOCK (Var Block; Num : Word);
Procedure Error_Msg_d(x : Integer);
Procedure Get_File_Name_D(Var dfile : Str64; sFilename : Str64;
                           ins_type : Integer);
Procedure Log_Xfer_d(Longblk, Shortblk, SOHerr,
                      Comperr, Blocknumerr, Timeouterr,
                      resenderr, checksumerr : Integer;
                      Avg_BPS, Effective_PCT : Real);
Function  Open_File_d(var dfile : String; Var InFile : File) : Boolean;
Function  GetFileSize(BlockOffset : Integer) : Boolean;

Var
   Save_RTS : Boolean;
   crc2     : WORD;

Implementation


Function GetFileSize(BlockOffset : Integer) : Boolean;
Var
   S : String[12];
Begin
   S := '';
   While block[BlockOffset] In ['0'..'9'] Do
      Begin
         S := S + block[BlockOffset];
         Inc(BlockOffset);
      End;
   GetFileSize := Str2Long(S, ExpectedSize);
End;



Procedure Error_Msg_d(x : Integer);
Begin
   Case x Of
      1 : StatusMsg('TRANSFER CANCELLED BY SENDER');
      2 : StatusMsg('DISK I/O ERROR');
      3 : StatusMsg('SAVE DATA ERROR');
      4 : StatusMsg('TRANSFER CANCELLED BY RECEIVER');
      5 : StatusMsg('LOST INTERRUPT ERROR');
      6 : StatusMsg('FILE HEADER ERROR');
   End;
   Delay(2000);
   Logit('++ Download Aborted.');
End;


Procedure Get_File_Name_d(Var dfile  : Str64;
                           sFilename : Str64;
                           ins_type  : Integer);
Begin
   If (Scripting or Hosting) Then
      dfile := sFilename
   Else
      Begin
         dfile := Get_File_Name(Downld_Path, sFilename, '',
                                ins_type, 'Download File Allocation',False);
         If dfile <> '' Then
            Downld_Path := Last_Path(dfile, Downld_Path);
      End;
   If dfile <> '' Then
      Logit('Download File ' + dfile);
End;



Procedure Log_Xfer_d(Longblk, Shortblk, SOHerr,
                     Comperr, Blocknumerr, Timeouterr,
                     resenderr, checksumerr : Integer;
                     Avg_BPS, Effective_PCT : Real);
Var
   x : Str5;
Begin
   If Longblk > 0 Then
      Logit('++ Long block errors   : ' + Long2Str(Longblk));
   If Shortblk > 0 Then
      Logit('++ Short block errors  : ' + Long2Str(Shortblk));
   If SOHerr > 0 Then
      Logit('++ SOH errors          : ' + Long2Str(SOHerr));
   If Comperr > 0 Then
      Logit('++ Complement errors   : ' + Long2Str(Comperr));
   If Blocknumerr > 0 Then
      Logit('++ Block number errors : ' + Long2Str(Blocknumerr));
   If Timeouterr > 0 Then
      Logit('++ Time Out errors     : ' + Long2Str(Timeouterr));
   If resenderr > 0 Then
      Logit('++ Resend errors       : ' + Long2Str(resenderr));
   If checksumerr > 0 Then
      Logit('++ Checksum errors     : ' + Long2Str(checksumerr));
   Log_BPSStuff;
End;


Function Open_File_d(Var dfile : String; Var InFile : File) : Boolean;
Var
   Ok : Boolean;
Begin
   If not qq.OverWrite then
      If ExistFile(Dfile) then
         Begin
            If not qq.AutoIncrement then
               Begin
                  Open_File_d := False;
                  Exit;
               End
            Else
               Dfile := IncFileName(Dfile);
         End;
   Assign(InFile, dfile);
   Rewrite(InFile);
   IO := IOResult;
   If IO <> 0 then
      Open_File_d := False
   Else
      Open_File_d := True;
End;


Function Save_Data_Block(BufCount : Integer) : Integer;
Begin

   If CTS_ and not qq.NoCTSDrop then
      Turn_Off_RTS;

   BlockWrite(InFile, Buffer01^[0], BufCount);
   Save_Data_Block := IoResult;

   If CTS_ and not qq.NoCTSDrop then
      Turn_On_RTS;
End;

Procedure Close_File(Transfer_Method : Transfer_Type);
Var
   x  : Integer;
Begin
   IO := Save_Data_Block(BufCnt);
   Close(InFile);
   Write_Byte(ACK);
   If IO <> 0 Then
      Begin
         Error_Msg_d(2);
         If not qq.SavePartial then
            Erase(InFile);
      End
   Else
      Begin
         If Transfer_Method <> Ymodem then
            StatusMsg('SUCCESS');
         Delay(300);
      End;
   If Transfer_Method <> Ymodem then
      Sound_Completion;
End;


Function Send_NAK(Var Transfer_Method : Transfer_Type;
                  Var Aborted : Boolean) : Boolean;
Var
   x1, y1, x : Integer;
   Response  : Char;
   ET        : EventTimer;
Begin
   Response := ' ';            { initial setting }
   x := 1;
   clear_buffer;
   Repeat
      If (Transfer_Method = Xmodem_Crc) And (x > 5) Then
         Transfer_Method := Xmodem;
      If Transfer_Method <> Ymodem Then
         StatusMsg('SENDING NAK #' + Long2Str(x));
      Case Transfer_Method Of
         Xmodem       : Write_Byte(NAK);
         Xmodem_Crc,
         Xmodem_1K,
         Ymodem       : Write_Byte('C');
         Ymodem_G,
         Xmodem_1K_G  : Write_Byte('G');
      End;
      NewTimerSecs(ET, 5);
      Repeat
         If Check_Keyboard Then
            Begin
               Aborted := True;
               Send_NAK := False;
               Error_Msg_D(4);
               Exit;
            End;
      Until Aborted Or CommPressed Or TimerExpired(ET);
      If CommPressed Then
         Begin
            If Transfer_Method In
            [Xmodem, Xmodem_Crc, Xmodem_1K, Xmodem_1K_G,
             Ymodem_G, Ymodem] Then
               Begin
                  Send_NAK := True;
                  StatusMsg('');
                  Exit;
               End
            Else
               Response := Cinkeyz;
         End;
      Inc(x);
   Until (x >= 20) Or (Response In [ACK, CAN]);
   If (x <= 20) And (Response = ACK) Then
      Send_NAK := True
   Else
      Send_NAK := False;
End;

{$F-}
Function Cinkey2     (Var Block; d, max : Word) : Word; External;
Function Cinkey2_ISI (Var Block; d, max : Word) : Word; External;
{$L Cinkey2}
{$F+}

Procedure CRCBLOCK (Var Block; Num : Word); External;
{$L crcblock}


Procedure Get_next_block(Transfer_Method : Transfer_Type;
                         Var dd          : Integer;
                         Relaxed         : Boolean);
Var
   CutoffX : LongInt;
   x : Integer;
   ET : EventTimer;
Begin
   dd := 0;
   CRC := 0;
   NewTimerSecs(ET,10);
   While (Not TimerExpired(ET)) And (Not Aborted) And (dd = 0) Do
      Begin
         { Get the first Byte }
         If CommPressed Then
            Begin
               Inc(dd);
               block[1] := Cinkeyz;
               Time_Stamp;
               Case block[1] Of
                  EOT : Begin
                           Cutoff := 0;
                           Exit;
                        End;
                  CAN : Begin
                           Aborted := True;
                           Error_Msg_D(1);
                           Exit;
                        End;
                  STX : Begin {Ymodem / Ymodem-G}
                           Block_Bytes := 1029;
                           Show_Block_Size(1024);
                           Cutoff := Round(33.0 * Speed_X);
                        End;
                  SOH : Begin
                           Show_Block_Size(128);
                           Case Transfer_Method Of
                              Xmodem : Begin
                                          Cutoff := Round(25.5 * Speed_X);
                                          Block_Bytes := 132;
                                       End;
                              Xmodem_Crc,
                              Xmodem_1K,
                              Xmodem_1K_G : Begin
                                           Cutoff := Round(25.5 * Speed_X);
                                           Block_Bytes := 133;
                                        End;
                           End; { case }
                        End;
               Else            { Must be an error block }
                  Case Transfer_Method Of
                     Xmodem : Begin
                                 Cutoff := Round(25.5 * Speed_X);
                                 Block_Bytes := 132;
                              End;
                     Xmodem_Crc : Begin
                                     Cutoff := Round(25.5 * Speed_X);
                                     Block_Bytes := 133;
                                  End;
                     Xmodem_1K,
                     Xmodem_1K_G : Begin
                                  Cutoff := Round(33.0 * Speed_X);
                                  Block_Bytes := 1029;
                               End;
                  End;         { case }
               End;            { case }
            End;
         If Check_Keyboard then
            Begin
               Aborted := True;
               Error_Msg_D(4);
               Exit;
            End;
      End;

   If Relaxed Then
      Cutoff := Cutoff + 30;
   CutoffX := (Cutoff + qq.Download_Time);

   { Get the rest of the Block }

   NewTimerSecs(ET, CutOffX);
   While (Not TimerExpired(ET)) And (dd < Block_Bytes) And (Not Aborted) Do
      Begin
         If CommPressed then
            While CommPressed and (dd < Block_Bytes) do
               Begin
                  {$IfDef ISI}
                  If qq.Use_ISI then
                     dd := Cinkey2_ISI(Block,dd,Block_Bytes-dd)
                  Else
                  {$EndIf}
                     dd := Cinkey2(Block,dd,Block_Bytes-dd);
                  {Fasttext(Long2Str(Block_Bytes)+' '+
                            Long2Str(dd)+' '+
                            Long2Str(Crc)+'    ',1,60);}
                  {delay(10);}
               End;
         If Keypressed then
            If Check_Keyboard then
               Begin
                  Aborted := True;
                  Error_Msg_D(4);
                  Exit;
               End;
      End;
   If Transfer_Method = Xmodem then
      Begin
         For x := 4 to 131 do
            CRC := (CRC+ord(Block[x])) and $FF;
         {Fasttext(Long2Str(Block_Bytes)+' '+
                   Long2Str(dd)+' '+
                   Long2Str(Crc)+'  ',2,60);}
         {Delay(10);}
      End
   Else
      CrcBlock(Block[4],dd-3);
End;


Function Short_Block_OK(x : Integer)   : Boolean;
Begin
   If (x < Block_Bytes) And (x > 0) Then
      Begin
         StatusMsg('SHORT BLOCK #' + Long2Str(Blocknum));
         Ok := False;
         Inc(Ecount);
         Inc(Shortblk);
         Short_Block_OK := False;
      End
   Else
      Short_Block_OK := True;
End;

Function SOH_OK : Boolean;
Begin
   If Not(block[1] In [SOH, STX]) Then
      Begin
         Ok := False;
         StatusMsg('HEADER ERROR IN BLOCK #' + Long2Str(Blocknum));
         Inc(Ecount);
         Inc(SOHerr);
         SOH_OK := False;
      End
   Else
      SOH_OK := True;
End;

Function Timeout_OK(x : Integer)   : Boolean;
Begin
   If x = 0 Then
      Begin
         Ok := False;
         StatusMsg('TIMEOUT');
         Inc(Ecount);
         Inc(Timeouterr);
         Timeout_OK := False;
      End
   Else
      Timeout_OK := True;
End;

Function Resend_Block_OK : Boolean;
Begin
   If Ord(block[2]) = Pred(Sec) Then
      Begin
         Ok := False;
         StatusMsg('DUPLICATE BLOCK #' + Long2Str(Blocknum));
         Inc(resenderr);
         Write_Byte(ACK);
         NxBlk := True;
         Resend_Block_OK := False;
      End
   Else
      Resend_Block_OK := True;
End;

Function Blocknum_OK : Boolean;
Begin
   If Sec <> Ord(block[2]) Then
      Begin
         Ok := False;
         StatusMsg('BAD BLOCK NUMBER IN BLOCK #' + Long2Str(Blocknum));
         Inc(Ecount);
         Inc(Blocknumerr);
         Blocknum_OK := False;
      End
   Else
      Blocknum_OK := True;
End;

Function Complement_OK : Boolean;
Begin
   If (Sec Xor 255) <> Ord(block[3]) Then
      Begin
         Ok := False;
         StatusMsg('COMPLIMENT BYTE BAD IN BLOCK #' + Long2Str(Blocknum));
         Inc(Ecount);
         Inc(Comperr);
         Complement_OK := False;
      End
   Else
      Complement_OK := True;
End;

Function Checksum_OK(Transfer_Method : Transfer_Type; Use_CRC : Boolean) : Boolean;
Var
   Check : Boolean;
   x, q  : Integer;

   Procedure Whoops;
   Begin
      Ok := False;
      Inc(Ecount);
      Inc(checksumerr);
      If Use_CRC Then StatusMsg('CRC ERROR IN BLOCK #' + Long2Str(Blocknum))
                 Else StatusMsg('CHECKSUM ERROR IN BLOCK #' + Long2Str(Blocknum));
      DELAY(2000);
      Check := False;
   End;

Begin
   Check := True;
   If Use_CRC Then
      Begin
         If CRC <> 0 Then Whoops
      End
   Else
      Begin
         If (CRC And 255) <> Ord(block[132]) Then Whoops
      End;
   Checksum_OK := Check;
End;

Function Save_Block(transfer : Transfer_Type) : Boolean;
Var
   NumBytes       : Integer;
   Check          : Boolean;
Begin
   Check := True;
   Case Transfer Of
      Xmodem_1K_G : ;
      Else Begin
              clear_buffer;
              Write_Byte(ACK);
           End;
   End;

   Case block[1] Of
      SOH : NumBytes := 128;
      STX : NumBytes := 1024;
      Else  NumBytes := 0;
   End;

   Move(block[4], Buffer01^[BufCnt*128], NumBytes);

   Case block[1] Of
      SOH : Begin
               Inc(BufCnt);
               Tot_K := Tot_K + 128;
            End;
      STX : Begin
               BufCnt := BufCnt + 8;
               Tot_K := Tot_K + 1024;
            End;
   End;

   If BufCnt = qqMaxBuf Then
      Begin
         IO := Save_Data_Block(BufCnt);
         If IO <> 0 Then
            Begin
               Beep;Beep;
               Check := False;
               Close(InFile);
               IO := IoResult;
               If not qq.SavePartial then
                  Erase(InFile);
               IO := IoResult;
               Error_Msg_d(3);
               clear_buffer;
               Write_Byte(^x^x);
               Save_Block := False;
               Exit;
            End;
         BufCnt := 0;
      End;
   Ecount := 0;
   Inc(Blocknum);
   Sec := 255 And (Succ(Sec));
   Save_Block := Check;
End;

Procedure Error_NAK;
Begin
   If Not NxBlk Then
      Begin
         If Ecount > 4 Then
            Delay(500);
         clear_buffer;
         Write_Byte(NAK);
      End
   Else
      NxBlk := False;
End;

Procedure Wait_For_Clean_Line(SendCANS : Boolean);
Var
   Ch : Char;
Begin
   Flush_KBD;
   Repeat
      If SendCANS then
         Begin
            Write_Byte(^X^X^X^X^X^X^H^H^H^H^H^H);
            delay(500);
         End;
      While CommPressed Do
         CH := Cinkeyz;
      Delay(500);
   Until Not CommPressed or KeyPressed;
   Flush_KBD;
End;

End.
