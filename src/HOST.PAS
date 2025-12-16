Unit Host;
{$P+,V-}

Interface

Uses
   TpCrt,    TPString,  Dos,      TpDos,   QShell,
   Initial,  Group1,    Procs,    Comm,    Comm2,
   Group02,  QDial,     Upld,     Qdial2,  Files,
   Emuls,    QDosCmd,   Qmem,     Screen,  Batch,
   ApTimer,  TpDate,    Constant, OpKey,   ExitDOS;

Procedure SysopToDOS;
Function  HostMode(Restart : Boolean) : Integer;
Procedure HangupHost;
Function  Connected : Boolean;
Function  Sc(A : Real)      : Str80;
Function  Value(Original_String : String) : Word;
Function  FTime : Integer;
Function  GetSecurity(What : String) : Str80;
Function  GetLine(What : String) : Str80;
Function  GetYesNo(What : String) : Str80;
Function  GetCR(What : String) : Str80;
Function  GetNumber(What : String) : Str80;
Function  GetPromptKey : Str80;
Function  Receive(Var C : Char)  : Boolean;
Function  Send_File(FName : String) : Boolean;
Procedure Parse(Var Parse_Line : Str80);
Function  TimeLeft : Integer;
Function  Phone_Is_Ringing : Boolean;
Function  Determine_Bits : Char;
Procedure Initialize_Comm;
Procedure SendCRLF;
Procedure SendLine(txt : String);
Procedure SendString(txt            : String;
                     Num_CRs        : Integer);
Procedure SendText(txt : String);


Implementation

Uses Downld;

Type
   MSG_Header = Record
                   MsgNum         : Integer;    {computed}
                   NameTo         : String[30]; {Name of receiver}
                   NameFrom       : String[30]; {name of sender}
                   DateTime       : String[19]; {message entry stats}
                   Subject        : String[30]; {Subject of message}
                   Private        : Boolean;    {for public to read?}
                   HasRead        : Boolean;    {read by receiver?}
                   Killed         : Boolean;    {killed message?}
                   StartPos       : LongInt;
                   Lines          : Integer;    {Line #'s in Detail File}
                End;

Var
   MsgFile           : File Of MSG_Header;
   MsgDetail         : Text;
   HostDone, Local   : Boolean;
   HostSecurity      : Word;
   ValidHostCommands : Set Of Char;
   LogonTime         : Integer;
   DetailFile        : String[64];
   PWDFile           : String[64];
   HdrFile           : String[64];

Const
   Tab_           = '     ';

   Procedure ShowModemMsg (s : String);
   Begin
      Writeln ('Msg from Modem:');
      Writeln (s);
   End;


   Procedure Reset_Vars;
      { Resets some of the Vars after each call }
   Begin
      DataBits := EightBits;
      Hfirstname := '';
      Hlastname := '';
      HPassword := '';
   End;


   Function Get_Modem_Ok : Boolean;
   Var
      Ch     : Char;
      LineIn : String;
      ET     : EventTimer;
   Begin
      If qq.OKMessage = '' Then
         Begin
            Get_Modem_Ok := True;
            Exit;
         End;
      LineIn := '';
      NewTimerSecs(ET, 3);
      Repeat
         If CommPressed Then
            While CommPressed Do
               Begin
                  Ch := Cinkeyz;
                  LineIn := LineIn + Ch;
               End;
      Until (Pos(qq.OKMessage, LineIn) > 0) Or TimerExpired(ET);
      ShowModemMsg(LineIn);
      Clear_buffer;
      If Pos(qq.OKMessage, LineIn) > 0 Then
         Get_Modem_Ok := True
      Else
         Get_Modem_Ok := False;
   End;


   Procedure Initialize_Modem;
      { Initialize the Modem After Each Call }
   Begin
      
      {If qq.DoRecalibrate then
         DelayCalibrate;}

      If Connected Then
         Repeat
            writeln('Error, Carrier detected.');
            HangupHost;
         Until Not Connected or KeyPressed;

      If qq.HostInit <> '' then
         Repeat
            Reset_Vars;
            Initialize_Comm;
            Clear_Buffer;
            Clear_Buffer2;
            Delay(100);
            Parse_Write_Modem(qq.HostInit);
            Delay(600);
         Until Get_Modem_Ok Or Keypressed;
      Clear_buffer;
      Writeln('Waiting for call...');
   End;


   Function Phone_Is_Ringing : Boolean;
   Var
      s          : String;
      ringing    : Boolean;
      y, x,
      ring_count : Integer;
      ET, ET2    : EventTimer;
   Begin
      If Not CommPressed Then
         Phone_Is_Ringing := False
      Else
         Begin
            s := '';
            ringing := False;
            Ring_Count := 0;
            NewTimerSecs(ET,120); {2 minutes}
            NewTimerSecs(ET2, 10);
            Repeat
               If CommPressed Then
                  While CommPressed Do
                     Begin
                        s := s + Upcase(Cinkeyz);
                     End;
               If Pos(STUpCase(qq.Host_Ring_Msg), s) > 0 Then
                  Begin
                     Inc(Ring_Count);
                     s := '';
                     NewTimerSecs(ET2, 10);
                     Writeln('RING #',Ring_Count);
                  End;
               If Ring_Count = qq.Host_Ring_Count then
                  Ringing := True;
            Until Ringing or
                  TimerExpired(ET) Or
                  TimerExpired(ET2);
            If Not Ringing then
               Begin
                  Writeln ('Call intercepted, resetting.');
                  Initialize_Modem;
               End;
            Phone_Is_Ringing := Ringing;
         End;
   End;


   Function Determine_Bits : Char;
   Var
      C              : Char;
   Begin
      C := Cinkeyz;
      Case C Of
         #128..#254 :
            Begin
               DataBits := SevenBits;
               C := Chr(Ord(C) And $7F);
            End;
      End;                        { Case }
      Determine_Bits := C;
   End;


   Procedure Initialize_Comm;
   Begin
      BaudInit := qq.ComSpeed;
      NewSpeed := BaudInit;
      NewCParity := 'N';
      DataBits := EightBits;
      NewDBits := 8;
      NewSBits := 1;
      Init_Port;
   End;


   Procedure SendString(txt : String; Num_CRs : Integer);
   Var
      I : Integer;
   Begin
      OutKey(txt);
      If Online Then
         Write_Byte(txt);
      For i := 1 To Num_CRs Do
         Begin
            OutKey(CRLF);
            If Online Then
               Write_Byte(CRLF);
         End;
   End;

   Procedure SendLine(txt : String);
   Begin
      SendString(txt, 1);
   End;

   Procedure SendText(txt : String);
   Begin
      SendString(txt, 0);
   End;

   Procedure SendCRLF;
   Begin
      SendString('', 1);
   End;

   Procedure Test_Msg_Stuff;
   Begin
      HdrFile := SearchName(QMODEM_HDR);
      DetailFile := SearchName(QMODEM_MSG);
      Assign(MsgFile, HdrFile);
      Assign(MsgDetail, DetailFile);
      If (Not ExistFile(HdrFile)) or (Not existFile(DetailFile))Then
         Begin

            {create a new message header file}
            Rewrite(MsgFile);
            writeln('Header file created');
            Logit('@HOST Header file created');
            Close(MsgFile);

            {clear the detail file in case of error}
            writeln('Detail file created');
            Logit('@HOST Detail file created');
            Rewrite(MsgDetail);
            WriteLn(MsgDetail, _QMODEMUC_+' HOST MESSAGE DETAIL FILE');
            Close(MsgDetail);
            IO := IOResult;
         End;
   End;



   Procedure EnterMessage(Too, Subj : String);
   Var
      txt       : Array [1..17] of String[72];
      msghead   : MSG_Header;
      lst, Line : Integer;
      Dummy     : String;
      C         : Char;
      Ok        : Boolean;
   Label
      EExit, cont;

      Procedure WrapText;
      Var
         Col, x         : Integer;
         I, Fine        : Boolean;
      Begin
         Dummy := txt[Line];
         Fine := False;
         Repeat
            Fine := False;
            Col := Ord(Dummy[0]);
            Repeat
               I := Receive(C);
            Until (C In [#8, #9, #11..#255]) Or Not Connected;
            If Not Connected Then Exit;
            If (C = #8) Or (C = #127) Then
               Begin
                  If Col > 0 Then
                     Begin
                        Dummy[0] := Pred(Dummy[0]);
                        SendText(#8#32#8);
                     End;
               End
            Else
               If (C = #9) And (Col > 62) Then
                  C := #8
               Else
                  If (C = #9) And (Col <= 62) Then
                     Begin
                        Dummy := Dummy + Tab_;
                        SendText('     ');
                     End
                  Else
                     Begin
                        SendText(C);
                        If Not(C In [#13, #10]) Then
                           Begin
                              Dummy := Dummy + C;
                              If Col = 74 Then
                                 Begin
                                    x := 74;
                                    While (Dummy[x] <> ' ') And (x <> 0) Do
                                       Dec(X);
                                    If x <> 0 Then
                                       Begin
                                          Col := 75 - x;
                                          SendText(CharStr(#8, Col) + CharStr(#32, Col));
                                          txt[Line] := Copy(Dummy, 1, x);
                                          Fine := True;
                                          txt[Line + 1] := Copy(Dummy, x + 1, 255);
                                       End
                                    Else
                                       Begin
                                          txt[Line] := Copy(Dummy, 1, 74);
                                          Fine := True
                                       End
                                 End
                           End
                     End;
         Until (C = #13) Or Fine Or Not Connected;
         SendCRLF;
         If Not Fine Then
            txt[Line] := Dummy;
      End;


      Procedure Entry(startline : Integer);
      Begin
         Line := startline;
         Repeat
            SendText(txt[Line]);
            WrapText;
            Inc(Line);
         Until (txt[Pred(Line)] = '') Or (Line = 17) Or Not Connected;
      End;


   Begin
      Assign(MsgFile, HdrFile);
      Assign(MsgDetail, DetailFile);
      SendLine('');
      If too = '' Then
         Begin
            Repeat
               too := GetLine('To: ');
               If too = '' Then Exit;
               If Length(too) > 30 Then SendLine('Max 30 characters');
            Until (Length(too) < 31) Or Not Connected;
            Repeat
               Subj := GetLine('Subject: ');
               If Subj = '' Then Exit;
               If Length(Subj) > 30 Then SendLine('Max 30 characters');
            Until (Length(Subj) < 31) Or Not Connected;
         End;
      SendText('Private (y/n) ? ');
      Repeat
         Ok := Receive(CH);
         Ch := Upcase(CH);
         If Ch = #27 Then Exit;
      Until Ch In ['Y', 'N'];
      SendLine(CH);

      Reset(MsgFile);
      If FileSize(MsgFile) = 0 Then
         lst := 0
      Else
         Begin
            Seek(MsgFile, FileSize(MsgFile) - 1);
            Read(MsgFile, msghead);
            lst := msghead.MsgNum;
         End;
      FillChar(msghead, SizeOf(msghead), #0);
      With msghead Do
         Begin
            MsgNum   := Succ(lst);
            NameTo   := STUpCase(too);
            NameFrom := Hfirstname + ' ' + Hlastname;
            DateTime := DateS +' ' +TimeS;
            Subject  := Subj;
            Private  := Ch = 'Y';  {for public to read?}
            HasRead  := False;     {read by receiver?}
            Killed   := False;     {killed message?}
         End;
      SendLine(CRLF + 'Enter your message.  72 chars per line, 16 lines max.  Autowrap');
      SendLine('Blank line ends message.');
      SendLine(CharStr('-', 75));

      FillChar(txt, SizeOf(txt), 0); {clear the buffer}
      Line:= 2;
      {get the text now}
cont:
      Entry (Pred(Line));
      SendText('(C)ontinue, (S)ave or (A)bort > ');
      Repeat
         Ok := Receive(CH);
         Ch := Upcase(CH);
      Until Not Connected Or (CH In ['C', 'A', 'S']);
      SendLine(CH);
      If Not Connected Then GoTo EExit;
      If Ch = 'C' Then GoTo cont;
      If Ch = 'A' Then GoTo EExit;
      SendLine(CRLF + 'Saving message ');
      Append(MsgDetail);
      msghead.StartPos := TextFileSize(MsgDetail);
      x := 1;
      While (x < 18) And (txt[x] <> '') Do
         Begin
            WriteLn(MsgDetail, txt[x]);
            Inc(x);
         End;
      Close(MsgDetail);
      msghead.Lines := Pred(x);
      Seek(MsgFile, FileSize(MsgFile));
      Write(MsgFile, msghead);
EExit:
      Close(MsgFile);
      IO := IOResult;
   End;



   Procedure ReadMessages;
   Var
      fst, lst       : Integer;
      msghead        : MSG_Header;
      XHD, XL        : LongInt;
      s, Inp         : String;
      I              : Integer;
   Label
      NoMsg, EExit, skip2;

      Function Locate(i : Integer)   : Boolean;
      Var
         Ok             : Boolean;
         mm             : MSG_Header;
         x              : Integer;
      Begin
         Ok := False;
         Seek(MsgFile, 0);
         Read(MsgFile, mm);
         x := 1;
         While (Not Ok) And (Not EOF(MsgFile)) And (mm.MsgNum < i) Do
            Begin
               If EOF(MsgFile) Then
                  Begin
                     Locate := False;
                     Exit;
                  End;
               Read(MsgFile, mm);
               Inc(x);
            End;
         If EOF(MsgFile) And (mm.MsgNum > i) Then
            Locate := False
         Else
            Locate := True;
         Seek(MsgFile, x - 1);
      End;


   Begin
      If Not existFile(HdrFile) Then
         Begin
            NoMsg:
            SendLine(CRLF + 'No messages to read.' + CRLF);
            Exit;
         End;
      Assign(MsgFile, HdrFile);
      Assign(MsgDetail, DetailFile);
      Reset(MsgFile);
      Reset(MsgDetail);
      x := FileSize(MsgFile);
      If x = 0 Then
         Begin
            Close(MsgFile);
            IO := IOResult;
            GoTo NoMsg;
         End
      Else
         Begin
            {find the first and last msg numbers to display}
            Read(MsgFile, msghead);
            fst := msghead.MsgNum;
            Seek(MsgFile, FileSize(MsgFile) - 1);
            Read(MsgFile, msghead);
            lst := msghead.MsgNum;
            SendLine(CRLF + 'Messages from ' + Long2Str(fst) + ' to ' + Long2Str(lst));
            Repeat
               Inp := GetLine('Start with Msg # ? ');
               If Inp = '' Then
                  GoTo EExit;
               Ok := Str2Int(Trim(Inp), i);
               If Ok Then
                  Ok := Locate(i); {position to header}
            Until Ok Or Not Connected;

            {Top of Read Loop}
            Repeat
               With msghead Do
                  Begin
                     xhd := FilePos(MsgFile);
                     Read(MsgFile, msghead);
                     {Inc(i);}
                     If HostSecurity = 0 Then
                        Begin
                           If Killed Then
                              GoTo skip2;
                           If Private Then
                              If ((NameTo <> Hfirstname + ' ' + Hlastname) and
                                  (NameFrom <> Hfirstname + ' ' + Hlastname)) then
                                 GoTo skip2;
                        End;
                     ClrScr;
                     Write_Byte(^L);
                     SendLine('     Msg# : ' + Long2Str(MsgNum));
                     SendText('       To : ' + NameTo);
                     If Killed then  SendText(' (killed)');
                     If Private Then SendText(' (private)')
                                Else SendText(' (public)');
                     If HasRead Then SendLine(' (read)')
                                else SendLine(' (not read)');
                     SendLine('     From : ' + NameFrom);
                     SendLine('  Subject : ' + Subject);
                     SendLine('Date/Time : ' + DateTime);
                     SendLine(CharStr('-', 40));
                     If TextSeek(MsgDetail, StartPos) Then
                        For x := 1 To Lines Do
                           Begin
                              ReadLn(MsgDetail, s);
                              SendLine(s);
                           End
                     Else
                        SendLine('Error reading Detail file');
                     If (NameTo = Hfirstname + ' ' + Hlastname) then
                        Begin
                           HasRead := True;
                           Seek(MsgFile, xhd);
                           Write (MsgFile, msghead);
                        End;
                  End;
               XL := FilePos(MsgFile);
               SendText(CRLF + '(R)eply');
               If (msghead.NameTo = Hfirstname + ' ' + Hlastname) Or
                  (msghead.NameFrom = Hfirstname + ' ' + Hlastname) or
                  (HostSecurity > 0) Then
                  SendText(', (K)ill');
               SendText(', (Q)uit, [ENTER] next msg > ');
               Repeat
                  Ok := Receive(CH);
                  Ch := Upcase(CH);
                  If (CH = 'K') And
                     (msghead.NameTo <> Hfirstname + ' ' + Hlastname) And
                     (msghead.NameFrom <> Hfirstname + ' ' + Hlastname)  And
                     (HostSecurity = 0) then
                     Ch := #0;
               Until Not Connected Or (CH In [#13, 'R', 'Q', 'K']);
               SendLine(CH);
               Case Ch Of
                  'R' : Begin
                           Close(MsgFile);
                           Close(MsgDetail);
                           IO := IOResult;
                           SendLine('REPLY...');
                           EnterMessage(msghead.NameFrom, msghead.Subject);
                           Reset(MsgFile);
                           Reset(MsgDetail);
                           Seek(MsgFile, XL);
                        End;
                  'Q' : GoTo EExit;
                  'K' : Begin
                           msghead.Killed := True;
                           Seek(MsgFile, FilePos(MsgFile) - 1);
                           Write(MsgFile, msghead);
                        End;
               End;
skip2:
            Until EOF(MsgFile) Or Not Connected;
         End;
EExit:
      Close(MsgFile);
      Close(MsgDetail);
      IO := IOResult;
      SendLine('');
   End;


   Procedure SysopToDOS;
   Begin
      SendLine(' ');
      SendLine(' ');
      SendLine('Sysop has dropped to DOS.  Please wait...');
      Dos_CMD;
      SendLine('Ok, you can continue...');
      SendLine(' ');
   End;



   Procedure ProtMNU;
   Begin
      SendLine('Protocols available');
      SendLine('-------------------');
      SendLine('X - Xmodem');
      SendLine('C - Xmodem CRC');
      SendLine('O - Xmodem-1K');
      SendLine('Y - Ymodem (batch)');
      SendLine('Z - Zmodem (batch)');
      If CTS_ then
         Begin
            SendLine('F - Xmodem-1K/G');
            SendLine('G - Ymodem/G (batch)');
         End;
      SendCRLF;
   End;


   Procedure Get_Prot(Var P : Char);
   Var
      s : String;
   Begin
      Repeat
         If Not Send_File(SearchName('Prots.HST')) Then
            ProtMNU;
         s := GetLine('Enter Protocol, blank aborts > ');
         If S <> '' then
            Parse(s)
         Else
            S := #32;
         P := s[1];
         P := Upcase(P);
         If P = 'A' Then SendLine('ASCII not allowed');
      Until P <> 'A';
   End;


   Procedure DoDownload;
   Var
      dfile    : String;
      P        : Char;
      DirInfo  : SearchRec;
      BatchCount : Integer;
   Const
      BatchPrompt = 'Enter File(s) to Download, blank ends > ';
   Label
      Loop01, Continue;
   Begin
      Get_Prot(P);
      If P = #32 then Exit;
      If (P in ['Y','G','Z']) and
         (Is_External(P) = 0) then
         Begin
            batchcount := 0;
            ClearBatchNames(false,true);
            Repeat
               dfile := GetLine(^M^J'Enter File(s) to Download, max 20, blank ends > ');
               If dfile = '' then
                  If BatchCount = 0 Then
                     Exit
                  Else
                     Goto Continue;
               For x := 1 to Inputs do
                  Begin
                     dfile := Responses[x];
                     If qq.Host_DLPath = '' then
                        If HostSecurity = 0 then
                           dfile := JustFilename(dfile);
                     FindFirst(AddBackSlash(qq.Host_DLPath) + dfile, AnyFile - VolumeID - SysFile - Directory, DirInfo);
                     If (DosError <> 0) Then
                        SendLine('-- File ' + Pad(STUpCase(dfile),12) + ' has no match.  Skipped')
                     Else
                        If BatchCount >= 20 Then
                           SendLine('-- File ' + Pad(STUpCase(dfile),12) + ' Skipped')
                        Else
                           Begin
                              AddBatchName(Addbackslash(qq.Host_DLPath), dfile);
                              Inc(BatchCount);
                              If (Pos('?',dfile) > 0) or (Pos('*',dfile) > 0) then
                                 Begin
                                    SendString (' -- File(s)     ',0);
                                    Repeat
                                        SendString(Pad(DirInfo.Name,16),0);
                                        FindNext(DirInfo);
                                    Until DosError <> 0;
                                    SendCRLF;
                                 End
                              Else
                                 SendLine(Pad(Long2Str(BatchCount),2)+' File ' + Pad(STUpCase(dfile),12) + ' OK');
                           End;
                  End;
            Until BatchCount = 20;
         End
      Else
         Begin
            Loop01:
            dfile := GetLine('Enter File to Download, blank ends > ');
            If dfile = '' Then Exit;
            If qq.Host_DLPath = '' then
               If HostSecurity = 0 then
                  dfile := JustFilename(dfile);
            If ((Pos('*', dfile) > 0) Or (Pos('?', dfile) > 0)) And (P In ['X', 'O', 'C', 'R', 'F']) Then
               Begin
                  SendLine('Wildcards not allowed');
                  Goto Loop01;
               End;
            FindFirst(AddBackSlash(qq.Host_DLPath) + dfile, AnyFile - VolumeID - SysFile, DirInfo);
            If DosError <> 0 Then
               Begin
                  SendLine('File ' + STUpCase(dfile) + ' does not exist.');
                  Goto Loop01;
               End;
            ClearBatchNames(False,True);
            AddBatchName(Addbackslash(qq.Host_DLPath), dfile);
         End;
      Continue:
      SendLine(CRLF + 'Begin your Download.  CTRL-X to Cancel');
      Delay(2000);
      Upload(AddBackSlash(qq.Host_DLPath) + dfile, P, ' ');
      Set_Colors;
   End;


   Procedure DoUpload;
   Var
      dfile    : String;
      P        : Char;
      xfers    : Set of Char;
      Num      : integer;
   Begin
      Xfers := ['X', 'O', 'C', 'R', 'F', 'Z', 'G', 'Y'];
      Get_Prot(P);
      If P = #32 then Exit;
      { Check the external list for filename prompting }
      Num := Is_External(P);
      If Num > 0 then
         If qq.Xfer_File_Prompt[Num] = 'Y' then
            Xfers := Xfers + [P];

      If not (P in ['Y','G','Z']) then
         Begin
            If (P In xfers) Then
               If Responses[2] = '' Then
                  dfile := GetLine('Enter Filename to Upload > ')
               Else
                  dfile := Responses[2]
            Else
               dfile := #255;
            If dfile = '' Then Exit;
         End
      Else
         Dfile := #255;
      If (Not existFile(AddBackSlash(qq.Host_ULPath) + dfile)) Or (dfile = #255) Then
         Begin
            SendLine(CRLF + 'Begin your Upload.  CTRL-X to Cancel');
            Delay(2000);
            DownLoad(AddBackSlash(qq.Host_ULPath) + dfile, P, P);
            Set_Colors;
         End
      Else
         If (Pos('*', dfile) > 0) Or (Pos('?', dfile) > 0) Then
            SendLine('Wildcards not allowed')
         Else
            SendLine('File ' + STUpCase(dfile) + ' already exists.');
   End;

   Procedure HangupHost;
   Begin
      Local := False;
      HangupPrim;
      If Not Connected Then
         If Last_Online_State Then
            Stop_Online_Timer;
      Check_Host_Hangup_Routine;
      Clear_buffer;
   End;

   {$I HOST2.PAS}

   Procedure ShowHostDir;
   Var
      Pattern : String[64];
      DirInfo : SearchRec;
      F       : Text;

      Procedure show_dir;
      Var
         DT : DateTime;
      Begin
         If DirInfo.Attr And Directory = Directory Then
            Exit;
         Write(F, Pad(DirInfo.Name, 12));
         Write(F, ' ', DirInfo.Size:9, '  ');
         UnPackTime(DirInfo.Time, DT);
         Write(F, DT.Hour:2, ':');
         If DT.Min < 10 Then
            Write(F, '0');
         Write(F, DT.Min);
         If DT.Month = 0 Then
            Write(F, '  ??-??-?? ')
         Else
            Begin
               Write(F, '  ');
               If DT.Month < 10 Then Write(F, '0'); Write(F, DT.Month, '-');
               If DT.Day < 10 Then Write(F, '0'); Write(F, DT.Day, '-');
               WriteLn(F, (DT.Year Mod 100):2, ' ')
            End;
      End;

   Begin
      Assign(F, 'QMHOST.DIR');
      Rewrite(F);
      WriteLn(F, ^M^J'--- FILE LIST ---');
      Pattern := AddBackSlash(qq.Host_DLPath) + '*.*';
      FindFirst(Pattern, AnyFile - VolumeID - SysFile - Hidden, DirInfo);
      While DosError = 0 Do
         Begin
            Inc(x);
            show_dir;
            FindNext(DirInfo);
         End;
      WriteLn(F, '------ END ------');
      Close(F);
      IO := IOResult;
      If Not Send_File('QMHOST.DIR') Then ;
      Erase(F);
      SendText('Press any key to continue');
      Repeat
      Until Receive(Ch);
      Clear_Buffer;
      IO := IOResult;
   End;


   Procedure GetName;
      { Get the callers name & Password }
   Var
      NameInput      : Str80;
      C              : Integer;
   Label
      Bye, F1;
   Begin
      NameInput := '';
      Hfirstname := '';
      Hlastname := '';
      HPassword := '';
      Display_Status(' LOGON In Progress ');
      DataBits := EightBits;
      F1:
      C := 1;
      While (NameInput = '') And (C < 6) and Connected Do
         Begin
            NameInput := GetLine('Please enter your FIRST name : ');
            Inc(C);
         End;
      If not Connected then goto Bye;
      If NameInput = '' Then
         Begin

            Bye:
            HangupHost;
            Exit;
         End;
      Parse(NameInput);
      Hfirstname := STUpCase(Responses[1]);
      If DataBits <> EightBits then
         Begin
            SendCRLF;
            SendLine('Please call back using 8-N-1 as your COMM settings.');
            Goto Bye;
         End;
      If Inputs > 1 Then
         Hlastname := STUpCase(Responses[2])
      Else
         Begin
            Hlastname := STUpCase(GetLine('Please enter your LAST name  : '));
            If Hlastname = '' Then GoTo F1;
         End;
      If Inputs > 2 Then
         HPassword := STUpCase(Responses[3])
      Else
         Begin
            C := 1;
            Repeat
               HPassword := STUpCase(GetSecurity('Password : '));
               Inc(C);
            Until (C > 2) Or (HPassword <> '') or Not Connected;
            If not Connected then goto Bye;
         End;
   End;


   Procedure Respond;  { Basically tells them we're Connected }
   Begin
      If Not Connected Then Exit;
      Write_Byte(#12);
      Delay(800);
      ClrScr;
      SendCRLF;
      Clear_Buffer;
      If Not Send_File(SearchName('PRELOG.HST')) Then
         SendLine('You have connected to '+_Qmodem_+' running in Host Mode.');
   End;

   Procedure Get_Result_Codes;
      { Get a Result Code from the Modem }
   Var
      Line       : String;
      Ch         : Char;
      ET, ET2    : EventTimer;
   Begin

      {If qq.DoRecalibrate then
         DelayCalibrate;}

      Writeln ('> Incoming Call <');
      Display_Status (' Press any key to Cycle ');
      Clear_Buffer;
      NewTimerSecs(ET, 40);
      Repeat
         Line := '';
         NewTimerSecs(ET2, 6);
         Repeat
            Repeat
            Until Keypressed Or
                  CommPressed or
                  TimerExpired(ET2);
            If CommPressed Then
               Begin
                  Ch := Cinkeyz;
                  Line := Line + Ch;
               End;
         Until ((Ch = #13) And (Length(Line) > 2)) Or
               TimerExpired(ET2) or
               Keypressed;
         If Line <> '' then
            Begin
               Line := Trim (Line);
               ShowModemMsg (Line);
            End;
         If Keypressed Then
            Begin
               Writeln ('Sysop dropped caller');
               HangupHost;
               Exit;
            End;
         If Length(Line) > 80 Then { Garbage connection, drop DTR }
            Begin
               Writeln ('Too much line noise');
               HangupHost;
               Exit;
            End;
         If Line = qq.Host_Ring_Msg Then
            Begin
               Delay(1000);
               Parse_Write_Modem (qq.Host_Answer);
            End;
         If Pos (qq.connect, Line) > 0 Then
            Begin
               Set_DCE_Speed (Line);
               SetSpeedMsg   (Line);
            End;

      Until (Pos(qq.connect,    Line) > 0) Or
            (Pos(qq.noconnect,  Line) > 0) Or
            (Pos(qq.noconnect2, Line) > 0) Or
            (Pos(qq.noconnect3, Line) > 0) Or
            (Pos(qq.noconnect4, Line) > 0) Or
            TimerExpired(ET);

      NewTimerSecs(ET2, 3);
      Repeat
      Until TimerExpired(ET) or
            Connected;

      If Not Connected Then
         Begin
            Writeln ('Caller disconnected');
            Exit;
         End;
      Clear_Buffer;
      Delay(2000);  { A pause in case an MNP/non-MNP connect occurs }
   End;

   Procedure LogCallerName;
   Begin
      Logit('@HOST CALLER > '+Hfirstname+' '+Hlastname);
      If Connected Then
         If Not Last_Online_State Then
            Start_Online_Timer;
   End;


   Procedure CheckName;
   Var
      F    : Text;
      S1, S2, s3,
      n1, n2, n3, n4, n5, Message : String;
      x, C : Integer;
      Ch   : Char;
      ET   : EventTimer;
   Label
      Cb;
   Begin
      If Not Connected Then Exit;
      If ExistFile(SearchName(QMODEM_PWD)) Then
         Begin
            Assign(F, SearchName(QMODEM_PWD));
            Reset(F);
            While Not EOF(F) Do
               Begin
                  ReadLn(F, S1);
                  Parse(S1);
                  For X := 1 to 5 do
                     Begin
                        Responses[x] := STUpCase(Responses[x]);
                     End;
                  If (Hfirstname = Responses[1]) And (Hlastname = Responses[2]) Then
                     Begin
                        n1 := Responses[1];
                        n2 := Responses[2];
                        n3 := Responses[3];
                        n4 := Responses[4];
                        n5 := Responses[5];
                        If HPassword = n3 Then
                           Begin

                              CB:

                              If (qq.HostOpen = 2) and (Not Local) Then
                                 Begin
                                    SendLine(CRLF + 'Hang up and await CALLBACK');
                                    Delay(2000);
                                    Repeat
                                       HangupHost;
                                       Delay(6000);
                                    Until not ONLINE;
                                    Writeln('Dialing ' + Responses[5]);
                                    Logit('@HOST CALLBACK '+Hfirstname+' '+
                                          Hlastname+' Number > '+n5);
                                    Parse_Write_Modem(qq.Dial_Prefix + n5 + qq.Dial_Postfix);
                                    x := 0;
                                    Repeat
                                       If CommPressed Then
                                          Get_modem_message(CH);
                                       Inc(x);
                                       Delay(100);
                                    Until Keypressed Or (CH = 'C') Or (x > 300);
                                    If Keypressed Or (x > 300) Then
                                       Begin
                                          HangupHost;
                                          Exit;
                                       End;
                                 End;
                              SendLine(CRLF + 'Welcome ' + Hfirstname);
                              LogCallerName;
                              HostSecurity := value(n4);
                              Close(F);
                              Exit;
                           End
                        Else
                           Begin
                              C := 1;
                              Repeat
                                 SendLine('Password does not match');
                                 HPassword := STUpCase(GetSecurity('Password : '));
                                 Inc(C);
                              Until (C > 2) Or (HPassword = n3);
                              If HPassword = n3 then
                                 Goto CB
                              Else
                                 Begin
                                    Delay(1000);
                                    HangupHost;
                                    Exit;
                                 End;
                           End;
                     End;
               End;
            Close(F);
         End
      Else
         Begin
            Assign(F, SearchName(QMODEM_PWD));
            Rewrite(F);
            Close(F);
            IO := IOResult;
            Writeln(QMODEM_PWD+' file created.');
         End;
      If qq.HostOpen = 0 Then
         SendLine('Adding you as a NEW USER.')
      Else
         Begin
            SendLine(^m^J'Sorry, this is a closed system.');
            Delay(1000);
            HangupHost;
            Exit;
         End;
      Append(F);
      WriteLn(F, Hfirstname + ' ' + Hlastname + ' ' + HPassword + ' 0  ; NEW USER');
      LogCallerName;
      Close(F);
      IO := IOResult;
      HostSecurity := 0;
   End;

   Procedure ShutDownHost;
   Var
      s : String;
   Begin
      s := GetSecurity('Enter password for Shutdown > ');
      If STUpCase(s) = STUpCase(qq.HostShutdown) Then
         Begin
            HostDone := True;
            HangupHost;
            Exit_to_DOS(True, 'Y');
         End;
   End;


   Procedure ShellToDos;
   Var
      S : String;
      s2 : string[2];
      rc : Integer;
   Begin
      If qq.HostPassword <> '' then
         S := GetSecurity('Enter password for "Shell to DOS" > ');
      If (qq.HostPassword = '') or
         (STUpCase(s) = STUpCase(qq.HostPassword)) Then
         Begin
            If Online then
               Begin
                  s2 := HexB(Async_IRQ);
                  rc := Shell('QMHOST.BAT ' + Long2Str(qq.CommPort) + ' '
                              + Long2Str(NewSpeed) + ' '
                              + HexW(ComBase) + ' '
                              + S2[2], ''+'', ''+'',
                              False, False,False);
               End
            Else
               DOS_Cmd;
         End
      Else
         Exit;
   End;

   Procedure Chat;
   Var
      Ch : Char;
      Col : Integer;
      lastcol : Integer;
      tmp : String;

      Procedure ShowCh(Ch : Char);
      Begin
         Case Ch Of
            #8,
            #127 : Begin
                      SendText(CH + #32 + CH);
                      If Col > 1 then
                         Dec(Col);
                   End;
            #13  : Begin
                      SendText(#13#10);
                      Col := 1;
                      LastCol := 1;
                   End;
            #32  : Begin
                      SendText(Ch);
                      Inc(Col);
                      LastCol := Col;
                      tmp := '';
                   End;
            Else   Begin
                      Inc(Col);
                      SendText(CH);
                      tmp := tmp + Ch;
                      If (Col > 77) then
                         Begin
                            If LastCol > 1 then
                               Begin
                                  For X := 1 to Length(Tmp) do
                                     SendText(#8#32#8);
                                  SendText(#13#10);
                                  SendText(tmp);
                                  Col := Length(Tmp);
                               End
                            Else
                               Begin
                                  SendText(#13#10);
                                  Col := 1;
                               End;
                            LastCol := 1;
                         End;
                   End;
         End;
      End;

   Begin
      SendLine(CRLF + CRLF + ^G'You are now Chatting with the Sysop' + CRLF);
      Display_Status(' Chatting with ' + Hfirstname + ' ' + Hlastname + '.   F2-Exit Chat ');
      tmp := '';
      Col := 1;
      LastCol := 1;
      Repeat
         Repeat
         Until Keypressed Or CommPressed;
         If Keypressed Then
            Begin
               CharWord := ReadKeyA;
               Case CharWord Of
                  F2 : Begin
                          SendLine(CRLF + 'Returning you to Host Mode' + CRLF);
                          Delay(1000);
                          Exit;
                       End;
                  Else If ExtendedChar = Normal then
                          ShowCh(Char(CharWord));
               End;
            End
         Else
            Begin
               Ch := Cinkeyz;
               ShowCh(Ch);
            End;
      Until False;
   End;

   Procedure ChatPage;
   Var
      Ch : Char;
      x  : Integer;
      ET : EventTimer;
   Begin
      NewTimerSecs(ET, 30);
      WriteLn;
      Display_Status (' '+Hfirstname + ' ' + Hlastname +'    F2-Answer Page ');
      SendText(CRLF + 'Paging Sysop for 30 seconds.   Press any key to abort');
      While not TimerExpired(ET) do
         Begin
            SendText(^G);
            Delay(1000);
            If Keypressed Then
               Begin
                  CharWord := ReadKeyA;
                  If CharWord = F2 Then
                     Begin
                        Chat;
                        Exit;
                     End;
               End
            Else
               If CommPressed Then
                  Begin
                     Ch := Cinkeyz;
                     Exit;
                  End;
         End;
      SendLine(^m^J'Sysop is not answering Page.');
      Delay(1000);
   End;


   Procedure Check_Ring;
      { Check to see if the Phone is Ringing and Send an ATA if Necessary }
   Begin
      If Phone_Is_Ringing Then
         Begin
            Clear_buffer;
            Delay(2500);
            Parse_Write_Modem(qq.Host_Answer);
            Get_Result_Codes;
            Delay(500);
            If Not Connected Then
               Initialize_Modem;  { Reset Everything }
         End;
   End;




   Function HostMode(Restart : Boolean) : Integer;
      { Mainline Answering Phone and everything before ASKNAMES }
   Var
      Ch  : Char;
      Cmd : String;
      hET : EventTimer;
   Label
      StartOnline, ByeBye, Sysop2, realdone, Skip;

      Procedure Check_Host_CH;
      Begin
         Ch := UpCase(Ch);
         Case Ch of
            ^H,
            #127 : If Length(Cmd) > 0 then
                      Begin
                         Cmd := Copy(Cmd,1,Pred(Length(cmd)));
                         Sendtext(#8#32#8);
                      End;
            Else   If (Ch In ValidHostCommands) then
                      Begin
                         Cmd := Cmd + Ch;
                         Sendtext(Ch);
                      End;
         End;
      End;

      Procedure ShowHelp;
      Var
         f : string[12];
      Begin
         Parse(Cmd);
         If Inputs = 1 then
            f := 'HELP.HST'
         Else
            f := 'HELP'+Responses[2,1]+'.HST';
        If Not Send_File(SearchName(f)) Then
           SendLine('Help file '+F+' not found.')
        Else
          Begin
             SendText('Press any key to continue');
             Repeat
             Until Receive(Ch);
             Clear_Buffer;
          End;
      End;


   Begin
      Hosting := True;
      HelpTopic := 0;
      If Restart Then
         GoTo Skip;
      Logit ('********** HOST STARTED **********');
      WriteLn;
      HostDone := False;
      Local := False;

      If Connected then
         Goto StartOnline;

      Test_MSG_Stuff;
      Repeat
         Initialize_Modem;
         Repeat
            Display_Status(' F1-Local Logon   ESC-Exit Host ');
            If Keypressed Then
               Begin
                  CharWord := ReadKeyA;
                  Case CharWord Of
                     F1  : Begin
                              Local := True;
                              If qq.HostOffHook <> '' then
                                 Repeat
                                    Parse_Write_Modem(qq.HostOffHook);
                                    Delay(600);
                                 Until Get_Modem_Ok Or Keypressed;
                              Goto StartOnline;
                           End;
                     Esc : Goto RealDone;
                  End;
               End;
            If Not Connected Then
               Check_Ring;
         Until Connected;
         StartOnline:
         Respond;
         GetName;
         If ForceHost then
            Goto RealDone;

         CheckName;

         Sysop2:

         LogonTime := FTime;
         ValidHostCommands := [#13, '?', 'O', 'F', 'G', 'P', ' ',
                               'R', 'E', 'U', 'D', 'S', 'Z'];

         Skip:

         If Connected Then
            Repeat
               Display_Status('');
               Display_Status(' User ' + Hfirstname + ' ' + Hlastname + '   F2-Chat   F5-DOS   F10-Hangup ');
               If TimeLeft < 3 Then
                  SendLine(^m^J'Warning, ' + Long2Str(TimeLeft) + ' minutes before logoff'^M^J);
               SendCRLF;
               If Not Send_File(SearchName('MENU.HST')) Then
                  Begin
                     SendLine(' Host Menu');
                     SendLine('---------------------');
                     SendLine(' U - Upload a file');
                     SendLine(' D - Download a file');
                     SendLine(' F - File Directory');
                     SendLine(' R - Read Message');
                     SendLine(' E - Enter Message');
                     SendLine(' G - Goodbye (hangup)');
                     SendLine(' O - Open a Script');
                     SendLine(' P - Page the Sysop');
                     SendLine(' S - Shell to DOS');
                     SendLine(' ? - Help!');
                  End;
               SendString(CRLF + '(' + Long2Str(TimeLeft) + ' min. left) '+_Qmodem_+' Host Command > ', 0);
               NewTimerSecs(hET, 300);
               Repeat
                  Cmd := '';
                  Ch := #0;
                  Repeat
                     If TimeLeft <= 0 Then
                        Begin
                           SendLine(^M^J'Time limit exceeded');
                           GoTo ByeBye;
                        End;
                     If Keypressed Then
                        Begin
                           NewTimerSecs(hET, 300);
                           CharWord := ReadKeyA;
                           Case CharWord Of
                              F10 : Begin
                                       HangupHost;
                                       Ch := #13;
                                    End;
                             F2   : Begin
                                       Flush_KBD;
                                       Chat;
                                       NewTimerSecs(hET, 300);
                                       Ch := #13;
                                    End;
                             F5   : Begin
                                       SysopToDOS;
                                       NewTimerSecs(hET, 300);
                                       Ch := #13;
                                    End;
                             Else   If ExtendedChar = Normal then
                                       Ch := Char(CharWord);
                           End;
                           Check_Host_CH;
                        End
                     Else
                        If CommPressed then
                           Begin
                              Ch := Cinkeyz;
                              Check_Host_CH;
                              NewTimerSecs(hET, 300);
                           End;
                  Until (Ch = #13) or TimerExpired(hET);
                  If TimerExpired(hET) then
                     Begin
                        Sendline(^M^J'Keyboard timeout!');
                        Goto ByeBye;
                     End;
               Until Not Connected Or (Upcase(Cmd[1]) In ValidHostCommands);
               SendCRLF;
               Case Upcase(Cmd[1]) Of
                  #13,' ' : ;
                  '?' : ShowHelp;
                  'F' : ShowHostDir;
                  'Z' : If HostSecurity > 0 Then
                           ShutDownHost;
                  'S' : ShellToDos;
                  'R' : ReadMessages;
                  'E' : EnterMessage('', '');
                  'O' : Begin
                           If Scripting then
                              SendLine('Open Script not available.  Script already running')
                           Else
                              Begin
                                 If Online then
                                    Script_to_Open := 'QMHOST.SCR'
                                 Else
                                    Script_to_Open := 'QMHOSTL.SCR';
                                 If not ExistFile(qq.Script_Path+Script_to_Open) then
                                    SendLine(^M^J'Open Script Command not available')
                                 Else
                                    Begin
                                       Script_Debug := False;
                                       Already_Initialized := False;
                                       Scripting := True;
                                       HostMode := 1;
                                       Exit;
                                    End;
                              End;
                        End;
                  'P' : If Online then ChatPage;
                  'D' : If Online or Local then DoDownload;
                  'U' : If Online or Local then DoUpload;
                  'G' : Begin
                           ByeBye:
                           If Not Send_File(SearchName('LOGOFF.HST')) Then
                              SendLine('Goodbye');
                           Logit('@HOST HANGUP > '+Hfirstname+' '+Hlastname);
                           Delay(3000);
                           HangupHost;
                        End;
                  Else
                     SendLine(CRLF + 'Unknown command, try again.' + CRLF);
               End;
               IO := IOResult;
            Until Not Connected or ForceHost;
      Until HostDone or HostViaScript or ForceHost;

      realdone:
      Logit('*********** HOST ENDED ***********');
      HostMode := 0;
      Hosting := False;
      Set_Base_Colors;
   End;

End.
