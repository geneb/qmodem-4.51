{$I-,R-}

Unit Printer2;

Interface

Uses Dos;

Var
   PrtlogLst : Text;   { for normal Alt-9 Logging }


Function  SetDeviceMode(Handle: word; SetRawMode: boolean): boolean;
Function  OpenPrinter(Var Lst : Text; DeviceOrFile : String) : Boolean;
Procedure ClosePrinter(Var Lst : Text);

Implementation

Var IO : Word;

{ Return the current value of the device raw/cooked mode
  and set to new mode }

Function SetDeviceMode(Handle: word;SetRawMode: boolean): boolean;
Var
   Regs: Registers;
Begin
   With Regs do
      Begin
         AX := $4400;                     { Get the current device status }
         BX := Handle;
         MsDos(Regs);
         SetDeviceMode := odd(DX shr 5);  { Test the current value of RAW bit }
         AX := $4401;                     { Set the new device status }
         BX := Handle;
         DX := DX and $00DF;              { Clear the RAW bit }
         If SetRawMode then
            Inc(DX,32);                   { Turn the RAW bit on }
         MsDos(Regs);
         If regs.Flags and FCarry <> 0 then
            SetDeviceMode := False
         Else
            SetDeviceMode := True;
      End
  End;


Function OpenPrinter(Var Lst : Text; DeviceOrFile : String) : Boolean;
Var
   DOFlen : Byte absolute DeviceOrFile;
Begin
   OpenPrinter := True;
   If DeviceOrFile[Length(DeviceOrFile)] = ':' then
      Dec(DOFlen);
   If DeviceOrFile = '' then
      DeviceOrFile := 'PRN';  {The Default}
   Assign(Lst, DeviceOrFile);  { Open the printer device }
   Append(Lst);
   IO := IOResult;
   If IO <> 0 then
      Rewrite(Lst);
   IO := IOResult;
   { Set to RAW (binary) mode }
   If not SetDeviceMode(TextRec(Lst).Handle,true) then ;
   OpenPrinter := (IO = 0);
   If IO <> 0 then
      Begin
         Close(Lst);
         IO := IOResult;
      End;
End;


Procedure ClosePrinter(Var Lst : Text);
Begin
   Close(Lst);
   If IOResult <> 0 then;
End;


End.
