Unit XferStuf;

Interface
Uses
   TpCrt,    TPDos,     OpKey,
   TPWindow, TpDate,
   TPString, TpInline,
   Screen,   Files,
   Comm,     Procs,
   Initial;


Function  Check_Keyboard : Boolean;
Function  Blocksize(File_name : Str80; Size : Integer; Var L : LongInt) : LongInt;
Function  Blocksize2(L : LongInt; Size : Integer) : LongInt;
Procedure Show_Errors;
Procedure Time_Stamp;
Procedure Sound_Completion;
Procedure Figure_BPS(TotalFile : LongInt);
Procedure Log_BPSStuff;
Procedure Download_Status(S, P : String);
Procedure Build_Xfer_Screen(Ch : Char);
Procedure StatusMsg(S : String);
Procedure Show_Protocol(S : String);
Procedure Show_Filename(S: String);
Procedure Show_Bytes_Total(L : LongInt);
Procedure Show_Bytes_Rcvd(L : LongInt);
Procedure Show_Error_Count(L : LongInt);
Procedure Show_Blocks_Total(L : LongInt);
Procedure Show_Blocks_Rcvd(L : LongInt);
Procedure Show_Block_Size(L : LongInt);
Procedure Show_Time_Remaining(Total,SoFar,CPS : LongInt);
Procedure Show_Time_Elapsed(S : String);
Procedure Show_Gas_Gauge(L : Integer);
Procedure Clear_Status_Fields;
Procedure Show_NA_Fields;



Implementation


Function Check_Keyboard : Boolean;
Var
   CH   : Char;
   O2,O    : Boolean;
Begin
   O := False;
   If Keypressed Then
      Begin
         Case ReadKeyNoGrey of
            Esc  : O := True;
            Up   : O2 := MoveWindow(0, -1); {Up}
            Down : O2 := MoveWindow(0,  1); {down}
            Left : O2 := MoveWindow(-1, 0); {left}
            Right: O2 := MoveWindow(1,  0); {right}
         End;
      End
   Else
      If OnOffXferState <> Online then
         O := True;
   Check_Keyboard := O;
End;



Function Blocksize(File_name : Str80; Size : Integer; Var L : LongInt) : LongInt;
Var
   x      : LongInt;
   fil    : File Of Byte;
   areal  : Real;
Begin
   areal := Size * 1.0;
   Assign(fil, File_name);
   Reset(fil);
   IO := IoResult;             {dummy ioresult read}
   L := FileSize(fil);
   If L > 0 Then
      x := Trunc((L + areal - 1.0) / areal)
   Else
      x := 0;
   IO := IoResult;             {dummy ioresult read}
   Close(fil);
   IO := IoResult;             {dummy ioresult read}
   Blocksize := x;
End;



Function Blocksize2(L : LongInt; Size : Integer) : LongInt;
Var
   Areal  : Real;
Begin
   areal := Size * 1.0;
   If L > 0 Then
      L := Trunc((L + areal - 1.0) / areal);
   Blocksize2 := L;
End;


Procedure StatusMsg(S : String);
Begin
   FastWriteWindow(Pad(S,36),8,14,qq.Menu);
End;


Procedure Build_Xfer_Screen(Ch : Char);
Const
   Dl = ' Download ';
   Ul = ' Upload ';
   snt = 'Sent';
   rcv = 'Rcvd';
Var
   S1 : String[10];
   S2 : String[4];
Begin
   If Ch = 'D' then
      Begin
         S1 := DL;
         S2 := rcv;
      End
   Else
      Begin
         S1 := UL;
         S2 := snt;
      End;
   Setwindow2(2,4,76,14,S1+'Status ',false);
   Window(3,5,75,13);
   ClrScr;
   { Screen Window Layout
  1---+----10---+----20---+----30---+----40---+----50---+----60---+
 ีออออออออออออออออออออออออออออ Download Status ออออออออออออออออออออออออออออธ
 ณ File  QWERTY             Protocol     Xmodem                            ณ
 ณ Path  Z:\DL                                                             ณ
 ณ                                                                         ณ
 ณ Bytes Total n.a.         Blocks Total n.a.       Time Elapsed xx:xx:xx  ณ
 ณ Bytes Rcvd  0            Blocks Rcvd  0          ++ Remaining xx:xx:xx  ณ
 ณ Error Count 0            Block Size              Efficiency             ณ
 ณ                                                  Chars/Second           ณ
 ณ Status Msgs                                                             ณ
 ณ Completion  < not available for this protocol >                         ณ
 ิอออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออพ
  }

   FastWriteWindow('File'       , 1, 2, qq.Menu2);
   FastWriteWindow('Path'       , 2, 2, qq.Menu2);
   FastWriteWindow('Protocol'   , 1,27, qq.Menu2);
   FastWriteWindow('Bytes Total', 4, 2, qq.Menu2);
   FastWriteWindow('Bytes '+S2  , 5, 2, qq.Menu2);
   FastWriteWindow('Error Count', 6, 2, qq.Menu2);
   FastWriteWindow('Status Msgs', 8, 2, qq.Menu2);
   FastWriteWindow('Completion' , 9, 2, qq.Menu2);
   FastWriteWindow('Blocks Total', 4, 27, qq.Menu2);
   FastWriteWindow('Blocks '+S2  , 5, 27, qq.Menu2);
   FastWriteWindow('Block Size'  , 6, 27, qq.Menu2);
   FastWriteWindow('Time Elapsed', 4, 51, qq.Menu2);
   FastWriteWindow('++ Remaining', 5, 51, qq.Menu2);
   FastWriteWindow('Efficiency'  , 6, 51, qq.Menu2);
   FastWriteWindow('Chars/Second', 7, 51, qq.Menu2);
   Display_Status(S1+'In Progress    ESC-Cancel Transfer ');
End;


Procedure Show_Protocol(S : String);
Begin
   FastWriteWindow(Pad(S,32),1,36,qq.Menu);
End;


Procedure Show_Filename(S: String);
Begin
   S := STUpCase(S);
   FastWriteWindow(Pad(JustFileName(S),12),1,8,qq.Menu);
   FastWriteWindow(Pad(JustPathName(S),64),2,8,qq.Menu);
End;


Procedure Download_Status(S, P : String);
Begin
   Show_Filename(S);
   Show_Protocol(P);
End;


Procedure Show_Bytes_Total(L : LongInt);
Begin
   FastWriteWindow(Pad(Long2Str(L),8),4,14,qq.Menu);
End;

Procedure Show_Bytes_Rcvd(L : LongInt);
Begin
   FastWriteWindow(Pad(Long2Str(L),8),5,14,qq.Menu);
End;

Procedure Show_Error_Count(L : LongInt);
Begin
   FastWriteWindow(Pad(Long2Str(L),5),6,14,qq.Menu);
End;

Procedure Show_Blocks_Total(L : LongInt);
Begin
   FastWriteWindow(Pad(Long2Str(L),6),4,40,qq.Menu);
End;

Procedure Show_Blocks_Rcvd(L : LongInt);
Begin
   FastWriteWindow(Pad(Long2Str(L),6),5,40,qq.Menu);
End;

Procedure Show_Block_Size(L : LongInt);
Begin
   FastWriteWindow(Pad(Long2Str(L),5),6,40,qq.Menu);
End;

Procedure Show_Time_Elapsed(S : String);
Begin
   FastWriteWindow(S,4,64,qq.Menu);
End;

Procedure Show_Time_Remaining(Total,SoFar,CPS : LongInt);
Var
   Secs : LongInt;
Begin
   If Total > 0 then
      Begin
         Secs := (Total - SoFar) Div MaxWord(Word(CPS),1);
         FastWriteWindow(TimeToTimeString(qq.ElapsedStr,Secs),5,64,qq.Menu);
      End;
End;

Procedure Show_Gas_Gauge(L : Integer);
Begin
   FastWriteWindow(Pad(Long2Str(L*2)+'%',5),9,14,qq.menu);
   FastWriteWindow(CharStr('ฒ', L),9,19,qq.Menu);
   FastWriteWindow(CharStr('þ',50-L),9,L+19,qq.Menu2);
End;

Procedure Clear_Status_Fields;
Begin
   Show_FileName('');
   FastWriteWindow(Pad('',8),4,14,qq.Menu);
   FastWriteWindow(Pad('',8),5,14,qq.Menu);
   FastWriteWindow(Pad('',5),6,14,qq.Menu);
   FastWriteWindow(Pad('',6),4,40,qq.Menu);
   FastWriteWindow(Pad('',6),5,40,qq.Menu);
   FastWriteWindow(Pad('',5),6,40,qq.Menu);
   FastWriteWindow(Pad('',8),4,64,qq.Menu);
   FastWriteWindow(Pad('',8),5,64,qq.Menu);
   FastWriteWindow(Pad('',7),6,64,qq.Menu);
   FastWriteWindow(Pad('',6),7,64,qq.Menu);
   Show_Gas_Gauge(0);
End;


Procedure Show_NA_Fields;
Begin
   FastWriteWindow(Pad('n.a.',6),4,40,qq.Menu);
   FastWriteWindow(Pad('n.a.',8),4,14,qq.Menu);
   FastWriteWindow(Pad('n.a.',8),5,64,qq.Menu);
   FastWriteWindow(Pad('< not available for this protocol >',50),9,14,qq.Menu);
End;


Procedure Show_Errors;
Var
   x : Integer;
Begin
   HiddenCursor;
   Show_Blocks_Rcvd(Pred(BlockNum));
   Show_Bytes_Rcvd(Tot_K);

   If Stamp_Taken Then
      Show_Time_Elapsed(Elapsed_Online(Time_));

   Show_Error_Count(Ecount);

   If ShowPct Then
      Begin
         x := round(((Min(ExpectedSize+1, Tot_K) * 1.0) / (ExpectedSize+1)) * 100.0) Div 2;
         Show_Gas_GAuge(x);
      End;
End;

Procedure Log_BPSstuff;
Var
  x : Str5;
Begin
   Str((Avg_BPS / 10):1:0, x);
   Logit   ('++ Chars Per Second    : ' + x);
   Str(Effective_PCT:1:1, x);
   Logit   ('++ Effective Percent   : ' + x);
End;


Procedure Time_Stamp;
Begin
   If Not Stamp_Taken Then
      Begin
         Time_ := CurrentTimeX;
         Stamp_Taken := True;
      End;
End;


Procedure Figure_BPS(TotalFile : LongInt);
Var
   CPS : LongInt;
Begin
   Avg_BPS := (Tot_K * 1000.0) / (Elapsed(Time_, CurrentTimeX)+0.1);
   If Avg_BPS > NewSpeed * 1.0 then
      Avg_BPS := NewSpeed * 1.0;
   Effective_PCT := Avg_BPS / DCE_Speed * 100.0;
   If Effective_PCT > 400.0 Then Effective_PCT := 400.0;
   CPS := Round(Avg_BPS);
   If CPS > NewSpeed Then CPS := NewSpeed;
   CPS := CPS Div 10;
   FastWriteWindow(Real2Str(Effective_PCT,6,2)+'%',6,64,qq.Menu);
   FastWriteWindow(Pad(Long2Str(CPS),6),7,64,qq.Menu);
   Show_Time_Remaining(TotalFile, Tot_K, CPS);
End;


Procedure Sound_Completion;
Begin
   If noise Then
      For x := 1 To 5 Do
         Begin
            Sound(qq.Dtone);
            Delay(200);
            NoSound;
            Delay(200);
         End;
End;


End.
