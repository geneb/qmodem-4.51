Program beg;

Uses
  TpCrt;


  Procedure AskForCashWildCat;
  var
   Counter : Byte;
  Begin
   ClrScr;
   FrameWindow(1,1,80,23,15,14,' REGISTER WILDCAT! TODAY ');
   FastWrite('When you Register WILDCAT! you''ll receive:',3,4,10);
   FastWrite('  The Commercial version, with all the latest bells & whistles.',5,6,10);
   FastWrite('  Comprehensive 350+ typeset operations manual.',6,6,10);
   Fastwrite('  Access to the multi-line Private User Only HQ BBS.',7,6,10);
   FastWrite('  90 day technical support by phone.',8,6,10);
   FastWrite('  One year technical support via Private HQ BBS and CompuServe.',9,6,10);
   FastWrite('  Automatic notification of all MAJOR program updates.',10,6,10);
   FastWrite('  Your own registration number to show you''ve registered your copy.',11,6,10);
   FastWrite('  Plus much, much more.',12,6,10);
   FastWrite('Become a Registered WILDCAT! Sysop. Order today from: Software Etc.,',14,4,10);
   FastWrite('Soft Warehouse, Egghead or your local software dealer.  Or contact us at:',15,4,10);
   FastCenter('Mustang Software, Inc.',17,15);
   FastCenter('Post Office Box 2264',18,15);
   FastCenter('Bakersfield, CA  93303-2264',19,15);
   FastCenter('Business Office   (805) 395-0223    ORDERS ONLY (800) 999-9619',21,10);
   FastCenter('Technical Support (805) 334-2240    CompuServe  (GO PCVENA SS9)',22,10);
   For Counter := 1 to 8 Do
   FastWrite(#26,4+Counter,6,15);
   Gotoxy(1,24);
   Counter := 10;
   While (Counter > 0) and not keypressed Do
   begin
    delay(500);
    Dec(Counter);
   end;
  end;


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
   Counter := 10;
   While (Counter > 0) and not keypressed Do
   begin
    delay(500);
    Dec(Counter);
   end;
  end;



  Begin

    AskForCashQmodem;

  End.