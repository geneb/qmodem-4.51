{$M 2000,1000,1000}
{$I-}

{

     (C)Copyright 1988 by The Forbin Project Inc.  All rights reserved.

     The source code for the conversion is included in case you want to
     see how it was done.  This assumes you have Turbo Pascal 4.0 and
     the Turbo Professional package from TurboPower Software.

     Enjoy!

}

Program Convert_Phone_File;

Uses TPCrt,TPDos,TPString;

Type
   Phone_type = Record
                   Name           : String[27];
                   Filerxxx       : Integer;
                   Number         : String[19];
                   Filler2        : Word;
                   Dbits, Sbits   : Integer;
                   Parity         : Char;
                   Script_File    : String[12];
                   Last_Connect   : String[8];
                   Times_Called   : LongInt;
                   flrxxxx        : Integer;
                   Protocol       : Char;
                   Echo1          : Char;
                   Password       : String[14];
                   EntryNumber    : Integer;
                   Marked         : Boolean;
                   Emulation      : Byte;
                   LearnTag       : Boolean;
                   NoteNum        : Word;           {never change this!}
                   HasNote        : Boolean;
                   NoPrefix       : Boolean;
                   ComSpeed       : LongInt;
                   Filler         : Array[1..3] Of Byte;
                End;

Var
   Old            : Array[1..200] Of Phone_type;
   OldNums        : Array[1..200] Of Word;
   ErrNums        : Array[1..200] Of Word;
   OldFile        : File Of Phone_type;
   O              : Phone_type;
   IO, X, Y,
   ErrorCount     : Integer;
   AName          : String;
   HasErrors      : Boolean;
   Ch             : Char;

Function NextFreeNum : Integer;
Var
   x : Integer;
Begin
   For x := 1 to 200 do
      if OldNums[x] = 0 then
         begin
            NextFreeNum := x;
            OldNums[x] := x;
            Exit;
         End;
   NextFreeNum := 0;
End;



Begin
   Writeln;
   WriteLn('FIXNOTES - 03/19/90 FON ZAP II');
   If ParamCount > 0 then
      AName := ForceExtension(STUpCase(Paramstr(1)),'FON')
   else
      Begin
         Writeln (^M^J'Correct syntax :  FIXNOTES filename.FON');
         Writeln ('Where ''filename'' is the name of the phonebook to be converted.');
         Halt;
      End;
   Writeln(^M^J'This will ZAP ',AName,' to the fix the FON file corrupted by');
   Writeln('the new Insert/Delete code.  The Note Numbers have been trashed.');
   Write  ('Continue ? (y/n) ');
   Repeat
      ch := Upcase(ReadKey);
   until ch in ['Y','N'];
   writeln (ch);
   if Ch = 'N' then
      Halt;
   Writeln ('Analyzing ',AName);
   For x := 1 to 200 do
      Begin
         OldNums[x] := 0;
         ErrNums[x] := 0;
      End;

   Assign(OldFile, AName);
   Reset(OldFile);
   If IOResult <> 0 then
      Begin
         Writeln;
         Writeln ('File ',ANAME,' does not exist.');
         Halt;
      End;

   For x := 1 to 200 do
      Read(OldFile, Old[x]);
   Close(OldFile);

   HasErrors := False;
   ErrorCount := 0;
   For x := 1 to 200 do
      Begin
         y := Old[x].NoteNum;
         If OldNums[y] = 0 then
            OldNums[y] := y
         Else
            Begin
               ErrNums[x] := 1;
               Inc(ErrorCount);
               HasErrors := True;
            End;
      End;

   If not HasErrors then
      Begin
         Writeln('File ',ANAME,' has no errors.');
         Halt;
      End;
   Writeln('File contains ',ErrorCount,' errors.');
   Writeln('Fixing....');

   For x := 1 to 200 do
      Begin
         If ErrNums[x] = 1 then
            Old[x].NoteNum := NextFreeNum;
      End;

   Assign(OldFile, AName);
   Rewrite(OldFile);
   If IOResult <> 0 then
      Begin
         Writeln ('File ',ANAME,' does not exist.');
         Halt;
      End;

   For x := 1 to 200 do
      Write(OldFile, Old[x]);
   Close(OldFile);

   WriteLn('FIXNOTES Completed.');
   Writeln;
End.
