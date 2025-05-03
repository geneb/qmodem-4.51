UNIT TPZ;

INTERFACE

Uses
   Comm2, Qcrcs, XferStuf;

Function Zmodem_Receive(Auto : Boolean) : Boolean;
Function Zmodem_Send(Fname : String) : Boolean;

Procedure Z_ZRPOSmsg;
Procedure Z_FlushOutBound;
Procedure Z_SendBreak;
Function  Z_ReceiveByte: Integer;

Procedure Z_OpenWindow(Ch : Char);
Procedure Z_CloseWindow;
Procedure Z_ShowName(filename: String);
Procedure Z_ShowSize(l: LongInt);
Procedure Z_ShowCheck(is32: Boolean);
Procedure Z_Message(s: String);
Procedure Z_Frame(n,Where: Integer);
Procedure Z_ShowLocD(l: LongInt);
Procedure Z_ShowLocS(L: LongInt; Done : Boolean);
Function  Z_Online : Boolean;


IMPLEMENTATION

USES
   Initial,  Dos,       Comm,   TpCrt,  Screen,   Files,
   TPDos,    TPString,  Procs,  Batch,  Downld0,  Upld0;

Const
   IsCancelled : Boolean = False;

Var
   CrashOn : Boolean;
   CrashCheck : LongInt;


Function Z_Online : Boolean;
Begin
   Z_Online := (OnOffXferState = Online);
End;


CONST
   ZBufSize = 1024;
   ZPort : WORD = 1;
   ZBaud : LongInt = 0;

TYPE
   HdrType  = Array[0..3] of Byte;
   BufType  = Array[0..2048] of Byte;
   AttnType = Array[0..32] of Byte;

CONST
   ZPAD = 42;  { '*' }
   ZBIN = 65;  { 'A' }
   ZHEX = 66;  { 'B' }
   ZBIN32 = 67;{ 'C' }
   ZDLE = 24;  { ^X  }
   ZDLEE = 88;
   ZRQINIT = 0;
   ZRINIT = 1;
   ZSINIT = 2;
   ZACK = 3;
   ZFILE = 4;
   ZSKIP = 5;
   ZNAK = 6;
   ZABORT = 7;
   ZFIN = 8;
   ZRPOS = 9;
   ZDATA = 10;
   ZEOF = 11;
   ZFERR = 12;
   ZCRC = 13;
   ZCHALLENGE = 14;
   ZCOMPL = 15;
   ZCAN = 16;
   ZFREECNT = 17;
   ZCOMMAND = 18;
   ZSTDERR = 19;
   ZCRCE = 104; { 'h' }
   ZCRCG = 105; { 'i' }
   ZCRCQ = 106; { 'j' }
   ZCRCW = 107; { 'k' }
   ZRUB0 = 108; { 'l' }
   ZRUB1 = 109; { 'm' }
   ZOK = 0;
   ZERROR = -1;
   ZTIMEOUT = -2;
   RCDO = -3;
   FUBAR = -4;
   GOTOR = 256;
   GOTCRCE = 360; { 'h' OR 256 }
   GOTCRCG = 361; { 'i' "   "  }
   GOTCRCQ = 362; { 'j' "   "  }
   GOTCRCW = 363; { 'k' "   "  }
   GOTCAN = 272;  { CAN OR  "  }

   ENQ = 5;
   CAN = 24;
   XOFF = 19;
   XON = 17;
   SOH = 1;
   STX = 2;
   EOT = 4;
   ACK = 6;
   NAK = 21;
   CPMEOF = 26;

   ZF0 = 3;
   ZF1 = 2;
   ZF2 = 1;
   ZF3 = 0;
   ZP0 = 0;
   ZP1 = 1;
   ZP2 = 2;
   ZP3 = 3;

   CANFDX = 1;    { can handle full-duplex          (yes for PC's)}
   CANOVIO = 2;   { can overlay disk and serial I/O (ditto)       }
   CANBRK = 4;    { can send a break - True but superfluous       }
   CANCRY = 8;    { can encrypt/decrypt - not defined yet         }
   CANLZW = 16;   { can LZ compress - not defined yet             }
   CANFC32 = 32;  { can use 32 bit crc frame checks - true        }
   ESCALL = 64;   { escapes all control chars. NOT implemented    }
   ESC8 = 128;    { escapes the 8th bit. NOT implemented          }

   TESCCTL = 64;
   TESC8 = 128;

   { ZF0 }
   ZCBIN = 1;
   ZCNL = 2;
   ZCRESUM = 3;
   { ZF1 }
   ZMNEW = 1;
   ZMCRC = 2;
   ZMAPND = 3;
   ZMCLOB = 4;
   ZMSPARS = 5;
   ZMDIFF = 6;
   ZMPROT = 7;
   { ZF2 }
   ZTLZW = 1;
   ZTCRYPT = 2;
   ZTRLE = 3;
   { ZF3 }
   ZCACK1 = 1;

VAR
   rxpos: LongInt;
   rxhdr: hdrtype;
   Sending,
   ZPgDn : Boolean;
   rxtimeout,
   rxtype,
   rxframeind: Integer;
   attn: attntype;
   secbuf: buftype;
   zbufcount : Word;
   FileN: String;
   fmode: Integer;
   ftime,
   fsize: LongInt;
   usecrc32: Boolean;
   zcps,
   txpos: LongInt;
   txhdr: hdrtype;
   ztime: LongInt;

CONST
   lastsent: Byte = 0;


CONST
   C1970 = 2440588;
   D0 =    1461;
   D1 =  146097;
   D2 = 1721119;

Procedure GregorianToJulianDN(Year, Month, Day : Integer;
                                  Var JulianDN : LongInt);
var
  Century,
  XYear    : LongInt;
Begin {GregorianToJulianDN}
  If Month <= 2 Then
     Begin
        Year := pred(Year);
        Month := Month + 12;
     End;
  Month := Month - 3;
  Century := Year div 100;
  XYear := Year mod 100;
  Century := (Century * D1) shr 2;
  XYear := (XYear * D0) shr 2;
  JulianDN := ((((Month * 153) + 2) div 5) + Day) + D2
                                    + XYear + Century;
End; {GregorianToJulianDN}


Procedure JulianDNToGregorian(JulianDN : LongInt;
                  Var Year, Month, Day : Integer);
var
  Temp, XYear   : LongInt;
  YYear, YMonth,YDay : Integer;
Begin
  Temp := (((JulianDN - D2) shl 2) - 1);
  XYear := (Temp mod D1) or 3;
  JulianDN := Temp div D1;
  YYear := (XYear div D0);
  Temp := ((((XYear mod D0) + 4) shr 2) * 5) - 3;
  YMonth := Temp div 153;
  If YMonth >= 10 Then
     Begin
        YYear := YYear + 1;
        YMonth := YMonth - 12;
     End;
  YMonth := YMonth + 3;
  YDay := Temp mod 153;
  YDay := (YDay + 5) div 5;
  Year := YYear + (JulianDN * 100);
  Month := YMonth;
  Day := YDay;
End; {JulianDNToGregorian}


Function Z_ToUnixDate(fdate: LongInt): String;
VAR
   dt: DateTime;
   secspast, datenum, dayspast: LongInt;
   s: String;
Begin
   UnpackTime(fdate,dt);
   GregorianToJulianDN(dt.year,dt.month,dt.day,datenum);
   dayspast := datenum - c1970;
   secspast := dayspast * 86400;
   secspast := secspast + dt.hour * 3600 + dt.min * 60 + dt.sec;
   s := '';
   While (secspast <> 0) AND (Length(s) < 255) DO
      Begin
         s := Chr((secspast AND 7) + $30) + s;
         secspast := (secspast SHR 3)
      End;
   s := '0' + s;
   Z_ToUnixDate := s
End;

Function Z_FromUnixDate(s: String): LongInt;
VAR
   dt: DateTime;
   secspast, datenum: LongInt;
   n: WORD;
Begin
   secspast := LongInt(0);
   For n := 1 TO Length(s) DO
      secspast := (secspast SHL 3) + Ord(s[n]) - $30;
   datenum := (secspast DIV 86400) + c1970;
   JulianDNToGregorian(datenum,Integer(dt.year),Integer(dt.month),Integer(dt.day));
   secspast := secspast MOD 86400;
   dt.hour := secspast DIV 3600;
   secspast := secspast MOD 3600;
   dt.min := secspast DIV 60;
   dt.sec := secspast MOD 60;
   PackTime(dt,secspast);
   Z_FromUnixDate := secspast
End;


Function Z_OpenFile(Var f: FILE; pathname: String): Boolean;
Begin
   Assign(f,pathname);
   Reset(f,1);
   Z_OpenFile := (IOResult = 0);
End;

Function Z_MakeFile(Var f: FILE; pathname: String): Boolean;
Begin
   Assign(f,pathname);
   ReWrite(f,1);
   Z_MakeFile := (IOResult = 0);
End;

Procedure Z_CloseFile(Var f: FILE);
Begin
   Close(f);
   IO := IOResult;
End;

Procedure Z_SendCan;
VAR
   n: Byte;
Const
   CanStr = ^X^X^X^X^X^X^X^X^H^H^H^H^H^H^H^H^H^H;
Begin
   Clear_Buffer2;
   Write_Byte(CanStr);
   IsCancelled := True;
End;


Function Z_SeekFile(Var f: File; fpos: LongInt): Boolean;
Begin
   Seek(f,fpos);
   Z_SeekFile := (IOResult = 0)
End;


Function Z_WriteFile(Var f: FILE; Var buff;
                     Bytes: WORD; rxbytes : LongInt) : Boolean;
Begin
   If CTS_ and not qq.NoCTSDrop Then
      Turn_Off_RTS;
   BlockWrite(f,buff,bytes);
   If CTS_ and not qq.NoCTSDrop Then
      Turn_On_RTS;
   Z_WriteFile := IOResult=0;
End;


Function Z_ReadFile(Var f: FILE; Var buff; btoread: WORD; Var bread: WORD): Boolean;
Begin
   BlockRead(f,buff,btoread,bread);
   Z_ReadFile := (IOResult = 0)
End;


Function Z_FindFile(pathname: String; Var name: String; Var size, time: LongInt): Boolean;
VAR
   sr: SearchRec;
Begin
   FindFirst(pathname,Archive,sr);
   If (DosError <> 0) OR (IOResult <> 0) Then
      Begin
         Z_FindFile := FALSE;
         Exit
      End;
   name := sr.Name;
   size := sr.Size;
   time := sr.Time;
   Z_FindFile := TRUE
End;


Procedure Z_SetFTime(Var f: FILE; time: LongInt);
Begin
   SetFTime(f,time);
   If (IOResult <> 0) Then
      {null}
End;


Procedure Z_OpenWindow(Ch : Char);
Begin
   Build_Xfer_Screen(Ch);
End;


Procedure Z_CloseWindow;
Begin
   Restore_Screen;
End;


Procedure Z_ShowName(filename: String);
Begin
   Download_Status(filename,'ZMODEM');
   If filename <> '' Then
      Logit('++ File '+filename);
End;


Procedure Z_ShowSize(L: LongInt);
Begin
   Show_Bytes_Total(L);
   Show_Blocks_Total(BlockSize2(L,1024));
End;


Procedure Z_ShowCheck(is32: Boolean);
Begin
   If is32 Then
      Show_Protocol('ZMODEM CRC32')
   Else
      Show_Protocol('ZMODEM CRC16');
End;



Procedure Z_Message(s: String);
Begin
   StatusMsg(s);
   Delay(250);
End;

Procedure Z_ZRPOSmsg;
Begin
   Clear_Buffer2;
   Z_Message('GOT ZRPOS HEADER');
End;


Procedure Z_Frame(N, Where : Integer);
Var
  S : String;
Begin
   S := '';
   {S := S + '['+Long2Str(Where)+'] ';}
   If IsCancelled Then
      N := 16;
   Case N OF
      -4 : {S := S + 'FUBAR ?!?'};
      -3 : S := S + 'NOCARRIER';
      -2 : S := S + 'TIMEOUT';
      -1 : Begin
             S := S + 'ERROR';
           End;
      0,
      1,
      2  : S := S + 'INITIALIZING';
      3  : S := S + 'ZACK';
      4  : S := S + 'ZFILE';
      5  : S := S + 'ZSKIP';
      6  : S := S + 'ZNAK';
      7  : S := S + 'ZABORT';
      13 : S := S + 'ZCRC';
      14 : S := S + 'ZCHALLENGE';
      8  : S := S + 'ZFINISHED';
      9  : S := S + 'ZRPOS';
      10 : S := S + 'ZHEADER';
      11 : S := S + 'ZEOF';
      12 : S := S + 'FERR';
      15 : S := S + 'COMPLETE';
      16 : S := S + 'CANCELLED';
      17 : S := S + 'ZFREECNT';
      18 : S := S + 'ZCOMMAND';
      19 : S := S + 'ZSTDERR';
      ZCRCE   : {S := S + 'ZCRCE PACKET'};
      ZCRCG   : {S := S + 'ZCRCG PACKET'};
      ZCRCQ   : {S := S + 'ZCRCQ PACKET'};
      ZCRCW   : {S := S + 'ZCRCW PACKET'};
      GOTCRCE : {S := S + 'GOTCRCE PACKET'};
      GOTCRCG : {S := S + 'GOTCRCG PACKET'};
      GOTCRCQ : {S := S + 'GOTCRCQ PACKET'};
      GOTCRCW : {S := S + 'GOTCRCW PACKET'};
      Else       S := S + 'UNKNOWN ['+Long2Str(n)+']';
   End;
   StatusMsg(s);
End;


Procedure Z_ShowLocD(L: LongInt);
Begin
   Blocknum := (L div 1024)+1;
   Tot_K := L;
   Expectedsize := fsize;
   Show_Errors;
   Figure_BPS(fsize);
End;


Procedure Z_ShowLocS(L: LongInt; Done : Boolean);
Begin
   Blocknum := (L div 1024);
   If Done Then
      If (L mod 1024) <> 0 Then
         Inc(BlockNum);
   T_Errors := Ecount;
   Tot_K := L;
   Upld0.Show_Status(L, L, Fsize);
End;


Procedure Z_FlushOutBound;
Begin
   Repeat
   Until (not Z_Online) or (Not CommPressed);
   If (Not Z_Online) and CommPressed Then
      Clear_Buffer2;
End;


Procedure Z_SendBreak;
(* Send a break signal *)
Begin
   Break_Low;
End;



Function Z_ReceiveByte: Integer;
(* Input one Byte (N.B.: RETURNS AN Integer!) *)
VAR
   n: Integer;
Begin
   n := Ord(Cinkeyz);
   Z_ReceiveByte := n;
End;


Function Z_SetTimer: LongInt;
VAR
   l: LongInt;
   h,m,s,x: WORD;
Begin
   GetTime(h,m,s,x);
   l := LongInt(h) * 3600;
   l := l + LongInt(m) * 60;
   l := l + LongInt(s);
   Z_SetTimer := l
End;


Function Z_FileCRC32(Var f: FILE): LongInt;
VAR
   fbuf: buftype;
   crc: LongInt;
   bread, n: Integer;
Begin
   crc := $FFFFFFFF;
   Seek(f,0);
   IO := IOResult;
   Repeat
      BlockRead(f,fbuf,ZBUFSIZE,bread);
      For n := 0 TO (bread - 1) DO
         crc := UpdC32(fbuf[n],crc)
   Until (bread < ZBUFSIZE) OR (IOResult <> 0);
   Seek(f,0);
   IO := IOResult;
   Z_FileCRC32 := crc
End;


Function Z_GetByte(tenths: Integer): Integer;
(* Reads a Byte from the modem - Returns RCDO if *)
(* no carrier, or ZTIMEOUT if nothing received   *)
(* within 'tenths' of a second.                  *)
VAR
   N: LongInt;
Begin
   n := tenths*10;
   Repeat
      If CommPressed Then
         Begin
            Z_GetByte := Z_ReceiveByte; { got character }
            Exit;
         End;
      If NOT Z_Online Then
         Begin
            Z_GetByte := RCDO;    { nobody to talk to }
            Exit;
         End;
      If not ZPgDn Then
         ZPgDn := Check_keyboard;
      Dec(n);                     { dec. the count    }
      Delay(100);                  { pause 1/100th sec. }
   Until (n <= 0) or ZPgDn;
   Z_GetByte := ZTIMEOUT;         { timed out }
End;


Function Z_qk_read: Integer;
(* Just like Z_GetByte, but timeout value is in *)
(* global Var rxtimeout.                        *)
Begin
   Z_qk_read := Z_GetByte(rxtimeout);
End;


Function Z_TimedRead: Integer;
(* A Z_qk_read, that strips parity and *)
(* ignores XON/XOFF characters.        *)
VAR
   c: Integer;
Begin
   Repeat
      c := Z_qk_read;
      If c <> ZTIMEOUT Then
         c := c AND $FF7F                { strip parity }
   Until (c < 0) OR (NOT (Lo(c) IN [17,19])); { wait for other than XON/XOFF }
   Z_TimedRead := c;
End;


Procedure Z_PutString(Var px; len : Integer);
(* Outputs an ASCII-Z type String (null terminated) *)
(* Processes meta characters 221 (send break) and   *)
(* 222 (2 second delay).                            *)

VAR
   s,n,o: Integer;
   p : Buftype absolute px;

   Procedure SendBuf;
   Begin
       Write_Byte3(p[s],o);
       s := n+1;
       o := 0;
   End;

Begin
   n := 0;
   o := 0;
   s := 0;
   For n := 0 to LEN-1 do
      Begin
         Case p[n] OF
            0   : Begin
                     SendBuf;
                     Exit;
                  End;
            221 : Begin
                     SendBuf;
                     Z_SendBreak;
                  End;
            222 : Begin
                     SendBuf;
                     Delay(2000);
                  End;
            Else  Inc(o);
         End;
      End;
   SendBuf;

   If not ZPgDn Then
      ZPgDn := Check_keyboard;
End;


Procedure Z_PutHex(b: Byte);
(* Output a Byte as two hex digits (in ASCII) *)
(* Uses lower Case to avoid confusion with    *)
(* escaped control characters.                *)
CONST
   hex: Array[0..15] of CHAR = '0123456789abcdef';
Begin
   Write_Byte(Chr(Ord(hex[b SHR 4])));  { high nybble }
   Write_Byte(Chr(Ord(hex[b AND $0F]))) { low nybble  }
End;


Procedure Z_SendHexHeader(htype: Byte; Var hdr: hdrtype;Dorzee : Boolean);
(* Sends a zmodem hex type header *)
VAR
   crc: WORD;
   n, i: Integer;
Const
   HexHeaderStr = Chr(ZPad)+Chr(ZPad)+Chr(ZDle)+Chr(ZHex);
Begin
   {Z_Message('SENDING HEX HEADER');}

   If DoRZee Then
      Write_Byte('rz'^M);     { make it readable to the other end }

   Write_Byte(HexHeaderStr);
   Z_PutHex(htype);
   crc := UpdateCrc(htype,0);
   For n := 0 TO 3 DO
      Begin
         Z_PutHex(hdr[n]);
         crc := UpdateCrc(hdr[n],crc)
      End;
   crc := UpdateCrc(0,crc);
   crc := UpdateCrc(0,crc);

   Z_PutHex(Hi(crc));
   Z_PutHex(Lo(crc));
   Write_Byte(^M^J);
   If (htype <> ZFIN) AND (htype <> ZACK) Then
      Write_Byte(^Q);
End;


Function Z_PullLongFromHeader(Var hdr: hdrtype): LongInt;
VAR
   l: LongInt;
Begin
   l := hdr[ZP3];
   l := (l SHL 8) OR hdr[ZP2];
   l := (l SHL 8) OR hdr[ZP1];
   l := (l SHL 8) OR hdr[ZP0];
   Z_PullLongFromHeader := l;
End;


Procedure Z_PutLongIntoHeader(l: LongInt);
(* Reverse of above *)
Begin
   txhdr[ZP0] := Byte(l);
   txhdr[ZP1] := Byte(l SHR 8);
   txhdr[ZP2] := Byte(l SHR 16);
   txhdr[ZP3] := Byte(l SHR 24)
End;


Function Z_GetZDL: Integer;
(* Gets a Byte and processes for ZMODEM escaping or CANcel sequence *)
VAR
   b, c, d: Integer;
Begin
   If (NOT Z_Online) Then
      Begin
         Z_GetZDL := RCDO;
         Exit;
      End;
   c := Z_qk_read;
   If (c <> ZDLE) Then
      Begin
         Z_GetZDL := c;
         Exit;
      End;
   b := 0;
   If c = CAN Then
      Inc(b);  {Got first CAN}
   Repeat
      c := Z_qk_read;
      If (c = CAN) Then  {got another CAN}
         Inc(b);
   Until (c <> CAN) or (b = 6);
   { Flags set in high Byte }
   Case c OF
      CAN  : Z_GetZDL := GOTCAN; {got 6th CAN}

      ZCRCE,  {got a frame end marker}
      ZCRCG,
      ZCRCQ,
      ZCRCW: Z_GetZDL := (c OR GOTOR);
      ZRUB0: Z_GetZDL := $7F; {got an ASCII DELete}
      ZRUB1: Z_GetZDL := $FF  {any parity         }
      Else   If (c<0) then
                Z_GetZDL := c
             Else
                Z_GetZDL := c XOR $40;
   End
End;

Function Z_GetHex: Integer;
(* Get a Byte that has been received as two ASCII hex digits *)
VAR
   c, n: Integer;
Begin
   n := Z_TimedRead;
   If (n < 0) Then
      Begin
         Z_GetHex := n;
         Exit
      End;
   n := n - $30;                     {build the high nybble}
   If (n > 9) Then
      n := n - 39;
   If (n AND $FFF0 <> 0) Then
      Begin
         Z_GetHex := ZERROR;
         Exit
      End;
   c := Z_TimedRead;
   If (c < 0) Then
   Begin
      Z_GetHex := c;
      Exit
   End;
   c := c - $30;                     {now the low nybble}
   If (c > 9) Then
      c := c - 39;
   If (c AND $FFF0 <> 0) Then
      Begin
         Z_GetHex := ZERROR;
         Exit
      End;
   Z_GetHex := (n SHL 4) OR c        {Insert tab 'A' in slot 'B'...}
End;

Function Z_GetHexHeader(Var hdr: hdrtype): Integer;
(* Receives a zmodem hex type header *)
VAR
   crc: WORD;
   c, n: Integer;
   b : Byte;
Begin
   c := Z_GetHex;
   If (c < 0) Then
      Begin
         Z_GetHexHeader := c;
         Exit
      End;
   rxtype := c;                        {get the type of header}
   crc := UpdateCrc(rxtype,0);
   For n := 0 To 3 DO                  {get the 4 Bytes}
      Begin
         c := Z_GetHex;
         If (c < 0) Then
            Begin
               Z_GetHexHeader := c;
               Exit
            End;
         hdr[n] := Lo(c);
         crc := UpdateCrc(Lo(c),crc)
      End;
   c := Z_GetHex;
   If (c < 0) Then
      Begin
         Z_GetHexHeader := c;
         Exit
      End;
   crc := UpdateCrc(Lo(c),crc);
   c := Z_GetHex;
   If (c < 0) Then
      Begin
         Z_GetHexHeader := c;
         Exit
      End;
   crc := UpdateCrc(Lo(c),crc);             {check the CRC}
   If (crc <> 0) Then
      Begin
         Z_Message('CRC ERROR IN HEX HEADER');
         Inc(Ecount);
         Z_GetHexHeader := ZERROR;
         Exit
      End;

   If PeekPortByte(b) Then
      if b = 13 Then
         Begin
            c := Z_GetByte(2);
            If PeekPortByte(b) Then
               if b = 10 Then
                  Begin
                     c := Z_GetByte(2);
                     If PeekPortByte(b) Then
                        if b = 17 Then
                           Begin
                              c := Z_GetByte(2);
                           End;
                  End;
         End;

   Z_GetHexHeader := rxtype;
End;


Function Z_GetBinaryHeader(Var hdr: hdrtype): Integer;
(* Same as above, but binary with 16 bit CRC *)
VAR
   crc: WORD;
   c, n: Integer;
Begin
   c := Z_GetZDL;
   If (c < 0) Then
      Begin
         Z_GetBinaryHeader := c;
         Exit;
      End;
   rxtype := c;
   crc := UpdateCrc(rxtype,0);
   For n := 0 To 3 DO
      Begin
         c := Z_GetZDL;
         If (Hi(c) <> 0) Then
            Begin
               Z_GetBinaryHeader := c;
               Exit;
            End;
         hdr[n] := Lo(c);
         crc := UpdateCrc(Lo(c),crc);
      End;
   c := Z_GetZDL;
   If (Hi(c) <> 0) Then
      Begin
         Z_GetBinaryHeader := c;
         Exit;
      End;
   crc := UpdateCrc(Lo(c),crc);
   c := Z_GetZDL;
   If (Hi(c) <> 0) Then
      Begin
         Z_GetBinaryHeader := c;
         Exit;
      End;
   crc := UpdateCrc(Lo(c),crc);
   If (crc <> 0) Then
      Begin
         Inc(Ecount);
         Exit
      End;
   Z_GetBinaryHeader := rxtype;
End;


Function Z_GetBinaryHead32(Var hdr: hdrtype): Integer;
(* Same as above but with 32 bit CRC *)
VAR
   crc: LongInt;
   c, n: Integer;
Begin
   c := Z_GetZDL;
   If (c < 0) Then
      Begin
         Z_GetBinaryHead32 := c;
         Exit;
      End;
   rxtype := c;
   crc := UpdC32(rxtype,$FFFFFFFF);
   For n := 0 To 3 DO
      Begin
         c := Z_GetZDL;
         If (Hi(c) <> 0) Then
            Begin
               Z_GetBinaryHead32 := c;
               Exit;
            End;
         hdr[n] := Lo(c);
         crc := UpdC32(Lo(c),crc)
      End;
   For n := 0 To 3 DO
      Begin
         c := Z_GetZDL;
         If (Hi(c) <> 0) Then
            Begin
               Z_GetBinaryHead32 := c;
               Exit;
            End;
         crc := UpdC32(Lo(c),crc)
      End;
   If (crc <> $DEBB20E3) Then   {this is the polynomial value}
      Begin
         Inc(Ecount);
         Z_GetBinaryHead32 := ZERROR;
         Exit;
      End;
   Z_GetBinaryHead32 := rxtype;
End;


Function Z_GetHeader(Var hdr: hdrtype): Integer;
(* Use this routine to get a header - it will figure out  *)
(* what type it is getting (hex, bin16 or bin32) and call *)
(* the appropriate routine.                               *)
LABEL
   GotCAN, StartOver,
   again, agn2, splat, done;
VAR
   c, CANcount: Integer;
   n : LongInt;

Begin
   n := 4800;             {A guess at the # of garbage characters}

   StartOver:
   CanCount := 5;

   Again:
   If Check_KeyBoard or ZPgDn Then
      Begin
         Z_SendCan;                             {tell the other end,   }
         Z_Message('CANCELLED');               {the operator,         }
         c := ZCAN;                   {and the rest of the   }
         Goto Done;                                  {routines to forget it.}
      End;

   rxframeind := 0;
   rxtype := 0;
   c := Z_TimedRead;
   Case c OF
      Zpad: ;              {we want this! - all headers Begin with '*'.}

      Rcdo,
      Ztimeout: Goto Done;

      CAN: Begin

              GOTCAN:

              Dec(cancount);
              If (cancount <= 0) Then
                 Begin
                    c := ZCAN;
                    Goto done;
                 End;
              c := Z_GetByte(3);
              Case c OF
                 ZTIMEOUT: GOTO again;

                 ZCRCW: Begin
                           c := ZError;
                           Goto Done;
                        End;

                 RCDO: GOTO done;

                 CAN: Begin
                         Dec(cancount);
                         If (cancount < 0) Then
                            Begin
                               c := ZCAN;
                               Goto done;
                            End;
                         Goto again;
                      End;
              End;
           End
      Else
agn2: Begin
         Dec(n);
         If (n < 0) Then
            Begin
               Inc(Ecount);
               c := ZERROR;
               Goto Done;
            End;
         Goto StartOver;
      End;
   End;

   {only falls thru if ZPAD - anything Else is trash}
   cancount := 5;

   SPLAT:

   c := Z_TimedRead;
   Case c OF
      ZPAD: Goto splat;   {junk or second '*' of a hex header}

      RCDO,
      ZTIMEOUT: Goto Done;

      ZDLE: {this is what we want!} ;
      Else  Goto AGN2;
   End; {only falls thru if ZDLE}

   c := Z_TimedRead;
   rxframeind := c;

   Case c OF
      ZBIN32   : c := Z_GetBinaryHead32(hdr);
      ZBIN     : c := Z_GetBinaryHeader(hdr);
      ZHEX     : c := Z_GetHexHeader(hdr);
      CAN      : GOTO gotcan;
      RCDO,
      ZTIMEOUT : GOTO done;
      Else       Goto agn2;
   End; {only falls thru if we got ZBIN, ZBIN32 or ZHEX}
   rxpos := Z_PullLongFromHeader(hdr);        {set rxpos just in Case this}
Done:
   Z_GetHeader := c;                          {info (i.e.: ZRPOS, etc.   )}
End;



{##########################################################################}



(***************************************************)
(* RECEIVE FILE ROUTINES                           *)
(***************************************************)

CONST
   ZATTNLEN = 32;
VAR
   t: LongInt;
   rzbatch: Boolean;
   outfile: FILE;
   tryzhdrtype: Byte;
   rxcount: Integer;
   filestart: LongInt;
   isbinary, eofseen: Boolean;
   zconv: Byte;
   zrxpath: String;


Function RZ_ReceiveDa32(Var buf: buftype; blength: Integer): Integer;
(* Get a 32 bit CRC data block *)
LABEL
   crcfoo;
VAR
   c, d, n: Integer;
   crc: LongInt;
   done: Boolean;
Begin
   Time_Stamp;
   usecrc32 := TRUE;
   crc := $FFFFFFFF;
   rxcount := 0;
   done := FALSE;
   Repeat
      c := Z_GetZDL;
      If (Hi(c) <> 0) Then
      Begin

         CRCFOO:

         Case c OF
            GOTCRCE,
            GOTCRCG,
            GOTCRCQ,
            GOTCRCW:  Begin
                         d := c;
                         crc := UpdC32(Lo(c),crc);
                         For n := 0 TO 3 DO
                            Begin
                               c := Z_GetZDL;
                               If (Hi(c) <> 0) Then
                                  Goto crcfoo;
                               crc := UpdC32(Lo(c),crc)
                            End;
                         If (crc <> $DEBB20E3) Then
                            Begin
                               Z_Message('CRC ERROR');
                               Inc(Ecount);
                               RZ_ReceiveDa32 := ZERROR;
                            End
                         Else
                            RZ_ReceiveDa32 := d;
                         Exit;
                      End;

            GOTCAN  : Begin
                         Z_Message('CANCELLED BY SENDER');
                         RZ_ReceiveDa32 := ZCAN;
                         IsCancelled := True;
                         Exit;
                      End;

            ZTIMEOUT: Begin
                         Z_Message('TIMEOUT');
                         RZ_ReceiveDa32 := c;
                         Exit;
                      End;

            RCDO: BEGIN
                     RZ_ReceiveDa32 := c;
                     Exit;
                  END
            Else      Begin
                         Z_Message('GARBLED DATA SUBPACKET');
                         Clear_Buffer;
                         RZ_ReceiveDa32 := c;
                         Exit;
                      End;
         End;
      End;

      Dec(blength);
      If (blength < 0) Then
         Begin
            Z_Message('LONG SUBPACKET');
            RZ_ReceiveDa32 := ZERROR;
            Exit;
         End;
      buf[rxcount] := Lo(c);
      Inc(rxcount);
      crc := UpdC32(Lo(c),crc)
   Until done; {which will never happen here!}
End;


Function RZ_ReceiveData(Var bufx; blength: Integer): Integer;
(* get a 16 bit CRC data block *)
LABEL
   crcfoo;
VAR
   buf : Buftype absolute bufx;
   c, d: Integer;
   crc: WORD;
   done: Boolean;
Begin
   Time_Stamp;
   If (rxframeind = ZBIN32) Then
      Begin
         Z_ShowCheck(TRUE);
         RZ_ReceiveData := RZ_ReceiveDa32(buf,blength);
         Exit;
      End;
   Z_ShowCheck(FALSE);
   crc := 0;
   rxcount := 0;
   done := FALSE;
   Repeat
      c := Z_GetZDL;
      If (Hi(c) <> 0) Then
         Begin

         CRCFOO:

         Case c OF
            GOTCRCE,
            GOTCRCG,
            GOTCRCQ,
            GOTCRCW:  Begin
                         d := c;
                         crc := UpdateCrc(Lo(c),crc);
                         c := Z_GetZDL;
                         If (Hi(c) <> 0) Then
                            Goto crcfoo;
                         crc := UpdateCrc(Lo(c),crc);
                         c := Z_GetZDL;
                         If (Hi(c) <> 0) Then
                            Goto crcfoo;
                         crc := UpdateCrc(Lo(c),crc);
                         If (crc <> 0) Then
                            Begin
                               Inc(Ecount);
                               Z_Message('CRC ERROR');
                               RZ_ReceiveData := ZERROR;
                               Exit;
                            End;
                         RZ_ReceiveData := d;
                         Exit;
                      End;
            GOTCAN:   Begin
                         Z_Message('CANCELLED BY SENDER');
                         IsCancelled := True;
                         Clear_Buffer;
                         RZ_ReceiveData := ZCAN;
                         Exit;
                      End;
            ZTIMEOUT: Begin
                         Z_Message('TIMEOUT');
                         RZ_ReceiveData := c;
                         Exit;
                      End;
            Else      Begin
                         Z_Message('GARBLED DATA SUBPACKET');
                         Clear_Buffer;
                         RZ_ReceiveData := c;
                         Exit;
                      End
         End
      End;

      Dec(blength);

      If (blength < 0) Then
         Begin
            Z_message('LONG PACKET');
            RZ_ReceiveData := ZERROR;
            Exit;
         End;
      Buf[rxcount] := Lo(c);
      Inc(rxcount);
      CRC := UpdateCrc(Lo(c),crc);
   Until Done;
End;


Procedure RZ_AckBibi;
(* ACKnowledge the other ends request to terminate cleanly *)
VAR
   n: Integer;
Begin
   Z_PutLongIntoHeader(0);
   n := 4;
   Repeat
      Clear_Buffer;
      Z_SendHexHeader(ZFIN,txhdr,false);
      Case Z_GetByte(30) OF
         ZTIMEOUT,
         RCDO     : Exit;
         79       : Begin
                       If (Z_GetByte(10) = 79) Then;
                       Clear_Buffer;
                       Exit;
                    End;
         Else       Clear_Buffer;
      End;
      Dec(n);
   Until (n <= 0);
End;


Function RZ_InitReceiver: Integer;
{ "tryz()" in rzsz docs}
LABEL
   again, continueloop;
VAR
   c, n,
   errors: Integer;
Begin
   FillChar(attn,SizeOf(attn),0);
   Ecount := 0;
   For n := 20 DOWNTO 0 DO
      Begin
         Z_PutLongIntoHeader(0);
         {Full dplx, overlay I/O and CRC32}
         txhdr[ZF0] := CANFDX OR CANOVIO OR CANFC32 OR CANBRK;
         Z_SendHexHeader(tryzhdrtype,txhdr,False);
         If tryzhdrtype = ZSKIP Then
            tryzhdrtype := ZRINIT;

again:
         c := Z_GetHeader(rxhdr);
         Z_Frame(c,1);
         Case c OF
            ZTIMEOUT: Begin
                         Z_Message('TIMEOUT');
                      End;

            ZFILE   : Begin
                         zconv := rxhdr[ZF0];
                         tryzhdrtype := ZRINIT;
                         c := RZ_ReceiveData(secbuf,ZBUFSIZE);
                         Z_Frame(c,2);
                         If (c = GOTCRCW) Then
                            Begin
                               RZ_InitReceiver := ZFILE;
                               Exit;
                            End;
                         Z_SendHexHeader(ZNAK,txhdr,false);
                         Goto Again;
                      End;

            ZSINIT:   Begin
                         c := RZ_ReceiveData(attn,ZAttnLEN);
                         Z_Frame(c,3);
                         If (c = GOTCRCW) Then
                            Begin
                               Z_PutLongIntoHeader(1);
                               Z_SendHexHeader(ZACK,txhdr,False);
                            End
                         Else
                            Z_SendHexHeader(ZNAK,txhdr,False);
                         Goto Again;
                      End;

            ZFREECNT: Begin
                         Z_PutLongIntoHeader(Free_Space('0'));
                         Z_SendHexHeader(ZACK,txhdr,False);
                         Goto Again;
                      End;

            ZCOMMAND: BEGIN
                         c := RZ_ReceiveData(secbuf,ZBUFSIZE);
                         Z_Frame(c,4);
                         IF (c = GOTCRCW) THEN
                         BEGIN
                            Z_PutLongIntoHeader(LONGINT(0));
                            REPEAT
                               Z_SendHexHeader(ZCOMPL,txhdr,False);
                               Inc(Ecount)
                            UNTIL (Ecount> 10) OR (Z_GetHeader(rxhdr) = ZFIN);
                            RZ_AckBibi;
                            RZ_InitReceiver := ZCOMPL;
                            Exit
                         END;
                         Z_SendHexHeader(ZNAK,txhdr,False);
                         GOTO again;
                      END;
            ZCOMMAND: Begin
                         Z_SendHexHeader(ZNAK,txhdr,False);
                      End;

            ZCOMPL :  Goto Again;
            ZFIN:     Begin
                         RZ_AckBibi;
                         RZ_InitReceiver := ZCOMPL;
                         Exit;
                      End;

            ZCAN,
            RCDO:     Begin
                         RZ_InitReceiver := c;
                         Exit;
                      End;

         End;
         Continueloop:
      End;
   RZ_InitReceiver := ZERROR;
End;


Function RZ_GetHeader: Integer;
Label
   AutoInc;
VAR
   e, p, n, i: Integer;
   multiplier: LongInt;
   s: String;
   ttime, tsize: LongInt;
   tname: String;
Begin
   isbinary := TRUE;    {Force the issue!}
   fsize := LongInt(0);
   p := 0;
   s := '';
   While (p < 255) AND (secbuf[p] <> 0) DO
      Begin
         s := s + UpCase(Chr(secbuf[p]));
         Inc(p)
      End;
   Inc(p);
   (* get rid of drive & path specifiers *)
   FileN := IBMFilenameFix(JustFileName(s));

(**** done with name ****)

   fsize := LongInt(0);
   While (p < ZBUFSIZE) AND (secbuf[p] <> $20) AND (secbuf[p] <> 0) DO
      Begin
         fsize := (fsize *10) + Ord(secbuf[p]) - $30;
         Inc(p)
      End;
   Inc(p);
   Show_Bytes_Total(Fsize);
   SHow_Blocks_Total(BlockSize2(Fsize,1024));
   Show_Block_Size(1024);

(**** done with size ****)

   S := '';
   While (p < ZBUFSIZE) AND (secbuf[p] IN [$30..$37]) DO
      Begin
         S := S + Chr(secbuf[p]);
         Inc(p)
      End;
   Inc(p);
   If S <> '' Then
      Ftime := Z_FromUnixDate(s)
   Else
      Ftime := 0;

(**** done with time ****)

   {Fsize is the size reported by the remote Zmodem
    Tsize is the local copy size if it exists       }

   If (Z_FindFile(zrxpath+FileN,tname,tsize,ttime)) Then
      Begin
         If (fsize >= tsize) Then
            Begin
               filestart := tsize;
               If (NOT Z_OpenFile(outfile, zrxpath + FileN)) Then
                  Begin
                     RZ_GetHeader := ZERROR;
                     Exit
                  End;
               If (NOT Z_SeekFile(outfile,tsize)) Then
                  Begin
                     RZ_GetHeader := ZERROR;
                     Exit
                  End;
               Z_Message('CRASH RECOVERY');
               CrashOn := True;
               If tsize > 512 Then
                  Begin
                     FileStart := tsize-512;
                     CrashCheck := 512;
                  End
               Else
                  Begin
                     Filestart := 0;
                     CrashCheck := tsize;
                  End;
            End
         Else
            Begin
               If qq.AutoIncrement Then
                  Begin
                     FileN := IncFileName(Addbackslash(zrxpath)+FileN);
                     FileN := JustFileName(FileN);
                     Z_Message('INCREMENTING FILENAME');
                     Goto AutoInc;
                  End
               Else
                  If qq.Overwrite Then
                     Begin
                        Z_Message('OVERWRITING FILE');
                        Goto AutoInc;
                     End;
               Z_ShowName(FileN);
               Z_Message('FILE SKIPPED');
               RZ_GetHeader := ZSKIP;
               Exit
            End
      End
   Else
      Begin
         AutoInc:
         filestart := 0;
         If (NOT Z_MakeFile(outfile,zrxpath + FileN)) Then
            Begin
               Z_Message('CANNOT CREATE FILE');
               RZ_GetHeader := ZERROR;
               Exit
            End
      End;
   Z_ShowName(zrxpath+FileN);
   RZ_GetHeader := ZOK
End;


Function FileIsSame(Var F1 : File) : Boolean;
Var
   Result, x : Word;
   F : file;
   Buffer : Array[1..1024] of Byte;
Begin
   Z_Message('COMPARING BLOCKS');
   CrashOn := False;
   Assign(f, Addbackslash(zrxpath)+FileN);
   Reset (f,1);
   Seek  (f, FileStart);
   BlockRead (f,Buffer, CrashCheck, Result);
   Close (f);
   IO := IOResult;
   FileIsSame := False;
   For x := 1 to Result do
      If Buffer[x] <> secbuf[x-1] Then
         Exit;
   FileIsSame := True;
   Seek(F1,FileSize(F1)-CrashCheck);
End;


Procedure ReWindFile(Var RXbytes : LongInt);
Begin
   rxbytes := 0;
   If qq.OverWrite Then
      Begin
         Z_Message('OVERWRITING FILE');
         Seek(outfile,0);
         Truncate(outfile);
      End
   Else
      Begin
         Z_Message('INCREMENTING FILENAME');
         Close(outfile);
         FileN := IncFileName(Addbackslash(zrxpath)+FileN);
         FileN := JustFileName(FileN);
         Assign(outfile, Addbackslash(zrxpath)+FileN);
         ReWrite(outfile,1);
         Z_ShowName(FileN);
      End
End;


Function RZ_SaveToDisk(Var rxbytes: LongInt): Integer;
Begin
   If Check_KeyBoard or ZPgDn Then
      Begin
         Z_SendCan;                             {tell the other end,   }
         Z_Message('CANCELLED');               {the operator,         }
         RZ_SaveToDisk := ZERROR;
         Wait_for_Clean_Line(True);
         Exit;
      End;

   If (NOT Z_WriteFile(outfile,secbuf,rxcount,rxbytes)) Then
      Begin
         Z_Message('FILE WRITE ERROR');
         RZ_SaveToDisk := ZERROR;
      End
   Else
      RZ_SaveToDisk := ZOK;
   rxbytes := rxbytes + rxcount;
   Show_Block_Size(rxcount);
End;

Function RZ_ReceiveFile: Integer;
LABEL
   TopZRPOS, err, nxthdr, moredata;
VAR
   c, c2, n: Integer;
   rxbytes: LongInt;
   sptr: String;
   done: Boolean;
   OK : Boolean;
Begin
   Ecount := 0;
   zbufcount := 0;
   done := FALSE;
   eofseen := FALSE;
   c := RZ_GetHeader;
   If (c <> ZOK) Then
      Begin
         If (c = ZSKIP) Then
            tryzhdrtype := ZSKIP;
         RZ_ReceiveFile := c;
         Exit;
      End;
   c := ZOK;
   n := 20;
   rxbytes := filestart;
   rxpos := filestart;
   ztime := Z_SetTimer;
   zcps := 0;
   Repeat

TopZRPOS:

      Z_PutLongIntoHeader(rxbytes);
      Z_Message('SENDING ZRPOS');
      Z_SendHexHeader(ZRPOS,txhdr,False);

      NXTHDR:

      c := Z_GetHeader(rxhdr);
      Z_Frame(c,4);
      Case c OF
         ZDATA: Begin
                   If (rxpos <> rxbytes) Then
                      Begin
                         Dec(n);
                         Inc(Ecount);
                         If (n = 0) Then
                            Goto err;
                         Z_Message('BAD FILE POSITION');
                         Z_PutString(attn,ZattnLen)
                      End
                   Else
                      Begin

                         MOREDATA:

                         c := RZ_ReceiveData(secbuf,ZBUFSIZE);

                         Z_Frame(c,5);

                         Case c OF
                            ZCAN     : Begin
                                          Goto TopZRPOS{err};
                                       End;

                            ZERROR   : Begin
                                          Dec(n);
                                          Inc(Ecount);
                                          If (n = 0) Then
                                             Goto err;
                                          Z_PutString(attn,ZattnLen)
                                       End;

                            ZTIMEOUT : Begin
                                          Dec(n);
                                          If (n = 0) Then
                                             Goto err;
                                       End;

                            GOTCRCW,
                            GOTCRCE  : Begin
                                          n := 20;
                                          If CrashOn Then
                                             Begin
                                                OK := FileIsSame(outfile);
                                                If Not OK Then
                                                   Begin
                                                      ReWindFile(rxbytes);
                                                      Goto TopZRPOS;
                                                   End;
                                             End;
                                          c2 := RZ_SaveToDisk(rxbytes);
                                          If (c2 <> ZOK) Then
                                             Begin
                                                RZ_ReceiveFile := c2;
                                                Exit
                                             End;
                                          Z_ShowLocd(rxbytes);
                                          If c = GOTCRCW then
                                             Begin
                                                Z_PutLongIntoHeader(rxbytes);
                                                Z_SendHexHeader(ZACK,txhdr,False);
                                             End;
                                          Goto nxthdr;
                                       End;

                            GOTCRCQ,
                            GOTCRCG  : Begin
                                          n := 20;
                                          If CrashOn Then
                                             Begin
                                                OK := FileIsSame(outfile);
                                                If Not OK Then
                                                   Begin
                                                      ReWindFile(rxbytes);
                                                      Goto TopZRPOS;
                                                   End;
                                             End;
                                          c2 := RZ_SaveToDisk(rxbytes);
                                          If (c2 <> ZOK) Then
                                             Begin
                                                RZ_ReceiveFile := c2;
                                                Exit
                                             End;
                                          Z_ShowLocd(rxbytes);
                                          If c = GOTCRCQ then
                                             Begin
                                                Z_PutLongIntoHeader(rxbytes);
                                                Z_SendHexHeader(ZACK,txhdr,False);
                                             End;
                                          Goto MoreData;
                                       End;

                            Else       Begin
                                          Dec(n);
                                          Inc(Ecount);
                                          If (n = 0) Then
                                             Goto err;
                                          Z_ShowLocd(rxbytes);
                                          Z_PutString(attn,ZattnLen)
                                       End;

                         End {case}
                      End
                End; {case of ZDATA}

         ZNAK,
         ZTIMEOUT: Begin
                      Dec(n);
                      Inc(Ecount);
                      If (n = 0) Then
                         Goto TopZRPOS{err};
                      Z_ShowLocd(rxbytes);
                   End;

         ZFILE: Begin
                   c := RZ_ReceiveData(secbuf,ZBUFSIZE);
                   Z_Frame(c,6);
                End;

         ZEOF: IF rxpos = rxbytes Then
                  Begin
                     RZ_ReceiveFile := c;
                     Show_Blocks_rcvd(Blocksize2(rxbytes,1024));
                     Exit;
                  End
               Else
                  Goto nxthdr;

         ZERROR: Begin
                    Dec(n);
                    Inc(Ecount);
                    If (n = 0) Then
                       Goto err;
                    Z_ShowLocd(rxbytes);
                    Z_PutString(attn,ZattnLen)
                 End
         Else
            Begin
               Goto Err;
            End;

            {Goto TopZRPos{err;}
      End {case}
   Until (done);

   ERR:

   RZ_ReceiveFile := ZERROR;
End;


Function RZ_ReceiveBatch: Integer;
VAR
   s : String;
   c : Integer;
   done : Boolean;
Begin
   DONE := FALSE;
   While (NOT done) DO
      Begin
         If NOT (Z_Online) Then
            Begin
               RZ_ReceiveBatch := ZERROR;
               Exit
            End;
      CrashOn := False;
      Tot_K := 0;
      Effective_PCT := 0.0;
      Avg_BPS := 0.0;
      Stamp_Taken := False;
      Show_Gas_Gauge(0);
      Clear_Status_Fields;
      c := RZ_ReceiveFile;
      Z_Frame(c,7);
      If Ftime > 0 Then
         Z_SetFTime(outfile,ftime);
      Z_CloseFile(outfile);
      Log_BPSstuff;
      Case c OF
         ZEOF,
         ZSKIP: Begin
                   c := RZ_InitReceiver;
                   Z_Frame(c,8);
                   Case c OF
                      ZFILE : {null};
                      ZCOMPL: Begin
                                 RZ_ReceiveBatch := ZOK;
                                 Exit;
                              End;
                      Else    Begin
                                 RZ_ReceiveBatch := ZERROR;
                                 Exit;
                              End
                   End
                End
         Else
            Begin
               RZ_ReceiveBatch := c;
               Exit
            End
      End {case}
   End {while}
End;


Function Zmodem_Receive(Auto : Boolean) : Boolean;
VAR
   i: Integer;
   XPath : String;
LABEL
   EExit;
Begin
   Check_Parity;
   OnOffXferState := Online;
   Sending := False;
   IsCancelled := False;
   zbaud := NewSpeed;
   zport := qq.Commport;
   ShowPct := True;
   zPgDn := False;
   Script_Success := False;

   If Scripting or Hosting Then
      XPath := JustPathname(sFilename)
   Else
      If Auto Then
         XPath := Downld_Path
      Else
         Begin
            XPath := Get_File_Name(Downld_Path, '', '',
                                  5, 'Download Path Allocation',False);
            If XPath = '' Then
               Goto EExit;

            Downld_Path := XPath;
         End;

  Logit('Download Protocol : Zmodem');

  If QuickLearn Then
     WriteLearn('Download Z '+XPath);

   Z_OpenWindow('D');
   HiddenCursor;
   TextAttr := qq.Menu;
   zrxpath := Xpath;
   If (zrxpath[Length(zrxpath)] <> '\') AND (zrxpath <> '') Then
      zrxpath := zrxpath + '\';
   rxtimeout := 100;
   Clear_Buffer;
   tryzhdrtype := ZRINIT;
   Z_ShowName('');
   I := RZ_InitReceiver;
   If (i = ZCOMPL) or
      ((i = ZFILE) and ((RZ_ReceiveBatch) = ZOK)) Then
      Begin
         Status_Msg(9);
         Sound_Completion;
         Z_CloseWindow;
         Zmodem_Receive := TRUE;
         Script_Success := True;
      End
   Else
      Begin
         Clear_Buffer2;
         Z_SendCan;
         Wait_for_Clean_Line(False);
         Z_CloseWindow;
         EExit:
         Zmodem_Receive := FALSE;
      End;
   NormalCursor;
   Reset_Parity;
End;


(*######### SEND ROUTINES #####################################*)



VAR
   infile: FILE;
   strtpos: LongInt;
   rxbuflen: Integer;
   txbuf: buftype;
   blkred: Integer;


Procedure SZ_Z_SendByte(b: Byte);
Begin
   If ((b AND $7F) IN [16,17,19,24]) OR
      (((b AND $7F) = 13) AND ((lastsent AND $7F) = 64)) Then
      Begin
         Write_Byte(Chr(ZDLE));
         lastsent := (b XOR 64)
      End
   Else
      lastsent := b;
   Write_Byte(Chr(lastsent));
End;


Procedure SZ_SendBinaryHead32(htype: Byte; Var hdr: hdrtype);
VAR
   crc: LongInt;
   n: Integer;
Begin
   Write_Byte(Chr(ZPAD)+Chr(ZDLE)+Chr(ZBIN32));
   SZ_Z_SendByte(htype);
   crc := UpdC32(htype,$FFFFFFFF);
   For n := 0 TO 3 DO
      Begin
         SZ_Z_SendByte(hdr[n]);
         crc := UpdC32(hdr[n],crc)
      End;
   crc := (NOT crc);
   For n := 0 TO 3 DO
      Begin
         SZ_Z_SendByte(BYTE(crc));
         crc := (crc SHR 8)
      End;
   {
   If (htype <> ZDATA) Then
      Delay(500);
   }
End;

Procedure SZ_SendBinaryHeader(htype: Byte; Var hdr: hdrtype);
VAR
   crc: WORD;
   n: Integer;
Begin
   If (usecrc32) Then
      Begin
         SZ_SendBinaryHead32(htype,hdr);
         Exit;
      End;
   Write_Byte(Chr(ZPAD)+Chr(ZDLE)+Chr(ZBIN));
   SZ_Z_SendByte(htype);
   crc := UpdateCrc(htype,0);
   For n := 0 TO 3 DO
      Begin
         SZ_Z_SendByte(hdr[n]);
         crc := UpdateCrc(hdr[n],crc)
      End;
   crc := UpdateCrc(0,crc);
   crc := UpdateCrc(0,crc);
   SZ_Z_SendByte(Lo(crc SHR 8));
   SZ_Z_SendByte(Lo(crc));
   If (htype <> ZDATA) Then
      {Delay(500)}
End;

Procedure SZ_SendDa32(Var buf: buftype; blength: Integer; frameend: Byte);
VAR
   crc: LongInt;
   o,t: Integer;
   hold : Array[1..2048] of Byte;

   Procedure StoreBuf(b : Byte);
   Begin
      If ((b AND $7F) IN [16,17,19,24]) OR
         (((b AND $7F) = 13) AND ((lastsent AND $7F) = 64)) Then
         Begin
            Hold[o] := ZDLE;
            Inc(o);
            Hold[o] := (b XOR 64);
            inc(o);
            Exit;
         End;
      hold[o] := b;
      inc(o);
   End;


Begin
   crc := $FFFFFFFF;
   o := 1;
   For t := 1 TO blength DO
      Begin
         StoreBuf(Byte(buf[t-1]));
         crc := UpdC32(buf[t-1],crc)
      End;
   Write_Byte3(Hold[1],o-1);

   crc := UpdC32(frameend,crc);
   crc := (NOT crc);
   Write_Byte(Chr(ZDLE));
   Write_Byte(Chr(frameend));
   For t := 0 TO 3 DO
      Begin
         SZ_Z_SendByte(BYTE(crc));
         crc := (crc SHR 8);
      End;
   If frameend = ZCRCW Then
      Begin
         Write_Byte(^Q);
      End
End;

Procedure SZ_SendData(Var buf: buftype; blength: Integer; frameend: Byte);
VAR
   crc: WORD;
   o,t: Integer;
   hold : Array[1..2048] of Byte;

   Procedure StoreBuf(b : Byte);
   Begin
      If ((b AND $7F) IN [16,17,19,24]) OR
         (((b AND $7F) = 13) AND ((lastsent AND $7F) = 64)) Then
         Begin
            Hold[o] := ZDLE;
            Inc(o);
            Hold[o] := (b XOR 64);
            inc(o);
            Exit;
         End;
      hold[o] := b;
      inc(o);
   End;

Begin
   Time_Stamp;
   Z_Message('');
   If UseCrc32 Then
      Begin
         SZ_SendDa32(buf,blength,frameend);
         Exit;
      End;
   crc := 0;
   o := 1;
   For t := 1 TO blength DO
      Begin
         StoreBuf(Byte(buf[t-1]));
         crc := UpdateCrc(buf[t-1],crc)
      End;
   Write_Byte3(Hold[1], o-1);

   crc := UpdateCrc(frameend,crc);
   Write_Byte(Chr(ZDLE));
   Write_Byte(Chr(frameend));
   crc := UpdateCrc(0,crc);
   crc := UpdateCrc(0,crc);
   SZ_Z_SendByte(Lo(crc SHR 8));
   SZ_Z_SendByte(Lo(crc));
   If (FrameEnd = ZCRCW) Then
      Begin
         Write_Byte(^Q);
      End
End;


Procedure SZ_EndSEnd;
Var
   Done: Boolean;
Begin
   Done := False;
   Repeat
      Z_PutLongIntoHeader(txpos);
      SZ_SendBinaryHeader(ZFIN,txhdr);
      Case Z_GetHeader(rxhdr) OF
         ZFIN: Begin
                  Write_Byte('OO');
                  Exit;
               End;
         ZCAN,
         ZFERR,
         ZTIMEOUT: Exit
      End {case}
   Until (done)
End;



Function SZ_GetReceiverInfo: Integer;
Var
   Rxflags, n, c: Integer;
Begin
   For n := 1 TO 10 DO
      Begin
         Z_Message('REQUESTING INIT HEADER');
         Z_SendHexHeader(ZRQINIT,txhdr,true);
         c := Z_GetHeader(rxhdr);
         Z_Frame(c,9);
         Case c OF

            ZCHALLENGE: Begin
                           Z_PutLongIntoHeader(rxpos);
                           Z_SendHexHeader(ZACK,txhdr,False)
                        End;

            ZCOMMAND:   Begin
                           Z_PutLongIntoHeader(LongInt(0));
                           Z_SendHexHeader(ZRQINIT,txhdr,True)
                        End;

            ZRINIT:     Begin
                           rxbuflen := (WORD(rxhdr[ZP1]) SHL 8) OR rxhdr[ZP0];
                           usecrc32 := ((rxhdr[ZF0] AND CANFC32) <> 0);
                           Z_ShowCheck(usecrc32);
                           SZ_GetReceiverInfo := ZOK;
                           Exit;
                        End;
            ZCAN,
            RCDO :      Begin
                           SZ_GetReceiverInfo := ZERROR;
                           Exit;
                        End;

            ZTIMEOUT:   Delay(1000);

            Else        If (c <> ZRQINIT) OR (rxhdr[ZF0] <> ZCOMMAND) Then
                           Z_SendHexHeader(ZNAK,txhdr,True);

         End;
      End;
   SZ_GetReceiverInfo := ZERROR;
End;

Function SZ_SyncWithReceiver: Integer;
VAR
   c, num_errs: Integer;
   done: Boolean;
Begin
   num_errs := 14;
   done := FALSE;
   Z_Message('SYNCING WITH RECEIVER');
   Repeat
      c := Z_GetHeader(rxhdr);
      Z_Frame(c,10);
      Case c OF
         ZFIN   : Exit;
         ZCAN,
         ZABORT : Begin
                     SZ_SyncWithReceiver := ZERROR;
                     Exit;
                  End;

         ZRPOS  : Begin
                     Z_ZRPOSmsg;
                     If (NOT Z_SeekFile(infile,rxpos)) Then
                        Begin
                           Z_Message('FILE SEEK ERROR');
                           SZ_SyncWithReceiver := ZERROR;
                           Exit;
                        End;
                     Z_Message('ZRPOS -- REPOSITIONING');
                     Z_ShowLocS(rxpos,False);
                     txpos := rxpos;
                     Clear_Buffer2;
                     SZ_SyncWithReceiver := c;
                     Exit;
                  End;
         ZSKIP,
         ZRINIT,
         ZACK: Begin
                  SZ_SyncWithReceiver := c;
                  Exit
               End
         Else
            Begin
               Z_Message('LINE NOISE, !@#&*%');
               SZ_SendBinaryHeader(ZNAK,txhdr)
            End
      End {case}
   Until (done)
End;


Function SZ_SendFileData: Integer;
LABEL
   waitack, somemore, oops;
VAR
   c, e: Integer;
   newcnt,    blklen,   blkred,
   maxblklen, goodblks, goodneeded: WORD;
Begin
   goodneeded := 4;
   If (zbaud < 300) Then
      maxblklen := 128
   Else
      maxblklen := (WORD(zbaud) DIV 300) * 256;
   If (maxblklen > ZBUFSIZE) Then
      maxblklen := ZBUFSIZE;
   If (rxbuflen > 0) AND (rxbuflen < maxblklen) Then
      maxblklen := rxbuflen;
   blklen := maxblklen;
   ztime := Z_SetTimer;
   Time_Stamp;
   Clear_Buffer;

   SOMEMORE:

   If (CommPressed) Then
      Begin

         WAITACK:

         c := SZ_SyncWithReceiver;
         Z_Frame(c,11);
         Case c OF
            ZSKIP:  Begin
                       SZ_SendFileData := ZSKIP;
                       Exit;
                    End;
            ZACK:   ;
            ZRPOS:  Begin
                       Inc(Ecount);
                       If ((blklen SHR 2) > 32) Then
                          blklen := (blklen SHR 2)
                       Else
                          blklen := 32;
                       Show_Block_Size(BlkLen);
                       goodblks := 0;
                       goodneeded := 8;{(goodneeded SHL 1) OR 1)}
                       {Delay(250);}
                    End;
            ZRINIT: Begin
                       SZ_SendFileData := ZOK;
                       Exit;
                    End
            Else    Begin
                       SZ_SendFileData := ZERROR;
                       Exit;
                    End;
         End;
         While (CommPressed) DO
            Begin
               Case Z_GetByte(1) OF
                  CAN,
                  ZPAD: GOTO waitack;
                  RCDO: Begin
                           SZ_SendFileData := ZERROR;
                           Exit;
                        End;
               End;
            End;
      End;

   newcnt := rxbuflen;
   Z_PutLongIntoHeader(txpos);
   SZ_SendBinaryHeader(ZDATA,txhdr);

   Repeat
      If Check_KeyBoard or ZPgDn Then
         Begin
            Z_Message('CANCELLED');
            Z_SendCan;
            Goto oops;
         End;
      If (NOT Z_ReadFile(infile,txbuf,blklen,blkred)) Then
         Begin
            Z_Message('DISK I/O ERROR');
            Z_SendCan;
            Goto oops;
         End;
      If (blkred < blklen) Then
         e := ZCRCE
      Else
         If (rxbuflen <> 0) AND ((newcnt - blkred) <= 0) Then
            Begin
               newcnt := (newcnt - blkred);
               e := ZCRCW;
            End
         Else
            e := ZCRCG;
      SZ_SendData(txbuf,blkred,e);
      txpos := txpos + blkred;
      Z_ShowLocS(txpos, False);
      Show_Block_Size(BlkLen);
      Inc(goodblks);
      If (blklen < maxblklen) AND (goodblks > goodneeded) Then
         Begin
            If ((blklen SHL 1) < maxblklen) Then
               blklen := (blklen SHL 1)
            Else
               blklen := maxblklen;
            goodblks := 0;
            Show_Block_Size(BlkLen);
         End;
      If (e = ZCRCW) Then
         Goto waitack;
      While (CommPressed) DO
         Begin
            Case Z_GetByte(1) OF
               CAN,
               ZPAD: Begin
                        Clear_Buffer2;
                        SZ_SendData(txbuf,0,ZCRCE);
                        Goto waitack;
                     End;
            End;
         End;
   Until (e <> ZCRCG);
   Repeat

      Z_PutLongIntoHeader(txpos);
      Z_Message('SENDING EOF');
      SZ_SendBinaryHeader(ZEOF,txhdr);

      Repeat
         Z_ShowLocS(txpos,True);
         Delay(200);
      Until (BytesQueuedOut = 0);

      c := SZ_SyncWithReceiver;
      Case c OF
         ZACK  : ;
         ZRPOS : Goto SOMEMORE;
         ZRINIT: Begin
                    SZ_SendFileData := ZOK;
                    Log_BPSstuff;
                    Exit;
                 End;
         ZSKIP : Begin
                    SZ_SendFileData := c;
                    Log_BPSstuff;
                    Exit;
                 End
         Else
oops:    Begin
            SZ_SendFileData := ZERROR;
            Exit;
         End;
      End;
   Until (c <> ZACK);
   Log_BPSstuff;
End;


Function SZ_SendFile: Integer;
VAR
   c: Integer;
   done: Boolean;
Begin
   Ecount := 0;
   done := FALSE;
   Repeat
      If Check_KeyBoard or ZPgDn Then
         Begin
            Z_SendCan;
            Z_Message('CANCELLED');
            SZ_SendFile := ZERROR;
            Exit;
         End;

      FillChar(txhdr,4,0);
      txhdr[ZF0] := ZCRESUM; {recover}
      SZ_SendBinaryHeader(ZFILE,txhdr);
      SZ_SendData(txbuf,128,ZCRCW);
      Repeat
         c := Z_GetHeader(rxhdr);
         Z_Frame(c,12);
         Case c OF
            ZNAK : ;
            ZCAN,
            ZTIMEOUT,
            ZFIN,
            ZABORT: Begin
                       SZ_SendFile := ZERROR;
                       Exit;
                    End;

            ZRINIT: {null - this will cause a loopback};

            ZCRC: Begin
                     Z_PutLongIntoHeader(Z_FileCRC32(infile));
                     Z_SendHexHeader(ZCRC,txhdr,False);
                  End;

            ZSKIP: Begin
                       SZ_SendFile := c;
                       Exit;
                   End;

            ZRPOS: Begin
                      Z_ZRPOSmsg;
                      If (NOT Z_SeekFile(infile,rxpos)) Then
                         Begin
                            Z_Message('FILE POSITION ERROR');
                            Z_SendHexHeader(ZFERR,txhdr,False);
                            SZ_SendFile := ZERROR;
                            Exit;
                         End;
                      Z_ShowLocS(rxpos,False);
                      strtpos := rxpos;
                      txpos := rxpos;
                      SZ_SendFile := SZ_SendFileData;
                      Exit;
                   End
         End;
      Until (c <> ZRINIT);
   Until (done);
End;


Function Zmodem_Send(Fname : String) : Boolean;
VAR
   s: String;
   SaveDfile : String;
   n: Integer;
Label
   BatchTop, NextFile, EExit;
Begin
   Ecount  := 0;
   Sending := True;
   zbaud   := NewSpeed;
   zport   := qq.Commport;
   zPgDn   := False;
   IsCancelled := False;
   Zmodem_Send := False;
   Script_Success := False;
   OnOffXferState := Online;
   If Not InitialSetup(Zmodem, True, Fname) Then
      Exit;

  If QuickLearn Then
     WriteLearn('Upload   Z _ ;Batch files continued on next line(s)');

   BatchTop:

   If UpBpath <> '' Then
      dfile := AddBackSlash(UpBpath) + UpFList.Name
   Else
      dfile := UpBpath + UpFList.Name;

   SaveDfile := Dfile;

   Tot_K         := 0;
   Effective_PCT := 0.0;
   Avg_BPS       := 0.0;
   Stamp_Taken   := False;

   Clear_Status_Fields;

   If (NOT Z_FindFile(dfile,Fname,fsize,ftime)) Then
      Begin
         SZ_EndSEnd;
         Z_CloseWindow;
         Zmodem_Send := FALSE;
         Exit
      End;

   If (NOT Z_OpenFile(infile,dfile)) Then
      If (IOResult <> 0) Then
         Begin
            Z_Message('FILE OPEN ERROR');
            Z_SendCan;
            Z_CloseWindow;
            Zmodem_Send := FALSE;
            Exit
         End;
   Z_ShowName(dfile);
   Z_ShowSize(fsize);
   Str(fsize,s);
   s := (Fname + #0 + s + ' ');
   s := s + Z_ToUnixDate(ftime);
   n := Length(s);
   For n := 1 to Length(s) DO
      Begin
         If (s[n] in ['A'..'Z']) Then
            s[n] := Chr(Ord(s[n]) + $20)
      End;
   FillChar(txbuf,ZBUFSIZE,0);
   Move(s[1],txbuf[0],Length(s));
   If (zbaud > 0) Then
      rxtimeout := Integer(614400 DIV zbaud)
   Else
      rxtimeout := 100;
   If (rxtimeout < 100) Then
      rxtimeout := 100;
   Attn[0] := Ord('r');
   Attn[1] := Ord('z');
   Attn[3] := 13;
   Attn[4] := 0;
   Z_PutString(attn,ZattnLen);
   FillChar(attn,SizeOf(attn),0);
   Z_PutLongIntoHeader(LongInt(0));
   If (SZ_GetReceiverInfo = ZERROR) Then
      Begin
         Z_CloseWindow;
         Zmodem_Send := FALSE;
         Exit;
      End;
   n := SZ_SendFile;
   Z_CloseFile(infile);
   Z_Frame(n,13);
NextFile:
   FindNext(UpFList);
   If DosError = 0 Then
      Begin
         If QuickLearn Then
            WriteLearn('           '+SaveDfile+' _');
         Goto BatchTop;
      End
   Else
      If BatchHead^.Next <> Nil Then
         Begin
            BatchHead := BatchHead^.Next;
            dfile := BatchHead^.Bname;
            FindFirst(dfile, Archive + ReadOnly, UpFList);
            If DosError <> 0 Then
               GoTo NextFile;
            If QuickLearn Then
               WriteLearn('           '+SaveDfile+' _');
            UpBpath := JustPathName(dfile);
            {point to next file entry(s)}
            Goto BatchTop;
         End;

   If QuickLearn Then
      WriteLearn('           '+SaveDfile);
   Script_success := True;

   If (n = ZOK) Then
      Begin
         SZ_EndSend;
         Status_Msg(9);
         Sound_Completion;
      End
   Else
      EExit:
      Z_SendCan;
   Z_CloseWindow;
   Zmodem_Send := TRUE;
End;

END.
