Unit QLink2;

Interface

Uses
   TpCrt,    TpString, Initial,
   Screen,   TpMemChk, Qcrcs,
   Comm,     Comm2,    OpKey,
   ApTimer,  Procs,    Group1,
   Group02;


Procedure DoQlinkEmulation;


Implementation


{local structures}
Type
   PacketTypes = (KeyPacket,   DisplayPacket,  NakPacket,
                  AckPacket,   EOJPacket,      UnknownPacket);

   IncomingPacketStates = (NoPacket, HeaderPacket, DataPacket, CRCPacket);

   KeyPacketRecPtr = ^KeyPacketRec;
   KeyPacketRec    = Record              { 13 bytes }
                        PacketType       : PacketTypes;
                        PacketNumber     : Byte;
                        PacketNumberXor  : Byte;
                        PacketLength     : Word;
                        PacketScanCode   : Word;
                        PacketShiftFlags : Word;
                        PacketCRC        : LongInt;
                     End;

   PacketBufferType = Array[1..4096] of Byte; {Dummy, actual size varies}

   OutKeyType  = Record
                    ScanCode   : Word;
                    ShiftFlags : Word;
                 End;


Var
   IncomingPacketState   : IncomingPacketStates;
   PacketBuffer          : PacketBufferType;
   PacketXmitBuffer      : Array [1..3072] of Byte;
   LastIncomingPacket    : PacketTypes;
   OutKeyBufferCount     : Word; {queued outgoing keyboard characters}
   OutKeyBuffer          : Array [1..255] of OutKeyType;
   CurrentShiftFlags     : Word absolute $40:$84;
   KeyPacketACKPending   : Boolean;
   KeyPacketNumber       : Byte;
   PacketBufferCnt       : Word;
   KeyPacketOut,
   LastKeyPacketOut      : KeyPacketRecPtr;
   IncomingDisplayPacket : PackedWindowPtr;
   IncomingPacketLength  : Word;
   IncomingPacketCRC     : LongInt;
      IPCRC              : Array[1..4] of Byte absolute IncomingPacketCRC;
   TmpKey                : Array[1..50] of Byte;


Procedure DoubleBeep;
Begin
   Sound(500);
   Delay(50);
   Nosound;
   Delay(30);
   Sound(500);
   Delay(50);
   Nosound;
   Delay(100);
End;


Procedure SendKeyPacket(W : OutKeyType);
Begin
   Writeln('Scancode = ',Hexw(W.ScanCode));
   If not GetMemCheck(KeyPacketOut, SizeOf(KeyPacketOut^)) then
      Begin
          {insufficient memory?!?}
      End
   Else
      Begin
         With KeyPacketOut^ do
            Begin
               {Build the outgoing Key packet that QLINK will recognize.}

               If w.ScanCode = $EEEE then PacketType := ACKPacket Else
               If w.ScanCode = $FF00 then PacketType := NAKPacket Else
               If w.ScanCode = $FFFE then PacketType := EOJPacket Else
                                          PacketType := KeyPacket;
               PacketCRC := $FFFFFFFF;
               Inc(KeyPacketNumber);
               PacketNumber    := KeyPacketNumber;
               {PacketCRC := UpdC32(PacketCRC, PacketNumber);}
               PacketNumberXor := PacketNumber XOR 255;
               {PacketCRC := UpdC32(PacketCRC, PacketNumberXor);}
               PacketLength := SizeOf(KeyPacketOut);
               {PacketCRC := UpdC32(PacketCRC, HI(PacketLength));}
               {PacketCRC := UpdC32(PacketCRC, LO(PacketLength));}
               PacketScanCode  := W.ScanCode;
               PacketCRC := UpdC32(PacketCRC, LO(PacketScanCode));
               PacketCRC := UpdC32(PacketCRC, HI(PacketScanCode));
               PacketShiftFlags  := W.ShiftFlags;
               PacketCRC := UpdC32(PacketCRC, LO(PacketShiftFlags));
               PacketCRC := UpdC32(PacketCRC, HI(PacketShiftFlags));

               {move the packet to the transmit buffer}
               Write_Byte (AutoQLink);
               Write_Byte3(KeyPacketOut^, SizeOf(KeyPacketOut^));
               Move(KeyPacketOut^,tmpkey[1], sizeof(KeyPacketOut^));
               Write ('Key Packet Out : ');
               For x := 1 to SizeOf(KeyPacketOut^) do
                  Write(Hexb(tmpkey[x]),' ');
               Writeln;

               If PacketType <> KeyPacket then
                  Begin
                     FreeMemCheck(KeyPacketOut, SizeOf(KeyPacketOut^));
                     Exit;
                  End;

               {Set the ACK pending flag}
               KeyPacketACKPending := True;

               {Save the Key packet pointer}
               LastKeyPacketOut := KeyPacketOut;

            End;
      End;

End;


Procedure SendEOJPacket;
VAr
   W : OutKeyType;
Begin
   W.ScanCode := $FFFE;
   SendKeyPacket(W);
End;

Procedure SendACKPacket(PacketNum : Word);
VAr
   W : OutKeyType;
Begin
   W.ScanCode := $EEEE;
   W.ShiftFlags := PacketNum;
   SendKeyPacket(W);
End;

Procedure SendNAKPacket;
VAr
   W : OutKeyType;
Begin
   W.ScanCode := $FF00;
   SendKeyPacket(W);
End;



Function PanicRebootOK : Boolean;
Var
   OK : Boolean;
Begin
   OK := TRUE;  {Assume OK}
   {Display some message window about it}
   {ask if OK to force reboot on QLINK side}
   PanicRebootOK := OK;
End;


Procedure ShowIncomingPacket;
Begin
   If not GetMemCheck(IncomingDisplayPacket, IncomingPacketLength) then
      Begin
      End
   Else
      Begin
         Move(PacketBuffer[6],IncomingDisplayPacket^,IncomingPacketLength);
         DispPackedWindow(IncomingDisplayPacket);
         FreeMemCheck(IncomingDisplayPacket, SizeOf(IncomingDisplayPacket^));
      End;
End;


Procedure ShowKeyPacket;
Var
   W : Word;
Begin
   Move(PacketBuffer[6],W,2);
   Writeln('Key Received : ',HexW(W));
End;


Procedure ProcessIncomingPackets;
Var
   Ch : Char;
Begin
   Ch := CinkeyZ;
   Case IncomingPacketState of
      NoPacket     : Begin
                        If (Ch = #255) and
                           (LastCommStringX(4) = AutoQlink) then
                           Begin
                              PacketBufferCnt := 0;
                              IncomingPacketState := HeaderPacket;
                           End;
                     End;

      HeaderPacket : Begin
                        Inc(PacketbufferCnt);
                        PacketBuffer[PacketBufferCnt] := Byte(Ch);
                        If PacketBufferCnt = 1 then
                           If Ord(Ch) > 5  then
                              Begin
                                 IncomingPacketState := NoPacket;
                                 Exit;
                              End;
                        If PacketBufferCnt = 3 then
                           Begin
                              If PacketBuffer[2] <> PacketBuffer[3] xor 255 then
                                 Begin
                                    IncomingPacketState := NoPacket;
                                    Exit;
                                 End;
                           End;
                        If PacketBufferCnt = 5 then
                           Begin
                              Move (PacketBuffer[4], IncomingPacketLength, 2);
                              If IncomingPacketLength > 4000 then
                                 Begin
                                    IncomingPacketState := NoPacket;
                                    Exit;
                                 End;
                              IncomingPacketState := DataPacket;
                              IncomingPacketCRC := $FFFFFFFF;
                              Writeln('Incoming Packet : Length = ',IncomingPacketLength);
                           End;
                     End;

      DataPacket   : Begin
                        Inc(PacketbufferCnt);
                        PacketBuffer[PacketBufferCnt] := Byte(Ch);
                        IncomingPacketCRC := UpdC32(IncomingPacketCRC, Byte(Ch));
                        If PacketBufferCnt = IncomingPacketLength+5 then
                           IncomingPacketState := CRCPacket;
                     End;

      CRCPacket    : Begin
                        Inc(PacketBufferCnt);
                        PacketBuffer[PacketBufferCnt] := Byte(Ch);
                        If PacketBufferCnt = IncomingPacketLength+9 then
                           Begin
                              Writeln('Completed Packet!');
                              Write  ('Incoming Packet  : ');
                              For x := 1 to PacketBufferCnt do
                                 Write(Hexb(PacketBuffer[x]), ' ');
                              Writeln;
                              {Check the CRC of the packet}
                              If (PacketBuffer[PacketBufferCnt-3] = IPCRC[1]) and
                                 (PacketBuffer[PacketBufferCnt-2] = IPCRC[2]) and
                                 (PacketBuffer[PacketBufferCnt-1] = IPCRC[3]) and
                                 (PacketBuffer[PacketBufferCnt  ] = IPCRC[4]) then
                                 Begin
                                    {Figure out what packet we have and process}
                                    LastIncomingPacket := PacketTypes(PacketBuffer[1]);
                                    Case LastIncomingPacket of
                                        KeyPacket     : Begin
                                                          Writeln('KeyPacket received');
                                                          ShowKeyPacket;
                                                          Writeln('Sending ACK Packet');
                                                          SendACKPacket(PacketBuffer[2]);
                                                        End;
                                        DisplayPacket : Begin
                                                          ShowIncomingPacket;
                                                        End;
                                        AckPacket     : Begin
                                                           Writeln('ACK Packet Received');
                                                           FreeMemCheck(LastKeyPacketOut, SizeOf(LastKeyPacketOut^));
                                                           KeyPacketACKPending := False;
                                                        End;
                                        NakPacket     : Begin
                                                           Writeln('NAK Packet Received');
                                                           Write_Byte (AutoQLink);
                                                           Write_Byte3(LastKeyPacketOut^, SizeOf(LastKeyPacketOut^));
                                                           Move(LastKeyPacketOut^,tmpkey[1], sizeof(LastKeyPacketOut^));
                                                           Write ('Last Key Packet Out : ');
                                                           For x := 1 to SizeOf(LastKeyPacketOut^) do
                                                              Write(Hexb(tmpkey[x]),' ');
                                                           Writeln;
                                                        End;
                                        EOJPacket     : Begin
                                                           Writeln('EOJ Packet Received');
                                                        End;
                                        Else            Begin
                                                           Writeln('Unknown Packet Received');
                                                           LastIncomingPacket := UnknownPacket;
                                                        End;
                                    End;
                                 End
                              Else
                                 Begin
                                    IncomingPacketState := NoPacket;
                                    Exit;
                                 End;
                           End;
                     End;
   End;
End;



Procedure ProcessOutgoingKey;
var
  W : OutKeyType;
Begin
   W.ScanCode := ReadKeyWord;
   W.ShiftFlags := CurrentShiftFlags;
   If W.ScanCode = AltEqual then
      Begin
         If PanicRebootOK then
            Begin
               QLinkMode := False;
               {Exit;}
               Repeat
                  SendEOJPacket;
                  LastIncomingPacket := UnknownPacket;
                  Repeat
                     While CommPressed do
                        ProcessIncomingPackets;
                  Until LastIncomingPacket <> UnknownPacket;
               Until LastIncomingPacket = EOJPacket;
               Exit;
            End;
      End;
   If KeyPacketACKPending then
      If OutKeyBufferCount < 255 then
         Begin
            Inc(OutKeyBufferCount);
            OutKeyBuffer[OutKeyBufferCount] := W;
         End
      Else
         DoubleBeep
   Else
      If OutKeyBufferCount > 0 then
         Begin
            SendKeyPacket(OutKeyBuffer[1]);
            Dec(OutKeyBufferCount);
            Move(OutKeyBuffer[2], OutKeyBuffer[1], OutKeyBufferCount*SizeOf(OutKeyBuffer[1]));
         End
      Else
         SendKeyPacket(W);
End;



Procedure DoQlinkEmulation;
Begin
   OutKeyBufferCount := 0;
   KeyPacketACKPending := False;
   KeyPacketNumber := 0;
   LastIncomingPacket := UnknownPacket;
   Repeat

      If Keypressed then
         ProcessOutgoingKey;

      If Commpressed then
         ProcessIncomingPackets;

   Until QLinkMode = False;
End;


Begin
   KeyPacketOut     := NIL;
   LastKeyPacketOut := NIL;
   IncomingPacketState := NoPacket;
End.
