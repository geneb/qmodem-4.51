UNIT Group1;


INTERFACE

Uses Qmem,      TPInLine,  TpEntry,   Dos,      Stack5,
     TPDos,     TpCrt,     TPWindow,  TPString,
     Initial,   Comm,      Comm2,     Screen,
     Procs,     Music,     Files,     Emuls;


Procedure Dequeue_buffer;
{$IfNDef Bundle}
Function  GetReg : Word;
{$EndIf}

Procedure Check_xonxoff (ch : char);

Procedure Check_comm_char_extended (chz : Char);
Procedure Check_comm_codes;
Procedure Check_comm_char_2(ch1 : Char);
Procedure Do_Comm_Chars;


IMPLEMENTATION


Const
   InXonXoff : Boolean = False;



Procedure Dequeue_buffer;
Begin
   If Xon_Xoff Then
      Write_Byte(^S);  { Send XOFF }

   Push_Status;        {4.2F!!}
   Display_Status(' RECEIVE BUFFER FULL - Keyboard Input Suspended - Please Wait ');

   While Queue_Bytes + Buffer_High1 > recv_buf_size Do
      Check_comm_codes;              { Repeat until room in buffer }
   If Xon_Xoff  Then
      Write_Byte(^Q);  { Send XON }
   Buffer_full := False;
   Pop_Status;         {4.2F!!}
End;


Procedure Do_Comm_Chars;
Begin
   Case Emulation of
      TTY,
      ANSImode :
         Case Ch of
            ^H : Begin
                    Store_Cinkey(#8);
                    If qq.Destruct_BS then Write (#8#32#8)
                                      else Write (#8);
                 End;
            ^I : Begin
                    Store_Cinkey(#9);
                    PrtTab;
                 End;
            ^L : Begin
                     Store_Cinkey(#12);
                     Clear_Screen;
                  End;
            ^M : Begin
                    OutKey(^M);
                    If AddLF then OutKey(^J);
                 End;
            Else Outkey (Ch);
         End;
      Else
         OutKey (Ch);
   End; {Case}
End;


Procedure Check_comm_char_extended (chz : Char);
Begin
   Ch := Chz;
   Translate_In (Ch);
   If (Ch = #0) and not (Ord(Emulation) in [4,5]) then Exit;
   If not Hi_bit then
      Ch := Chr(Ord(Ch) and 127);
   If Xon_Xoff then
      Check_XonXoff(Ch);
   If Music_Flag then
      Music_Maker (Ch);
   CommCh := Ch;
   Do_Comm_Chars;
End;


Procedure check_comm_codes;
Begin
   CommCh := Cinkeyz;
   Check_comm_char_extended(CommCh);
End;


Procedure check_comm_char_2(ch1 : Char);
Begin
   Check_comm_char_extended(ch1);
End;


{$IfNDef Bundle}
Function GetReg : Word;
Var
   n, bit  : byte;
   i, CRC,
   divsel  : Integer;
   CRCREAL : real;
   BB      : String;
Const
   Divisors:
      Array [0..31] of integer=(1215,5021,9069,10565,10627,13061,13083,
                                15145,18911,22059,26529,29821,30491,
                                30493,30539,30989,-31727,-27589,-25517,
                                -23725,-22221,-21055,-20399,-19999,
                                -17769,-16863,-14895,-13533,-9401,
                                -9397,-7151,-865);
Begin
   BB := Board;
   For n := 1 to ord(BB[0]) do
      BB[n] := Upcase(BB[n]);  {Make all upcase}
   CRC := (((not ord(BB[0])) shl 8) + (ord(BB[0]) xor ord(BB[1])));      {CRC seed}
   DivSel := Divisors[(ord(BB[0]) + ord(BB[2])) and 31];  {make 0-31}
   For n := 1 to Length(BB) do
      Begin
         CRC := CRC XOR (ord(BB[n]) shl 8);
         For bit := 1 to 8 do
            If CRC and $8000 <> 0 then
               CRC := (CRC shl 1) XOR divsel
            Else
               CRC := CRC shl 1;
      End;
   GetReg := Word(CRC);
End;
{$EndIf}


Procedure Check_XonXoff(Ch:Char);
Var
   Ch1  : Char;
   Xoff : Boolean;
   InCode : Boolean;
Begin
   If not Online then   {4.2E!!}
      Exit;             {4.2E!!}
   If InXonXoff then
      Exit;
   Xoff := False;
   If Ch = ^S then
      Begin
         Xoff := True;
         Push_Status;   {4.2F!!}
         Display_Status (' XOFF(^S) Received, waiting for XON(^Q).  ^Q-Override and Continue ');
         InXonXoff := True;
         Repeat
            Repeat
            Until CommPressed
                  or KeyPressed
                  or not ONLINE;   {4.2F!!}
            If CommPressed then
               Begin
                  Ch1 := Cinkeyz;
                  If Ch1 = ^Q then
                     Xoff := False
                  Else
                     Check_Comm_Char_2(Ch1);
               End
            Else
               If KeyPressed then
                  Begin
                     Ch1 := Char(ReadKeyA);
                     If Ch1 = ^Q then
                        Xoff := False;
                  End              {4.2F!!}
               Else                {4.2F!!}
                  Xoff := False;   {4.2F!!}
         Until not Xoff;
         Pop_Status;               {4.2F!!}
         Home_Status_Msg;
         InXonXoff := False;
      End;
End;


Begin
   {$IfNDef Bundle}
   If GetReg <> Reg_Number then
      If GetReg <> 4213 then
         If GetReg <> 24593 then
            IsRegisteredOK := False;
   {$EndIf}
End.
