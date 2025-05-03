
{$X+}

unit
  QmMisc;

interface

uses
  Dos,      OpRoot,  OpDos,    OpCrt,
  OpString, OpFrame, OpWindow, QmColor;

const
  Configuration_Version_Supported = '4.5';

var
  Qmodem_Status_Window: RawWindowPtr;

function  AsciiZ2String(var AsciiZ_String): string;
function  Backup(Fn, Ext: string): boolean;
procedure CheckIoResult(Status_Text: string);
procedure DoClosing;
procedure EatKey;
procedure Fatal(Status_Text: string);
function IncFilename(File_Name: string): string;
procedure RewriteScreen;
procedure StatusLine(Status_Text: string);
function Warning(Status_Text: string): boolean;

implementation

var
  Original_ExitProc: pointer; { Holds Turbo'Status_Text exit process address.}

  function AsciiZ2String(var AsciiZ_String): string; assembler;
  asm
    PUSH    DS                {Save Turbo'Status_Text data segment}
    CLD                       {Don't move backwards}
    LES     DI, @Result       {Load string(@Result)}
    PUSH    DI                {Save string index/length byte}
    INC     DI                {Move to beginning of resulting string}
    LDS     SI, AsciiZ_String {Load AsciiZ string}
    XOR     BX, BX            {Zero out (internal) index counter}
  @Loop:
    CMP     byte ptr DS:[SI], 0 {"Have we reached the end of the AsciiZ?"}
    JE      @Done             {"Yes!" - Finish up string construction}
    INC     BX                {Increment (internal) counter}
    movsb                     {Transfer from "source" to "destination"}
    CMP     BX, 255           {"Have we reached Turbo'Status_Text max string length?"}
    JE      @Done             {"Yes!" - Finish up string construction}
    JMP     @Loop             {Process next character in AsciiZ string}
  @Done:
    POP     DI                {Restore string(@Result)'Status_Text index/length byte}
    MOV     AX, BX            {Our counter holds the length ...}
    STOSB                     {Save it to string(@Result)[0]}
    POP DS                    {Restore Turbo'Status_Text data segment}
  end;

  function Backup(Fn, Ext: string): boolean;
  const
    BS = 4096;
  var
    Status_Text: string;
    B: pointer;
  begin
    Backup := false;
    Status_Text := ForceExtension(Fn, Ext);

    If not GetMemCheck(B, BS) then
      exit;

    if Copyfile(Fn, Status_Text, B, BS) <> 0 then
      exit;

    Backup := true;
  end;

  procedure CheckIoResult(Status_Text: string);
  begin
    if IOResult <> 0 then
      Fatal(Status_Text);
  end;

  procedure DoClosing;
  begin
    RewriteScreen;
    writeln('QMFONCNV  Version 1.1 (12/19/91)');
    writeln('Copyright (c) 1991 Mustang Software, Inc.');
    halt(0);
  end;

  procedure EatKey;
  begin
    ReadKeyWord;
  end;

  procedure Fatal(Status_Text: string);
  const
    LX = 5;  LY = 6;
    HX = 75; HY = 7;
  var
    Fatal_Window: RawWindow;
  begin
    HiddenCursor;
    with Fatal_Window do
      if InitCustom(LX, LY, HX, HY, QmColorSet, DefWindowOptions or wBordered) then begin
        wFrame.AddHeader(' Fatal Error! ', heTC);
        wFrame.AddShadow(shBR, shSeeThru);
        Draw;
        HiddenCursor;
        wFastCenter(Status_Text, 1,
          ColorMono(QmColorSet.TextColor, QmColorSet.TextMono));
        wFastCenter(Center('Press any key to return to DOS', Succ(HX - LX)), 2,
          ColorMono(QmColorSet.HighlightColor, QmColorSet.HighlightMono));
        write(^G);
        Eatkey;
        Done;
      end;

    DoClosing;
  end;

  function IncFilename(File_Name: string): string;
  const
    Max_Name_Str_Len = 8;
    Zero_Str = '0';
  var
    New_File_Name: string;
    File_Index: longint;
    File_Index_Str: string;
    File_Index_Str_Len: byte absolute File_Index_Str;
    Dir_Str: DirStr;
    Name_Str: NameStr;
    Ext_Str: ExtStr;
    Name_Str_Len: byte absolute Name_Str;
  begin
    {Initialize our index}
    File_Index := -1;
    New_File_Name := File_Name;

    while ExistFile(New_File_Name) do begin
      {Increment our index}
      Inc(File_Index);
      {Isolate the file's name}
      FSplit(File_Name, Dir_Str, Name_Str, Ext_Str);
      {Update incremented string}
      File_Index_Str := LeftPadCh(Long2Str(File_Index), Zero_Str,
                                  Max_Name_Str_Len - Name_Str_Len);
      {Ensure length of Max_Name_Str_Len}
      Name_Str := Pad(Name_Str, Max_Name_Str_Len);
      {Update the file's name}
      move(File_Index_Str[1], Name_Str[Succ(Max_Name_Str_Len -
           File_Index_Str_Len)], File_Index_Str_Len);
      {Rebuild the file's full pathname}
      New_File_Name := Dir_Str + Name_Str + Ext_Str;
    end;

    {Return result to caller}
    IncFilename := New_File_Name;
  end;


  procedure RewriteScreen;
  begin
    Window(1, 1, ScreenWidth, ScreenHeight);
    TextAttr := $07;
    ClrScr;
  end;

  procedure StatusLine(Status_Text: string);
  var
    Text_Length: byte absolute Status_Text;
    Display_String: string;
  begin
    if Text_Length = 0 then
      Display_String := Center('Copyright (C) 1991 by Mustang Software Inc.', ScreenWidth)
    else Display_String := Pad(' ' + Status_Text, ScreenWidth);

    FastWrite(Display_String, ScreenHeight, 1,
      ColorMono(QmColorSet.HighlightColor, QmColorSet.HighlightMono));
  end;

  function Warning(Status_Text: string): boolean;
  const
    LX = 5;  LY = 6;
    HX = 75; HY = 7;
  var
    Warning_Window: RawWindow;
    W: word;
  begin
    HiddenCursor;
    with Warning_Window do
      if InitCustom(LX, LY, HX, HY, QmColorSet, DefWindowOptions or wBordered) then begin
        wFrame.AddHeader(' Warning! ', heTC);
        wFrame.AddShadow(shBR, shSeeThru);
        Draw;
        HiddenCursor;
        wFastCenter(Status_Text, 1,
          ColorMono(QmColorSet.TextColor, QmColorSet.TextMono));
        wFastCenter(Center('Press (Esc) to abort or (Space) to continue', Succ(HX - LX)), 2,
          ColorMono(QmColorSet.HighlightColor, QmColorSet.HighlightMono));

        repeat
          W := ReadKeyWord;
        until (W = $011B) or (W = $3920);

        Done;
      end;

    Warning := (W = $011B);
  end;

  (* Unit de/intialization *)

  procedure QmMiscExit; far;
  begin
    ExitProc := Original_ExitProc;
    NormalCursor;

    asm
      MOV     CX, 15         {Turbo only supports 15 files open at once. (???)}
      MOV     BX, 5          {Next handle after Std handles.}
    @NextHandle:
      MOV     AH, 3Eh        {Close file function.}
      INT     21h            {Call DOS.}
      INC     BX             {Increment file handle.}
      LOOP    @NextHandle    {Do it again...}
    end;
  end;

begin
  Original_ExitProc := ExitProc;
  ExitProc := @QmMiscExit;
  DetectMultitasking := true;
  ReinitCRT;
  Assign(Output, '');
  Rewrite(Output);
end.

