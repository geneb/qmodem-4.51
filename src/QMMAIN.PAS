Unit QMMAIN;

{$F+}
{$IfDef OVR} {$O+} {$EndIf}

{$I TPDEFINE.INC}

Interface

Uses
     {$IFDEF OVR}
     OvrStart,
     {$ENDIF}

     Int24,

     {$IFDEF OVR}
     OverLay,
     {$ENDIF}

     Qmem,     Stack5,   Initial,  GiveBk,   TpEdit,   TpDate,
     Uinit,    TpCrt,    TpString, TpWindow, Key,      Comm,
     Comm2,    Procs,    Group1,   QDial,    Emuls,    Group02,
     Menus,    Dos,      TpPick,   FKeys,    ExitDOS,  TpHelp,
     FoneStuf,

     {$IfDef QLink}
        QLink2,
     {$EndIf}

     {$IfNDef GG}
     Host,
     {$EndIf}

     Qinit,    TpDos,    TpEntry,  Files,
     Screen,   RunQInst,

     {$IFDEF UseMouse}
        TpMouse,
     {$ENDIF}

     Constant,
     Scripts,  Scripts2, Override, ExecSwap;

Procedure MAIN;


Implementation


   Procedure Do_Input_Output;
   Var
      x  : Integer;
   Begin
      {$IfDef QLink}
      If QLinkMode and (Emulation <> QLINK) then
         DoQLinkEmulation;
      If (Emulation = QLINK) and not QLinkMode then
         Begin
            Emulation := Last_Emulation;
            If not Set_Emulation_ST(EmulToEmulStr(Emulation)) then ;
         End
      Else
      {$EndIf}
      If Scripting Then           { We are in a Script }
         Begin
            {$IFDEF UseMouse}
            If MouseInstalled and MouseCursorOn then
               HideTheMouse;
            {$ENDIF}
            Execute_A_Script;
         End
      Else
         Begin
            If Scripting Then
               Begin
                  {$IFDEF UseMouse}
                  If MouseInstalled and MouseCursorOn then
                     HideTheMouse;
                  {$ENDIF}
                  ClearAllMarks; {Untags All FON entries}
                  Exit;
               End;

            If Force_Exit Then
               Leave := True;

            If CommPressed then
               Begin
                  {$IfDef UseMouse}
                  If MouseInstalled and MouseCursorOn then
                     HideTheMouse;
                  {$EndIf}

                  For x := 1 To 250 Do
                     If CommPressed Then
                        Check_comm_codes;

                  {$IfDef UseMouse}
                  If MouseInstalled and (not MouseCursorOn) then
                     ShowTheMouse;
                  {$EndIf}
               End;

            If Keypressed and not Leave Then
               Begin
                  {$IFDEF UseMouse}
                  If MouseInstalled and MouseCursorOn then
                     HideTheMouse;
                  {$ENDIF}

                  Check_key_codes;

                  {$IFDEF UseMouse}
                  If MouseInstalled and (not MouseCursorOn) then
                     ShowTheMouse;
                  {$ENDIF}
               End;

            If Xon_Xoff Then
               If Queue_Bytes + Buffer_Low1 > recv_buf_size Then
                  Begin
                     Buffer_full := True;
                     Dequeue_buffer;
                  End;

            {$IFDEF UseMouse}
            If MouseInstalled and MousePressed then
               Begin
                  Mtimes := MouseKeyWord;
                  If (MouseKeyWordY+MouseYLo = Real_Last_Row) and
                     ShowSL then
                     Begin
                        Case CurrStatusLine3 of
                           WithToggles :
                              Case MouseKeyWordX+MouseXLo of
                                 1      : StuffQueueKey ($1C00); {Alt-Enter}
                                 3..9   : StuffQueueKey ($2200); {Emulation}
                                 18..28 : StuffQueueKey ($1900); {baud rate}
                                 29..42 : StuffQueueKey ($4700); {Home menu}
                                 44..46 : StuffQueueKey ($1200); {Duplex}
                                 47..48 : StuffQueueKey ($7F00);
                                 48..51 : StuffQueueKey ($0F00);
                                 52..53 : StuffQueueKey ($2C00);
                                 54..55 : StuffQueueKey ($3000);
                                 56..57 : StuffQueueKey ($3200);
                                 58..60 : StuffQueueKey ($7700);
                                 61..63 : StuffQueueKey ($8100);
                                 61..63 : StuffQueueKey ($8100);
                                 64..65 : StuffQueueKey ($1600);
                                 66..68 : StuffQueueKey ($8000);
                              End;
                           WithBBSInfo :
                              Case MouseKeyWordX+MouseXLo of
                                 1      : StuffQueueKey ($1C00); {Alt-Enter}
                              End;
                           WithCommands:
                              Case MouseKeyWordX+MouseXLo of
                                 1      : StuffQueueKey ($1C00); {Alt-Enter}
                              End;
                           End;
                     End
                  Else
                     Begin
                        {Send the character under the mouse cursor}
                        FastRead(1,MouseWhereY,MouseWhereX,MST);
                        Ch := MST[1];
                        If Mtimes = $EF00 then
                           StuffQueueKey(Ord(Ch))
                        Else
                           If Mtimes = $EE00 then
                              StuffString(Ch+^M)
                           Else
                              If Mtimes = $ED00 then
                                 HelpRoutine(0,NIL,54);
                     End;
               End;
            {$ENDIF}

            Home_Status_Msg;

            If Online Then
               Begin
                  If Not Last_Online_State Then
                     Start_Online_Timer;
               End
            Else
               If Last_Online_State Then
                  Stop_Online_Timer;

            Screen_mode_check2;

            GiveBack;
         End;
   End;

   Procedure Setup2;
   Begin
      Which_Screen;
      SetCrtBorder(qq.Border);
      qqMaxScrollHeap := LongInt(qq.MaxScrollLines) * 170; { bytes per line }
      Init;
      GiveInit;
      Reset_Tabstops;
      FON_Filename := SearchName(QMODEM_FON);
      FKEY_Filename := SearchName(QMODEM_KEY);
      Lastmanual := '';
      lm2 := '';
      load_fkeys(FKEY_Filename);
      Load_Prefix;
      Repeat until CurrentTime > Dex;

      Clear_Whole_Screen;

      If qq.UseInt16 then
         UseEnhancedKbd := EnhancedKbdInstalled;

      {$IFDEF UseMouse}
      If MouseInstalled then
         If qq.UseMouse then
            Begin
               EnableEditMouse;
               {EnableMenuMouse;}
               EnableHelpMouse;
               EnablePickMouse;
               EnableEntryMouse;
            End;
      {$ENDIF}

      EditHelpPtr := @HelpRoutine;
      MenuHelpPtr := @HelpRoutine;
      PickHelpPtr := @HelpRoutine;
      EntryHelpPtr := @HelpRoutine;

      {$IFDEF UseMouse}
      If MouseInstalled then
         FullMouseWindow;
      {$ENDIF}

      If Run_Qinstall_Now Then
         Check_Key_Combo(#49);  {Run_Qinstall}

      If not Force_Exit then
         Begin
            Set_Emulation_Up(qq.Emulate_Ch,True);
            New(Phone_Dir);
            Load_Phone_Dir(FON_Filename);
            Show_Ready_Msg;
         End;
   End;


   Procedure Error_Handler; Far;
   Begin
      ExitProc := ExitSave;
      If ErrorAddr = Nil Then Exit;
      Window(1,1,80,25);
      GotoXY(1,25);
      Writeln;
      WriteLn('A critical error has occured');
      WriteLn('Error number ', ExitCode, ' at ', Hex(Seg(ErrorAddr^)),
                                            ':', Hex(Ofs(ErrorAddr^)));
      CloseCom(False, False, False);
      If Capture Then Capture_Toggle('', True);
      If QuickLearn Then Learn('');
      If Logging Then Log_toggle('', True);
      Cursor_Emul := Cursor_Emul And $FE;
      ErrorAddr := Nil;
   End;


Procedure MAIN;
Begin
   EntryKeyPtr   := @ReadKeyNoGreyNoHelp;
   EditKeyPtr    := @ReadKeyNoGreyNoHelp;
   MenuGetKeyPtr := @ReadKeyNoGreyNoHelp;
   PickKeyPtr    := @ReadKeyNoGreyNoHelp;
   HelpKeyPtr    := @ReadKeyNoGreyNoHelp;

   {SetIntVec($24, SaveInt24);}
   Do_Unit_Inits;
   Load_Config;
   Which_Screen;
   Parse_Command_Line;
   IES := InitExecSwap;
   EWS := ExecWithSwap;
   SES := ShutdownExecSwap;
   Set_Emulation_Up (qq.Emulate_Ch,False);
   {$IFDEF OVR}
   OvrClearBuf;
   OvrSetBuf(OvrGetBuf+LongInt(qq.ExtraOvrBuf)*LongInt(1024));
   OvrSetRetry((OvrGetBuf div 3) * 2);
   If qq.EMS_OK then
      Begin
         OvrInitEMS;
         If OvrResult = 0 then
            Begin
               SaveOvrRead := OvrReadBuf;
               OvrReadBuf := MyOvrRead;
               UsingEMS := True;
            End;
      End;
   {$ENDIF}
   ExitSave := ExitProc;
   ExitProc := @Error_Handler;    { Set up the critical error handler }
   MapColors := False;

   Setup2;

   If Not Force_Exit Then
      Begin
         GetDir(0, CurrPath);

         If (qq.Log_Start = 'Y') And (qq.Log_Filename_s <> '') Then
            Begin
               If ExistFile(qq.Log_Filename_s) Then
                  Log_toggle(qq.Log_Filename_s, False)
               Else
                  Log_toggle(qq.Log_Filename_s, True);

               If Logging then
                  If InitStats then
                     Writelnb('Logging to ' + qq.Log_Filename_s);
            End;

         If Auto_Script And (Auto_Script_Name <> '') Then
            Begin
               Writelnb('Starting Script ' + Auto_Script_Name);
               Writelnb(CharStr('Í',ScreenWidth));
               Script_to_Open := '';
               ClearAllMarks; {Untags All FON entries}
               Open_Script(Auto_Script_Name);
            End
         Else
            {$IfNDef GG}
            If AutoHost then
               Begin
                  Writelnb ('/HOST mode invoked');
                  Writelnb(CharStr('Í',ScreenWidth));
                  Check_Key_Combo(#124);  {Start the HOST}
               End
            Else
            {$EndIf}
               Begin
                  Writelnb(^M^J'You are now in TERMINAL mode');
                  Writelnb(CharStr('Í',ScreenWidth));
               End;

         While CommPressed do
            Check_Comm_Codes;

         Set_Colors;
         HelpTopic := 0;

         If Online then
            Begin
               Load_INI;
               Set_Emulation_Up(qq.Emulate_Ch,False);
            End
         Else
            If ExistFile(QMODEM_INI) then
               Begin
                  Assign(INI_File, QMODEM_INI);
                  Erase (INI_File);
                  IO := IOresult;
               End;

         If not Restart_Invoked and not Online then
            If qq.AltDStart Then
               Begin
                  If Not NoMarksFound then
                     MoveToFirstTagged;
                  StuffQueueKey ($2000);
               End
            Else
               ClearAllMarks;

         While Not Leave Do
            Do_Input_Output;

         ChDir(CurrPath);
      End;

   If Force_Exit Then
      If Online then
         Save_INI;

   Remove_Port;

   SetCrtBorder(0);

   {$IFDEF UseMouse}
   If MouseInstalled then
      Begin
         DisableEventHandling;
         HideTheMouse;
      End;
   {$ENDIF}

   Boring;

   If Lo(DosVersion) <= 3 then
      SetCBreak(SaveRealBreak);
End;

End.