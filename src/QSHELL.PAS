{$I  TPDEFINE.INC}

Unit QSHELL;

Interface

Uses
     Qmem,
     Dos,              TpCrt,
     TpDos,
     {$IFDEF OVR}      Overlay, {$ENDIF}
     Initial,
     TpDate,           {$IFDEF UseMouse} TpMouse, {$ENDIF}
     TpWindow,         TpString,
     Files,            Procs,
     FoneStuf,         Constant,   Comm,
     Screen,           Comm2;


Function  Shell(S, S1, S2 : String;
                Clear, KeyCont, Qinst : Boolean) : Integer;

Function  MiniShell(S : String) : Integer;


{} IMPLEMENTATION {}


Procedure ShowExecError(RetCode : Integer);
Begin
  Case RetCode Of
     - 1 : Writelnb('Insufficient memory for Free List');
     - 2 : Writelnb('DOS SetBlock error before EXEC call');
     - 3 : Begin
              Writelnb('A TSR was loaded while executing the DOS Shell and '+_Qmodem_+' cannot recover.');
              Writelnb('A Reboot (Ctrl-Alt-Del) is recommended at this time.');
           End;
     - 4 : Writelnb('Insufficient memory to run DOS command');
       1 : Writelnb('Invalid function');
       2 : Writelnb('File/path not found.  Refer to DOS Path command');
       8 : Writelnb('Insufficient memory to load Command Processor');
      10 : Writelnb('DOS environment error');
      11 : Writelnb('Illegal .EXE file format');
      Else WritelnB('Error trying to find Command Processor')
  End;
  KeyContinue(qq.InfoColor);
End;


Function Shell(S, S1, S2 : String;
               Clear, KeyCont, Qinst : Boolean) : Integer;
Var
   {$IFDEF UseMouse}
   MSP                 : MouseStatePtr;
   {$ENDIF}
   OldSplit            : Boolean;
   ComSpec,
   CommandTail,
   SwapDrv,
   OSplit_String       : String;
   Savedatetime,sdt    : LongInt;
   OldY, OldX, ooutx,
   LastPhone,
   oouty, ReturnCode   : Integer;
   OldCursorEmulation  : Byte;
   Current_Pos_On_Disk : String[64];
   SaveLogging,
   SaveAltDStart       : Boolean;
   ft : text;
const
  SwapLoc : array[Boolean] of String[4] = ('DISK', 'EMS');
Label
  SmallShell;

   Procedure msg2;
   Begin
      If Clear and not QInst Then
         If S2 <> '' Then writeln(S2);
   End;

Begin
  ComSpec := GetEnv('COMSPEC');
  If ComSpec = '' Then
     Begin
        Writelnb('Error trying to find COMSPEC=');
        KeyContinue(qq.InfoColor);
        Exit;
     End;
  Screen_Mode_Check;
  Which_Screen;
  OldY := Last_Row;
  OldX := Last_Col;
  ooutx := Outx;
  oouty := Outy;
  Shadow := False;
  savedatetime := 0;
  sdt := 0;
  SaveLogging := False;
  Save_Screen(1, 1, Last_Col, Real_Last_Row);
  OldSplit := Split;
  If Split then
     OSplit_String := Split_String;

  GetDir(0, Current_Pos_On_Disk);

  OldCursorEmulation := Cursor_Emul;
  Cursor_Emul := Cursor_Emul And $FE;

  If qq.FIFOshell = 'N' then
     TurnOffFIFO;

  Logit('@SHELL ' + S);

  If Clear and not Qinst Then
     Begin
        Window(1, 1, Last_Col, Real_Last_Row);
        TextAttr := GLattr;
        ClrScr;
        If S1 <> '' Then
           writeln(S1);
     End;

  CloseCom(True, True, False);

  {$IfDef Int14}
  If Int14 then
     RemoveInt1C;
  {$EndIf}

  {$IFDEF UseMouse}
  If MouseInstalled then
     Begin
        SaveMouseState(MSP, True);
        DisableEventHandling;
     End;
  {$ENDIF}

  If Logging then
     Begin
        SaveLogging := Logging;   {Save the state of the LOG file}
        Log_Toggle('',False);     {Close the log}
     End;

  SwapDrv := Fullpathname(qq.SwapDirectory + QMODEM_SWP);
  If not qq.MaxDiskShell then
     SwapDrv := '';

  UseEmsIfAvailable := qq.EMS_OK;

  If (not qq.MaxShell) then
     Goto SmallShell;

  If not UseEmsIfAvailable and (SwapDrv <> '') then
     If ExistFile(SwapDrv) then
        Begin
           Writeln('Swapfile already exists.  Using Small Shell.');
           Goto SmallShell;
        End;

  If (not IES(HeapEnd, SwapDrv)) then
     Begin
        If not Qinst then
           WriteLn('Unable to allocate Swap space.');

        SmallShell:

        Msg2;
        SaveAltDStart := qq.AltDStart;
        qq.AltDStart := True;

        LastPhone := CurrentPhone;
        Write_Fon_File;
        Dispose(Phone_Dir);

        ReturnCode := ExecDos(S, True, Nil);

        New(Phone_Dir);
        Load_Phone_Dir(FON_Filename);

        qq.AltDStart := SaveAltDStart;
        CurrentPhone := LastPhone;
     End
  Else
     Begin
        If S = '' then CommandTail := ''        {just call DOS}
                  Else CommandTail := '/C '+S;  {execute a BAT}
        If not Scripting and not Qinst then
           WriteLn('Swapping '+ Long2Str(BytesSwapped)+' bytes to '+ SwapLoc[EmsAllocated]);
        msg2;

        Assign   (ft, FON_Filename);
        Reset    (ft);
        GetFTime (ft, savedatetime);
        Close    (ft);

        If CTS_ then
           Turn_Off_RTS;

        SwapVectors;
        ReturnCode  := EWS(COMSPEC, CommandTail);
        SwapVectors;
        SES;

        If CTS_ then
           Turn_On_RTS;

        Assign   (ft, FON_Filename);
        Reset    (ft);
        GetFTime (ft, sdt);
        Close    (ft);

     End;

  Shell := ReturnCode;
  If ReturnCode <> 0 Then
     ShowExecError(ReturnCode);

  {$IFDEF UseMouse}
  If MouseInstalled then
     Begin
        RestoreMouseState(MSP, True);
        EnableEventHandling;
     End;
  {$ENDIF}

  If SaveLogging then
     Log_Toggle(Log_FileN, False);  {open the LOG again}

  Init_Port;

  {$IfDef Int14}
  If Int14 then
     RestoreInt1C;
  {$EndIf}

  Cursor_Emul := OldCursorEmulation;

  If ReturnCode <> 0 Then
     Logit('++ @SHELL Failed')
  Else
     Begin
        Logit('++ @SHELL Successful');
        If KeyCont Then
           KeyContinue(qq.InfoColor);
     End;

  ChDir(Current_Pos_On_Disk);
  IO := IoResult;
  Which_Screen;
  Restore_Screen;
  If (Last_Col <> OldX) Or (Last_Row <> OldY) Then
     Begin
        Clear_Whole_Screen;
        SetCrtBorder(qq.Border);
        If Split then
           Begin
              SplitScreen;
              SplitScreen;
           End;
        Display_Status('');
        Home_Status_Msg;
        Writelnt('Video mode changed.  Screen not restored.');
     End
  Else
     Begin
        Display_Status('');
        Home_Status_Msg;
        If not Split then
           Set_Full_Window;
     End;

  If sdt <> SaveDateTime then
     Begin
        WritelnT ('FON file changed.  Reloading');
        Load_Phone_Dir(FON_Filename);
     End;

  Shadow := True;
  If OldSPlit then
     Split_String := OSplit_String;
End;




Function MiniShell(S : String) : Integer;
Var
   {$IFDEF UseMouse}
   MSP          : MouseStatePtr;
   {$ENDIF}
   ComSpec,
   CommandTail,
   SwapDrv      : String;
   ReturnCode   : Integer;
   OldCursorEmulation  : Byte;
   Current_Pos_On_Disk : String[64];

Begin
  ComSpec := GetEnv('COMSPEC');
  If ComSpec = '' Then
     Begin
        Writelnb('Error trying to find COMSPEC=');
        KeyContinue(qq.InfoColor);
        Exit;
     End;
  GetDir(0, Current_Pos_On_Disk);
  OldCursorEmulation := Cursor_Emul;
  Cursor_Emul := Cursor_Emul And $FE;
  CloseCom(True, True, False);
  {$IfDef Int14}
  If Int14 then
     RemoveInt1C;
  {$EndIf}

  {$IFDEF UseMouse}
  If MouseInstalled then
     Begin
        SaveMouseState(MSP, True);
        DisableEventHandling;
     End;
  {$ENDIF}

  SwapDrv := fullpathname(QMODEM_SWP);
  UseEmsIfAvailable := true;
  If (not IES(HeapEnd, SwapDrv)) then
     Begin
        ReturnCode := ExecDos(S, True, Nil);
     End
  Else
     Begin

        If CTS_ then
           Turn_Off_RTS;

        If S = '' then CommandTail := ''        {just call DOS}
                  Else CommandTail := '/C '+S;  {execute a BAT}
        SwapVectors;
        ReturnCode  := EWS(COMSPEC, CommandTail);
        SwapVectors;
        SES;

        If CTS_ then
           Turn_On_RTS;
     end;

  MiniShell := ReturnCode;

  If ReturnCode <> 0 Then
     ShowExecError(ReturnCode);

  {$IFDEF UseMouse}
  If MouseInstalled then
     Begin
        RestoreMouseState(MSP, True);
        EnableEventHandling;
     End;
  {$ENDIF}

  Init_Port;
  {$IfDef Int14}
  If Int14 then
     RestoreInt1C;
  {$EndIf}

  Cursor_Emul := OldCursorEmulation;

  ChDir(Current_Pos_On_Disk);
  IO := IoResult;

End;


End.
