{$S-,I-,R-}
{$M 2048,0,655360}
Program ISIplus;

Uses
   DOS, TpInt, TpTSR;

Const
   Hotkey = $0910;  {Alt-RightShift-Q for the popup Status of the ISR}
   WaitForDOS = True;
   ModuleName : String[7] = 'ISIplus';


   {$F+}
   Procedure PopupEntryPoint(Var Regs : Registers);
   Begin
      Writeln('Hello world!');
   End;
   {$F-}

Begin
   If ModuleInstalled(ModuleName) then
      Begin
         Writeln('ISIplus already resident.');
         Halt;
      End;
   InstallModule(ModuleName, Nil);
   If DefinePop(HotKey, @PopupEntryPoint, Ptr(SSeg,Sptr), WaitForDos) then
      Begin
         Writeln('ISIplus loaded.  Press Alt-RightShift-Q to activate.');
         PopupsOn;
         If not TerminateandStayResident(ParagraphsToKeep,0) then {};
      End;

   Writeln('Unable to go resident.');
End.
