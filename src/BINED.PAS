{$A-}
Unit BinEd;    {-The Borland binary editor interface for Turbo Pascal}

interface

  Uses  tpcrt,
        initial;

const
  MaxFileSize = $FFE0;        {Maximum file size editable by Binary Editor}
  EdOptInsert = $1;           {Insert on flag}
  EdOptIndent = $2;           {Autoindent on flag}
  EdOptTAB = $8;              {Tab on flag}
  EdOptBlock = $10;           {Show marked block}
  EdOptNoUpdate = $20;        {Don't update screen when entering editor}
  EventKBflag = 1;            {Scroll, num or caps locks modified mask}
  CAnorm = #255#1;            {Activates CRT "normal" attribute}
  CAlow = #255#2;             {Activates CRT "low"        -    }
  CAblk = #255#3;             {Activates CRT "block"      -    }
  CAerr = #255#4;             {Activates CRT "error"      -    }
  EdStatTextMod = 1;          {Text buffer modified mask}

type
  AttrArray = array[0..3] of Byte;
  ASCIIZ = array[0..255] of Char;
  ASCIIZptr = ^ASCIIZ;
  TextBuffer = array[0..$FFF0] of Char;

  CRTinsStruct =              {CRT installation structure}
  record
    CRTtype : Byte;           {1=IBM, 0=Non}
    CRTx1, CRTy1,
    CRTx2, CRTy2 : Byte;      {Initial window size}
    CRTmode : Byte;           {Initial mode 0-3,7 or FF(default)}
    CRTsnow : Byte;           {0 if no snow, don't care for mono}
    AttrMono : AttrArray;     {CRT attributes for mono mode}
    AttrBW : AttrArray;       {CRT attributes for b/w modes}
    AttrColor : AttrArray;    {CRT attributes for color modes}
  end;
  CIptr = ^CRTinsStruct;

  EdInsStruct =               {Command table installation structure}
  record
    ComTablen : Word;         {Maximum length of command table}
    ComTab : TextBuffer;      {Command table}
  end;
  EIptr = ^EdInsStruct;

  MIinsStruct =               {Main installation structure}
  record
    Ver : Byte;               {Main version}
    VerSub : Byte;            {Sub version}
    VerPatch : Char;          {Patch level}
    CPUmhz : Byte;            {CPU speed for delays}
    CIstruct : CIptr;         {Points to CRT installation record}
    EIstruct : EIptr;         {Points to Editor installation area}
    DefExt : ASCIIZptr;       {Points to ASCIIZ default extension}
  end;
  MIptr = ^MIinsStruct;

  EdCB =                      {Editor control block in detail}
  record
    x1, y1, x2, y2 : Byte;    {Upper left and lower right corners of editor window}
    DataSeg : Word;           {Segment address of editor data area}
    DataSegLen : Word;        {Requested data area length (bytes)}
    Options : Word;           {Bit flags for editor options}
    FileStr : ASCIIZptr;      {Points to ASCIIZ filename}
    Commands : ASCIIZptr;     {Points to ASCIIZ string of editor commands}
    Reserved1 : ASCIIZptr;    {Not used here}
    Reserved2 : ASCIIZptr;    {Not used here}
    Event : Pointer;          {Points to event handling procedure}
    Buffer : ^TextBuffer;     {Points to text area}
    BufSize : Word;           {Available size for text}
    MIstruct : MIptr;         {Points to main installation record}
    ComTab : ASCIIZptr;       {Points to terminate command table}
    EOtext : Word;            {Current number of chars in text buffer}
    CursorPos : Word;         {Current cursor position in buffer}
    BlockStart : Word;        {Start of marked block in buffer}
    BlockEnd : Word;          {End of marked block in buffer}
    Status  : Word;           {Editor status}
    DataPtr : ^TextBuffer;    {Points to Turbo heap block allocated for text buffer}
  end;

Var
  {CRT attributes for   normal low blk error}
  MonoArray : AttrArray;
  p : pointer;

  {--------------------------------------------------------------------------}

Procedure CRTputFast(x, y : Word; s : string);
  {-Use binary editor services to write a string to the screen}
  {x in 1..25, y in 1..80}

function ExpandPath(Fname : string) : string;
  {-Return a complete path using the binary editor services}

function InitBinaryEditor
  (var EdData : EdCb;          {Editor control block}
    DataLen : Word;            {Size of binary editor workspace}
    Cx1 : Byte;                {Editor window, upper left x 1..80}
    Cy1 : Byte;                {Editor window, upper left y 1..25}
    Cx2 : Byte;                {Editor window, lower right x 1..80}
    Cy2 : Byte;                {Editor window, lower right y 1..25}
    WaitForRetrace : Boolean;  {True for snowy color cards}
    Coptions : Word;           {Initial editor options}
    DefExtension : string;     {Default file extension (must start with period)}
    var ExitCommands;          {Commands to exit editor}
    UserEventProcPtr : Pointer {Pointer to user event handler}
    ) : Word;

  {-Initialize the binary editor, returning a status code}
  {
  Status Codes -
  0 = Successful initialization
  1 = Insufficient memory space for text buffer
  }

function ReadFileBinaryEditor (var EdData : EdCb; Fname : string) : Word;
    {
    Read a file into the binary editor buffer space, returning a status code
    Status codes -
       0 = Successful read
       1 = File not found, new file assumed
       2 = File too large to edit
    }

procedure ResetBinaryEditor(var EdData : EdCb);
  {-Call the editor reset procedure}

function UseBinaryEditor(var EdData : EdCb; StartCommands : string) : Integer;
   {
   Edit file, using startcommands, and returning an exitcode
   Exit codes -
      -1 = Editing terminated with ^KD
       0 = Editing terminated with first user-specified exit command
       1 ...
   }

function ModifiedFileBinaryEditor(var EdData : EdCb) : Boolean;
  {-Return true if text buffer was modified during edit}

function FileNameBinaryEditor(var EdData : EdCb) : string;
  {-Return the current file pathname of the specified control block}

function SaveFileBinaryEditor(var EdData : EdCb; MakeBackup : Boolean) : Word;
  {-Save the current file in the editor text buffer, returning a status code}
  {
  Status codes -
    0 = Successful save
    1 = File creation error
    2 = Disk write error
    3 = Error closing file
  }

procedure ReleaseBinaryEditorHeap(var EdData : EdCb);
  {-Release heap space used by a binary editor control block}

  {==========================================================================}

implementation

  {$L BINED}

  {Routines internal to ASM code - all called NEAR}
  procedure pAssign(var fromstr, tostr : ASCIIZ); external;
  procedure cCrtPutf(var s : ASCIIZ; r, c : Word); external;
  procedure EditInit(var EdData : EdCb); external;
  procedure EditNew(var EdData : EdCb); external;
  function  Editor(var EdData : EdCb) : Integer; external;

var
  UserEventAddr : Pointer;

  {$L EVENT}

  {$F+}
  procedure EventCheck(pinfo, peventno : Word); external;
    {-Called to activate user background processes}
  {$F-}

  function AsciizToStr(a : ASCIIZ) : string;
    {-Convert ASCIIZ to Turbo string}
  var
    s : string;
    slen : Byte absolute s;

  begin                       {AsciizToStr}
    slen := 0;
    while a[slen] <> #0 do
      slen := Succ(slen);
    Move(a, s[1], slen);
    AsciizToStr := s;
  end;                        {AsciizToStr}

  procedure StrToAsciiz(s : string; var a : ASCIIZ);
    {-Convert a Turbo string into an ASCIIZ}
  var
    slen : Byte absolute s;

  begin                       {StrToAsciiz}
     Move(s[1], a, slen);
     a[slen] := #0;
  end;                        {StrToAsciiz}

  procedure CRTputFast(x, y : Word; s : String);
    {-Use binary editor services to write a string to the screen}
    {x in 1..25, y in 1..80}
  var
    a : ASCIIZ;

  begin                       {CRTputFast}
    {Create ASCIIZ string}
    StrToAsciiz(s, a);

    cCrtPutf(a, Pred(y), Pred(x));
  end;                        {CRTputFast}

  function ExpandPath(Fname : String) : String;
    {-Return a complete path using the binary editor services}
  var
    fromstr, tostr : ASCIIZ;

    function StupCase(s : string) : string;
      {-Uppercase a string}
    var
      i : Word;

    begin                     {StupCase}
      for i := 1 to Length(s) do
        s[i] := UpCase(s[i]);
      StupCase := s;
    end;                      {StupCase}

  begin                       {ExpandPath}
    {Create ASCIIZ string from input}
    StrToAsciiz(Fname, fromstr);

    {Call the binary editor service}
    pAssign(fromstr, tostr);

    {Get Turbo string from Asciiz}
    ExpandPath := StupCase(AsciizToStr(tostr));
  end;                        {ExpandPath}

  function InitBinaryEditor
   (var EdData : EdCB;
    DataLen : Word;
    Cx1, Cy1, Cx2, Cy2 : Byte;
    WaitForRetrace : Boolean;
    Coptions : Word;
    DefExtension : String;
    var ExitCommands;
    UserEventProcPtr : Pointer
    ) : Word;

    {-Initialize the binary editor, returning a status code}
    {
    Status Codes -
    0 = Successful initialization
    1 = Insufficient memory space for text buffer
    }
  var
    nofs, bofs, codelen : Word;

  begin                       {InitBinaryEditor}

    {Initialize the editor control block}
    with EdData do begin

      {Get the data space}
      DataSegLen := DataLen;
      If not GetHeap(EditHeap, DataPtr, DataSegLen+15) then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;


      {Assure data space paragraph aligned}
      if Ofs(DataPtr^) <> 0 then
        DataSeg := Succ(Seg(DataPtr^))
      else
        DataSeg := Seg(DataPtr^);

      x1 := Pred(Cx1);
      x2 := Pred(Cx2);
      y1 := Pred(Cy1);
      y2 := Pred(Cy2);
      Options := Coptions;

             {Space for max length file string}
      If not GetHeap(EditHeap, FileStr, 72) then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;

             {Room for 255 bytes of startup keystrokes}
      If not GetHeap(EditHeap, Commands, 256) then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;


      FillChar(Commands^, 256, #0); {No startup commands right now}

             {Null out unused fields}
      If not GetHeap(EditHeap, Reserved1, 8) then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;

      FillChar(Reserved1^, 8, #0);

      Reserved2 := nil;

      if UserEventProcPtr = nil then
         {Disable event checking}
         Event := nil
      else begin
         {Set up for user event checking}
         Event := Addr(EventCheck);
         UserEventAddr := UserEventProcPtr;
      end;

      Buffer := nil;          {Returned by Binary editor after initialization}
      BufSize := 0;           {Returned by Binary editor after initialization}

      {Allocate and initialize main installation area}
      If not GetHeap (EditHeap, MIstruct, SizeOf(MIstruct^)) then
         Begin
            {Insufficient data space}
            InitBinaryEditor := 1;
            Exit;
         End;

      with MIstruct^ do begin
        Ver := 4;
        VerSub := 0;
        VerPatch := 'A';      {4.0A}
        CPUmhz := 5;          {CPU speed in MHz - not critical}
        If not GetHeap(EditHeap, CIstruct, SizeOf(CIstruct^)) then
           Begin
              {Insufficient data space}
              InitBinaryEditor := 1;
              Exit;
           End;
        with CIstruct^ do begin
          CRTtype := 1;
          CRTx1 := 0;
          CRTy1 := 0;
          CRTx2 := 79;
          CRTy2 := 24;        {Change to 42 for EGA 43 line mode}
          CRTmode := $FF;     {Default screen mode}
          if CheckSnow then
            CRTsnow := $FF
          else
            CRTsnow := $0;
          MonoArray[0] := qq.Menu;   {Normal text}
          MonoArray[1] := qq.Menu2;  {Block text}
          MonoArray[2] := qq.Windf;  {frame color}
          MonoArray[3] := qq.Menu2;  {error}
          AttrMono := MonoArray;
          AttrBW := MonoArray;
          AttrColor := MonoArray;
        end;
        EIstruct := nil;      {Command installation record set by Binary Editor}
        If not GetHeap(EditHeap, DefExt, 8) then    {Default file extension}
           Begin
              {Insufficient data space}
              InitBinaryEditor := 1;
              Exit;
           End;


        StrToAsciiz(DefExtension, DefExt^);
      end;

      {Install special exitcommands}
      ComTab := Addr(ExitCommands);

      {Position and status variables used by editor}
      EOtext := 0;
      CursorPos := 0;
      BlockStart := 0;
      BlockEnd := 0;
      Status := 0;

    end;

    {Call the binary editor initialization procedure}
    EditInit(EdData);

    {Exit with success code}
    InitBinaryEditor := 0;

  end;                        {InitBinaryEditor}

  function ReadFileBinaryEditor
   (var EdData : EdCB;
    Fname : String) : Word;

    {-Read a file into the binary editor buffer space, returning a status code}
    {
    Status codes -
    0 = Successful read
    1 = File not found, new file assumed
    2 = File too large to edit
    }
  const
    ctrlz = #26;
  var
    f : file;
    fsize : longint;
    zpos, bytesread : Word;

  begin                       {ReadFileBinaryEditor}
    with EdData do begin

      {Expand the pathname and store it in editor control block}
      Fname := ExpandPath(Fname);
      StrToAsciiz(Fname, FileStr^);

      {See whether file exists}
      Assign(f, Fname);
      Reset(f, 1);
      if IOResult <> 0 then begin
        {Couldn't open file, assume a new one}
        EOtext := 0;
        Buffer^[EOtext] := #0;
        ReadFileBinaryEditor := 1;
        Exit;
      end;

      {Check the file size}
      fsize := FileSize(f);
      if fsize > BufSize then begin
        {File too big}
        ReadFileBinaryEditor := 2;
        Close(f);
        Exit;
      end;

      {Read the file}
      BlockRead(f, Buffer^, fsize, bytesread);
      Close(f);
      EOtext := fsize;

      {Scan for control Z in last sector of file}
      if EOtext < 512 then
        zpos := 0
      else
        zpos := EOtext-512;
      while zpos <> EOtext do
        if Buffer^[zpos] = ctrlz then
          EOtext := zpos
        else
          inc(zpos);
      Buffer^[EOtext] := #0;

    end;
    {Exit with success code}
    ReadFileBinaryEditor := 0;
  end;                        {ReadFileBinaryEditor}

  procedure ResetBinaryEditor(var EdData : EdCB);
    {-Call the editor reset procedure}
  Var zzz : word;
  begin                       {ResetBinaryEditor}
    EditNew(EdData);
  end;                        {ResetBinaryEditor}

  function UseBinaryEditor
   (var EdData : EdCB;
    StartCommands : String) : Integer;
    {-Edit file, using startcommands, and returning an exitcode}

  begin                       {UseBinaryEditor}
    {Put the start commands into the editor control block}
    if Length(StartCommands) > 0 then
      Move(StartCommands[1], EdData.Commands^, Length(StartCommands));

    {Call the editor}
    UseBinaryEditor := Editor(EdData);
  end;                        {UseBinaryEditor}

  function ModifiedFileBinaryEditor(var EdData : EdCB) : Boolean;
    {-Return true if text buffer was modified during edit}

  begin                       {ModifiedFileBinaryEditor}
    ModifiedFileBinaryEditor := (EdData.Status and EdStatTextMod) <> 0;
  end;                        {ModifiedFileBinaryEditor}

  function FileNameBinaryEditor(var EdData : EdCb) : String;
    {-Return the file name in the specified control block}

  begin                       {FileNameBinaryEditor}
    FileNameBinaryEditor := AsciizToStr(EdData.FileStr^);
  end;                        {FileNameBinaryEditor}

  function SaveFileBinaryEditor(var EdData : EdCB; MakeBackup : Boolean) : Word;
    {-Save the current file in the editor text buffer, returning a status code}
    {
    Status codes -
    0 = Successful save
    1 = File creation error
    2 = Disk write error
    3 = Error closing file
    }
  var
    f : file;
    Fname : string;
    i, byteswritten : Word;

    function Exist(Fname : string; var f : file) : Boolean;
      {-Return true and assigned file handle if file exists}
    var
      i : Word;
    begin                     {Exist}
      Assign(f, Fname);
      Reset(f);
      Exist := (IOResult = 0);
      Close(f);
      {Clear ioresult}
      i := IOResult;
    end;                      {Exist}

    procedure MakeBakFile(NewName : string);
      {-Make a backup file}
    var
      nf, bf : file;
      BakName : string;
      DotPos : Byte;
      C : Char;

    begin                     {MakeBakFile}
      if Exist(NewName, nf) then begin
        {Workfile already exists, back it up}

        {Find position of last period in NewName}
        DotPos := Succ(Length(NewName));
        repeat
          dec(DotPos);
          C := NewName[DotPos];
        until (C = '.') or (C = '\') or (C = ':') or (DotPos = 0);

        if (dotpos = 0) or (C <> '.') then
          bakname := newname+'.BAK'
        else
          bakname := Copy(NewName, 1, dotpos)+'BAK';

        if Exist(bakname, bf) then
          {Backup already exists, erase it}
          Erase(bf);
        {Rename existing file to backup}
        Rename(nf, bakname);
      end;
    end;                      {MakeBakFile}

  begin                       {SaveFileBinaryEditor}
    with EdData do begin
      Fname := AsciizToStr(FileStr^);
      if MakeBackup then
        MakeBakFile(Fname);
      Assign(f, Fname);
      Rewrite(f, 1);
      if IOResult <> 0 then begin
        SaveFileBinaryEditor := 1;
        Close(f);
        i := IOResult;        {Clear ioresult}
        Exit;
      end;
      BlockWrite(f, Buffer^, Succ(EOtext), byteswritten);
      if (byteswritten <> Succ(EOtext)) or (IOResult <> 0) then begin
        SaveFileBinaryEditor := 2;
        Close(f);
        Exit;
      end;
      Close(f);
      if IOResult <> 0 then begin
        SaveFileBinaryEditor := 3;
        Exit;
      end;
      {Reset editor modified bit}
      Status := 0;
      {Success status}
      SaveFileBinaryEditor := 0;
    end;
  end;                        {SaveFileBinaryEditor}

  procedure ReleaseBinaryEditorHeap(var EdData : EdCB);
    {-Release heap space used by a binary editor control block}

  begin                       {ReleaseBinaryEditorHeap}
    with EdData do begin
      FreeHeap(EditHeap, DataPtr, DataSegLen+15);
      FreeHeap(EditHeap, FileStr, 72);
      FreeHeap(EditHeap, Commands, 256);
      FreeHeap(EditHeap, Reserved1, 8);
      FreeHeap(EditHeap, MIstruct^.CIstruct, SizeOf(MIstruct^.CIstruct^));
      FreeHeap(EditHeap, MIstruct^.DefExt, 8);
      FreeHeap(EditHeap, MIstruct, SizeOf(MIstruct^));
    end;
  end;                        {ReleaseBinaryEditorHeap}

end.
