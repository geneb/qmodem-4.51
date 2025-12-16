{$M 2000,1000,31000}
{$I-}

Program Convert_Phone_File;

Uses TPCrt,TPDate,TPDos,TPString;

Type
   tparity        = Char;

   Phone_type =     Record
                       Name           : String[27];
                       Filerxxx       : Integer;
                       Number         : String[19];
                       Speed          : Word;
                       Dbits, Sbits   : Integer;
                       Parity         : tparity;
                       Script_File    : String[12];
                       zz             : Record Case Boolean of
                                           True : (Last_Connect : String[8]);
                                           False: (LastDate : Word);
                                        End;
                       Times_Called   : LongInt;
                       flrxxxx        : Integer;
                       Protocol       : Char;
                       Echo1          : Char;
                       Password       : String[14];
                       EntryNumber    : Integer;
                       Marked         : Boolean;
                       Emulation      : Byte;
                       LearnTag       : Boolean;
                       NoteNum        : Word;
                       Filler         : Array[1..9] Of Byte;
                    End;

   New_Phone_type = Record
                       Name           : String[27];
                       Filerxxx       : Integer;
                       Number         : String[19];
                       Filler2        : Word;
                       Dbits, Sbits   : Integer;
                       Parity         : tparity;
                       Script_File    : String[12];
                       LastDate       : Word;
                       Fillerxxxx     : String[6];
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
   OldFile        : File Of Phone_type;
   Newfile        : File Of New_Phone_type;
   o              : Phone_type;
   n              : New_Phone_type;
   IO, X          : Integer;
   Spaces         : String[10];
   Aname          : String;
   filler1        : Array[1..130] Of Byte;
   Ch, Echo1,
   DateCh,
   Protocol1      : Char;

Begin
   Clrscr;
   Writeln;
   WriteLn('Qmodem 4.x --> 4.5 TD Phone File Converter');
   If ParamCount > 0 then
      AName := ForceExtension(STUpCase(Paramstr(1)),'FON')
   else
      Begin
         Writeln (^M^J'Correct syntax :  4XTO45  filename.FON');
         Writeln ('Where ''filename'' is the name of the phonebook to be converted.');
         Halt;
      End;
   Writeln(^M^J'This will convert ',AName,' to the 4.5 TD format.  If');
   Writeln('your current version of Qmodem is greater than 4.1B, then');
   Writeln('you do NOT need to run this conversion program.  If you are');
   Writeln('unsure, respond "N" to the next question and make a backup');
   Writeln('copy of ',AName,' before running this program.');
   Write  (^M^J'Continue ? (y/n) ');
   Repeat
      ch := Upcase(ReadKey);
   until ch in ['Y','N'];
   writeln (ch);
   if Ch = 'N' then
      Halt;
   WriteLn;
   FillChar(Old, SizeOf(Old), 0);
   If ExistFile (ForceExtension(AName,'Old')) then
      Begin
         Writeln ('The file ',ForceExtension(AName,'OLD'),' already exists.');
         Writeln ('It must be deleted or renamed to continue.');
         Halt;
      End;
   If Not existfile(AName) Then
      Begin
         Writeln ('The file ',AName,' must exist for the conversion');
         Writeln ('program to run.');
         Halt;
      End;
   WriteLn('   Starting Conversion');
   Assign(OldFile, AName);
   Reset(OldFile);
   For X := 1 To 200 Do
   Begin
      FillChar(O, SizeOf(O), #0);
      Read(OldFile, O);
      Old[X] := O;
   End;
   Close(OldFile);
   x := IOResult;
   Writeln ('   Renaming ',AName);
   Writeln ('         to ',ForceExtension(AName,'OLD'));
   Rename(OldFile,ForceExtension(AName,'OLD'));
   x := IOResult;
   Assign(Newfile, AName );
   Rewrite(Newfile);
   Writeln ('   Writing  ',AName);
   For X := 1 To 200 Do
      Begin
         FillChar(N, SizeOf(N), #0);
         N.Name            := Trim(Copy(Old[X].Name,1,27));
         N.Number          := Old[X].Number;
         N.Password        := Trim(Copy(Old[X].Password,1,14));
         N.ComSpeed        := Word(Old[X].Speed);
         N.Dbits           := Old[X].Dbits;
         N.Sbits           := Old[X].Sbits;
         Case Byte(Old[X].Parity) of
            0 : N.Parity   := 'N';
            1 : N.Parity   := 'E';
            2 : N.Parity   := 'O';
         End;
         N.Script_File     := Old[X].Script_File;
         DateCh := Old[x].zz.Last_Connect[3];
         N.LastDate :=
             DateStringToDate('mm'+Datech+'dd'+datech+'yy',
                              Old[x].zz.Last_Connect);
         N.Times_Called    := LongInt(Round(Old[X].Times_Called));
         N.Protocol        := Old[X].Protocol;
         N.Echo1           := Old[X].Echo1;
         N.Marked          := False;
         N.LearnTag        := False;
         N.NoteNum         := Old[X].NoteNum;
         Write(Newfile, N);
         If IOResult <> 0 then
            Begin
               Writeln ('   Error trying to create the new FON.  Check disk space');
               Writeln ('   for a possible full disk.');
               Halt;
            End;
      End;
   Close(Newfile);
   WriteLn('   Conversion Complete');
   Writeln;
End.
