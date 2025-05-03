{$A-,F-,I-,R-,S-}
Unit BINFSE;

Interface

Uses
   Qmem,
   Initial,
   Dos,
   TpCrt,
   TPString,
   {OpEnhKbd,}
   Procs,
   QShell,
   Screen,
   Files;


Type
   AttrArray      = Array[0..3] Of Byte;
   AsciiZ         = Array[0..255] Of Char;
   ASCIIZptr      = ^AsciiZ;
   TextEBuffer    = Array[0..$FFF0] Of Char;

   CRTinsStruct =                 {CRT installation structure}
      Record
         CRTtype        : Byte;   {1=IBM, 0=Non}
         CRTx1, CRTy1,
         CRTx2, CRTy2   : Byte;   {Initial window size}
         CRTmode        : Byte;   {Initial mode 0-3,7 or FF(default)}
         CRTsnow        : Byte;   {0 if no snow, don't care for mono}
         AttrMono       : AttrArray; {CRT attributes for mono mode}
         AttrBW         : AttrArray; {CRT attributes for b/w modes}
         AttrColor      : AttrArray; {CRT attributes for color modes}
      End;
   CIptr          = ^CRTinsStruct;

   EdInsStruct =                  {Command table installation structure}
      Record
         ComTablen      : Word;   {Maximum length of command table}
         ComTab         : TextEBuffer; {Command table}
      End;
   EIptr          = ^EdInsStruct;

   MIinsStruct =                  {Main installation structure}
      Record
         Ver            : Byte;   {Main version}
         VerSub         : Byte;   {Sub version}
         VerPatch       : Char;   {Patch level}
         CPUmhz         : Byte;   {CPU speed for delays}
         CIstruct       : CIptr;  {Points to CRT installation record}
         EIstruct       : EIptr;  {Points to Editor installation area}
         DefExt         : ASCIIZptr; {Points to ASCIIZ default extension}
      End;
   MIptr          = ^MIinsStruct;

   EdCB =                         {Editor control block in detail}
      Record
         x1, y1, x2, y2 : Byte;   {Upper left and lower right corners of editor window}
         DataSeg        : Word;   {Segment address of editor data area}
         DataSegLen     : Word;   {Requested data area length (bytes)}
         Options        : Word;   {Bit flags for editor options}
         FileStr        : ASCIIZptr; {Points to ASCIIZ filename}
         Commands       : ASCIIZptr; {Points to ASCIIZ string of editor commands}
         Reserved1      : ASCIIZptr; {Not used here}
         Reserved2      : ASCIIZptr; {Not used here}
         Event          : Pointer; {Points to event handling procedure}
         EBuffer        : ^TextEBuffer; {Points to text area}
         EBufSize       : Word;   {Available size for text}
         MIstruct       : MIptr;  {Points to main installation record}
         ComTab         : ASCIIZptr; {Points to terminate command table}
         EOtext         : Word;   {Current number of chars in text EBuffer}
         CursorPos      : Word;   {Current cursor position in EBuffer}
         BlockStart     : Word;   {Start of marked block in EBuffer}
         BlockEnd       : Word;   {End of marked block in EBuffer}
         Status         : Word;   {Editor status}
         DataPtr        : ^TextEBuffer; {Points to Turbo heap block allocated for text EBuffer}
      End;

Var
   {CRT attributes for   normal low blk error}
   MonoArray      : AttrArray;
   P              : Pointer;
   FSEname        : Str64;
   FName          : String;
   DataPtr_       : Boolean;
   FileStr_,
   Commands_,
   Reserved1_,
   MIstruct_,
   CIstruct_,
   DefExt_       : Boolean;


Const
   {Commands other than ^K^D to exit editor}

   ExitCommands : Array[0..20] Of Char = (#2, ^K, ^q,  {^KQ  Abort}
                                          #2, #0, #60, {F2   Save}
                                          #2, #0, #61, {F3   New}
                                          #2, #0, #67, {F9   Abort}
                                          #2, #0, #68, {F10  Save & Exit}
                                          #1, #27,     {ESC  abort}
                                          #2, #0, #59, {F1   Help}
                                          #0);
   MakeBackup     = True;


Var
   windx1, windy1,
   windx2, Windy2 : Byte;
   EdData         : EdCB;         {Editor control block}
   ECode          : Word;         {Status code set by binary editor functions}
   ExitCommand    : Word;         {Code for command used to leave editor}
   ReloadFile     : Boolean;
   EBsize         : Word;

Const
   EdOptInsert    = $1;           {Insert on flag}
   EdOptIndent    = $2;           {Autoindent on flag}
   EdOptTAB       = $8;           {Tab on flag}
   EdOptBlock     = $10;          {Show marked block}
   EdOptNoUpdate  = $20;          {Don't update screen when entering editor}
   EventKBflag    = 1;            {Scroll, num or caps locks modified mask}
   CAnorm         = #255#1;       {Activates CRT "normal" attribute}
   CAlow          = #255#2;       {Activates CRT "low"        -    }
   CAblk          = #255#3;       {Activates CRT "block"      -    }
   CAerr          = #255#4;       {Activates CRT "error"      -    }
   EdStatTextMod  = 1;            {Text EBuffer modified mask}


Procedure ViewFile(S : String);

Procedure FSE (FName : String;
               CurPos,TopRow,LastRow : Word;
               ForceInternal : Boolean);

Function  ReadInTheFile : Integer;

Function  FindByteOffset(FName : String; Row, Col : Word) : Word;

Procedure CRTputFast(x, y : Word; S : String);
   {-Use binary editor services to write a string to the screen}
   {x in 1..25, y in 1..80}

Function ExpandPath(FName : String) : String;
   {-Return a complete path using the binary editor services}

Function InitBinaryEditor
   (Var EdData     : EdCB;        {Editor control block}
    DataLen        : Word;        {Size of binary editor workspace}
    Cx1            : Byte;        {Editor window, upper left x 1..80}
    Cy1            : Byte;        {Editor window, upper left y 1..25}
    Cx2            : Byte;        {Editor window, lower right x 1..80}
    Cy2            : Byte;        {Editor window, lower right y 1..25}
    WaitForRetrace : Boolean;     {True for snowy color cards}
    Coptions       : Word;        {Initial editor options}
    DefExtension   : String;      {Default file extension (must start with period)}
    Var ExitCommands;             {Commands to exit editor}
    UserEventProcPtr : Pointer    {Pointer to user event handler}
    )              : Word;

   {-Initialize the binary editor, returning a status code}
  {
  Status Codes -
  0 = Successful initialization
  1 = Insufficient memory space for text EBuffer
  }

Function ReadFileBinaryEditor(Var EdData : EdCB; FName : String) : Word;
    {
    Read a file into the binary editor EBuffer space, returning a status code
    Status codes -
       0 = Successful read
       1 = File not found, new file assumed
       2 = File too large to edit
    }

Procedure ResetBinaryEditor(Var EdData : EdCB);
   {-Call the editor reset procedure}

Function UseBinaryEditor(Var EdData : EdCB; StartCommands : String) : Integer;
   {
   Edit file, using startcommands, and returning an ECode
   Exit codes -
      -1 = Editing terminated with ^KD
       0 = Editing terminated with first user-specified exit command
       1 ...
   }

Function ModifiedFileBinaryEditor(Var EdData : EdCB) : Boolean;
   {-Return true if text EBuffer was modified during edit}

Function FileNameBinaryEditor(Var EdData : EdCB) : String;
   {-Return the current file pathname of the specified control block}

Function SaveFileBinaryEditor(Var EdData : EdCB; MakeBackup : Boolean) : Word;
  {-Save the current file in the editor text EBuffer, returning a status code}
  { Status codes -
      0 = Successful save
      1 = File creation error
      2 = Disk write error
      3 = Error closing file
  }

Procedure ReleaseBinaryEditorHeap(Var EdData : EdCB);
   {-Release heap space used by a binary editor control block}



{********************} Implementation {*********************}

Var
   MainScrSaved : Boolean;

Procedure ViewFile(S : String);
Var
   Temp, DFile : String;
   rc : Integer;
Begin
   If S = '' then
      DFile := Get_File_Name('', qq.Browse_PGM, '', 13,
                             'View File Allocation',False)
   Else
      Dfile := qq.Browse_PGM + ' '+ S;
   If DFile <> '' Then
      Begin
         If (STUpCase(Copy(Dfile, 1, 7)) = '@EDITOR') then
            Begin
               Temp := Trim(Copy(DFile, 8, Length(DFile) - 7));
               Logit (Dfile);
               rc := Shell (Temp+'',''+'', ''+'', True, False,False);
               Exit;
            End;
         If STUpCase(Copy(DFile, 1, 4)) = '@FSE' Then
            Begin
               Temp := Trim(Copy(DFile, 5, Length(DFile) - 4));
               FSE(Temp, 0, 2, Pred(Last_Row),TRUE);
               Exit;
            End;

         Logit('View Execution');
         If QuickLearn then
            WriteLearn('DOS      "'+Dfile+'"');
         rc := Shell(DFile+'', ''+'', ''+'', True, False,False);
      End;
End;


Function FindByteOffset(FName : String; Row, Col : Word) : Word;
Var
   Counter : Word;
   F       : Text;
   S       : String;
Begin
   If Row = 1 Then
      Begin
         FindByteOffset := Pred(Col);
         Exit;
      End;
   Counter := 0;
   Assign(F, FName);
   If IoResult = 0 Then
      Begin
         Reset(F);
         If IoResult = 0 Then
            Begin
               For x := 1 To Pred(Row) Do
                  Begin
                     ReadLn(F, S);
                     Counter := Counter + Length(S) + 2;
                  End;
               FindByteOffset := Pred(Counter + Col);
               Close(F);
            End;
      End;
   IO := IoResult;
End;



Procedure EditErrorWindow(Msg : String);
Var
   c1, r1, c2, r2 : Byte;
   SaveTextAttr : Word;
Begin
   Msg := Center(' ' + Msg + ' ', 28);
   c1 := Pred(40 - (Length(Msg) Div 2));
   c2 := Succ(40 + (Length(Msg) Div 2));
   r1 := 9;
   r2 := 12;
   SaveTextAttr := TextAttr;
   Beep;
   SetWindow2 (c1,r1,c2,r2,' Edit Error! ',false);
   TextAttr := qq.menu;
   ClrScr;
   Write (Msg + Pad('', (Length(Msg) - 28) Div 2));
   KeyContinue (TextAttr);
   Restore_Screen;
   TextAttr := SaveTextAttr;
End;

Procedure CheckInitBinary(ECode : Word);
   {-Check the results of the editor load operation}
Begin                          {CheckInitBinary}
   If ECode <> 0 Then          {Couldn't initialize editor}
      Case ECode Of
         1  : EditErrorWindow('Insufficient space for text Buffer');
         Else EditErrorWindow('Unknown load error');
      End;
End;                           {CheckInitBinary}

Procedure CheckReadFile(ECode : Word; FName : String);
   {-Check the results of the file read}
Var
   F              : File;
Begin                          {CheckReadFile}
   If ECode <> 0 Then
      Begin                    {Couldn't read file}
         Case ECode Of
            1 : Begin {New file, assure valid file name}
                   Assign(F, FName);
                   Rewrite(F);
                   If IoResult <> 0 Then
                      Close(F)
                   Else
                      Begin
                         Close(F);
                         Erase(F);
                         Exit;
                      End;
                End;
            2 : EditErrorWindow('Insufficient text Buffer size');
            Else EditErrorWindow('Unknown read error');
         End;
      End;
End;                           {CheckReadFile}

Procedure CheckSaveFile(ECode : Word; FName : String);
   {-Check the results of a file save}
Begin                          {CheckSaveFile}
   If ECode <> 0 Then
      Begin                    {Couldn't save file}
         Case ECode Of
            1  : EditErrorWindow('Unable to create ' + FName);
            2  : EditErrorWindow('Error while writing ' + FName);
            3  : EditErrorWindow('Unable to close ' + FName);
            Else EditErrorWindow('Unknown write error');
         End;
      End;
End;                           {CheckSaveFile}


Procedure InitWindow(Var EdData : EdCB);
   {-Draw a nice screen frame around the editor window}
Begin
   {Draw a frame around the editor window}
   If not MainScrSaved then
      Begin
         With EdData Do
            If FSEHeader then
               Setwindow1(x1, y1, x2 + 2, y2 + 2, qq.editW, NewFSEHeader, false)
            Else
               Setwindow1(x1, y1, x2 + 2, y2 + 2, qq.editW, ' Full Screen Edit ', false);
         MainScrSaved := True;
      End;
End;

Procedure GetFSEname;
Begin
   FSEname := CleanPathName(Get_File_Name('', Last_Edit, '', 12,
                            'Internal Editor File Allocation',True));
End;

Function ExitBinaryEditor(Var EdData     : EdCB;
                          ExitCommand : Integer) : Boolean;
   {-Handle an editor exit - save or abandon file}
Var
   ECode  : Word;
Begin                          {ExitBinaryEditor}
   Case ExitCommand Of
      -1,4  : Begin       {^K^D or F10}
                 ECode := SaveFileBinaryEditor(EdData, MakeBackup);
                 CheckSaveFile(ECode, FileNameBinaryEditor(EdData));
                 ExitBinaryEditor := True;
                 GotoXY(1, 25);
              End;

      0,3,5 : Begin     {^K^Q or F9 or ESC}
                 If ModifiedFileBinaryEditor(EdData) Then
                    Begin
                       HelpTopic := 0;
                       Setwindow2(21, 6, 58, 8, 'Warning',false);
                       Write(' File modified. Save it? (Y/N) ');
                       If Get_Yes_No = 'Y' Then
                          Begin
                             ECode := SaveFileBinaryEditor(EdData, MakeBackup);
                             CheckSaveFile(ECode, FileNameBinaryEditor(EdData));
                          End;
                       Restore_Screen;
                    End;
                 ExitBinaryEditor := True;
              End;

      1     : Begin     {F2}
                 ECode := SaveFileBinaryEditor(EdData, MakeBackup);
                 CheckSaveFile(ECode, FileNameBinaryEditor(EdData));
                 ExitBinaryEditor := False;
              End;

      2     : Begin     {F3}
                 ECode := SaveFileBinaryEditor(EdData, MakeBackup);
                 CheckSaveFile(ECode, FileNameBinaryEditor(EdData));
                 GetFSEname;
                 If FSEname = '' Then
                    Begin
                       ExitBinaryEditor := True;
                       Exit;
                    End
                 Else
                    Last_Edit := FSEname;
                 ReloadFile := True;
                 ExitBinaryEditor := False;
              End;

      6     : Begin     {F1 Help}
                 HelpRoutine(9,NIL,6);
                 ExitBinaryEditor := False;
              End;
   End;
End;                           {ExitBinaryEditor}

Function ReadInTheFile : Integer;
Begin
   {Read the file}
   ECode := ReadFileBinaryEditor(EdData, FSEname);
   CheckReadFile(ECode, FileNameBinaryEditor(EdData));
   If ECode > 1 Then
      Begin
         ReadInTheFile := ECode;
         Exit;
      End;
   {Reset the editor for the new file}
   ResetBinaryEditor(EdData);
   ReadInTheFile := 0;
End;



{$L BINED}

{Routines internal to ASM code - all called NEAR}
Procedure pAssign(Var fromstr, tostr : AsciiZ); External;
Procedure cCrtPutf(Var S : AsciiZ; R, C : Word); External;
Procedure EditInit(Var EdData : EdCB); External;
Procedure EditNew(Var EdData : EdCB); External;
Function  Editor(Var EdData : EdCB) : Integer; External;


Function AsciizToStr(A : AsciiZ)    : String;
   {-Convert ASCIIZ to Turbo string}
Var
   S              : String;
   SLen           : Byte Absolute S;

Begin                          {AsciizToStr}
   SLen := 0;
   While A[SLen] <> #0 Do
      SLen := Succ(SLen);
   Move(A, S[1], SLen);
   AsciizToStr := S;
End;                           {AsciizToStr}

Procedure StrToAsciiz(S : String; Var A : AsciiZ);
   {-Convert a Turbo string into an ASCIIZ}
Var
   SLen           : Byte Absolute S;

Begin                          {StrToAsciiz}
   Move(S[1], A, SLen);
   A[SLen] := #0;
End;                           {StrToAsciiz}

Procedure CRTputFast(x, y : Word; S : String);
   {-Use binary editor services to write a string to the screen}
   {x in 1..25, y in 1..80}
Var
   A              : AsciiZ;
Begin                          {CRTputFast}
   {Create ASCIIZ string}
   StrToAsciiz(S, A);
   cCrtPutf(A, Pred(y), Pred(x));
End;                           {CRTputFast}

Function ExpandPath(FName : String) : String;
   {-Return a complete path using the binary editor services}
Var
   fromstr, tostr : AsciiZ;

Begin                          {ExpandPath}
   {Create ASCIIZ string from input}
   StrToAsciiz(FName, fromstr);

   {Call the binary editor service}
   pAssign(fromstr, tostr);

   {Get Turbo string from Asciiz}
   ExpandPath := STUpCase(AsciizToStr(tostr));
End;                           {ExpandPath}

Function InitBinaryEditor (Var EdData      : EdCB;
                               DataLen     : Word;
                               Cx1,
                               Cy1,
                               Cx2,
                               Cy2 : Byte;
                               WaitForRetrace : Boolean;
                               Coptions       : Word;
                               DefExtension   : String;
                           Var ExitCommands;
                               UserEventProcPtr : Pointer) : Word;

   {-Initialize the binary editor, returning a status code}
   {  Status Codes -
      0 = Successful initialization
      1 = Insufficient memory space for text EBuffer
   }
Var
   nofs, bofs, codelen : Word;

Begin                          {InitBinaryEditor}
   DataPtr_   := False;
   FileStr_   := False;
   Commands_  := False;
   Reserved1_ := False;
   MIstruct_  := False;
   CIstruct_  := False;
   DefExt_    := False;

   {Initialize the editor control block}
   With EdData Do
   Begin

      {Get the data space}
      DataSegLen := DataLen;
      GetMem(DataPtr, DataSegLen+15);
      If DataPtr = NIL then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;
      DataPtr_ := True;

      {Assure data space paragraph aligned}
      If Ofs(DataPtr^) <> 0 Then
         DataSeg := Succ(Seg(DataPtr^))
      Else
         DataSeg := Seg(DataPtr^);

      x1 := Pred(Cx1);
      x2 := Pred(Cx2);
      y1 := Pred(Cy1);
      y2 := Pred(Cy2);

      Options := Coptions;

      {Space for max length file string}
      GetMem(FileStr, 72);
      If FileStr = NIL then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;
      FileStr_ := True;

      {Room for 255 bytes of startup keystrokes}
      GetMem(Commands, 256);
      If Commands = NIL then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;


      Commands_ := True;

      FillChar(Commands^, 256, #0); {No startup commands right now}

      {Null out unused fields}
      Getmem(Reserved1, 8);
      If Reserved1 = NIL then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;
      Reserved1_ := True;

      FillChar(Reserved1^, 8, #0);

      Reserved2 := Nil;

      Event := Nil;

      EBuffer := Nil;           {Returned by Binary editor after initialization}
      EBufSize := 0;            {Returned by Binary editor after initialization}

      {Allocate and initialize main installation area}
      GetMem(MIstruct, SizeOf(MIstruct^));
      If MIstruct = NIL then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;
      MIstruct_ := True;

      With MIstruct^ Do
      Begin
         Ver := 4;
         VerSub := 0;
         VerPatch := 'A';      {4.0A}
         CPUmhz := 5;          {CPU speed in MHz - not critical}
         Getmem(CIstruct, SizeOf(CIstruct^));
         If CIstruct = NIL then
            Begin
               {Insufficient data space}
               InitBinaryEditor := 1;
               Exit;
            End;
         CIstruct_ := True;

         With CIstruct^ Do
         Begin
            CRTtype := 1;
            CRTx1 := 0;
            CRTy1 := 0;
            CRTx2 := pred(Last_Col);
            CRTy2 := 24;       {Change to 42 for EGA 43 line mode}
            CRTmode := $FF;    {Default screen mode}
            If CheckSnow Then
               CRTsnow := $FF
            Else
               CRTsnow := $0;
            MonoArray[0] := qq.edit1;     {Normal Text}
            MonoArray[1] := qq.edit2;     {Block Text}
            MonoArray[2] := qq.edit2;     {Frame Color}
            MonoArray[3] := qq.edit2;     {Error}
            AttrMono     := MonoArray;
            AttrBW       := MonoArray;
            AttrColor    := MonoArray;
         End;
         EIstruct := Nil;      {Command installation record set by Binary Editor}
         Getmem(Defext, 8);
         If DefExt = NIL then
            Begin
               {Insufficient data space}
               InitBinaryEditor := 1;
               Exit;
            End;
         DefExt_ := True;

         StrToAsciiz(DefExtension, DefExt^);
      End;

      {Install special exitcommands}
      ComTab := Addr(ExitCommands);

      {Position and status variables used by editor}
      EOtext := 0;
      CursorPos := 0;
      BlockStart := 0;
      BlockEnd := 0;
      Status := 0;

   End;

   {Call the binary editor initialization procedure}
   EditInit(EdData);

   {Exit with success code}
   InitBinaryEditor := 0;

End;                           {InitBinaryEditor}

Function ReadFileBinaryEditor(Var EdData     : EdCB;
                               FName : String) : Word;

   {-Read a file into the binary editor EBuffer space, returning a status code}
 {
 Status codes -
 0 = Successful read
 1 = File not found, new file assumed
 2 = File too large to edit
 }
Const
   ctrlz          = #26;
Var
   F              : File;
   fsize          : LongInt;
   zpos, bytesread : Word;

Begin                          {ReadFileBinaryEditor}
   With EdData Do
      Begin

         {Expand the pathname and store it in editor control block}
         FName := ExpandPath(FName);
         StrToAsciiz(FName, FileStr^);

         {See whether file exists}
         Assign(F, FName);
         Reset(F, 1);
         If IoResult <> 0 Then
            Begin
               {Couldn't open file, assume a new one}
               EOtext := 0;
               EBuffer^[EOtext] := #0;
               ReadFileBinaryEditor := 1;
               Exit;
            End;

         {Check the file size}
         fsize := FileSize(F);
         If fsize > EBufSize Then
            Begin
               {File too big}
               ReadFileBinaryEditor := 2;
               Close(F);
               Exit;
            End;

         {Read the file}
         BlockRead(F, EBuffer^, fsize, bytesread);
         Close(F);
         EOtext := fsize;

         {Scan for control Z in last sector of file}
         If EOtext < 512 Then
            zpos := 0
         Else
            zpos := EOtext - 512;
         While zpos <> EOtext Do
            If EBuffer^[zpos] = ctrlz Then
               EOtext := zpos
            Else
               Inc(zpos);
         EBuffer^[EOtext] := #0;

      End;
   {Exit with success code}
   ReadFileBinaryEditor := 0;
End;                           {ReadFileBinaryEditor}

Procedure ResetBinaryEditor(Var EdData : EdCB);
   {-Call the editor reset procedure}
Var W  : Word;
Begin                          {ResetBinaryEditor}
   EditNew(EdData);
End;                           {ResetBinaryEditor}

Function UseBinaryEditor
   (Var EdData     : EdCB;
    StartCommands : String) : Integer;
   {-Edit file, using startcommands, and returning an ECode}

Begin                          {UseBinaryEditor}
   {Put the start commands into the editor control block}
   If Length(StartCommands) > 0 Then
      Move(StartCommands[1], EdData.Commands^, Length(StartCommands));

   {Call the editor}
   UseBinaryEditor := Editor(EdData);
End;                           {UseBinaryEditor}

Function ModifiedFileBinaryEditor(Var EdData : EdCB) : Boolean;
   {-Return true if text EBuffer was modified during edit}

Begin                          {ModifiedFileBinaryEditor}
   ModifiedFileBinaryEditor := (EdData.Status And EdStatTextMod) <> 0;
End;                           {ModifiedFileBinaryEditor}

Function FileNameBinaryEditor(Var EdData : EdCB) : String;
   {-Return the file name in the specified control block}

Begin                          {FileNameBinaryEditor}
   FileNameBinaryEditor := AsciizToStr(EdData.FileStr^);
End;                           {FileNameBinaryEditor}

Function SaveFileBinaryEditor(Var EdData : EdCB; MakeBackup : Boolean) : Word;
   {-Save the current file in the editor text EBuffer, returning a status code}
 {
 Status codes -
 0 = Successful save
 1 = File creation error
 2 = Disk write error
 3 = Error closing file
 }
Var
   F              : File;
   FName          : String;
   I, byteswritten : Word;

   Function exist(FName : String; Var F : File) : Boolean;
      {-Return true and assigned file handle if file exists}
   Var
      I              : Word;
   Begin                       {Exist}
      Assign(F, FName);
      Reset(F);
      exist := (IoResult = 0);
      Close(F);
      {Clear ioresult}
      I := IoResult;
   End;                        {Exist}

   Procedure MakeBakFile(NewName : String);
      {-Make a backup file}
   Var
      nf, bf         : File;
      BakName        : String;
      DotPos         : Byte;
      C              : Char;

   Begin                       {MakeBakFile}
      If exist(NewName, nf) Then
      Begin
         {Workfile already exists, back it up}

         {Find position of last period in NewName}
         DotPos := Succ(Length(NewName));
         Repeat
            Dec(DotPos);
            C := NewName[DotPos];
         Until (C = '.') Or (C = '\') Or (C = ':') Or (DotPos = 0);

         If (DotPos = 0) Or (C <> '.') Then
            BakName := NewName + '.BAK'
         Else
            BakName := Copy(NewName, 1, DotPos) + 'BAK';

         If exist(BakName, bf) Then
            {Backup already exists, erase it}
                           Erase(bf);
         {Rename existing file to backup}
         Rename(nf, BakName);
      End;
   End;                        {MakeBakFile}

Begin                          {SaveFileBinaryEditor}
   With EdData Do
   Begin
      FName := AsciizToStr(FileStr^);
      If MakeBackup Then
         MakeBakFile(FName);
      Assign(F, FName);
      Rewrite(F, 1);
      If IoResult <> 0 Then
      Begin
         SaveFileBinaryEditor := 1;
         Close(F);
         I := IoResult;        {Clear ioresult}
         Exit;
      End;
      BlockWrite(F, EBuffer^, Succ(EOtext), byteswritten);
      If (byteswritten <> Succ(EOtext)) Or (IoResult <> 0) Then
      Begin
         SaveFileBinaryEditor := 2;
         Close(F);
         Exit;
      End;
      Close(F);
      If IoResult <> 0 Then
      Begin
         SaveFileBinaryEditor := 3;
         Exit;
      End;
      {Reset editor modified bit}
      Status := 0;
      {Success status}
      SaveFileBinaryEditor := 0;
   End;
End;                           {SaveFileBinaryEditor}

Procedure ReleaseBinaryEditorHeap(Var EdData : EdCB);
   {-Release heap space used by a binary editor control block}

Begin                          {ReleaseBinaryEditorHeap}
   With EdData Do
   Begin
      If DataPtr_   then FreeMem(DataPtr,DataSegLen + 15);
      If FileStr_   then Freemem(FileStr, 72);
      If Commands_  then Freemem(Commands, 256);
      If Reserved1_ then Freemem(Reserved1, 8);
      If CIstruct_  then Freemem(MIstruct^.CIstruct, SizeOf(MIstruct^.CIstruct^));
      If DefExt_    then Freemem(MIstruct^.DefExt, 8);
      If MIstruct_  then Freemem(MIstruct, SizeOf(MIstruct^));
   End;
End;                           {ReleaseBinaryEditorHeap}

Procedure FSE (FName : String;
               CurPos,TopRow,LastRow : Word;
               ForceInternal : Boolean);
Label
   EExit;
Var
   DoInit,
   RestoreVmode,
   ResetVideo  : Boolean;
   S, O, P     : ^Word;
   Hold16      : Pointer;
   VMode,
   SaveVMode   : Byte;
   SaveLastCol,
   SaveLastRow,
   SaveRLR     : Byte;
Begin
   If (not ForceInternal) and
      (STUpCase(Copy(qq.Browse_PGM, 1, 7)) = '@EDITOR') and
      (FName <> '') Then
      Begin
         ViewFile(FName);
         Exit;
      End;
   ResetVideo := False;
   AllowE0Codes := False;
   R.AH := $F;
   Intr($10, R);
   VMode := R.AL;
   {*
       For some strange reason, the VEGA VGA from Video-7 will set the
       Video mode to 1 (40x25) whenever it is in one of it's extended
       modes (like 132x43 or 80x60).  This causes the internal editor to
       get confused and messes up the display.  So much for 100%
       compatability!
   *}
   If Mem[$40:$49] = 1 then      { if 40 column mode, set it to 80 }
      Mem[$40:$49] := 3;

   RestoreVmode := False;
   If (Last_Col > 80)  then
      Begin
         Save_Screen (1,1,Last_Col,Last_Row);
         SaveLastCol := Last_Col;
         SaveLastRow := Last_Row;
         SaveRLR     := Real_Last_Row;
         ResetVideo  := True;

         r.AH := 0;
         r.AL := 3;
         Intr($10, R);
         ReInitCRT;

         CheckSnow := qq.CheckSnowx = 'Y';
         TopRow   := 3;
         LastRow  := 23;
         Last_Col := 80;
         Last_Row := 24;
         Real_Last_Row := 25;
      End
   else
      If not (VMode in [2,3,7]) then
         Begin
            SaveVMode := Vmode;
            Mem[$40:$49] := 3;
            RestoreVmode := True;
         End;

   Windx1 := 2;
   Windy1 := TopRow;
   Windx2 := Pred(Last_Col);
   If qq.ShowStatusLine then
      Windy2 := LastRow
   else
      Windy2 := Pred(LastRow);
   ReloadFile := False;
   DoInit := True;
   MainScrSaved := False;
   If FName = '' Then
      Begin
         GetFSEname;
         If FSEname = '' Then Exit
                         Else Last_Edit := FSEname;
      End
   Else
      FSEname := CleanPathName(FName);

   Push_Window;
   Push_Status;
   NormalCursor;
   {Initialize a window for the file}

   EBSize := Min(64000, MaxAvail-10000);

   {FillChar(EdData,Sizeof(EdData),#0);}
   ECode := InitBinaryEditor(
               EdData,       {Editor control block }
               EBsize,       {Size to reserve for EBuffer, $FFE0 max}
               Windx1,       {Coordinates of editor window, upper left 1..80}
               Windy1,       {Coordinates of editor window, upper left 1..25}
               Windx2,       {Coordinates of editor window, lower right}
               Windy2,       {Coordinates of editor window, lower right}
               True,         {True to wait for retrace on color cards}
               EdOptInsert+
               EdOptIndent,  {Initial editor toggles}
               '',           {Default extension for file names}
               ExitCommands, {Commands to exit editor}
               Nil);         {Address of user event handler}
   CheckInitBinary(ECode);
   If ECode <> 0 Then
      GoTo EExit;

   { Patch the BINED to use the supplied VideoSegment that TpCRT stores }
   S := @cCrtPutf;
   S := Ptr(Seg(S^), Ofs(S^) + 8);
   S := Ptr(Seg(S^), S^);
   O := @cCrtPutf;
   O := Ptr(Seg(O^), Ofs(O^) + 12);
   P := Ptr(S^, O^);
   P^ := VideoSegment;
   If ReadInTheFile > 1 Then
      GoTo EExit;

   EdData.CursorPos := CurPos;

   If ResetVideo then
      FastWrite(' - Video Mode temporarily switched to 80x25 - ',1,17,qq.WindF);

   Repeat
      Display_Status('');
      Display_Status(' F1-Help  F2-Save  F3-New  F9,ESC-Abort  F10-Save & Exit ');

      If ReloadFile Then
         Begin
            If ReadInTheFile > 1 Then
               GoTo EExit;
            ReloadFile := False;
         End;

      If DoInit Then
         Begin
            {Set up the window border and title}
            InitWindow(EdData);
            DoInit := False;
         End;

      {Edit the file}
      AllowE0Codes := False;
      ExitCommand := UseBinaryEditor(EdData, '');
      AllowE0Codes := True;

      {Handle the exit by saving the file or whatever}
   Until ExitBinaryEditor(EdData, ExitCommand);

   EExit:

   ReleaseBinaryEditorHeap(EdData);
   If MainScrSaved then
      Restore_Screen;

   Pop_Window;
   Pop_Status;

   x := IoResult;

   If ResetVideo then
      Begin
         r.AH := 0;
         r.AL := VMode;
         Intr($10, R);
         reinitcrt;
         CheckSnow := qq.CheckSnowx = 'Y';
         Last_Col := SaveLastCol;
         Last_Row := SaveLastRow;
         Real_Last_Row := SaveRLR;
         Restore_Screen;
      End
   Else
      If RestoreVMode then
         Mem[$40:$49] := SaveVMode;
End;


End.
