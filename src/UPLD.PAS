Unit Upld;

Interface

Uses
   Dos,       TpCrt,
   TPString,  TpEdit,
   Emuls,     Initial,
   Comm,      Comm2,
   {$IFDEF UseMouse}
   TpMouse,
   {$ENDIF}
   Button,    Files,
   QShell,    XferStuf,
   Procs,     Group1,
   Group02,   Batch,
   Screen,    Upld0;



Procedure Upload(FName     : String;
                 menu_num,
                 Protocol  : Char);


Implementation

Uses TPZ;

Var
   Fsize : LongInt;
   Tot_KF : LongInt;
   SaveFileMode : Byte;

   Procedure Upload(FName     : String;
                    menu_num,
                    protocol  : Char);




(*
  FlushOutputBuffer : Keeps the Interrupt driven transmit buffer running
                      at the end of a file upload.  The serial port may
                      go to sleep and this prevents that from happening.
*)

   Procedure FlushOutputBuffer(Size, SizeF, Fsize : LongInt);
   Begin
      Repeat
         Show_Status(Size, SizeF, Fsize);
         Delay(50);
      Until (BytesQueuedOut = 0) Or Keypressed; { Send all data }
   End;


   Procedure Check_Keyboard_Abort;
   Begin
      If Keypressed then
         If Check_Keyboard then
            Begin
               Status_Msg(1);
               Aborted := True;
            End;
   End;


   Procedure Check_Error_Count_Abort;
   Begin
      If Errors > 9 then
         Begin
            Status_Msg(11);
            Aborted := True;
         End;
   End;

   Procedure Check_Com_Cancel_Abort;
   Begin
      If CommPressed Then
         If Check_Comm_Cancel then
            Begin
               Status_Msg(4);
               Aborted := True;
            End;
   End;


   Procedure Check_For_Aborts;
   Begin
      Check_Keyboard_Abort;
      Check_Error_Count_Abort;
      Check_Com_Cancel_Abort;
   End;


   Function Do_Block_Check(Size : Integer) : Boolean;
   Var
      L : LongInt;
   Begin
      tblks := Blocksize(dfile, Size, L); { Get the Blocksize }
      If tblks < 1 Then        { Zero Blocks Error }
         Begin
            Status_Msg(2);
            Do_Block_Check := False;
            Exit;
         End;
      Do_Block_Check := True;

      Clear_Status_Fields;
      Show_Gas_Gauge(0);
      Show_Filename(dfile);
      Show_Bytes_Total(L);
      Show_Block_Size(Size);
      Show_Blocks_Total(tblks);
   End;


   Function Reset_File : Boolean;
   Var
      f2 : File of Byte;
   Begin
      Assign(InFile, dfile);
      Reset(InFile);           { Open the file }
      IO := IoResult;
      If IO <> 0 Then
         Begin
            Status_Msg(10);    {File open error}
            Reset_File := False;
            Exit;
         End;
      Assign(f2, dfile);
      Reset(f2);
      Fsize := FileSize(f2);
      Close(f2);
      IO := IOResult;
      Reset_File := True;
   End;


   Procedure Write_Cancel;
   Begin
      Write_Byte(^x^x^x^x^x^x^H^H^H^H^H^H);
   End;


   Procedure Upload_Ymodem(Use_G : Boolean);
   Label
      Err2, NextFile, EExit, BatchTop;
   Var
      Ok             : Boolean;
      Pcall          : Transfer_Type;
      SaveDfile : String;
      xch : Char;
   Begin
      If Use_G then Pcall := Ymodem_G
               else Pcall := Ymodem;
      If Use_G then xch   := 'G'
               else xch   := 'Y';

      If Not InitialSetup(Pcall, True, FName) Then
         GoTo EExit;

      If QuickLearn then
         WriteLearn('Upload   '+xch+' _ ;Batch files continued on next line(s)');


   BatchTop:

      Show_Filename(UpFList.Name);

      If UpBpath <> '' Then
         dfile := AddBackSlash(UpBpath) + UpFList.Name
      Else
         dfile := UpBpath + UpFList.Name;
      Logit('++ File '+dfile);

      SaveDfile := dfile;

      If Not Do_Block_Check(1024) Then
         GoTo NextFile;

      If Not Reset_File Then
         GoTo EExit;

      Errors      := 0;
      I           := 8;
      InByte      := ' ';
      Block_Bytes := 1029;
      Blocknum    := 0;
      Aborted     := False;
      T_Errors    := 0;
      Tot_K       := 0;
      Tot_KF      := 0;
      Stamp_Taken := False;

      Ok := Get_NAK(Pcall, False);
      If Not Ok Then
         GoTo EExit;

      Ok := Send_Header_U(Pcall, dfile, true);
      If Not Ok Then
         GoTo EExit; { Header Block was Ignored }

      If Pcall <> Ymodem_G then
         Begin
            Ok := Get_NAK(Pcall, False);
            If Not Ok Then
               GoTo EExit;
         End;

      Status_Msg(99);

      While Not EOF(InFile) Do
         Begin

            Inc(Blocknum);

            Check_For_Aborts;

            If Aborted Then
               Begin
                  Delay(1500);
                  Clear_Buffer;
                  Write_Cancel;
                  GoTo EExit;
               End;

            { Put together a new Packet }
            FillChar(YBlock, 1024, #0);
            If Not Get_next_block(I) Then
               Begin
                  Status_Msg(3);
                  GoTo EExit;
               End;

            Sec := Blocknum And 255;
            Block[1] := STX;
            Block[2] := Chr(Sec);
            Block[3] := Chr(Sec Xor 255);
            Move(YBlock, block[4], 1024);
            Block[1028] := #0;
            Block[1029] := #0;
            Comp_CRC(1029, 4);
            If Use_G then
               Begin
                  Send_Block(Block_Bytes);
               End
            Else
               Repeat
                  Send_Block(Block_Bytes);
                  Repeat
                     BT := Get_Block_Response(False);
                     If BT = CAN Then
                        Begin
                           Status_Msg(4);
                           GoTo EExit;
                        End;
                     Check_Keyboard_Abort;
                     If BT <> ACK Then
                        Begin
                           Errors := Succ(Errors);
                           T_Errors := Succ(T_Errors);
                           If Errors > 4 then
                              Delay(3000);
                           Show_Status(Tot_K, Tot_KF, Fsize);
                        End;
                     Check_Error_Count_Abort;
                  Until Aborted Or (BT In [ACK, NAK, 'C']);
                  If Aborted Then
                     Begin
                        Clear_Buffer;
                        Write_Cancel;
                        GoTo EExit;
                     End;
               Until BT = ACK;
            Inc(Tot_K, 1029);
            Inc(Tot_KF, 1024);
            Show_Status(Tot_K, Tot_KF, Fsize);
            Errors := 0;
         End;

      If qq.UseHighSpeed Then
         FlushOutputBuffer(Tot_K, Tot_KF, Fsize);

      Show_Status(Tot_K, Tot_KF, Fsize);

      Script_success := False;

      If Not Aborted Then
         Begin

            Send_EOT(True, False);

            NextFile:
            FindNext(UpFList);
            If DosError = 0 Then
               Begin
                  If QuickLearn then
                     WriteLearn('           '+SaveDfile+' _');
                  Goto BatchTop;
               End;

            If BatchHead^.Next <> Nil then
               Begin
                  BatchHead := BatchHead^.Next;
                  dfile := BatchHead^.Bname;
                  FindFirst(dfile, Archive + ReadOnly, UpFList);
                  If DosError <> 0 Then
                     GoTo NextFile;
                  If QuickLearn then
                     WriteLearn('           '+SaveDfile+' _');

                  {point to next file entry(s)}

                  UpBpath := JustPathName(dfile);
                  Goto BatchTop;
               End
            Else
               Begin
                  If QuickLearn then
                     WriteLearn('           '+SaveDfile);
                  Ok := Get_NAK(Pcall, False);
                  If Not Ok Then GoTo EExit;
                  Ok := Send_Header_U(Pcall, '',False);
                  Status_Msg(9);        {Success}
                  Sound_Completion;
               End;

            Script_success := True;
         End;

      EExit:

      Close(InFile);
      IO := IoResult;
      Clear_Buffer2;
   End;


   Procedure Upload_Xmodem(Use_CRC, Relaxed_Timing, Use_1K, Use_G : Boolean);
   Label
      EExit;
   Var
      Ok    : Boolean;
      x     : LongInt;
      Pcall : Transfer_Type;
      BaseSize : Word;
   Begin
      If Use_1K Then
         If Use_G Then
            Pcall := Xmodem_1K_G
         Else
            Pcall := Xmodem_1K
      Else
         If Use_CRC Then
            Pcall := Xmodem_Crc
         Else
            Pcall := Xmodem;

      If Not InitialSetup(Pcall, False, FName) Then
         GoTo EExit;

      If Use_1K then
         Begin
            BaseSize := 1024;
            I := 8;
         End
      Else
         Begin
            BaseSize := 128;
            I := 1;
         End;

      If Not Do_Block_Check(BaseSize) Then
         GoTo EExit;

      If Not Reset_File Then
         GoTo EExit;

      Errors   := 0;
      InByte   := ' ';
      Blocknum := 0;
      Aborted  := False;
      Tot_K    := 0;
      Tot_KF   := 0;
      T_Errors := 0;
      Stamp_Taken := False;

      Case Pcall Of
         Xmodem_1K,
         Xmodem_1K_G : Block_Bytes := 1029;
         Xmodem_CRC  : Block_Bytes := 133;
         Xmodem      : Block_Bytes := 132;
      End;

      If Not Get_NAK(Pcall, relaxed_timing) Then
         Begin
            Status_Msg(1);    {Abort by SENDER}
            GoTo EExit;
         End;

      Status_Msg(99);

      Clear_Buffer;
      While Not EOF(InFile) Do
         Begin

            Check_For_Aborts;

            If Aborted Then
               Begin
                  Delay(1500);
                  Clear_buffer;
                  Write_Cancel;
                  GoTo EExit;
               End
            Else
               Begin           { put together a new packet }
                  Inc(Blocknum);
                  FillChar(YBlock, 1024, #0);

                  Ok := Get_next_block(I);
                  If Not Ok Then
                     Begin
                        Status_Msg(3);
                        GoTo EExit;
                     End;

                  Sec := Blocknum And 255;
                  If Pcall in [Xmodem_1K, Xmodem_1K_G] then
                     block[1] := STX
                  Else
                     block[1] := SOH;
                  block[2] := Chr(Sec);
                  block[3] := Chr(Sec Xor 255);
                  Move(YBlock, block[4], BaseSize);
                  block[BaseSize+4] := #0;
                  block[BaseSize+5] := #0;
                  If Use_CRC or Use_1K Then
                     Comp_CRC(BaseSize+5, 4)
                  Else
                     Begin
                        q := 0;
                        For x := 4 To 131 Do
                           q := q + Ord(block[x]);
                        q := q And 255;
                        block[132] := Chr(q);
                     End;
                  If Use_G then
                     Begin
                        Send_Block(Block_Bytes);
                     End
                  Else
                     Repeat
                        Send_Block(Block_Bytes);
                        Repeat
                           BT := Get_Block_Response(relaxed_timing);
                           If BT = CAN Then
                              Begin
                                 Status_Msg(4);
                                 GoTo EExit;
                              End;
                           If BT <> ACK Then
                              Begin
                                 Errors := Succ(Errors);
                                 T_Errors := Succ(T_Errors);
                                 Show_Status(Tot_K, Tot_KF, Fsize);
                              End;
                           Check_Keyboard_Abort;
                           Check_Error_Count_Abort;
                        Until Aborted Or (BT In [ACK, NAK, 'C']);
                        If Aborted Then
                           Begin
                              Delay(2000);
                              Clear_Buffer;
                              Write_Cancel;
                              GoTo EExit;
                           End;
                     Until BT = ACK;
                  Inc(Tot_K,Block_Bytes);
                  Inc(Tot_KF,BaseSize);
                  Show_Status(Tot_K, Tot_KF, Fsize);
                  Errors := 0;
               End;
         End;

      If qq.UseHighSpeed then
         FlushOutputBuffer(Tot_K, Tot_KF, Fsize);

      If Not Aborted Then
         Begin
            Send_EOT(True, True);
            Script_success := True;
         End;

EExit:
      Close(InFile);
      IO := IoResult;
   End;


   Procedure Upload_Ascii;
   Var
      InFile   : Text;
      III      : File of Byte;
      BytesSoFar,
      Xsize    : LongInt;
      Done     : Boolean;
      tmp      : String;
      X1, X2,
      Y1, Y2,
      X3, X, Y : Integer;
      S,  T    : String;
      Ch       : Char;
   Label
      Eexit, DoSave;

      Procedure Show_Incoming_Char(Var CH : Char);
      Const
         IsXoff : Boolean = False;
      Begin
         While CommPressed or (IsXoff and (not Keypressed)) Do
            If CommPressed then
               Begin

                  CH := Cinkeyz;

                  If Xon_Xoff Then
                     Begin
                        If Ch = ^S then
                           Begin
                              IsXoff := True;
                              Ch := #0;
                           End
                        Else
                           If Ch = ^Q then
                              Begin
                                 IsXoff := False;
                                 Ch := #0;
                              End;
                     End;

                  If CH = ^X Then
                     Begin
                        Display_Status(' Cancelled by Receiver ');
                        Done := True;
                        Exit;
                     End;

                  OutKey(Ch);

                  If Char(qq.ASCII_Pace_Ch) <> #0 Then
                     If Char(qq.ASCII_Pace_Ch) = Ch Then
                        Exit;
            End;
      End;


      Procedure UpAsciiError(IO : Integer);
      Begin
         Setwindow2(16,10,63,13,'',false);
         TextAttr := qq.Menu;
         Writeln(' Error Opening/Reading file.  Upload aborted.');
         Write  (' ');
         Fasttext(Long2Str(IO),13,55);
         If Scripting Then Delay(2000)
                      Else KeyContinue(qq.Menu2);
         Restore_Screen;
      End;

      Procedure D_Status;
      Begin
         Display_Status(' Uploading ' + JustFileName(dfile) + '  Sent = '+Pad(Long2Str(BytesSoFar),6) +
                        '  Complete = '+ Long2Str(Round((BytesSoFar / Xsize)*100.0))+
                        '%   ESC-Terminate ');
      End;


   Begin
      Script_Success := False;
      Pop_Window;
      Restore_Screen;
      Get_The_Filename_u(3, FName,True);
      If Split then
         Begin
            Split_Window_Top;
         End
      Else
         Begin
            Window(1,1,ScreenWidth, ScreenHeight-1);
         End;
      Push_Status;
      If dfile <> '' Then
         Begin
            BytesSoFar := 0;
            Assign (III, dfile);
            Reset (III);
            Xsize := FileSize(III);
            Close (III);
            D_Status;
            Assign(InFile, dfile);
            Reset(InFile);
            IO := IoResult;
            If IO <> 0 then
               Begin
                  UpAsciiError(IO);
                  Goto EExit;
               End;
            Logit('++ Protocol : ASCII');
            If QuickLearn then
               WriteLearn('Upload   A '+Dfile);

            Clear_Buffer;
            Done := False;
            Repeat
               s := '';
               Repeat
                  Read(InFile,Ch);
                  Inc(BytesSoFar);
                  IO := IOResult;
                  If IO <> 0 then
                     Begin
                        UpAsciiError(IO);
                        Goto EExit;
                     End;
                  S := S + Ch;

               Until (Ch = Char(qq.ASCII_EOL_Ch)) or
                     (Length(S) = 240) or
                     EOF(InFile);

               D_Status;

               If qq.ASCII_Out_Xlate then
                  For x := 1 to Length(S) do
                     Translate_Out(S[x]);

               If qq.ASCII_Out_Expand then
                  If S[1] in [#10,#13,Char(qq.ASCII_EOL_Ch)] Then
                     S := ' ' + S;

               If (qq.ASCII_Out_CR > 0) then
                  Begin
                     Case qq.ASCII_Out_CR of
                        1 : Begin
                               t := '';
                               for x := 1 to Length(S) do
                                  If s[x] <> #13 then
                                     t := t + s[x];
                               s := t;
                            End;
                        2 : Begin
                               t := '';
                               for x := 1 to Length(S) do
                                  If s[x] <> #13 then
                                     t := t + s[x]
                                  Else
                                     t := t + s[x] + #10;
                               s := t;
                            End;
                     End;
                  End;

               If (qq.ASCII_Out_LF > 0) then
                  Begin
                     Case qq.ASCII_Out_LF of
                        1 : Begin
                               t := '';
                               for x := 1 to Length(S) do
                                  If s[x] <> #10 then
                                     t := t + s[x];
                               s := t;
                            End;
                        2 : Begin
                               t := '';
                               for x := 1 to Length(S) do
                                  If s[x] <> #10 then
                                     t := t + s[x]
                                  Else
                                     t := t + #13 + s[x];
                               s := t;
                            End;
                     End;
                  End;

               For x := 1 to Length(S) do
                  Begin
                     Write_Byte(S[x]);
                     If Echo then
                        OutKey(S[x]);
                     If qq.ASCII_Pace_Speed > 0 then
                        Delay (qq.ASCII_Pace_Speed);
                  End;

               If qq.ASCII_Pace_Ch > 0 then
                  Repeat
                     Show_Incoming_Char(Ch);
                  Until (Ch = Char(qq.ASCII_Pace_Ch)) or KeyPressed
               Else
                  Show_Incoming_Char(CH);

               D_Status;

               If Keypressed Then
                  Begin
                     A := Char(ReadKeyA);
                     If A = #27 Then
                        Begin
                           Done := True;
                           Display_Status(' Cancelled by Sender ');
                        End;
                  End;

            Until Done or EOF(InFile);
            Delay(3000);
            Repeat
               If CommPressed Then
                  Show_Incoming_Char(CH);
               Delay(1500);
            Until Not CommPressed;
            If Noise Then
               Sound_Completion;
            Display_Status(' File Transmitted ');
            Logit('++ Transfer Successful.');
            Script_Success := True;
            EExit:
            Close(InFile);
            IO := IOResult;
            Pop_Status;
            Save_Screen(1,1,3,3);
            Push_Window;
         End;
   End;


   Procedure Upload_External(CH : Char; PauseAfter : Boolean);
   Var
      Temp    : String;
      num, x  : LongInt;
      rc      : Integer;
   Begin
      Temp := '';
      num := Is_External(CH);

      Get_The_Filename_u(4, FName,False);
      If dfile = '' Then
         Exit;

      Logit('Upload Executing ' + qq.xfer_send_bat[num]);
      If QuickLearn then
         WriteLearn('Upload   '+CH+' '+Dfile);

      clear_buffer;
      dfile := STLoCase(dfile);
      Temp := Temp + Long2Str(NewSpeed)+' '+
                     Long2Str(qq.Commport)+' '+
                     Long2Str(DCE_Speed)+ ' '+
                     STLoCase(dfile);

      RC := Shell(qq.xfer_send_bat[num] + ' ' + Temp,
                  'Executing ' + qq.xfer_send_bat[num],
                  ''+'', True, False,False);
      Clear_Buffer;
      If RC <> 0 Then
         Begin
            writelnb('Error loading ' + qq.xfer_send_bat[num] + '.  RC='+Long2Str(RC));
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

   Var
      Internals, Externals : Set of Char;
      Mflag : Boolean;
      ul3 : Word;

   Begin
      GetDir(0, UpSaveDir);
      IO := IoResult;
      Tot_K := 0;
      Rspeed := NewSpeed * 1.0;
      Avg_BPS := 0.0;
      Effective_PCT := 0.0;
      Stamp_Taken := False;
      dfile := '';
      Externals := [];

      {$IfDef GG}

         Internals := [#13, #27, 'A', 'X'];
         wx := -5;
         ul3 := 5;

      {$Else}

         Internals := [#13, #27, 'A', 'X', 'C', 'R', 'O', 'Y', 'G', 'F', 'Z'];
         If CTS_ Then
            wx := 2
         Else
            Begin
               Internals := Internals - ['G', 'F'];
               wx := 0;
            End;

         If qq.Total_Xfers > 0 Then
            ul3 := 11 + wx + qq.Total_Xfers
         Else
            ul3 := 10 + wx;

         For x := 1 To qq.Total_Xfers Do
            Externals := Externals + [qq.Xfer_select_chr[x]];

      {$EndIf}


      If FName = '' Then
         FName := L_S_Filename;

      If Scripting or Hosting Then
         Script_success := False
      Else
         Begin
            Setwindow2(28, 1, 53, ul3, ' Upload Protocols ',false);
            HelpTopic := 14;
            TextAttr := qq.menu2;
            PushButtonList;

            {$IFDEF UseMouse}
            Mflag := MouseInstalled and MouseCursorOn;
            {$ENDIF}

            If Not ('A' in Externals) then
               AddButton(1,2,1,1,qq.Menu,qq.Menu2, 'A - Ascii',    ord('A'))
            Else
               FastwriteWindow('Ascii',1,6,qq.menu2);
            If Not ('X' in Externals) then
               AddButton(2,2,1,1,qq.Menu,qq.Menu2, 'X - Xmodem',   ord('X'))
            Else
               FastwriteWindow('Xmodem',2,6,qq.menu2);

            {$IfNDef GG}

            If Not ('C' in Externals) then
               AddButton(3,2,1,1,qq.Menu,qq.Menu2, 'C - Xmodem CRC', ord('C'))
            Else
               FastwriteWindow('Xmodem CRC',3,6,qq.menu2);
            If Not ('R' in Externals) then
               AddButton(4,2,1,1,qq.Menu,qq.Menu2, 'R - Xmodem Relaxed', ord('R'))
            Else
               FastwriteWindow('Xmodem Relaxed',4,6,qq.menu2);
            If Not ('O' in Externals) then
               AddButton(5,2,1,1,qq.Menu,qq.Menu2, 'O - Xmodem-1K',   ord('O'))
            Else
               FastwriteWindow('Xmodem-1K',5,6,qq.menu2);
            If Not ('Y' in Externals) then
               AddButton(6,2,1,1,qq.Menu,qq.Menu2, 'Y - Ymodem Batch',   ord('Y'))
            Else
               FastwriteWindow('Ymodem Batch',6,6,qq.menu2);
            If Not ('Z' in Externals) then
               AddButton(7,2,1,1,qq.Menu,qq.Menu2, 'Z - Zmodem Batch',   ord('Z'))
            Else
               FastwriteWindow('Zmodem Batch',7,6,qq.menu2);
            If CTS_ Then
               Begin
                  If Not ('F' in Externals) then
                     AddButton(8, 2,1,1,qq.Menu,qq.Menu2, 'F - Xmodem-1K/G', ord('G'))
                  Else
                     FastwriteWindow('Xmodem-1K/G',8,6,qq.menu2);
                  If Not ('G' in Externals) then
                     AddButton(9 ,2,1,1,qq.Menu,qq.Menu2, 'G - Ymodem/G Batch', ord('G'))
                  Else
                     FastwriteWindow('Ymodem/G Batch',9 ,6,qq.menu2);
               End;

            {$EndIf} {GG}


            {$IFDEF UseMouse}
            If MouseInstalled then
               AddButton(ul3-1,15,2,2,qq.WindF, qq.WindF, '<F1=Help>',$3B00);
            {$ENDIF}

            {$IfNDef GG}
            If qq.Total_Xfers > 0 Then
               Begin
                  FastWrite('突様様様 External 様様様裕',9+wx, 28, qq.Windf);
                  For x := 1 To qq.Total_Xfers Do
                     AddButton(8+wx+x,2,1,1,qq.Menu,qq.Menu2,
                               qq.Xfer_select_chr[x]+' - '+qq.xfer_label[x],
                               ord(qq.Xfer_select_chr[x]));
                  GotoXY(1,9 + wx + qq.Total_Xfers);
               End
            Else
            {$EndIf}
               GotoXY(1, 8 + wx);

            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  MouseWindow(28, 1, 53, ul3);
                  If not Mflag then
                     ShowTheMouse;
               End;
            {$ENDIF}

            TextAttr := qq.Menu;
            Write(' Your Choice ? ');
            Display_Status(' LETTER-Select a Protocol for the File Transfer   ESC-Exit ');
            Write(Protocol + #8);
            Repeat
               CheckForAButton(True);
               If KeyPressed then
                  Menu_Num := Upcase(Char(ReadKeyA));
            Until Menu_Num In Internals+Externals;
            If Menu_num = #13 Then
               Menu_num := Protocol;
            PopButtonList;
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  FullMouseWindow;
                  If not Mflag then
                     HideTheMouse;
               End;
            {$ENDIF}
            Restore_Screen;
         End;

      If (Menu_num <> #27) And (Menu_num <> ' ') Then
         Begin
            InUpload := True;
            Push_window;
            Menu_num := Upcase(Menu_num);
            xpr := Menu_num;
            HelpTopic := 0;
            Check_Parity;
            OnOffXferState := Online;
            SaveFileMode := FileMode;
            If Lo(DosVersion) >= 3 then        {4.2F!!}
               FileMode := $40;                {4.2F!!}
            If Menu_Num in Externals then
               Upload_External(Upcase(Menu_num),not (Scripting or Hosting))
            Else
               Begin
                  Case Menu_num Of
                     'A' : Begin
                              Reset_Parity;
                              Upload_ASCII;
                           End;
                                        { CRC |Relax|Use1K|Use/G}
                                        {-----|-----|-----|-----}
                     'X' : Upload_Xmodem(False,False,False,False);
                     {$IfNDef GG}
                     'C' : Upload_Xmodem(True, False,False,False);
                     'R' : Upload_Xmodem(False,True, False,False);
                     'O' : Upload_Xmodem(True, False,True, False);
                     'F' : Upload_Xmodem(True, False,True, True);
                     'Y' : Upload_Ymodem(                  False);
                     'G' : Upload_Ymodem(                  True);
                     'Z' : OK := Zmodem_Send(Fname);
                     {$EndIf}
                  End;
                  If Menu_Num in ['Y','G','Z'] then
                     ClearBatchNames(True,false);
               End;
            Reset_Parity;
            Restore_Screen;
            Pop_window;
            FileMode := SaveFileMode;
         End;
      NormalCursor;
      ChDir(UpSaveDir);
      InUpload := False;
   End;

End.
