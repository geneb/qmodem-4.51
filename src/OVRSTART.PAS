Unit OvrStart;
Interface

Uses Dos, TpCrt, Overlay, Constant;

Var
   UsingEMS : Boolean;
   SaveOvrRead : OvrReadFunc;

Function  MyOvrRead(OvrSeg : Word) : Integer;
Procedure EMSErr (E : Integer);
Procedure DOSErr (E : Integer);
Procedure OVRProblem;


Implementation

Const
  Digits : array[0..$F] of Char = '0123456789ABCDEF';

Var
  Ch : Char;

Procedure OVRProblem;
Begin
   If OvrResult = 0 then Exit;
   Case OvrResult of
      -1 : writeln('Overlay Manager Error');
      -2 : writeln('Overlay File not found');
      -3 : writeln('Insufficient HEAP');
      -4 : writeln('Overlay I/O Error');
      -5 : writeln('EMS driver not installed');
      -6 : writeln('Insufficient EMS memory');
   End;
   Case OvrResult of
      -1,-2,-3,-4 : Begin
                       Write('Press any key to Exit ');
                       Ch := ReadKey;
                       Writeln;
                       Halt(99);
                    End;
   End;
End;

Function HexW(W : Word) : string;
    {-Return hex string for word}
  begin
    HexW[0] := #4;
    HexW[1] := Digits[hi(W) shr 4];
    HexW[2] := Digits[hi(W) and $F];
    HexW[3] := Digits[lo(W) shr 4];
    HexW[4] := Digits[lo(W) and $F];
  end;

Procedure ErrCont;
Begin
   Write  ('ENTER to Continue, ^C to abort');
   Ch := ReadKey;
   If CH = ^C then Halt;
   Writeln;
End;


Procedure EMSErr (E : Integer);
Begin
   Writeln('<< '+_QMODEM_+' - EMS OVERLAY ERROR : ',HexW(Lo(E)),'! >>');
   ErrCont;
End;

Procedure DOSErr (E : Integer);
Begin
   Writeln('<< '+_QMODEM_+' - DOS OVERLAY ERROR : ',(Lo(E)),'! >>');
   ErrCont;
End;

{$F+}

Function MyOvrRead(OvrSeg : Word) : Integer;
Var
   E : Integer;
Begin
   Repeat
      E := SaveOvrRead(OvrSeg);
      If E <> 0 then
         If UsingEMS then
            EMSErr(E)
         Else
            DOSErr(E);
   Until E = 0;
   MyOvrRead := 0;
End;

{$F-}

Begin
   If Lo(DosVersion) >= 3 then
      OvrFileMode := $20;

   OvrInit (QMODEM_OVR);
   If OvrResult <> 0 then
      OVRproblem
   Else
      Begin
         SaveOvrRead := OvrReadBuf;
         OvrReadBuf  := MyOvrRead;
         UsingEMS    := False;
      End;
End.
