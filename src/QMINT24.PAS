
{$F+,B-}

unit
  QmInt24;

interface

uses
  Dos,     OpDos,    OpInt,   OpCrt,
  OpFrame, OpWindow, QmColor, QmMisc;

implementation

const
  INT24_Handle = 16;

var
  DOS_Version:   word;
  Error_Window:  RawWindow;
  SAVE_ExitProc: pointer;

  function Get_Action_Code: byte;
  const
    DOS2_Response_Set: set of char = ['A', 'R', 'I'];
    DOS3_Response_Set: set of char = ['R', 'I', 'F'];
    Prompt_Line = 5;
  var
    Action_Code: word;
    Key: char;
    Response_Prompt: string;
    Response_Length: byte absolute Response_Prompt;
    Response_Set: set of char;
  begin
    if hi(DOS_Version) < 3 then begin
      Response_Prompt := 'Abort, Retry, Ignore?';
      Response_Set := DOS2_Response_Set;
    end else begin
      Response_Prompt := 'Retry, Ignore, Fail?';
      Response_Set := DOS3_Response_Set;
    end;

    with Error_Window do begin
      wFastCenter(Response_Prompt, Prompt_Line,
        ColorMono(QmColorSet.FlexBHelpColor, QmColorSet.FlexBHelpMono));
      GotoXY(((wXH - wXL - Response_Length) shr 1) + Response_Length + 2, Prompt_Line);
    end;

    Repeat
      Key := Upcase(char(lo(ReadKeyWord)));
    until Key in Response_Set;

    case Key of
      'I': Action_Code := 0;
      'R': Action_Code := 1;
      'A': Action_Code := 2;
      'F': Action_Code := 3;
    end;

    Get_Action_Code := lo(Action_Code);
  end;

  function Handle_Error(Error_Code: byte; Device_Name: string): word;
  const
    Error_Description: array[1..90] of string[35] = (
      {  1 } 'Invalid function number',
      {  2 } 'File not found',
      {  3 } 'Path not found',
      {  4 } 'No handles available',
      {  5 } 'Access denied',
      {  6 } 'Invalid handle',
      {  7 } 'Memory control blocks lost',
      {  8 } 'Insufficient memory',
      {  9 } 'Invalid memory address',
      { 10 } 'Invalid environment',
      { 11 } 'Invalid format',
      { 12 } 'Invalid access code',
      { 13 } 'Invalid data',
      { 14 } '',                        { RESERVED }
      { 15 } 'Invalid drive',
      { 16 } 'Attempt to remove current directory',
      { 17 } 'Not the same device',
      { 18 } 'No more files',
      { 19 } 'Disk write-protected',

      (* Ordinal 20 through 31 equate to INT24's lo(DI) register *)
      { 20 } 'Unknown unit',
      { 21 } 'Drive not ready',
      { 22 } 'Unknown command',
      { 23 } 'Data error (CRC)',
      { 24 } 'Bad request structure length',
      { 25 } 'Seek error',
      { 26 } 'Unknown media type',
      { 27 } 'Sector not found',
      { 28 } 'Printer out of paper',
      { 29 } 'Write fault',
      { 30 } 'Read fault',
      { 31 } 'General failure',

      { 32 } 'File sharing violation',
      { 33 } 'Lock violation',
      { 34 } 'Invalid disk change',
      { 35 } 'FCB unavaliable',
      { 36 } 'Sharing buffer overflow',
      { 37 } '',                        { RESERVED }
      { 38 } 'Unable to complete file operation', { DOS 4.xx }

      {39-49 reserved}
      { 39 } '',
      { 40 } '',
      { 41 } '',
      { 42 } '',
      { 43 } '',
      { 44 } '',
      { 45 } '',
      { 46 } '',
      { 47 } '',
      { 48 } '',
      { 49 } '',

      { 50 } 'Unsupported network request',
      { 51 } 'Remote computer not listening',
      { 52 } 'Duplicate name on network',
      { 53 } 'Network name not found',
      { 54 } 'Network busy',
      { 55 } 'Device no longer exists on network',
      { 56 } 'NetBIOS command limit exceeded',
      { 57 } 'Error in network adapter',
      { 58 } 'Incorrect response from network',
      { 59 } 'Unexpected network error',
      { 60 } 'Remote adapter incompatible',
      { 61 } 'Print queue full',
      { 62 } 'Queue not full',
      { 63 } 'Not enough room for print file',
      { 64 } 'Network name deleted',
      { 65 } 'Access denied',
      { 66 } 'Incorrect network device type',
      { 67 } 'Network name not found',
      { 68 } 'Network name limit exceeded',
      { 69 } 'NETBIOS session limit exceeded',
      { 70 } 'Temporary pause',
      { 71 } 'Network request not accepted',
      { 72 } 'Print or disk redirection paused',

      {73-79 reserved}
      { 73 } '',
      { 74 } '',
      { 75 } '',
      { 76 } '',
      { 77 } '',
      { 78 } '',
      { 79 } '',

      { 80 } 'File already exists',
      { 81 } '',                        { RESERVED }
      { 82 } 'Cannot make directory',
      { 83 } 'Fail on Int 24',
      { 84 } 'Too many redirections',
      { 85 } 'Duplicate redirection',
      { 86 } 'Invalid password',
      { 87 } 'Invalid parameter',
      { 88 } 'Network write fault',
      { 89 } 'Unsupported network function',
      { 90 } 'Missing system component');
  var
    Action_Code: word;
    DOS_Regs: registers;
    SAVE_CheckBreak: boolean;
    SAVE_Cursor_Location: word;
    SAVE_Cursor_Size: word;
    SAVE_TextAttr: byte;
  begin
    { Save current display state }
    GetCursorState(SAVE_Cursor_Location, SAVE_Cursor_Size);
    SAVE_TextAttr := TextAttr;
    SAVE_CheckBreak := CheckBreak;
    CheckBreak := false;
    TextAttr := ColorMono(QmColorSet.FlexBHelpColor, QmColorSet.FlexBHelpMono);

    sound(894);
    delay(625);
    nosound;

    with Error_Window do begin
      Draw;
      { GotoXY(1, 1); }
      TextAttr := ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono);
      Clrscr;

      {Check error code}
      case Error_Code of
        {Write-protect error}
        0: begin
          wFastCenter('Disk in drive '+ Device_Name + ' is write-protected', 1,
            ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));
          wFastCenter('Remove tab before retrying', 2,
            ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));
        end;

        {Drive not ready}
        2: if Device_Name[2] = ':' then begin
          wFastCenter('Drive ' + Device_Name + ' not ready', 1,
            ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));
          wFastCenter('Close drive door before retrying', 2,
            ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));
        end else wFastCenter('Printer ' + Device_Name + ' not ready', 1,
          ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));

        {Printer out of paper}
        9: wFastCenter('Printer ' + Device_Name + ' is out of paper', 1,
          ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));

      {Other possible errors are ...
          1: Unkown unit,
          3: Unkown command,
          4: Data error (bad CRC),
          5: Bad request structrue length,
          6: Seek error,
          7: Unkown media type,
          8: Sector not found,
         10: Write fault,
         11: Read fault, and
         12: General failure.}
      else
        begin
          if Device_Name[2] = ':' then
            wFastCenter('Error with drive ' + Device_Name, 1,
              ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono))
          else wFastCenter('Check printer ' + Device_Name, 1,
            ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));
        end;
      end;

      { Don't attempt to read extended error information unless user is
        using DOS 3.x or higher. }

      If DOS_Version < 3 then
        Inc(Error_Code, 19)
      else with DOS_Regs do begin
        AH := $59;
        BX := 0;
        MsDos(DOS_Regs);
        Error_Code := AL;
      end;

      if (Error_Code > 0) and (Error_Code < 91) then
        wFastCenter('Probable cause:  ' + Error_Description[Error_Code], 3,
          ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono))
      else wFastCenter('Probable cause:  Unknown', 3,
        ColorMono(QmColorSet.FlexAHelpColor, QmColorSet.FlexAHelpMono));

      Action_Code := Get_Action_Code;
      Erase;
    end;

    RestoreCursorState(SAVE_Cursor_Location, SAVE_Cursor_Size);
    TextAttr := SAVE_TextAttr;
    CheckBreak := SAVE_CheckBreak;
    Handle_Error := Action_Code;
  end;

  procedure INT24_UserHandler(BP: word); interrupt;
    {-Interrupt handler for the critical error interrupt.}
  type
    Device_Header = record
      Next: pointer;
      Attributes: word;
      StrategyAddr: word;
      InterruptAddr: word;
      Name: array[1..8] of char
    end;
  var
    Device_Name: string;
    INT_Regs: IntRegisters absolute BP;

    function Device_Header_Name: string;
    begin
      with INT_Regs do
        Device_Header_Name := Asciiz2String(Device_Header(ptr(BP, SI)^).Name);
    end;

  begin
    { Allow other interrupts (like the timer) to continue processing.
      Yes, must send EOI to ensure that the PIC knows to continue on! }

    InterruptsOn;
    SendEOI;

    with INT_Regs do begin
      if (AX and $8000) = 0 then
        { Pass the drive name to user error handler }
        Device_Name := chr(lo(AX) + ord('A')) + ':'
      else with Device_Header(ptr(BP, SI)^) do
        if (Attributes and $8000) <> 0 then
          { Bad memory image of FAT - no device name available }
          Device_Name := '(File Allocation Table)'
        { Get name of character device }
        else Device_Name := Device_Header_Name;

      { Pass back user's response to DOS }
      AX := Handle_Error(lo(DI), Device_Name);
    end;
  end;

  procedure ExitHandler;
    {-Restore the original INT24 handler.}
  begin
    ExitProc := SAVE_ExitProc;
    RestoreVector(INT24_Handle);
    Error_Window.Done;
  end;

begin
  SAVE_ExitProc := ExitProc;
  SAVE_ExitProc := @ExitHandler;
  InitVector($24, INT24_Handle, @INT24_UserHandler);
  DOS_Version := OpDos.DosVersion;

  if Error_Window.InitCustom(15, 10, 65, 14, QmColorSet, DefWindowOptions or wBordered) then
    with Error_Window, wFrame do begin
      SetFrameAttr(QmColorSet.FlexCHelpColor, QmColorSet.FlexCHelpMono);
      SetHeaderAttr(QmColorSet.FlexCHelpColor, QmColorSet.FlexCHelpMono, false);
      AddHeader(' Critical Error! ', heTC);
      AddShadow(shBR, shSeeThru);
  end else begin
    assign(output, '');
    rewrite(output);
    writeln('Program too big to fit in memory');
    halt(1);
  end;
end.

