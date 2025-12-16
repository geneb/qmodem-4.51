UNIT BATCH;
{$P+,V-}

INTERFACE

Uses TpInLine,  TpEntry,   Dos,      TpDir,
     TpDos,     TpCrt,     TpString,
     Initial,   Screen,    Procs,
     {Group02, }  Constant,  Files;

Type
   BatchListPointer = ^BatchFileList;
   BatchFileList = Record
                      Bname : String[64];
                      Next  : BatchListPointer;
                   End;
Var
   BatchHead,
   BatchList : BatchListPointer;

Const
   InUpload : Boolean=False;


Procedure ClearBatchNames(ShowDeleteMsg, ForceAnyway :Boolean);
Procedure AddBatchName (path, name : String);
Function  Get_File_Name_Batch (P1, P2, P3 : String) : Boolean;


IMPLEMENTATION


Var
   Path1, Path2, Path3 : String[52];
   Enames1 : Array[1..20] of String[13];
   Enames2 : Array[1..20] of String[13];
   Enames3 : Array[1..20] of String[13];
   BATCHESR : ESrecord;
   xs       : String[13];



Procedure ClearBatchNames(ShowDeleteMsg, ForceAnyway :Boolean);
Var
   p : BatchListPointer;
   s : String;
   f : text;
Begin
   While BatchHead <> NIL do
      Begin
         p := BatchHead^.Next;
         Dispose(BatchHead);
         BatchHead := p;
      End;
   BatchHead := NIL;
   BatchList := NIL;
   If qq.BEWClear or ForceAnyway then
      Begin
         s := AddBackSlash(JustPathName(SearchName(QMODEM_CNF)))+QMODEM_BEW;
         If not ExistFile(s) then
            Exit;
         Assign (f,s);
         If ShowDeleteMsg then
            WritelnT('BEW Deleted. File: '+s);
         Erase(f);
         IO := IOResult;
      End;
End;

Procedure AddBatchName (path, name : String);
Var
   p : BatchListPointer;
Begin
   New(p);
   p^.Bname := FullPathName(AddBackslash(Path)+name);
   p^.Next := NIL;
   If BatchList = NIL then
      BatchHead := p
   Else
      BatchList^.Next := p;
   BatchList := p;
End;


Procedure WriteBatchNamesToDisk;
Var
   f : Text;
Begin
   Assign (f, AddBackSlash(JustPathName(SearchName(QMODEM_CNF)))+QMODEM_BEW);
   Rewrite(f);
   Writeln(f,Path1);
   For x := 1 to 20 do
      Writeln(f,Enames1[x]);
   Writeln(f,Path2);
   For x := 1 to 20 do
      Writeln(f,Enames2[x]);
   Writeln(f,Path3);
   For x := 1 to 20 do
      Writeln(f,Enames3[x]);
   Close(f);
   IO := IOResult;
End;

Procedure LoadBatchNamesFromDisk;
Var
   f : Text;
   s : String;
Begin
   s := AddBackSlash(JustPathName(SearchName(QMODEM_CNF)))+QMODEM_BEW;
   If not ExistFile(s) then
      Exit;
   Assign (f,s);
   Reset(f);
   If not EOF(f) then
      ReadLn(f,Path1);
   For x := 1 to 20 do
      If not EOF(f) then
         ReadLn(f,Enames1[x]);
   If not EOF(f) then
      ReadLn(f,Path2);
   For x := 1 to 20 do
      If not EOF(f) then
         ReadLn(f,Enames2[x]);
   If not EOF(f) then
      ReadLn(f,Path3);
   For x := 1 to 20 do
      If not EOF(f) then
         ReadLn(f,Enames3[x]);
   Close(f);
   IO := IOResult;
End;


Procedure BatchExistCommon(Var FR  : FieldRec;
                           Path, s : String);
var
   s2 : String;
Begin
   ChangeFieldAttr  (BATCHESR, FR.FieldID, qq.Menu2);
   ChangeStringAttr (BATCHESR, FR.FieldID, qq.ScrollBar);
   Case LastEntryCommand of
      ESuser1,
      ESuser4 : Begin
                   If LastEntryCommand = ESuser4 then
                      FR.EditSt^ := xs
                   Else
                      Begin
                         If s = '' then
                            s := '*.*';
                         HelpTopic := 93;
                         Show_Dir(AddBackSlash(Path)+S, AnyFile-Directory, s2);
                         FR.EditSt^ := JustFilename(s2);
                      End;
                   If FR.EditSt^ <> '' then
                      LastEntryCommand := ESnextField
                   Else
                      LastEntryCommand := ESnone;
                   s := FR.EditSt^;
                End;
   End;
   If Length(S) = 0 then
      Exit;
   If Exist_Wild(AddBackSlash(Path)+S) then
      Exit;
   ChangeFieldAttr(BATCHESR, FR.FieldID, $4F+128);
   ChangeStringAttr(BATCHESR, FR.FieldID, $4F);
   If Noise then
      RingBell;
End;

Function BatchExist1(Var FR      : FieldRec;
                     Var ErrCode : Byte;
                     Var ErrorSt : StringPtr) : Boolean;
Var
   S : String[12];
Begin
   BatchExist1 := True;
   S := Trim(FR.EditSt^);
   If (LastEntryCommand = ESdone)  or
      (LastEntryCommand = ESuser0) or
      (LastEntryCommand = ESuser3) then
      Exit
   Else
      BatchExistCommon(FR, Path1, S);
End;

Function BatchExist2(var FR      : FieldRec;
                     var ErrCode : Byte;
                     var ErrorSt : StringPtr) : Boolean;
var
   S : String[12];
begin
   BatchExist2 := True;
   S := Trim(FR.EditSt^);
   If (LastEntryCommand = ESdone)  or
      (LastEntryCommand = ESuser0) or
      (LastEntryCommand = ESuser3) then
      Exit
   Else
      BatchExistCommon(FR, Path2, S);
End;

Function BatchExist3(var FR      : FieldRec;
                     var ErrCode : Byte;
                     var ErrorSt : StringPtr) : Boolean;
var
   S : String[12];
begin
   BatchExist3 := True;
   S := Trim(FR.EditSt^);
   If (LastEntryCommand = ESdone)  or
      (LastEntryCommand = ESuser0) or
      (LastEntryCommand = ESuser3) then
      Exit
   Else
      BatchExistCommon(FR, Path3, S);
End;


Procedure BatchPathCommon(var FR: FieldRec;
                          Path : String);
Var
  sdrive,SD2 : String[72];
  IO2,IO3 : Word;
  SaveDrv : Char;
  OK : Boolean;
begin
   If (LastEntryCommand = ESuser1) or
      (LastEntryCommand = ESuser4) then
      Begin
         If Noise then RingBell;
         LastEntryCommand := ESnone;
      End
   Else
      Begin

         If Length(Path) = 0 then
            Exit;

         ChangeFieldAttr (BATCHESR, FR.FieldID, qq.Menu2);
         ChangeStringAttr(BATCHESR, FR.FieldID, qq.ScrollBar);

         Path := AddBackSlash(STupCase(Path));
         Path := CompleteFileName(FullPathName(Path));

         If Path[2] = ':' then
            Begin
               GetDir(0,Sdrive);
               IO3 := IOResult;
               SaveDrv := DefaultDrive;
               OK := Log_New_Drive(Path[1]);
               GetDir(0,Sd2);
               IO3 := IOResult;

               Chdir(JustPathName(Path));
               IO  := IOResult;
               OK := Log_New_Drive(SaveDrv);
               ChDir(SD2);
               IO3 := IOResult;
               Chdir(Sdrive);
               IO2 := IOresult;
               If IO = 0 then
                  Exit;
            End;

         ChangeFieldAttr (BATCHESR, FR.FieldID, $4F+128);
         ChangeStringAttr(BATCHESR, FR.FieldID, $4F);
         If Noise then
            RingBell;
         LastEntryCommand := ESnone;
      End;
End;

Function BatchPath1(var FR: FieldRec;
                    var ErrCode : Byte;
                    var ErrorSt : StringPtr) : Boolean;
Var
   S : String[64];
Begin
   BatchPath1 := True;
   S := Trim(FR.EditSt^);
   If (LastEntryCommand = ESdone)  or
      (LastEntryCommand = ESuser0) or
      (LastEntryCommand = ESuser3) then
      Exit
   Else
      Begin
         BatchPathCommon(FR, S);
         Path1 := S;
      End;
End;

Function BatchPath2(var FR: FieldRec;
                    var ErrCode : Byte;
                    var ErrorSt : StringPtr) : Boolean;
Var
   S : String[64];
Begin
   BatchPath2 := True;
   S := Trim(FR.EditSt^);
   If (LastEntryCommand = ESdone)  or
      (LastEntryCommand = ESuser0) or
      (LastEntryCommand = ESuser3) then
      Exit
   Else
      Begin
         BatchPathCommon(FR, S);
         Path2 := S;
      End;
End;

Function BatchPath3(var FR: FieldRec;
                    var ErrCode : Byte;
                    var ErrorSt : StringPtr) : Boolean;
Var
   S : String[64];
Begin
   BatchPath3 := True;
   S := Trim(FR.EditSt^);
   If (LastEntryCommand = ESdone)  or
      (LastEntryCommand = ESuser0) or
      (LastEntryCommand = ESuser3) then
      Exit
   Else
      Begin
         BatchPathCommon(FR, S);
         Path3 := S;
      End;
End;



Procedure ResetBatchVars(P1, P2, P3 : String);
Begin
   {Clear the temporary names list}
   FillChar(Enames1, SizeOf(Enames1), #0);
   FillChar(Enames2, SizeOf(Enames2), #0);
   FillChar(Enames3, SizeOf(Enames3), #0);
   {Initialize the Path variables}
   If P1 = '' then P1 := qq.BatchUL1;
   If P2 = '' then P2 := qq.BatchUL2;
   If P3 = '' then P3 := qq.BatchUL3;
   Path1 := AddBackSlash(P1);
   Path2 := AddBackSlash(P2);
   Path3 := AddBackSlash(P3);
End;

Function Get_File_Name_Batch (P1, P2, P3 : String) : Boolean;
Var
   ExitCommand : EStype;
   TempList : BatchListPointer;
   X,Y, OldHelp : Integer;
   OK : Boolean;
   stline : String[80];
Label Restart;
Begin
   OK := False;  {Assume ESC will exit}
   Push_Window;
   OldHelp := HelpTopic;
   HelpTopic := 5;
   If Help_Last then
      NormalCursor;
   xs := L_S_Filename;
   SetWindow2(1,1,77,22,' Batch Upload File Entry ', False);
   FastWrite('F1 Help',22,68, qq.Windf);
   stline :=' F2-Pick List   F3-Last Found   F4-Clear   F10-';
   If InUpload then
      Display_Status(stline+'Upload   ESC-Exit ')
   Else
      Display_Status(stline+'Save to Disk   ESC-Exit ');

{                                  Screen Layout

1---+----10---+----20---+----30---+----40---+----50---+----60---+----70
PATH : ____________________________________________________

FILES: FILENAME.EXE  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________

PATH : ____________________________________________________

FILES: ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________

PATH : ____________________________________________________

FILES: ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________
       ____________  ____________  ____________  ____________  ____________
}

   ReStart:
   ResetBatchVars(P1, P2, P3);

   LoadBatchNamesFromDisk;

   {<F2> Pop up a Pick Window}
   If not AddEntryCommand(ESuser1, 1, $3C00, 0) then ;

   {<F3> Place the last filename on screen in the current slot}
   If not AddEntryCommand(ESuser4, 1, $3D00, 0) then ;

   {<F4> Clear the BEW file and FILE fields}
   If not AddEntryCommand(ESuser3, 1, $3E00, 0) then ;

   {<F10> Alternate DONE key}
   If not AddEntryCommand(ESuser0, 1, $4400, 0) then ;

   InitESrecord(BATCHESR);
   SetFieldAttr(qq.Menu2);
   SetPromptAttr(qq.Menu);
   SetStringAttr(qq.scrollbar);
   SetCtrlAttr(qq.ScrollBar+128);
   SetPadChar('°');
   AddStringField(BATCHESR, 'PATH :', 1, 1, CharStr('!',52), 1, 8, 52, 89,
                            @BatchPath1,
                            Path1);
   For x := 1 to 4 do
      For y := 1 to 5 do
         AddStringField(BATCHESR, '', 1, 1, CharStr('!',12), x+2, y*14-14+8, 12, 89,
                        @BatchExist1,{ NIL,}
                        Enames1[x*5-5+y]);

   AddStringField(BATCHESR, 'PATH :', 8, 1, CharStr('!',52), 8, 8, 52, 89,
                            @BatchPath2,
                            Path2);
   For x := 1 to 4 do
      For y := 1 to 5 do
         AddStringField(BATCHESR, '', 1, 1, CharStr('!',12), x+9, y*14-14+8, 12, 89,
                        @BatchExist2,
                        Enames2[x*5-5+y]);


   AddStringField(BATCHESR, 'PATH :',15, 1, CharStr('!',52),15, 8, 52, 89,
                            @BatchPath3,
                            Path3);
   For x := 1 to 4 do
      For y := 1 to 5 do
         AddStringField(BATCHESR, '', 1, 1, CharStr('!',12), x+16, y*14-14+8, 12, 89,
                        @BatchExist3,
                        Enames3[x*5-5+y]);

   SetEntryWindow(BATCHESR, 2,2,76,21, False, qq.Menu, qq.Windf);

   For x := 1 to 3 do
      FastWrite('FILES:',x*7-7+4,2,qq.Menu);

   ExitCommand := EditScreen(BATCHESR, 1, False);
   DisposeEditScreen(BATCHESR);

   If ExitCommand = ESuser3 then
      Begin
         ClearBatchNames(True, True);
         Goto ReStart;
      End;

   If (ExitCommand = ESdone) or (ExitCommand = ESuser0) then
      Begin

         ClearBatchNames(false,true);   {Remove old entries if any}

         WriteBatchNamesToDisk;

         OK := True;

         If InUpload then
            Begin

               For x := 1 to 20 do
                  If Enames1[x] <> '' then
                     AddBatchName(Path1,Enames1[x]);

               For x := 1 to 20 do
                  If Enames2[x] <> '' then
                     AddBatchName(Path2,Enames2[x]);

               For x := 1 to 20 do
                  If Enames3[x] <> '' then
                     AddBatchName(Path3,Enames3[x]);

            End;
      End;

   HelpTopic := OldHelp;
   Restore_Screen;
   Pop_Window;
   Set_Colors;
   If Help_Last then
      HiddenCursor;
   Get_File_Name_Batch := OK;
End;


Begin
   BatchList := NIL;
   BatchHead := NIL;
End.
