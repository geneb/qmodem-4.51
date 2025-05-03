Unit FoneStuf;

Interface
Uses
   Dos,
   TPDos,
   TpCrt,
   TpDate,
   TPString,
   Initial,
   Comm,
   Procs,
   Files,
   Screen,
   Qdial;


Procedure Read_Existing_FON(FName : String);
Procedure Create_New_FON(FName : String);
Procedure Load_Phone_Dir(FName : String);
Procedure Write_Fon_File;
Procedure Write_Fon_Entry(C : Integer);
Procedure Undo_Fon_Changes;
Procedure Load_New_FON;
Procedure MoveToFirstTagged;


Implementation


Procedure MoveToFirstTagged;
Var
   X : Word;
Begin
   If not qq.AltDStart then
      ClearAllMarks
   Else
      Begin
         CurrentPhone := 1;
         x := 1;
         While (CurrentPhone = 1) and (x <= MAX_Phones) do
            If not Phone_dir^[x].Marked Then
               Inc(x)
            Else
               Begin
                  CurrentPhone := x;
                  Exit;
               End;
      End;
End;


Procedure Scan_For_Notes(Fname : String);
Var
   DirInfo  : SearchRec;
   Y, X     : Word;
   Found    : Boolean;
Begin
   FindFirst(ForceExtension(Fname,'*'), AnyFile, DirInfo);
   While DosError = 0 Do
      Begin
         If Str2Word(JustExtension(DirInfo.Name),X) then
            If (x > 0) and (x <= Max_Phones) then
               {Scan the list for the matching NoteNum entry}
               Begin
                  Y := 1;
                  Found := False;
                  While (Y <= Max_Phones) and (Not Found) do
                     Begin
                        If Phone_Dir^[y].NoteNum = X then
                           Begin
                              Phone_dir^[y].HasNote := True;
                              Found := True;
                           End;
                        Inc(Y);
                     End;
               End;
         FindNext(DirInfo);
      End;
End;


Procedure Load_New_FON;
Var
   Temp, dfile : String;
   x           : Integer;
Begin
   Write_Fon_File;
   Temp := FON_Filename;
   dfile := Get_File_Name('', AddBackslash(JustPathname(FON_Filename)),
                              'FON', 14, 'FON File Allocation',True);
   If dfile = '' Then
      FON_Filename := Temp
   Else
      Begin
         FON_Filename := ForceExtension(dfile,'FON');
         TextAttr := qq.Menu;
         Load_Phone_Dir(FON_Filename);
         Logit('New FON file ' + dfile);
      End;
End;


Procedure Undo_Fon_Changes;
Var
   x1 : Integer;
Begin
   Display_Status(' WAIT - Undoing last change ');
   If not ExistFile(ForceExtension(FON_Filename,'FBK')) then
      Begin
         Setwindow2(22, 19, 58, 22, '',false);
         Beep;
         TextAttr := qq.menu;
         Clrscr;
         Writeln(' No FBK file, cannot undo changes.');
         Write('   ');
         Keycontinue(qq.Menu);
         Restore_Screen;
         Exit;
      End
   Else
      Begin
         Assign (fonefile, Fon_Filename);
         Erase (fonefile);
         IO := IOResult;
      End;
   Assign(fonefile, ForceExtension(FON_Filename,'FBK'));
   Rename(Fonefile, FON_Filename);
   IO := IOResult;
   Read_Existing_Fon(FON_Filename);
End;


Procedure Show_Trunc_Msg;
Begin
   WritelnT (' Insufficient disk space to save FON file.  File truncated. ');
End;


Procedure Write_Fon_File;
Var
   x1 : Integer;
   f : File;
Begin
   If not Fon_Changed then
      Exit;
   Push_Status;
   Display_Status(' Writing Phone Book to Disk ');
   If qq.WriteFBK then
      Begin
         If ExistFile(ForceExtension(FON_Filename,'FBK')) then
            Begin
               Assign(fonefile,ForceExtension(FON_Filename,'FBK'));
               erase (Fonefile);
               IO := IOResult;
            End;
         Assign(fonefile, FON_Filename);
         Rename(Fonefile, ForceExtension(FON_Filename,'FBK'));
         IO := IOResult;
      End;
   Assign(f, FON_Filename);
   Rewrite(f, SizeOf(Phone_Dir^[1]));
   BlockWrite(f, Phone_Dir^,Max_Phones,X1);
   If X1 <> Max_Phones then
      Begin
         { ran out of room saving the real FON file,
           so delete the FBK and try again }
         If qq.WriteFBK then
            Begin
               WritelnT (' Erasing FBK file to make room for FON. ');
               Assign(fonefile,ForceExtension(FON_Filename,'FBK'));
               erase (Fonefile);
               IO := IOResult;
            End;
         Rewrite(f, SizeOf(Phone_Dir^[1]));
         BlockWrite(f, Phone_Dir^,Max_Phones,X1);
         If X1 <> Max_Phones then
            Show_Trunc_Msg;
      End;
   Close(f);
   IO := IoResult;
   pop_status;
   Fon_Changed := False;
End;


Procedure Write_Fon_Entry;
Var
   x1 : Integer;
Begin
   Assign(fonefile, FON_Filename);
   Reset (fonefile);
   Seek  (fonefile,Pred(C));
   Write (fonefile, Phone_dir^[C]);
   Close (fonefile);
   IO := IoResult;
End;


Procedure Read_Existing_FON(FName : String);
Var
   x, y     : Word;
   F        : File;
Begin
   Fon_Changed := False;
   If QuickLearn then
      WriteLearn('LoadFON  '+Fname);
   Assign(f, FName);
   Reset(f,SizeOf(Phone_Dir^[1]));
   IO := IoResult;
   BlockRead(F, Phone_Dir^, Max_Phones, X);
   If (x < Max_Phones) or (IOResult <> 0) then
      Begin
         Close(f);
         io := IOResult;
         Beep;
         WriteLnT('Error loading FON file.  Fixing '+Long2Str(Max_Phones-X)+' entries.');
         FillChar(Phone_Number, SizeOf(Phone_Number), #0);
         With phone_number Do
            Begin
               Echo1    := 'F';
               Default_Protocol := ' ';
               ComSpeed := qq.ComSpeed;
               dbits := qq.dbits;
               sbits := qq.stop_bits;
               Parity := qq.Cparity;
               Last_Connect := BadDate;
            End;
         For y := Succ(x) To max_phones Do
            Phone_dir^[y] := phone_number;
         Fon_Changed := True;
      End;
   Close(f);
   IO := IoResult;
   For x := 1 to Max_Phones do
      Begin
         Phone_dir^[x].HasNote := False;
         Phone_dir^[x].Name := TrimLead(Phone_dir^[x].Name);
      End;
   { Now, read in all files that match the FON.* and
     compare for Note files }
   Scan_For_Notes(Fname);
   MoveToFirstTagged;
End;


Procedure Create_New_FON(FName : String);
Var
   x, y           : Integer;
   f : File;
Label
   Error;
Begin
   FillChar(Phone_Number,Sizeof(Phone_Number),#0);
   With phone_number Do
      Begin
         ComSpeed := qq.ComSpeed;
         dbits := qq.dbits;
         sbits := qq.stop_bits;
         Parity := qq.Cparity;
         Last_Connect := BadDate;
         Times_Called := 0;
         Default_Protocol := 'X';
         Echo1 := 'F';
         Marked := False;
         LearnTag := False;
         HasNote := False;
         NoPrefix := False;
      End;

   FillChar(Phone_Dir^[1],Sizeof(Phone_Dir^[1]) * max_phones,#0);
   For x := 1 To max_phones Do
      Begin
         Phone_dir^[x] := phone_number;
         Phone_Dir^[x].NoteNum := X;
      End;

   With phone_number Do
      Begin
         Name := 'Mustang Software BBS';
         Number := '1-805-395-0650';
         dbits := 8;
         sbits := 1;
         parity := 'N';
         Marked := False;
         NoteNum := 1;
      End;
   Phone_dir^[1] := phone_number;

   Assign (f, Fname);
   Rewrite(f, SizeOf(Phone_Dir^[1]));
   BlockWrite(f, Phone_Dir^, Max_Phones, X1);
   If X1 <> Max_Phones then
      Show_Trunc_Msg;
   Close(f);
   Scan_For_Notes(Fname);
   IO := IOResult;
End;



Procedure Load_Phone_Dir(FName : String);
Begin
   If Not ExistFile(FName) Then
      Create_New_FON(FName)
   Else
      Begin
         Write_FON_File;
         Assign(fonefile, FName);
         Read_Existing_FON(FName);
      End;
End;


End.
