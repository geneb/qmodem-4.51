Unit Install0;

Interface

Uses
   Dos,        TpDos,      TpString,  TpCrt,
   TpWindow,   TpMenu,     Initial,
   Comm,       Procs,      Screen,    Files,
   Constant,   RunQInst,   Instal3a,  Instal3b;


Procedure Save_Config;
Procedure Check_For_Snow;
Procedure Create_New_CNF;
Procedure Part2Screen;
Procedure InitQinsMenu;
Procedure RedrawMenus(Mkey : MenuKey);
Function  DisplayFunctLow(x : MenuKey)   : String;
Procedure BuildQinstallMenu;
Function  DisplayFunc(S : String; K : MenuKey) : String;




Implementation

Uses   Install2;


   Procedure BuildQinstallMenu;
   Begin
      BuildPart1;
      BuildPart2;
   End;

   Function DisplayFunctLow(x : MenuKey)   : String;
   Var
      SS, tmps       : String;
      y, z           : Integer;
   Begin
      SS := '';
      Case x Of

             { ASCII Xfer Options }
         356 : SS := CharScrollStr(qq.ASCII_Pace_Ch)+' ';
         355 : SS := Pad(Long2Str(qq.ASCII_Pace_Speed),6);
         348 : If qq.ASCII_In_Xlate   Then SS := sON+'   '
                                      Else SS := sOff+'   ';
         352 : If qq.ASCII_Out_Xlate  Then SS := sON+'   '
                                      Else SS := sOff+'   ';
         349 : Case qq.ASCII_In_CR of
                  0 : SS := 'NONE  ';
                  1 : SS := 'STRIP ';
                  2 : SS := 'ADD LF';
               End;

         353 : Case qq.ASCII_Out_CR of
                  0 : SS := 'NONE  ';
                  1 : SS := 'STRIP ';
                  2 : SS := 'ADD LF';
               End;
         350 : Case qq.ASCII_In_LF of
                  0 : SS := 'NONE  ';
                  1 : SS := 'STRIP ';
                  2 : SS := 'ADD CR';
               End;

         354 : Case qq.ASCII_Out_LF of
                  0 : SS := 'NONE  ';
                  1 : SS := 'STRIP ';
                  2 : SS := 'ADD CR';
               End;

         357 : If qq.ASCII_Out_Expand Then SS := sON+'   '
                                      Else SS := sOff+'   ';

         358 : SS := Pad(Long2Str(qq.ASCII_EOL_Ch),6);


         228 : SS := Pad(Long2Str(qq.ComSpeed), 14);
         229 : SS := Pad(Long2Str(qq.dbits), 14);
         230 : Begin
                  Case qq.Cparity Of
                     'N' : SS := 'None          ';
                     'E' : SS := 'Even          ';
                     'O' : SS := 'Odd           ';
                     'M' : SS := 'Mark          ';
                     'S' : SS := 'Space         ';
                  End;
               End;
         231 : SS := Pad(Long2Str(qq.stop_bits), 14);
         232 : SS := PadCh(qq.baud_chng_before, 'ฐ', 14);
         233 : SS := PadCh(qq.baud_chng_after, 'ฐ', 14);
         234 : SS := Pad(Long2Str(qq.delay_Amount), 14);
         235 : SS := Pad(Long2Str(qq.redial_delay), 14);
         236 : SS := Pad(Long2Str(qq.Dial_Pacing), 14);
         237 : {$IfDef ISI}
               If qq.Use_ISI then
                  SS := Pad('ISI'+Long2Str(qq.CommPort), 14)
               Else
               {$EndIf}
                  SS := Pad('COM'+Long2Str(qq.CommPort), 14);
         454 : SS := Pad(Long2Str(qq.SendPace), 14);

         239 : SS := Slength(PadCh(qq.ModmInit, 'ฐ', 24), 24);
         240 : SS := PadCh(qq.Dial_Prefix,  'ฐ', 14) + CharStr(' ', 10);
         241 : SS := PadCh(qq.Dial_Postfix, 'ฐ', 14) + CharStr(' ', 10);
         242 : SS := PadCh(qq.connect, 'ฐ', 14) + CharStr(' ', 10);
         243 : SS := PadCh(qq.noconnect, 'ฐ', 14) + CharStr(' ', 10);
         244 : SS := PadCh(qq.noconnect2, 'ฐ', 14) + CharStr(' ', 10);
         245 : SS := PadCh(qq.noconnect3, 'ฐ', 14) + CharStr(' ', 10);
         246 : SS := PadCh(qq.noconnect4, 'ฐ', 14) + CharStr(' ', 10);
         247 : SS := PadCh(qq.Cancel_Ch, 'ฐ', 14) + CharStr(' ', 10);
         248 : SS := Slength(PadCh(qq.modem_hangup, 'ฐ', 22), 22)+'  ';
         249 : SS := PadCh(qq.Redial_Ring_Msg, 'ฐ', 14)  + CharStr(' ', 10);


         251 : SS := HexW(qq.Base[1]);
         252 : SS := HexW(qq.Base[2]);
         253 : SS := HexW(qq.Base[3]);
         254 : SS := HexW(qq.Base[4]);
         255 : SS := HexW(qq.Base[5]);
         256 : SS := HexW(qq.Base[6]);
         257 : SS := HexW(qq.Base[7]);
         258 : SS := HexW(qq.Base[8]);
         259 : SS := Hex1(qq.IRQ[1]) + '   ';
         260 : SS := Hex1(qq.IRQ[2]) + '   ';
         261 : SS := Hex1(qq.IRQ[3]) + '   ';
         262 : SS := Hex1(qq.IRQ[4]) + '   ';
         263 : SS := Hex1(qq.IRQ[5]) + '   ';
         264 : SS := Hex1(qq.IRQ[6]) + '   ';
         265 : SS := Hex1(qq.IRQ[7]) + '   ';
         266 : SS := Hex1(qq.IRQ[8]) + '   ';
         {$IfDef ISI}
         452 : SS := HexW(qq.ISI_Base);
         453 : SS := Hex1(qq.ISI_IRQ) + '   ';
         {$EndIf}

         269 : SS := Slength(PadCh(qq.Upload_Path_s, 'ฐ', 30), 30);
         270 : SS := Slength(PadCh(qq.Downld_Path_s, 'ฐ', 30), 30);
         271 : SS := Slength(PadCh(qq.Script_Path,   'ฐ', 30), 30);
         426 : SS := Slength(PadCh(qq.SwapDirectory, 'ฐ', 30), 30);
         441 : SS := Slength(PadCh(qq.BatchUL1,      'ฐ', 30), 30);
         442 : SS := Slength(PadCh(qq.BatchUL2,      'ฐ', 30), 30);
         443 : SS := Slength(PadCh(qq.BatchUL3,      'ฐ', 30), 30);
         447 : SS := Slength(PadCh(qq.AltWPick,      'ฐ', 30), 30);


         273 : Case qq.HostOpen Of
                  0 : SS := 'OPEN' + CharStr(' ', 26);
                  1 : SS := 'CLOSED' + CharStr(' ', 24);
                  2 : SS := 'CALLBACK' + CharStr(' ', 22);
               End;
         274 : SS := Slength(PadCh(qq.Host_DLPath,   'ฐ', 30), 30);
         275 : SS := Slength(PadCh(qq.Host_ULPath,   'ฐ', 30), 30);
         276 : SS := Pad(Long2Str(qq.HostMaxTime), 30);
         277 : SS := PadCh(qq.HostPassword, 'ฐ', 8) + CharStr(' ', 22);
         278 : SS := PadCh(qq.HostShutdown, 'ฐ', 8) + CharStr(' ', 22);
         279 : SS := Slength(PadCh(qq.HostInit,      'ฐ', 30), 30);
         280 : SS := PadCh(qq.Host_Answer,           'ฐ', 14) + CharStr(' ', 16);
         281 : SS := PadCh(qq.OKMessage,             'ฐ', 14) + CharStr(' ', 16);
         282 : SS := PadCh(qq.Host_Ring_Msg,         'ฐ', 14)  + CharStr(' ', 16);
         283 : SS := PadCh(qq.HostOffHook, 'ฐ', 14)  + CharStr(' ', 16);
         284 : SS := Pad(Long2Str(qq.Host_Ring_Count), 30);


         360 : SS := Slength(PadCh(qq.Help_Path, 'ฐ', 30), 30);
         361 : SS := Slength(PadCh(qq.ScrndumpF_s, 'ฐ', 30), 30);
         362 : SS := Slength(PadCh(qq.CaptureF_s, 'ฐ', 30), 30);
         363 : SS := Slength(PadCh(qq.Log_Filename_s, 'ฐ', 30), 30);
         364 : SS := Slength(PadCh(qq.Scroll_Sav_s, 'ฐ', 30), 30);
         365 : SS := Slength(PadCh(qq.Browse_PGM, 'ฐ', 30), 30);
         446 : SS := Slength(PadCh(qq.PrinterID, 'ฐ', 64), 30);
         451 : If qq.TimeDateStamp        Then SS := sON+ CharStr(' ', 27)
                                          Else SS := sOff+ CharStr(' ', 27);



         402 : SS := Pad(Long2Str(qq.CTone1), 4);
         403 : SS := Pad(Long2Str(qq.CTone2), 4);
         404 : SS := Pad(Long2Str(qq.CTone3), 4);
         439 : SS := Pad(Long2Str(qq.ConnectCycles), 4);
         405 : SS := Pad(Long2Str(qq.UTone), 4);
         406 : SS := Pad(Long2Str(qq.Dtone), 4);
         408 : SS := Pad(Long2Str(qq.Status_Delay),3)+' ';
         409 : SS := Pad(Long2Str(qq.Download_Time),3)+' ';
         410 : SS := Pad(Long2Str(qq.BREAKdelay),4);
         411 : SS := Pad(Long2Str(qq.DTRdelay),4);

         {$IfDef GG}
            412 : Case qq.emulate_ch Of
                     'A' : SS := '   TTY';
                     'B' : SS := '  ANSI';
                     'C' : SS := 'AVATAR';
                  End;
         {$Else}
            412 : Case qq.emulate_ch Of
                     'A' : SS :=  '   TTY';
                     'B' : SS :=  '  ANSI';
                     'C' : SS :=  ' VT100';
                     'D' : SS :=  'TVI925';
                     'E' : SS := 'DEBUG_A';
                     'F' : SS := 'DEBUG_H';
                     'G' : SS :=  'AVATAR';
                  End;
         {$EndIf}

         { Set up initial display for TOGGLES }
         368 : If Xon_Xoff                Then SS := sON
                                          Else SS := sOff;
         369 : If Not DirectVideo         Then SS := sON
                                          Else SS := sOff;
         371 : If noise                   Then SS := sON
                                          Else SS := sOff;
         372 : If addlf                   Then SS := sON
                                          Else SS := sOff;
         373 : If Music_flag              Then SS := sON
                                          Else SS := sOff;
         374 : If qq.CTSc = 'Y'           Then SS := sON
                                          Else SS := sOff;
         375 : If qq.NoCTSDrop            Then SS := sON
                                          Else SS := sOff;
         376 : If qq.LockDTE              Then SS := sON
                                          Else SS := sOff;
         377 : If qq.BS_DEL_Swap = 'Y'    Then SS := sON
                                          Else SS := sOff;
         378 : If qq.Log_Start = 'Y'      Then SS := sON
                                          Else SS := sOff;
         379 : If qq.CheckSnowx = 'Y'     Then SS := sON
                                          Else SS := sOff;
         380 : If qq.Grow_Window          Then SS := sON
                                          Else SS := sOff;
         381 : If qq.ShowStatusLine       Then SS := sON
                                          Else SS := sOff;
         382 : If qq.FIFOshell = 'Y'      Then SS := sON
                                          Else SS := sOff;
         383 : If qq.KeypadEmuls = 'Y'    Then SS := sON
                                          Else SS := sOff;
         384 : If qq.Destruct_BS          Then SS := sON
                                          Else SS := sOff;
         385 : If qq.LineWrap             Then SS := sON
                                          Else SS := sOff;
         386 : If qq.ENQ                  Then SS := sON
                                          Else SS := sOff;
         455 : If qq.StrictColor          Then SS := sON
                                          Else SS := sOff;

         {RunTime Setups}
         388 : If qq.EMS_OK               Then SS := sON
                                          Else SS := sOff;
         389 : If qq.AutoZ                Then SS := sON
                                          Else SS := sOff;
         390 : If qq.UseInt16             Then SS := sON
                                          Else SS := sOff;
         391 : If qq.UseHighSpeed         Then SS := sON
                                          Else SS := sOff;
         392 : If qq.Use16550             Then SS := sON
                                          Else SS := sOff;
         393 : If qq.VideoRestore         Then SS := sON
                                          Else SS := sOff;
   {$IFDEF UseMouse}
         424 : If qq.UseMouse             Then SS := sON
                                          Else SS := sOff;
   {$ENDIF}
         427 : If qq.Share_IRQ            Then SS := sON
                                          Else SS := sOff;
         428 : If qq.MaxShell             Then SS := sON
                                          Else SS := sOff;
         445 : If qq.MaxDiskShell         Then SS := sON
                                          Else SS := sOff;
         444 : If qq.DoRecalibrate        Then SS := sON
                                          Else SS := sOff;
	 429 : If qq.GuardHangup          Then SS := sON
                                          Else SS := sOff;
	 430 : If qq.IgnoreCD             Then SS := sON
                                          Else SS := sOff;
	 431 : If qq.TagAdvance           Then SS := sON
                                          Else SS := sOff;
	 432 : If qq.JumpScroll           Then SS := sON
                                          Else SS := sOff;
	 434 : If qq.OverWrite            Then SS := sON
                                          Else SS := sOff;
	 436 : If qq.SavePartial          Then SS := sON
                                          Else SS := sOff;
	 435 : If qq.AutoIncrement        Then SS := sON
                                          Else SS := sOff;
	 437 : If qq.AltDStart            Then SS := sON
                                          Else SS := sOff;
	 450 : If qq.WriteFBK             Then SS := sON
                                          Else SS := sOff;
	 438 : If qq.BEWClear             Then SS := sON
                                          Else SS := sOff;
	 440 : If qq.ClearFTags           Then SS := sON
                                          Else SS := sOff;
	 448 : If qq.E0Doorway            Then SS := sON
                                          Else SS := sOff;

         395 : SS := Pad(Long2Str(qq.MaxScrollLines), 4);
         398 : SS := Pad(Long2Str(qq.MaxBuf), 3) + ' ';
         399 : SS := Pad(Long2Str(qq.ExtraOvrBuf), 3) + ' ';

         { External Protocols }
         67  : If qq.Xfer_select_chr[1] <> ' ' Then
                  SS := Pad(qq.xfer_label[1], 12);
         292 : If qq.Xfer_select_chr[2] <> ' ' Then
                  SS := Pad(qq.xfer_label[2], 12);
         298 : If qq.Xfer_select_chr[3] <> ' ' Then
                  SS := Pad(qq.xfer_label[3], 12);
         304 : If qq.Xfer_select_chr[4] <> ' ' Then
                  SS := Pad(qq.xfer_label[4], 12);
         310 : If qq.Xfer_select_chr[5] <> ' ' Then
                  SS := Pad(qq.xfer_label[5], 12);
         316 : If qq.Xfer_select_chr[6] <> ' ' Then
                  SS := Pad(qq.xfer_label[6], 12);
         322 : If qq.Xfer_select_chr[7] <> ' ' Then
                  SS := Pad(qq.xfer_label[7], 12);
         328 : If qq.Xfer_select_chr[8] <> ' ' Then
                  SS := Pad(qq.xfer_label[8], 12);
         334 : If qq.Xfer_select_chr[9] <> ' ' Then
                  SS := Pad(qq.xfer_label[9], 12);
         340 : If qq.Xfer_select_chr[10] <> ' ' Then
                  SS := Pad(qq.xfer_label[10], 12);

         287 : If qq.Xfer_select_chr[1] In [' ', #0] Then SS := Pad('ฐ',12)
                                                     Else SS := Pad(qq.Xfer_select_chr[1],12);
         288 : SS := PadCh(qq.xfer_label[1], 'ฐ', 12);
         289 : SS := PadCh(qq.xfer_send_bat[1], 'ฐ', 12);
         290 : SS := PadCh(qq.xfer_receive_bat[1], 'ฐ', 12);
         291 : SS := Pad(qq.Xfer_file_prompt[1],12);

         293 : If qq.Xfer_select_chr[2] In [' ', #0] Then SS := Pad('ฐ',12)
                                        Else SS := Pad(qq.Xfer_select_chr[2],12);
         294 : SS := PadCh(qq.xfer_label[2], 'ฐ', 12);
         295 : SS := PadCh(qq.xfer_send_bat[2], 'ฐ', 12);
         296 : SS := PadCh(qq.xfer_receive_bat[2], 'ฐ', 12);
         297 : SS := Pad(qq.Xfer_file_prompt[2],12);

         299 : If qq.Xfer_select_chr[3] In [' ', #0] Then SS := Pad('ฐ',12)
                                        Else SS := Pad(qq.Xfer_select_chr[3],12);
         300 : SS := PadCh(qq.xfer_label[3], 'ฐ', 12);
         301 : SS := PadCh(qq.xfer_send_bat[3], 'ฐ', 12);
         302 : SS := PadCh(qq.xfer_receive_bat[3], 'ฐ', 12);
         303 : SS := Pad(qq.Xfer_file_prompt[3],12);

         305 : If qq.Xfer_select_chr[4] In [' ', #0] Then SS := Pad('ฐ',12)
                                         Else SS := Pad(qq.Xfer_select_chr[4],12);
         306 : SS := PadCh(qq.xfer_label[4], 'ฐ', 12);
         307 : SS := PadCh(qq.xfer_send_bat[4], 'ฐ', 12);
         308 : SS := PadCh(qq.xfer_receive_bat[4], 'ฐ', 12);
         309 : SS := Pad(qq.Xfer_file_prompt[4],12);

         311 : If qq.Xfer_select_chr[5] In [' ', #0] Then SS := Pad('ฐ',12)
                                         Else SS := Pad(qq.Xfer_select_chr[5],12);
         312 : SS := PadCh(qq.xfer_label[5], 'ฐ', 12);
         313 : SS := PadCh(qq.xfer_send_bat[5], 'ฐ', 12);
         314 : SS := PadCh(qq.xfer_receive_bat[5], 'ฐ', 12);
         315 : SS := Pad(qq.Xfer_file_prompt[5],12);

         317 : If qq.Xfer_select_chr[6] In [' ', #0] Then SS := Pad('ฐ',12)
                                         Else SS := Pad(qq.Xfer_select_chr[6],12);
         318 : SS := PadCh(qq.xfer_label[6], 'ฐ', 12);
         319 : SS := PadCh(qq.xfer_send_bat[6], 'ฐ', 12);
         320 : SS := PadCh(qq.xfer_receive_bat[6], 'ฐ', 12);
         321 : SS := Pad(qq.Xfer_file_prompt[6],12);

         323 : If qq.Xfer_select_chr[7] In [' ', #0] Then SS := Pad('ฐ',12)
                                         Else SS := Pad(qq.Xfer_select_chr[7],12);
         324 : SS := PadCh(qq.xfer_label[7], 'ฐ', 12);
         325 : SS := PadCh(qq.xfer_send_bat[7], 'ฐ', 12);
         326 : SS := PadCh(qq.xfer_receive_bat[7], 'ฐ', 12);
         327 : SS := Pad(qq.Xfer_file_prompt[7],12);

         329 : If qq.Xfer_select_chr[8] In [' ', #0] Then SS := Pad('ฐ',12)
                                         Else SS := Pad(qq.Xfer_select_chr[8],12);
         330 : SS := PadCh(qq.xfer_label[8], 'ฐ', 12);
         331 : SS := PadCh(qq.xfer_send_bat[8], 'ฐ', 12);
         332 : SS := PadCh(qq.xfer_receive_bat[8], 'ฐ', 12);
         333 : SS := Pad(qq.Xfer_file_prompt[8],12);

         335 : If qq.Xfer_select_chr[9] In [' ', #0] Then SS := Pad('ฐ',12)
                                         Else SS := Pad(qq.Xfer_select_chr[9],12);
         336 : SS := PadCh(qq.xfer_label[9], 'ฐ', 12);
         337 : SS := PadCh(qq.xfer_send_bat[9], 'ฐ', 12);
         338 : SS := PadCh(qq.xfer_receive_bat[9], 'ฐ', 12);
         339 : SS := Pad(qq.Xfer_file_prompt[9],12);

         341 : If qq.Xfer_select_chr[10] In [' ', #0] Then SS := Pad('ฐ',12)
                                         Else SS := Pad(qq.Xfer_select_chr[10],12);
         342 : SS := PadCh(qq.xfer_label[10], 'ฐ', 12);
         343 : SS := PadCh(qq.xfer_send_bat[10], 'ฐ', 12);
         344 : SS := PadCh(qq.xfer_receive_bat[10], 'ฐ', 12);
         345 : SS := Pad(qq.Xfer_file_prompt[10],12);

         415 : SS := CharScrollStr(Ord(qq.CharBeeps));
         416 : SS := CharScrollStr(Ord(qq.CharANSI));
         417 : SS := CharScrollStr(Ord(qq.SLC));
         418 : SS := CharScrollStr(Ord(qq.CharTag));
         419 : SS := CharScrollStr(Ord(qq.noteTag));
         413 : SS := PadCh(qq.DateStr,    'ฐ', 10);
         414 : SS := PadCh(qq.TimeStr,    'ฐ', 10);
         449 : SS := PadCh(qq.ElapsedStr, 'ฐ', 10);

      End;
      DisplayFunctLow := SS;
   End;


   {$F+}
   Function DisplayFunc(S : String; K : MenuKey) : String;
   {-Customizes the display string for each make menu item}
   Var
      SS             : String;
      x              : MenuKey;
   Begin
      x := K;
      SS := DisplayFunctLow(x);
      If SS = '' Then
         Begin
            DisplayFunc := S;
            Exit;
         End;
      Move(SS[1], S[Length(S) - Length(SS)], Length(SS));
      DisplayFunc := S;
   End;
   {$F-}


   Procedure InitQinsMenu;
   Begin
      Qinstall_Menu := NewMenu([], @DisplayFunc);
      BuildPart1;
      BuildPart2;
      ResetMenu(Qinstall_Menu);
   End;


   Procedure RedrawMenus(Mkey : MenuKey);
   Begin
      DisposeMenu(Qinstall_Menu);
      SetPickColors;
      SetHelpColors;
      InitQinsMenu;
      SelectMenuItem(Qinstall_Menu,Mkey);
   End;

   Procedure Save_Config;
   Var
      P : String;
   Label EExit;

      Procedure ErrorSaveConfig;
      Begin
         Setwindow2(11, 11, 70, 15, ' Error! ',false);
         TextAttr := qq.Menu;
         WriteLn(' Error saving : ', P);
         WriteLn(' Error code   : ', IO);
         KeyContinue(qq.Menu2);
         Restore_Screen;
      End;

   Begin
      FillChar(qq.Filler, SizeOf(qq.Filler), 0); {blank out filler}
      qq.config_version := Config_Version_Const; { Config version }
      P := SearchName(Qmodem_CNF);
      If Pos(';',JustPathName(P)) > 0 then
         P := JustPathName(SearchName(Qmodem_EXE))+QModem_CNF;
      Assign(Config_file, P);
      Rewrite(Config_file);
      IO := IoResult;
      If IO <> 0 Then
         Begin
            ErrorSaveConfig;
            Goto EExit;
         End;
      Write(Config_file, qq);
      IO := IoResult;
      If IO <> 0 Then
         ErrorSaveConfig;
      EExit:
      Close(Config_file);
      IO := IoResult;
   End;



   Procedure Check_For_Snow;
   Var
      x              : Word;
      ColorCh        : Char;
      CH             : Char;
      TempArray      : Array[1..100] Of Byte;
      CGAmemory      : Array[1..100] Of Byte Absolute $B800:0;
   Begin
      TextAttr    := 7;
      DirectVideo := True;
      CheckSnow   := False;
      BiosScroll  := True;
      ClrScr;
      GotoXY (28,1);
      WriteLn(_QMODEMUC_+' INSTALLATION PART 1');
      WriteLn;
      WriteLn('The file '+QMODEM_CNF+' was not found in the current directory or the directory');
      WriteLn('pointed to by the Environment variable "'+_QMODEMUC_+'=",  so it is assumed this is');
      WriteLn('a new installation.   A few questions will be asked to determine how '+_Qmodem_);
      WriteLn('should be setup for you.  Please follow the  directions and  this will only');
      WriteLn('take a few minutes.');
      WriteLn(PadCh('', '_', 79));
      WriteLn;
      { Show which adapter is currently active.}

      Writeln('Display adapter detected : ',CurrentDisplaySt);

      { Check for Snow on the screen if a CGA is detected }

      Case CurrentDisplay Of
         CGA : Begin
                  Flush_KBD;
                  Write('Press any key to test for video snow > ');
                  CharWord := ReadKeyA;
                  For x := 1 To 3000 Do
                     Move(CGAmemory[1], TempArray[1], 100);
                  WriteLn;
                  Write('Did your screen look fuzzy ? [Y/N] ');
                  qq.CheckSnowx := Get_Yes_No;
                  WriteLn;
               End;
         Else
            qq.CheckSnowx := 'N';
      End;

      qq.DirectVideo := True;
      DirectVideo := qq.DirectVideo;

      Case CurrentDisplay Of
         MonoHerc : Begin
                       ColorCh := 'N';
                       Write('Press any key to continue ');
                       ColorCh := ReadKey;
                    End;
         Else       Begin
                       Write('Do you have a Color monitor connected ? [Y/N] ');
                       ColorCh := Get_Yes_No;
                    End;
      End;
      qq.edit1 := $0F;
      qq.edit2 := $70;
      qq.editw := 07;
      qq.Scrollbar := $0F;
      Case ColorCh Of
         'N' : Begin
                  qq.TXTColor := 7;  { white color            }
                  qq.Border := 0;    { border black           }
                  qq.Menu := 15;     { Hi int menu c          }
                  qq.menu2 := 7;     { white menu color       }
                  qq.WindF := 15;    { Window Border color    }
                  qq.InfoColor := 15;     { Status msgs            }
                  qq.Statuslinecolor  := $7F;   { Status Line Foreground }
                  qq.Statuslinecolor2 := $70;
                  qq.editf := $07;
                  qq.Qcolor1[BodyColor]   := 07;
                  qq.Qcolor1[HiliteColor] := $0F;
                  qq.Qcolor1[SelectColor] := $70;
                  qq.Qcolor1[FrameColor]  := $07;
                  qq.Qcolor1[HeaderColor] := $07;
                  qq.Qcolor1[HelpColor] := $7F;
                  qq.HelpColors[1] := $07;
                  qq.HelpColors[2] := $07;
                  qq.HelpColors[3] := $07; {not used}
                  qq.HelpColors[4] := $7f;
                  qq.HelpColors[5] := $70;
                  qq.HelpColors[6] := $0F;
                  qq.HelpColors[7] := $07;
                  qq.HelpColors[8] := $70;
               End;
      Else
         Begin
            qq.TxtColor := $17;      { white on blue     }
            qq.Border := $0;         { border Black      }
            qq.Menu := $3E;          { Yellow on cyan    }
            qq.Menu2 := $31;         { Blue on Cyan      }
            qq.WindF := $38;         { LightGray on Cyan }
            qq.InfoColor := $1E;          { Yellow on Blue    }
            qq.StatusLineColor  := $71;         { Blue on White     }
            qq.StatusLineColor2 := $78;         { Blue on White     }
            qq.Editf := $70;
            qq.Qcolor1[BodyColor]    := $31;   { Blue on cyan      }
            qq.Qcolor1[HiliteColor]  := $3E; { Yellow on cyan    }
            qq.Qcolor1[SelectColor]  := $1F; { White on blue     }
            qq.Qcolor1[FrameColor]   := $03;  { Cyan on black     }
            qq.Qcolor1[HeaderColor]  := $03;  { Cyan on black     }
            qq.Qcolor1[HelpColor] := $71;
            qq.HelpColors[1] := $1f;  {frame}
            qq.HelpColors[2] := $17;  {Normal text}
            qq.HelpColors[3] := $17;  {not used}
            qq.HelpColors[4] := $5F;  {selected target}
            qq.HelpColors[5] := $50;  {unselected target}
            qq.HelpColors[6] := $1E;  {highlight text}
            qq.HelpColors[7] := $07;  {not used}
            qq.HelpColors[8] := $70;  {not used}
         End;
      End;
   End;

   Procedure Create_New_CNF;
   Var
      x : Word;
      f : Text;
   Begin
      FillChar(qq, SizeOf(qq), 0);
      With qq Do
         Begin
            If ExistFile('DIRLIST.QSM') then
               Begin
                  Assign(F, 'DIRLIST.QSM');
                  Reset(F);
                  Readln(F,Upload_Path_S);
                  Readln(F,Downld_Path_S);
                  Readln(F,Script_Path);
                  Close(F);
                  Erase(F);
                  IO := IOResult;
               End;

            ComSpeed       := 2400;                { 2400 baud        }
            Cparity        := 'N';                 { no parity        }
            stop_bits      := 1;                   { 1 stop bit       }
            dbits          := 8;                   { 8 data bits      }
            connect        := 'CONNECT';           { Verbose prompt   }
            noconnect      := 'NO CARRIER';        { Verbose prompt   }
            noconnect2     := 'BUSY';              { Verbose prompt   }
            noconnect3     := 'NO DIAL';           { Verbose prompt   }
            noconnect4     := 'VOICE';             { Verbose prompt   }
            emulate_ch     := 'B';                 { Emulation mode default }
            delay_Amount   := 5;                   { delay between attempts }
            addlfc         := 'N';                 { linefeeds to CR?       }
            musicc         := 'N';                 { ANSI mode default      }
            redial_delay   := 60;                  { delay before retry     }
            Dial_Prefix    := 'ATDT';              { modem dial init        }
            Commport       := 1;                   { comm port to use       }
            ModmInit       := 'ATE1Q0X1V1S7=60^M'; { modem startup command  }
            Capture        := False;               { is capture active?             }
            Dial_Pacing    := 10;                  { Speed to send characters       }
            modem_hangup   := '^~^~^~+++^~^~^~ATH^M'; { modem hang-up command}
            Cancel_Ch      := '^M';                { character to cancel modem dial }
            MaxBuf         := 8;                   { Download Buffer size           }
            Dial_Postfix   := '^M';                { Dial Ending (CR)               }
            CTSc           := 'N';                 { Use CTS signal                 }
            Xon_Xoffc      := 'Y';                 { Use Xon/Xoff protocol          }
            Noisec         := 'Y';                 { Beeps and Bells toggle start   }
            LockDTE        := False;               { Set speed from redial window   }
            ShowStatusLine := True;
            KeypadEmuls    := 'N';     { keypad works as in 3.1a }
            Base[1]        := $3F8;    { Base address for Com1          }
            Base[2]        := $2F8;    { Base address for Com2          }
            IRQ[1]         := 4;       { IRQ for Com1                   }
            IRQ[2]         := 3;       { IRQ for Com2                   }
            Status_Delay   := 200;     { Status Delay in seconds        }
            Host_Ring_Msg  := 'RING';  { When a RING is detected        }
            Redial_Ring_Msg:= 'RING';  { When a RING is detected        }
            FIFOshell      := 'N';     { FIFO buffer in Shell           }
            Download_Time  := 10;      { Additional time delay for xfer's }
            CTone1         := 1200;    { Connect tone 1  }
            CTone2         := 1400;    { Connect tone 2  }
            CTone3         := 1600;    { Connect tone 3  }
            UTone          := 1200;    { Upload Tone     }
            Dtone          := 1200;    { Download Tone   }
            MaxScrollLines := 100;     { 100 lines       }
            Editf          := $70;
            ScrollBar      := 112;
            DateStr        := 'mm-dd-yy';
            TimeStr        := 'hh:mm:ss';
            ElapsedStr     := TimeStr;
            WriteFBK       := True;
            CharBeeps      := #13;
            CharANSI       := #14;
            SLC            := #176;
            CharTag        := #251;
            NoteTag        := #240;
            Grow_Window    := False;
            Explode        := False;
            OKMessage      := 'OK';
            HostInit       := 'ATE1Q0V1M1H0S0=0^M';
            Host_Answer    := 'ATA^M';
            HostOpen       := 0;
            HostMaxTime    := 60;
            HostOffHook    := 'ATM0H1^M';
            ExtraOvrBuf    := 30;
            Help_Path      := QMODEM_HLP;
            HostPassword   := 'PASSWORD';
            HostShutDown   := HostPassword;
            Host_Ring_COunt:= 1;
            ScrnDumpF_s    := 'SCREEN.DMP';
            CaptureF_s     := 'CAPTURE.CAP';
            Log_Filename_s := _QMODEMUC_+'.LOG';
            Scroll_Sav_s   := 'SCROLL.SAV';
            ASCII_Out_Expand := TRUE;
            ASCII_EOL_Ch   := 10;
            BREAKdelay     := 500;
            DTRdelay       := 1000;
            AutoZ          := False;
            EMS_OK         := FALSE;
            UseInt16       := False;
            UseHighSpeed   := False;
            Use16550       := True;
            VideoRestore   := False;
            ENQ            := False;
            LineWrap       := True;
            Destruct_BS    := True;
            Share_IRQ      := False;
            MaxShell       := True;
            MaxDiskShell   := True;
            GuardHangup    := False;
            IgnoreCD       := False;
            TagAdvance     := True;
            BEWClear       := True;
            ConnectCycles  := 5;
            ClearFTags     := True;
            BatchUL1       := '';
            BatchUL2       := '';
            BatchUL3       := '';
            DoRecalibrate  := False;

            For x := 0 To 255 Do
               Begin
                  Xlate_Table_In[x] := x;          { Default Xlate Table }
                  Xlate_Table_Out[x] := x;         { Default Xlate Table }
               End;

            For x := 1 To 10 Do
               Xfer_select_chr[x] := ' ';         { Clean Xfer char }

            Check_For_Snow;

            Save_Config;

         End;
   End;

   Procedure Part2Screen;
   Begin
      Window (1,1,ScreenWidth, ScreenHeight);
      ClrScr;
      GotoXY(29, 4);
      WriteLn(_QMODEMUC_+' INSTALLATION PART 2');
      WriteLn;
      WriteLn('  The window above is the "Alt-N Setup Menu".  With it, you can customize');
      WriteLn('  almost every part of '+_Qmodem_+'.  Go through all of the options now to finish');
      WriteLn('  the installation procedure.  When you are through, select Exit/Save to');
      WriteLn('  write out the new configuration file.');
      WriteLn;
      WriteLn('        Press ENTER to Edit the selected option or open a SubMenu.');
      WriteLn('        Press ESC to abort the changes made or close the SubMenu.');
      WriteLn;
      WriteLn('  ษอออออออออออออออออออป');
      WriteLn('  บ Option A          บ ');
      WriteLn('  บ Option B   ฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤฤ Selections that are followed by the ');
      WriteLn('  บ ษอออออออออออออออออออออป        character have SubMenus below them. ');
      WriteLn('  บ บ Sub Option B1       บ');
      WriteLn('  ศอบ Sub Option B2       บ');
      WriteLn('    บ Sub Menu Below     บ');
      WriteLn('    ศอออออออออออออออออออออผ');
      WriteLn('                          ฺฤ The Status Line will always give you help on');
      WriteLn('                          ณ  the option you are changing.');
      Write  ('                          ');
   End;

End.
