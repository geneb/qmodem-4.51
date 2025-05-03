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
      Const
         DividingLine = 6;

         Procedure Show_Incoming_Char(Var CH : Char);
         Const
            IsXoff : Boolean = False;
         Begin
            While CommPressed or (IsXoff and (not Keypressed)) Do
               If CommPressed then
                  Begin

                     CH := Cinkey;

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
         Get_The_Filename_u(3, FName,True);
         If dfile <> '' Then
            Begin
               BytesSoFar := 0;
               Assign (III, dfile);
               Reset(III);
               Xsize := FileSize(III);
               Close(III);
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
               Save_Screen(1,1,3,3);
               Push_Window;
            End;
      End;
