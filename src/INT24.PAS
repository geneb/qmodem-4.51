{$S-,A-,R-,P+,V+}
Unit Int24;

Interface

Var
   CriticalProc: pointer;   { Address of special critical error handler }

Implementation

Uses Dos,
     TpCrt,
     TpWindow,
     TpString,
     Initial;

Const Attr = $70;

Var
   ExitSave  : pointer;
   xOldInt24 : pointer;
   CurrentCriticalProc : pointer;
   Int24FLAGS,
   Int24AL,
   Int59AX,
   Int59BH,
   Int59CH,
   Int59BL : Integer;
Type
   DeviceHeader = Record
                     Next: pointer;
                     Attributes: word;
                     StrategyAddr: word;
                     InterruptAddr: word;
                     Name: array[1..8] of char
                  End;
Var
   DeviceName: string[8];
   SaveCriticalProc: pointer;
   Regs : Registers;
   RC   : Word;

Procedure CallUserHandler(var RC         : Word;
                              ErrorCode  : Word;
                          var DeviceName : string);
  Inline($FF/$1E/>CurrentCriticalProc);

Procedure JmpOldISR(OldISR: pointer);
  inline($5B/                   {  pop bx             ;BX = Ofs(OldIsr)}
         $58/                   {  pop ax             ;AX = Seg(OldIsr)}
         $87/$5E/$0E/           {  xchg bx,[bp+14]    ;Switch old BX and Ofs(OldIsr)}
         $87/$46/$10/           {  xchg ax,[bp+16]    ;Switch old AX and Seg(OldIsr)}
         $89/$EC/               {  mov sp,bp          ;Restore SP}
         $5D/                   {  pop bp             ;Restore BP}
         $07/                   {  pop es             ;Restore ES}
         $1F/                   {  pop ds             ;Restore DS}
         $5F/                   {  pop di             ;Restore DI}
         $5E/                   {  pop si             ;Restore SI}
         $5A/                   {  pop dx             ;Restore DX}
         $59/                   {  pop cx             ;Restore CX}
         $CB);                  {  retf               ;Chain to OldIsr, leaving CS and IP params on the stack}

{$F+}
Procedure Int24Handler(Flags,CS,IP,AX,BX,CX,DX,SI,DI,DS,ES,BP: integer); interrupt;
  { Interrupt handler for the critical error interrupt }
begin
   Int24FLAGS := Flags;
   Int24AL := LO(AX);
   regs.AH := $59;
   regs.BX := 0;
   Intr($21,regs);
   Int59AX := regs.AX;
   Int59BH := regs.BH;
   Int59BL := regs.BL;
   Int59CH := regs.CH;
   if (AX and $8000) = 0 then    { Pass the drive name to user error handler }
      DeviceName := chr(lo(AX)+ord('A')) + ':'
   else
      with DeviceHeader(ptr(BP,SI)^) do
         if (Attributes and $8000) = 0 then
            DeviceName := ''   { Bad memory image of FAT - no device name }
         else
            DeviceName := copy(Name,1,pred(pos(' ',Name+' ')));
                          { Get name of character device }
   CurrentCriticalProc := CriticalProc;
   CallUserHandler(RC, LO(DI),DeviceName);

   AX := RC;
end;

procedure DefaultCriticalHandler(var RC : Word;
                                     ErrorCode: word;
                                 var DeviceName: string);
const
   ExtendedErrorDesc: array[1..88] of string[27] =
              { List of generic descriptions of critical errors }
   ('Function number invalid',            'File not found',
    'Path not found',                     'Too many Open Files',
    'Access Denied',                      'Handle Invalid',
    'Memory Ctrl Block Bad',              'Insufficient Memory',
    'Bad Memory Address',                 'Environment Invalid',
    'Format Invalid',                     'Access Code Invalid',
    'Data Invalid',                       'Unknown Unit',
    'Disk Drive Invalid',                 'Remove Directory Failed',
    'Not Same Device',                    'No more Files',
    'Disk is Write Protected',            'Unknown Unit',
    'Drive not Ready',                    'Unknown Command',
    'Data Error (CRC)',                   'Bad Request Struct Length',
    'Seek Error',                         'Unknown Media Type',
    'Sector not Found',                   'Printer out of Paper...',
    'Write Fault',                        'Read Fault',
    'General Failure',                    'File Sharing Violation',
    'Lock Violation',                     'Disk Change Invalid',
    'FCB Unavaliable',                    'Sharing Buffer Exceeded',
    '','','','','','','','','','','','','',{37-49 reserved}
    'Unsupported Net Request',            'Remote not Listening',
    'Duplicate Name on Net',              'Net Name not Found',
    'Network BUSY',                       'Device no longer on Net',
    'NETBIOS Cmd Limit Exceeded',         'Error in Net Adapter',
    'Incorrect Response from Net',        'Unexpected Net Error',
    'Remote Adapter Incompatible',        'Print Queue FULL',
    'Queue not Full',                     'No room for Print File',
    'Network Name Deleted',               'Access Denied',
    'Incorrect Net Device Type',          'Net Name Not Found',
    'Net Name Limit Exceeded',            'NetBIOS Session Exceeded',
    'Temporary Pause',                    'Net Request not Accepted',
    'Print or Disk Redir Paused',         '','','','','','','',{73-79 reserved}
    'File Already Exists',                '',{81 reserved}
    'Cannot Make Directory',              'FAIL ON INT24H CRITICAL',
    'Out of Structures',                  'Already Assigned',
    'Invalid Password',                   'Invalid Parameter',
    'Net Write Fault');
var
   CurrentAttr     : byte;
   I,x             : integer;
   Key             : char;
   SaveCheckBreak,
   OK              : boolean;
   SaveCursorLoc   : word;
   SaveCursorSize  : word;
   SaveScreen      : Pointer;
   SaveTextAttr    : byte;
   W               : WindowPtr;
Label
   GetOut;

Begin
   If (Int59AX > 88) or (Int59AX = 27) then
      Begin
         RC := 3;
         Exit;
      End;
   GetCursorState(SaveCursorLoc,SaveCursorSize); { Save current display }
   SaveTextAttr := TextAttr;
   SaveCheckBreak := CheckBreak;
   CheckBreak := false;
   TextAttr := qq.WindF;
   Ok := SaveWindow(18,9,54,14,True,SaveScreen);
   Push_Window;
   FrameWindow (18,9,54,14,textattr,textattr,' Critical Error Handler! ');
   Window(19,10,53,13);
   GotoXY(1,1);
   TextAttr := qq.menu2;
   Clrscr;
   {
   FastText(' '+Long2Str(Int59AX)+' '+
                Long2Str(Int59BH)+' '+
                Long2Str(Int59BL)+' '+
                Long2Str(Int59CH)+' '
                ,14,20);}

   Case ErrorCode of    { Check for obvious problems }
      0: begin
            FastWrite('Disk in drive '+DeviceName+' is write-protected',10,20,qq.Menu2);
            FastWrite('Remove tab before retrying',11,20,qq.menu2)
         end;

      2: if DeviceName[2] = ':' then { Problem with a drive or device }
            Begin
               FastWrite('Drive '+DeviceName+' not ready',10,20,qq.Menu2);
               FastWrite('Close drive door before retrying',11,20,qq.Menu2);
            end
         else
            FastWrite('Printer '+DeviceName+' not ready',10,20,qq.menu2);

      9: FastWrite('Printer '+DeviceName+' is out of paper',10,20,qq.menu2);

      else       { Handle bizarre errors more generically }
          begin
            if DeviceName[2] = ':' then
               FastWrite('Error with drive '+DeviceName,10,20,qq.menu2)
            else
               FastWrite('Check printer '+DeviceName,10,20,qq.menu2);
         End;
   end;

   FastWriteWindow(ExtendedErrorDesc[Int59AX],3,2,qq.menu2);

   FastWrite('etry, Ignore or Fail ?',13,21,qq.menu2);
   FastWrite('R',13,20,qq.menu);
   FastWrite('I',13,27,qq.menu);
   FastWrite('F',13,37,qq.menu);
   gotoxy(27,4);
   
   {If qq.DoRecalibrate then
      DelayCalibrate;}
      
   Sound (50);
   delay(250);
   for x := 50 downto 30 do
     Begin
        Sound(x);
        delay(15);
     End;
   Delay(300);
   Nosound;
   while KeyPressed do                          { Clear keyboard buffer }
      Key := ReadKey;
   Repeat
      Key := Upcase(ReadKey);
   Until Key in ['R','I','F'];
   Case upcase(Key) of
      'R' : RC := 1;
      'I' : RC := 0;
      'F' : RC := 3;
   End;
   While KeyPressed do                          { Clear keyboard buffer }
      Key := ReadKey;
   RestoreWindow (18,9,54,14,True,SaveScreen);
   Pop_Window;
   RestoreCursorState(SaveCursorLoc,SaveCursorSize);
   TextAttr := SaveTextAttr;
   CheckBreak := SaveCheckBreak;
End;

Procedure ExitHandler;   { Restore the original Int24 handler }
Begin
   ExitProc := ExitSave;
   SetIntVec($24,xOldInt24);
End;


Begin
   ExitSave := ExitProc;
   ExitProc := @ExitHandler;
   CriticalProc := @DefaultCriticalHandler;
   GetIntVec($24,xOldInt24);
   SetIntVec($24,@Int24Handler);
End.
