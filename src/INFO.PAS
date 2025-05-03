Unit Info;

Interface

Uses
   TpCrt,     TPString,
   TpWindow,  Initial,
   Screen,    Files,
   Qinit,     Constant,
   Printer2,  Procs;


Procedure pgm_info;


Implementation


Procedure PrintOrderForm;
Var
   Lst : Text;
Begin
   If OpenPrinter(LSt, qq.PrinterID) then
      Begin
         Write('  Printing');
         Writeln(LST,'You may order Qmodem using this order form and we''ll rush you the latest');
         Writeln(LST,'commercial release, including 375+ page typeset manual, disks, sample');
         Writeln(LST,'scripts, Registered User Access on our 15 line support bbs, Free CompuServe');
         Writeln(LST,'subscription, OffLine Xpress (OLX) the .QWK packet mail reader and your own');
         Writeln(LST,'registration number for voice support.');
         Writeln(LST,'');
         Writeln(LST,'All this for only $99.00.  Previous Qmodem Registered Owners may Upgrade');
         Writeln(LST,'to v5 and receive this complete package for only $35.00.');
         Writeln(LST,'');
         Writeln(LST,'If you wish to order using your Visa, MasterCard or American Express Card,');
         Writeln(LST,'then you may also fax this order form to Mustang Software @ 805-395-0713.');
         Writeln(LST,'You may also call us Toll Free @ 800-999-9619.');
         Writeln(LST,'');
         Writeln(LST,'Thank you in advance for your order.  You support is greatly appreciated!');
         Writeln(LST,'----------------------------------------------------------------------------');
         Writeln(LST,'Order sent/faxed on  ____/____/____');
         Writeln(LST,'');
         Writeln(LST,'Name:         ________________________________________________');
         Writeln(LST,'');
         Writeln(LST,'Company:.     ________________________________________________');
         Writeln(LST,'');
         Writeln(LST,'Address:      ________________________________________________');
         Writeln(LST,'');
         Writeln(LST,'              ________________________________________________');
         Writeln(LST,'');
         Writeln(LST,'City:         _______________________________State____________');
         Writeln(LST,'');
         Writeln(LST,'Zip/Postal Code:___________________ Country:__________________');
         Writeln(LST,'');
         Writeln(LST,'Daytime Voice Phone:  ________________________________________');
         Writeln(LST,'');
         Writeln(LST,'Please Check Payment Menthod:');
         Writeln(LST,'');
         Writeln(LST,'[ ] - Check/Money Order (US Funds)  [ ] - Visa');
         Writeln(LST,'[ ] - American Express              [ ] - MasterCard');
         Writeln(LST,'');
         Writeln(LST,'Credit Card Number: _________________________________Exp. Date___________');
         Writeln(LST,'');
         Writeln(LST,'Product:   (All shipped with dual media)');
         Writeln(LST,'');
         Writeln(LST,'[ ] - Qmodem v5 $99.00   [ ] - Qmodem v5 Upgrade $35.00 Reg#_____________');
         Writeln(LST,'                               (Previous Registration Number Required)');
         Writeln(LST,'Shipping Method:');
         Writeln(LST,'');
         Writeln(LST,'[ ] - UPS Standard $4.00    [ ] - Canada (US Mail) $10.00');
         Writeln(LST,'[ ] - UPS Blue $7.00        [ ] - Overseas $20.00');
         Writeln(LST,'[ ] - UPS Red $16.00');
         Writeln(LST,'');
         Writeln(LST,'*   CA RESIDENTS MUST INCLUDE CORRECT SALES TAX.');
         Writeln(LST,'');
         Writeln(LST,'Amount Enclosed: $________________');
         Writeln(LST,'');
         Writeln(LST,'Mail orders to:');
         Writeln(LST,'');
         Writeln(LST,'    Mustang Software, Inc.           Orders  : 800-999-9619');
         Writeln(LST,'    Post Office Box 2264             Info    : 805-395-0223');
         Writeln(LST,'    Bakersfield, CA  93303           BBS     : 805-395-0650');
         Writeln(LST,'                                     FAX     : 805-395-0713');
         Writeln(LST,'Form: qmtd1291');
         ClosePrinter(Lst);
         Delay(250);
      End;
End;




Procedure pgm_info;
Var
   x : Integer;
   ch : char;
   SaveExplode,
   SaveShadow    : Boolean;
Begin
   SaveExplode := Explode;
   SaveShadow := Shadow;
   Explode := True;
   Shadow := False;
   Save_Screen(1, 1, 80, 25);
   HiddenCursor;
   Window(1,1,80,25);

   Q_SST;
   Delay(370);

   SetWindow4(2,1,48,5,'');
   ClrScr;
   FastCenter(_Qmodem_+' - '+Version,1,TextAttr);
   FastCenter(CopyrightString,2,TextAttr);
   FastCenter('All Rights Reserved World-Wide',3,TextAttr);

   Delay(70);
   SetWindow4(27,6,55,11,'How to reach MSI');
   Clrscr;
   Writeln ('   Sales : (805) 395-0223');
   Writeln (' Support : (805) 334-2240');
   Writeln ('     BBS : (805) 395-0650');
   Write   ('     Fax : (805) 395-0713');

   {$IfNDef BUNDLE}
      Delay(70);
      SetWindow4(33,12,76,14,'');
      Clrscr;
      Write (' Print an Order Form ? (y/n) ');
      NormalCursor;
   {$EndIf}

   Ch := ReadKey;

   {$IfNDef Bundle}
      If UpCase(Ch) = 'Y' then
         PrintOrderForm;
      Restore_Screen; Delay(70);
   {$EndIf}

   While KeyPressed do
      Ch := ReadKey;

   Restore_Screen; Delay(70);
   Restore_Screen; Delay(70);
   Restore_Screen;
   NormalCursor;
   Explode := SaveExplode;
   Shadow := SaveShadow;
End;

End.
