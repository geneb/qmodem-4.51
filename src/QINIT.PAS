Unit Qinit;

INTERFACE

Uses
   Dos,        TpCrt,      Initial,    TpString,   Stack5,
   TpDate,     Procs,      Group1,     Constant,    Const1;


Procedure Init;
Procedure Q_SST;
Procedure Boring;


IMPLEMENTATION


Procedure Q_SST;
Var
   TmpPtr : Pointer;
Begin
   TmpPtr := @Logo;
   If CurrentDisplay in [MonoHerc,MCGA] then
      TmpPtr := @LogoM;
   DispPackedWindow(TmpPtr);
   GotoXY(1,2); Delay(5);
   GotoXY(1,24);Delay(5);
End;


Procedure Init;
Label
   eexit;
Var
   rnum  : String[5];
   xx, rword, rc : word;
Begin
  Window (1,1,Last_Col,Real_Last_Row);
  HiddenCursor;
  TextAttr := 7;
  Clrscr;
  Q_SST;

  {$IfNDef Bundle}
  If (Reg_Number > 0) and (Reg_Number = GetReg) then
     Dex := CurrentTime + LongInt(1)
  Else
  {$EndIf}
     Dex := CurrentTime + LongInt(2);
End;



Procedure AskForCashQmodem;
var
   Counter : Byte;
Begin
   ClrScr;
   FrameWindow(1,1,80,23,15,14,' REGISTER QMODEM TODAY ');
   FastWrite('When you Register Qmodem you''ll receive:',3,4,10);
   FastWrite('  The Commercial version, with all the latest bells & whistles.',5,6,10);
   FastWrite('  Comprehensive 375+ typeset operations manual.',6,6,10);
   Fastwrite('  Access to the multi-line Private User Only HQ BBS.',7,6,10);
   FastWrite('  Free technical support by phone.',8,6,10);
   FastWrite('  Unlimited technical support via Private HQ BBS and CompuServe.',9,6,10);
   FastWrite('  Automatic notification of all MAJOR program updates.',10,6,10);
   FastWrite('  Copy of OffLine Xpress (Off Line Mail Reader).',11,6,10);
   FastWrite('  Plus much, much more.',12,6,10);
   FastWrite('Become a Registered Qmodem User.  Order today from your local Software Etc.',14,4,10);
   FastWrite('retailer or from your local software dealer.  Or contact us at:',15,4,10);
   FastCenter('Mustang Software, Inc.',17,15);
   FastCenter('Post Office Box 2264',18,15);
   FastCenter('Bakersfield, CA  93303-2264',19,15);
   FastCenter('Business Office   (805) 395-0223    ORDERS ONLY (800) 999-9619',21,10);
   FastCenter('Technical Support (805) 334-2240    CompuServe  (GO PCVENA SS9)',22,10);
   For Counter := 1 to 8 Do
   FastWrite(#26,4+Counter,6,15);
   Gotoxy(1,24);
end;



Procedure Boring;
Begin
   If qq.VideoRestore then
      Begin
         If SetEGA43Exit then
            TextMode(3 + Font8x8)
         Else
            Begin
               r.AH := 0;
               r.AL := xInMode;
               Intr($10, R);
            End;
         ReInitCRT;
      End;
   Window(1,1,CurrentWidth,Succ(CurrentHeight));
   TextAttr := GLattr;
   Clrscr;

   {$IfNDef Bundle}
      If GetReg <> Reg_Number then
         AskForCashQmodem
      Else
         Writeln('Thank you for registering Qmodem.'^M^J' - Mustang Software Inc.');
   {$EndIf}
End;

End.
