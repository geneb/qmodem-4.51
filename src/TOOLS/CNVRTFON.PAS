Program Convert_Phone_File_rev_c;

Type
   tparity          = (none, even, oddd);

   Phone_type       = Record
                        Name                   : String[34];
                        Fillerx                : Byte;
                        Number                 : String[14];
                        Speed, Dbits, Sbits    : Integer;
                        Parity                 : Tparity;
                        Script_File            : String[12]; { Filename }
                        Last_Connect           : String[8];  { Mm-dd-yy }
                        Times_Called           : Real;
                        Default_Protocol       : Char;  { X/R/C/Y/A }
                        Echo1                  : Char;  { N/y }
                        Password               : String[20];
                        Filler                 : Array[1..9] of Byte;
                      End;



   New_Phone_type   = Record
                        Name                   : String[27];
                        Filerxxx               : Integer;
                        Number                 : String[19];
                        Speed                  : Word;
                        Dbits, Sbits           : Integer;
                        Parity                 : Tparity;
                        Script_File            : String[12]; { Filename }
                        Last_Connect           : String[8];  { Mm-dd-yy }
                        Times_Called           : LongInt;
                        flrxxxx                : Integer;
                        Default_Protocol       : Char;  { X/R/C/Y/A/G/I }
                        Echo1                  : Char;  { N/y  or F/H }
                        Password               : String[14];
                        EntryNumber            : Integer;
                        Marked                 : Boolean;
                        Filler                 : Array[1..13] of Byte;
                      End;




    AnyStr = String[255];

Var
  old : Array [1..200] of phone_type;
  OldFile : file of phone_type;
  Newfile : File of New_phone_Type;
  o : phone_type;
  n : new_phone_type;
  X : Integer;
  spaces : String[10];
  filler1 : Array[1..130] of Byte;
  Echo1, Protocol1 : Char;

Function exist (fname : anystr) : Boolean;
  Var
    F : File;
Begin
  Assign (f, fname);
  {$I-}
  reset (f);
  {$I+}
  Close(f);
  Exist := IOresult = 0;
End;

Begin
  FillChar(old,SizeOf(old),0);

  Writeln ('Qmodem Version 4.0 Phone File Converter');
  If sizeof(o) <> sizeof(n) then
     begin
        Writeln ('Size mismatch.  Old = ',sizeof(o),'  New = ',sizeof(n));
        Halt;
     End;
  writeln;
  If not exist('Qmodem.Fon') then
     Exit;
  writeln ('Starting the Conversion...');
  Assign (Oldfile, 'Qmodem.Fon');
  reset (oldfile);
  for x := 1 to 200 do Begin
     FillChar(o,SizeOf(o),0);
     read (oldfile, o);
     old[x] := o;
     End;
  close (oldfile);
  assign (newfile, 'Qmodem.Fon');
  rewrite (newfile);
  for x := 1 to 200 do
    Begin
      FillChar(n,SizeOf(n),0);
      n.name := Copy(old[x].name,1,27);
      n.number := old[x].number;
      n.password := Copy(old[x].password,1,14);
      n.speed := old[x].speed;
      n.dbits := old[x].dbits;
      n.sbits := old[x].sbits;
      n.parity := old[x].parity;
      n.Script_File := old[x].Script_File;
      n.Last_Connect := old[x].Last_Connect;
      n.Times_Called := LongInt(Round(old[x].times_called));
      n.Default_Protocol := old[x].default_protocol;
      n.Echo1 := old[x].echo1;
      n.marked := false;
      Write (newfile, n);
    End;
  close (Newfile);
  writeln ('Conversion complete.');
End.
