{$S-,I-,R-,P+,V-}
{$M 2048,0,655360}

program REGplus;              {Get the registration number}

Uses
   TpString,TpCrt, DOS, TpInt, TpTSR, TpWindow;

Const
   Hotkey = $0C13;  {Ctrl-Alt-R for the popup Status of the ISR}
   WaitForDOS = True;
   ModuleName : String[7] = 'REGplus';

Var
   BufPtr : Pointer;



   Function CRCvalue(Name : String) : Word;
   Var
      i,bit,n, CRC,divsel : Word;
   const
      { PRODUCTION CRCS }
      Divisors: array [0..31] of integer = (1215,5021,9069,10565,10627,13061,13083,
                                            15145,18911,22059,26529,29821,30491,
                                            30493,30539,30989,-31727,-27589,-25517,
                                            -23725,-22221,-21055,-20399,-19999,
                                            -17769,-16863,-14895,-13533,-9401,
                                            -9397,-7151,-865);
      { BETA CRCS }
      {
      Divisors: array [0..31] of integer = (12483,12861,15465,17917,20297,23255,
                                            27677,29549,30939,30941,30955,-31759,
                                            -27647,-27589,-20263,-20241,-20141,
                                            -17625,-17601,-15457,-15433,-13599,
                                            -13593,-10183,-7327,-7309,-2527,-2521,
                                            -1077,-1075,-205,-203);
      }
   Begin
      CRC := ((not ord(name[0]) shl 8) + (ord(name[0]) xor ord(name[1])));      {CRC seed}
      Divsel := divisors[(ord(name[0]) + ord(name[2])) and 31];  {make 0-31}
      For n := 1 to ord(name[0]) do
         Begin
            CRC := CRC XOR (ord(name[n]) shl 8);
            For bit := 1 to 8 do
               If CRC and $8000 <> 0 then
                  CRC := CRC shl 1 XOR DivSel
               Else
                  CRC := CRC shl 1;
         End;
      CRCvalue := CRC;
   End;


   {$F+}
   Procedure PopupEntryPoint(Var Regs : Registers);
   Label Top;
   var
      name         : String[50];
      ch : char;
      XY,SL,n : Word;

   begin
     detectmultitasking := true;
     reinitcrt;
     If not SaveWindow(8,8,70,12,True,BufPtr) then
        Exit;
     GetCursorState(xy,sl);
     FrameWindow(8,8,70,12,$1E,$1E,' REGPlus! ');
     Window(9,9,69,11);
     TextAttr := $17;
     ClrScr;
     Writeln('Press ESC to Exit, Letter to do REG #''s');
     top:
     Name := '';
     Repeat
        GotoXY(1,WhereY);
        If Name = '' then Write ('0      ')
                     Else Write (Pad(Long2Str(CRCvalue(Name)),7),Name);
        Clreol;
        Repeat
        Until Keypressed;
        Ch := UpCase(ReadKey);
        Case Ch of
           #27,^U : Begin
                       RestoreWindow(8,8,70,12,True,BufPtr);
                       RestoreCursorState(XY,SL);
                       If Ch = ^U then
                          If DisableTSR then {};
                       Exit;
                    End;
           #13 : Begin
                    Writeln;
                    Name := '';
                 End;
           ^H : Begin
                    If Length(Name) > 0 then
                       Name := Copy(Name,1,Length(Name)-1);
                 End;
           Else  If Length(Name) < 50 then
                    Name := Name + Ch;
        End;
     until Ch = #13;
     Goto Top;
   end;
   {$F-}

Begin
   If ModuleInstalled(ModuleName) then
      Begin
         Writeln('REGplus already resident.');
         Halt;
      End;
   InstallModule(ModuleName, Nil);
   If DefinePop(HotKey, @PopupEntryPoint, Ptr(SSeg,Sptr), WaitForDos) then
      Begin
         Writeln('REGPlus loaded!  Press <Ctrl><Alt><R> to activate.');
         PopupsOn;
         If not TerminateandStayResident(ParagraphsToKeep+256,0) then {};
      End;

   Writeln('Unable to go resident.');
End.


