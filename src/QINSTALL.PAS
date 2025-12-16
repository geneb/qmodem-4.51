{$M 12000, 80000, 80000}
{$P+,V-}
Program Qinstall;

{High value used 454}

{$I TPDEFINE.INC}

Uses
   {OpEnhKBD,}

   {$IFDEF UseMouse}
   TPMouse,
   {$EndIf}

   Dos,      TPDos,    Initial,  Comm,     Uinit,
   TPString, TpCrt,    Procs,    Screen,   Files,
   TPWindow, TpMenu0,   TpHelp,   Menus,    TpEdit,
   TpEntry,  TpPick,   Override, RunQinst, TpDir,

   {$IfDef Net}
   NCopy,
   {$Endif}

   Constant, Const2, Install0, Install2;


   Procedure GoQinstall;
   Var
      x              : Byte;
      OldExplode,
      OldShadow      : Boolean;
      Save_Last_Row  : Integer;
      Save_SL        : Char;

      Procedure Edit_Protocol_Window(c1, r1 : Byte;
                                     Wide   : Byte;
                                     Var S  : String);
      Begin
         ForceUpper := False;

         OK := Edit_String_Window_Mixed(c1, r1, Wide, 12, S);
         FastWrite(PadCh(S, ' ', 12), r1 - 2, c1 - 7, qq.Qcolor1[SelectColor]);
         ForceUpper := True;
      End;


      Procedure Edit_Select_Char1(c1, r1         : Byte;
                                   Wide           : Byte;
                                   Var S          : Char);
      Var
         Escaped        : Boolean;
         SS             : String[1];
      Begin
         SS[0] := #1;
         SS[1] := S;
         If (SS = ' ') Or (SS = #0) Then SS := '';
         ReadString('', Succ(r1), c1 + 2, Wide, 0,
                    qq.editf,
                    qq.Qcolor1[HiliteColor],
                    Escaped, SS);
         If (SS = #0) Or (SS = '') Then S := ' '
         Else S := SS[1];
         FastWrite(SS, Succ(r1), c1 + 2, qq.Qcolor1[SelectColor]);
      End;

      Procedure Edit_Select_Char_P(c1, r1         : Byte;
                                    Wide           : Byte;
                                    Var S          : Char);
      Begin
         Repeat
            Edit_Select_Char1(c1, r1, Wide, S);
         Until S in ['Y', 'N'];
      End;


      Procedure Edit_Select_Char(c1, r1         : Byte;
                                    Wide           : Byte;
                                    Var S          : Char);
      Begin
         Edit_Select_Char1(c1, r1, Wide, S);
      End;


      Procedure Edit_String_Window_Path(c1, r1         : Byte;
                                        Wide           : Byte;
                                        Var S          : String);
      Var
         Escaped : Boolean;
      Label Cont;
      Begin
         Repeat
            EditSize := 30;
            ReadString('', Succ(r1), c1 + 2, Wide, 0,
                       qq.editf,
                       {qq.Qcolor1[SelectColor],}
                       qq.Qcolor1[HiliteColor],
                       Escaped, S);
            If S = '' Then
               Goto Cont;
            S := AddBackSlash(S);
            S := CompleteFileName(FullPathName(S));
            If not CreatePath(S) Then
               WritelnT ('Cannot Create the Directory(s).  Try again.');
         Until CreatePath(S);
         Cont:
         FastWrite(PadCh(Slength(S, EditSize), '°', EditSize), Succ(r1),
                   c1 + 2, qq.Qcolor1[SelectColor]);
      End;


      Procedure Edit_Real_Window(c1, r1         : Byte;
                                 Wide           : Byte;
                                 DecPlaces      : Byte;
                                 NLo, NHi       : Real;
                                 Var R          : Real);
      Var
         Escaped        : Boolean;
         S              : String;
      Begin
         ClearFirstChar := True;
         ReadReal('', Succ(r1), c1 + 2, Wide,
                   0,
                   qq.editf,
                   {qq.Qcolor1[SelectColor],}
                   DecPlaces,
                   NLo, NHi,
                   Escaped, R);
         ClearFirstChar := False;
         Str(R:1:1, S);
         FastWrite(PadCh(S, ' ', Wide), Succ(r1), c1 + 2, qq.Qcolor1[SelectColor]);
      End;


      Procedure save_memory_model(XLow, XHigh : Integer);
      Var
         F      : File Of Byte;
         b1, b2 : Byte;
         ss     : String;
      Begin
         ss := SearchName(QMODEM_EXE);
         If not ExistFile(ss) then
            Begin
               SetWindow2(5,5,75,10, ' Error ', False);
               Writeln (' The '+QMODEM_EXE+' file was not found in via the SET environment');
               Writeln (' variable or in the PATH.  This must be available to save the memory');
               Writeln (' configuration.  No changes have been saved.');
               Keycontinue(qq.menu2);
               Restore_Screen;
            End
         Else
            Begin
               Assign(F, SS);
               Reset(F);
               IO := IoResult;
               Seek(F, $A);
               XLow := Min(XLow, XHigh);
               IO := IoResult;
               b1 := ((XLow + 68) Mod 4) * 64;
               b2 := (XLow + 68) Div 4;
               Write(F, b1);
               Write(F, b2);
               b1 := ((XHigh + 68) Mod 4) * 64;
               b2 := (XHigh + 68) Div 4;
               Write(F, b1);
               Write(F, b2);
               Close(F);
               IO := IoResult;
            End;
      End;


      Procedure CTones;
      Begin
         Sound(qq.CTone1);
         Delay(100);
         NoSound;
         Sound(qq.CTone2);
         Delay(100);
         NoSound;
         Sound(qq.CTone3);
         Delay(100);
         NoSound;
      End;

      Procedure UTones;
      Begin
         Sound(qq.UTone);
         Delay(100);
         NoSound;
      End;

      Procedure DTones;
      Begin
         Sound(qq.Dtone);
         Delay(100);
         NoSound;
      End;

      Procedure Edit_Base(Var Base : Word; Row : Byte);
      Var
         tmpstr         : Str4;
      Begin
         tmpstr := HexW(Base);
         Repeat
            OK := Edit_String_Window_UC(25, Pred(Row), 4, 4, tmpstr);
         Until Str2Word('$' + tmpstr, Base);
      End;

      Procedure Edit_IRQ(Var IRQ : Byte; Row : Byte);
      Var
         tmpstr : Str4;
         Ok     : Boolean;
         x      : Integer;
      Begin
         tmpstr := Hex1(IRQ);
         Repeat
            OK := Edit_String_Window_UC(25, Pred(Row), 1, 1, tmpstr);
         Until Str2Int('$' + tmpstr, x);
         IRQ := x;
      End;


      Procedure Compute_Total_Xfers;
      Var
         x, y : Integer;
      Begin
         x := 1;
         While (qq.Xfer_select_chr[x] <> ' ') And (x < 11) Do
            Inc(x);
         {move up any filled in entries and clear the lower ones}
         y := x;
         While (y < 10) Do
            Begin
               If qq.Xfer_Select_Chr[y] = ' ' then
                  Begin
                     Move(qq.Xfer_Select_Chr[y+1], qq.Xfer_Select_Chr[y],
                          SizeOf(qq.Xfer_Select_Chr[1])*(10-y));
                     Move(qq.Xfer_Label[y+1], qq.Xfer_Label[y],
                          SizeOf(qq.Xfer_Label[1])*(10-y));
                     Move(qq.Xfer_Send_Bat[y+1], qq.Xfer_Send_Bat[y],
                          SizeOf(qq.Xfer_Send_Bat[1])*(10-y));
                                               Move(qq.Xfer_Receive_Bat[y+1], qq.Xfer_Receive_Bat[y],
                          SizeOf(qq.Xfer_Receive_Bat[1])*(10-y));
                     Move(qq.Xfer_File_Prompt[y+1], qq.Xfer_File_Prompt[y],
                          SizeOf(qq.Xfer_File_Prompt[1])*(10-y));

                     FillChar(qq.Xfer_Select_Chr[10],   SizeOf(qq.Xfer_Select_Chr[10]), ' ');
                     FillChar(qq.Xfer_Label[10],         SizeOf(qq.Xfer_Label[10]), #0);
                     FillChar(qq.Xfer_Send_Bat[10],    SizeOf(qq.Xfer_Send_Bat[10]), #0);
                     FillChar(qq.Xfer_Receive_Bat[10], SizeOf(qq.Xfer_Receive_Bat[10]), #0);
                     qq.Xfer_File_Prompt[10] := 'N';

                  End;
               Inc(y);
            End;
         x := 1;
         While (qq.Xfer_select_chr[x] <> ' ') And (x < 11) Do
            Inc(x);
         qq.Total_Xfers := Pred(x);
         While x < 11 Do
            Begin
               qq.Xfer_select_chr[x] := ' ';
               Inc(x);
            End;
      End;


      Procedure EditCharTag(Var Ch : Char; col, row : Integer);
      Var
         x : Integer;
      Begin
         x := Ord(Ch);
         Edit_CharScroll_Window(Col, Row, x);
         Ch := Chr(x);
         FastWrite(CharScrollStr(x), Row, Col, qq.Qcolor1[SelectColor]);
      End;


      Procedure SwapToggleCht(Var Tog : Boolean;
                              Var Ch  : Char);
      Begin
         Tog := Not Tog;
         If Tog then Ch := 'Y' else Ch := 'N';
      End;

      Procedure SwapToggleCh(Var Ch  : Char);
      Begin
         If Ch = 'N' then Ch := 'Y' else Ch := 'N';
      End;


      Procedure Do_Main_Menu;
      Var
         CH             : Char;
         x, y           : Integer;
         tmpstr         : Str4;
         sss            : String;
         Ok             : Boolean;
         x1             : LongInt;
         Key            : LongInt;
         wx,wy : Word;
      Begin
         ForceUpper := True;      { make ALL text upper case }
         Repeat
            Key := MenuChoice(Qinstall_Menu, Ch);
            Case Integer(Key) Of

               {Alt-N/C}
               221 : Set_Blue_Shades;
               222 : Set_Purple_Shades;
               223 : Set_Red_Shades;
               224 : Set_Mono_Shades;
               225 : Set_LCD_Shades;

               {Alt-N/V/C}
               82  : Pick_and_Set_Colors;

               412 : Select_Emulation;


               { Communication parameters }
               228 : Select_Baud_Rate;
               229 : Select_DataBits;
               230 : Select_Parity;
               231 : Select_StopBits;
               232 : OK := Edit_String_Window_Mixed(43, 09, 14, 14, qq.baud_chng_before);
               233 : OK := Edit_String_Window_Mixed(43, 10, 14, 14, qq.baud_chng_after);
               234 : Edit_Integer_Window(43, 11, 3, 0, 999, qq.Delay_Amount);
               235 : Edit_Integer_Window(43, 12, 3, 0, 999, qq.Redial_Delay);
               236 : Edit_Integer_Window(43, 13, 3, 0, 999, qq.Dial_Pacing);
               454 : Edit_Integer_Window(43, 15, 4, 0, 9999, qq.SendPace);
               237 : Select_Com_Port;

               { Modem Commands }
               239 : OK := Edit_String_Window_Mixed(36, 6, 64, 24, qq.ModmInit);
               240 : OK := Edit_String_Window_Mixed(36, 7, 14, 14, qq.Dial_Prefix);
               241 : OK := Edit_String_Window_Mixed(36, 8, 14, 14, qq.Dial_Postfix);
               242 : OK := Edit_String_Window_Mixed(36, 9, 14, 14, qq.connect);
               243 : OK := Edit_String_Window_Mixed(36, 10, 14, 14, qq.noconnect);
               244 : OK := Edit_String_Window_Mixed(36, 11, 14, 14, qq.noconnect2);
               245 : OK := Edit_String_Window_Mixed(36, 12, 14, 14, qq.noconnect3);
               246 : OK := Edit_String_Window_Mixed(36, 13, 14, 14, qq.noconnect4);
               247 : OK := Edit_String_Window_Mixed(36, 14, 14, 14, qq.Cancel_Ch);
               248 : OK := Edit_String_Window_Mixed(36, 15, 22, 22, qq.modem_hangup);
               249 : OK := Edit_String_Window_Mixed(36, 16, 14, 14, qq.Redial_Ring_Msg);

               { Port Addresses }
               251 : Edit_Base(qq.Base[1], 8);
               252 : Edit_Base(qq.Base[2], 9);
               253 : Edit_Base(qq.Base[3], 10);
               254 : Edit_Base(qq.Base[4], 11);
               255 : Edit_Base(qq.Base[5], 12);
               256 : Edit_Base(qq.Base[6], 13);
               257 : Edit_Base(qq.Base[7], 14);
               258 : Edit_Base(qq.Base[8], 15);
               259 : Edit_IRQ(qq.IRQ[1], 16);
               260 : Edit_IRQ(qq.IRQ[2], 17);
               261 : Edit_IRQ(qq.IRQ[3], 18);
               262 : Edit_IRQ(qq.IRQ[4], 19);
               263 : Edit_IRQ(qq.IRQ[5], 20);
               264 : Edit_IRQ(qq.IRQ[6], 21);
               265 : Edit_IRQ(qq.IRQ[7], 22);
               266 : Edit_IRQ(qq.IRQ[8], 23);
               {$IfDef ISI}
               452 : Edit_Base(qq.ISI_Base, 9);
               453 : Edit_IRQ (qq.ISI_Irq, 10);
               {$EndIf}

               {Alt-N/M/Q}
               71 : Pick_and_Set_Modem;


               {Alt-N/D}
               269 : Begin
                        Edit_String_Window_Path(33, 3, 64, qq.Upload_Path_s);
                        Upload_Path := qq.Upload_Path_s;
                     End;
               270 : Begin
                        Edit_String_Window_Path(33, 4, 64, qq.Downld_Path_s);
                        Downld_Path := qq.Downld_Path_s;
                     End;
               271 : Edit_String_Window_Path(33, 5, 64, qq.Script_Path);
               426 : Edit_String_Window_Path(33, 6, 64, qq.SwapDirectory);
               441 : Edit_String_Window_Path(33, 7, 64, qq.BatchUL1);
               442 : Edit_String_Window_Path(33, 8, 64, qq.BatchUL2);
               443 : Edit_String_Window_Path(33, 9, 64, qq.BatchUL3);
               447 : OK:= Edit_String_Window_UC(33,10, 64, 30, qq.AltWPick);

               {Alt-N/H}
               273 : Select_Hostmode;
               274 : Edit_String_Window_Path(34, 4, 64, qq.Host_DLPath);
               275 : Edit_String_Window_Path(34, 5, 64, qq.Host_ULPath);
               276 : Edit_Integer_Window(34, 6, 4, 1, 1440, qq.HostMaxTime);
               277 : Begin
                        OK := Edit_String_Window_UC(34, 7, 8, 8, qq.HostPassword);
                        qq.HostPassword := Trim(qq.HostPassword);
                     End;
               278 : Begin
                        OK := Edit_String_Window_UC(34, 8, 8, 8, qq.HostShutdown);
                        qq.HostShutDown := Trim(qq.HostShutDown);
                     End;
               279 : OK := Edit_String_Window_Mixed(34, 9,40,30, qq.HostInit);
               280 : OK := Edit_String_Window_Mixed(34, 10, 14, 14, qq.Host_Answer);
               281 : OK := Edit_String_Window_Mixed(34, 11, 14, 14, qq.OKMessage);
               282 : OK := Edit_String_Window_Mixed(34, 12, 14, 14, qq.Host_Ring_Msg);
               283 : OK := Edit_String_Window_Mixed(34, 13, 14, 14, qq.HostOffHook);
               284 : Edit_Integer_Window(34, 14, 2, 1, 10, qq.Host_Ring_Count);

               {Alt-N/P}
               287 : Edit_Select_Char(49, 5, 1, qq.Xfer_select_chr[1]);
               288 : Edit_Protocol_Window(49, 6, 12, qq.xfer_label[1]);
               289 : OK := Edit_String_Window_UC(49, 7, 12, 12, qq.xfer_send_bat[1]);
               290 : OK := Edit_String_Window_UC(49, 8, 12, 12, qq.xfer_receive_bat[1]);
               291 : Edit_Select_Char_P(49, 9, 1, qq.Xfer_File_Prompt[1]);

               293..
               297 : If qq.Xfer_select_chr[1] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              293 : Edit_Select_Char(49, 6, 1, qq.Xfer_select_chr[2]);
                              294 : Edit_Protocol_Window(49, 7, 12, qq.xfer_label[2]);
                              295 : OK := Edit_String_Window_UC(49, 8, 12, 12, qq.xfer_send_bat[2]);
                              296 : OK := Edit_String_Window_UC(49, 9, 12, 12, qq.xfer_receive_bat[2]);
                              297 : Edit_Select_Char_P(49, 10, 1, qq.Xfer_File_Prompt[2]);
                           End;
                        End;

               299..
               303 : If qq.Xfer_select_chr[2] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              299 : Edit_Select_Char(49, 7, 1, qq.Xfer_select_chr[3]);
                              300 : Edit_Protocol_Window(49, 8, 12, qq.xfer_label[3]);
                              301 : OK := Edit_String_Window_UC(49, 9, 12, 12, qq.xfer_send_bat[3]);
                              302 : OK := Edit_String_Window_UC(49, 10, 12, 12, qq.xfer_receive_bat[3]);
                              303 : Edit_Select_Char_P(49, 11, 1, qq.Xfer_File_Prompt[3]);
                           End;
                        End;

               305..
               309 : If qq.Xfer_select_chr[3] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              305 : Edit_Select_Char(49, 8, 1, qq.Xfer_select_chr[4]);
                              306 : Edit_Protocol_Window(49, 9, 12, qq.xfer_label[4]);
                              307 : OK := Edit_String_Window_UC(49, 10, 12, 12, qq.xfer_send_bat[4]);
                              308 : OK := Edit_String_Window_UC(49, 11, 12, 12, qq.xfer_receive_bat[4]);
                              309 : Edit_Select_Char_P(49, 12, 1, qq.Xfer_File_Prompt[4]);
                           End;
                        End;

               311..
               315 : If qq.Xfer_select_chr[4] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              311 : Edit_Select_Char(49, 9, 1, qq.Xfer_select_chr[5]);
                              312 : Edit_Protocol_Window(49, 10, 12, qq.xfer_label[5]);
                              313 : OK := Edit_String_Window_UC(49, 11, 12, 12, qq.xfer_send_bat[5]);
                              314 : OK := Edit_String_Window_UC(49, 12, 12, 12, qq.xfer_receive_bat[5]);
                              315 : Edit_Select_Char_P(49, 13, 1, qq.Xfer_File_Prompt[5]);
                           End;
                        End;

               317..
               321 : If qq.Xfer_select_chr[5] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              317 : Edit_Select_Char(49, 10, 1, qq.Xfer_select_chr[6]);
                              318 : Edit_Protocol_Window(49, 11, 12, qq.xfer_label[6]);
                              319 : OK := Edit_String_Window_UC(49, 12, 12, 12, qq.xfer_send_bat[6]);
                              320 : OK := Edit_String_Window_UC(49, 13, 12, 12, qq.xfer_receive_bat[6]);
                              321 : Edit_Select_Char_P(49, 14, 1, qq.Xfer_File_Prompt[6]);
                           End;
                        End;

               323..
               327 : If qq.Xfer_select_chr[6] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              323 : Edit_Select_Char(49, 11, 1, qq.Xfer_select_chr[7]);
                              324 : Edit_Protocol_Window(49, 12, 12, qq.xfer_label[7]);
                              325 : OK := Edit_String_Window_UC(49, 13, 12, 12, qq.xfer_send_bat[7]);
                              326 : OK := Edit_String_Window_UC(49, 14, 12, 12, qq.xfer_receive_bat[7]);
                              327 : Edit_Select_Char_P(49, 15, 1, qq.Xfer_File_Prompt[7]);
                           End;
                        End;

               329..
               333 : If qq.Xfer_select_chr[7] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              329 : Edit_Select_Char(49, 12, 1, qq.Xfer_select_chr[8]);
                              330 : Edit_Protocol_Window(49, 13, 12, qq.xfer_label[8]);
                              331 : OK := Edit_String_Window_UC(49, 14, 12, 12, qq.xfer_send_bat[8]);
                              332 : OK := Edit_String_Window_UC(49, 15, 12, 12, qq.xfer_receive_bat[8]);
                              333 : Edit_Select_Char_P(49, 16, 1, qq.Xfer_File_Prompt[8]);
                           End;
                        End;

               335..
               339 : If qq.Xfer_select_chr[8] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              335 : Edit_Select_Char(49, 13, 1, qq.Xfer_select_chr[9]);
                              336 : Edit_Protocol_Window(49, 14, 12, qq.xfer_label[9]);
                              337 : OK := Edit_String_Window_UC(49, 15, 12, 12, qq.xfer_send_bat[9]);
                              338 : OK := Edit_String_Window_UC(49, 16, 12, 12, qq.xfer_receive_bat[9]);
                              339 : Edit_Select_Char_P(49, 17, 1, qq.Xfer_File_Prompt[9]);
                           End;
                        End;

               341..
               345 : If qq.Xfer_select_chr[9] <> ' ' Then
                        Begin
                           Case Integer(Key) Of
                              341 : Edit_Select_Char(49, 14, 1, qq.Xfer_select_chr[10]);
                              342 : Edit_Protocol_Window(49, 15, 12, qq.xfer_label[10]);
                              343 : OK := Edit_String_Window_UC(49, 16, 12, 12, qq.xfer_send_bat[10]);
                              344 : OK := Edit_String_Window_UC(49, 17, 12, 12, qq.xfer_receive_bat[10]);
                              345 : Edit_Select_Char_P(49, 18, 1, qq.Xfer_File_Prompt[10]);
                           End;
                        End;

                {Alt-N/P/A}
               356 : EditCharTag(Char(qq.ASCII_Pace_Ch), 71,19);
               355 : Edit_Integer_Window(69, 17, 3, 0, 255, qq.ASCII_Pace_Speed);
               348 : Begin
                        qq.ASCII_In_Xlate := Not qq.ASCII_In_Xlate;
                        If qq.ASCII_In_Xlate Then FastWrite(sON,14, 70, qq.Qcolor1[SelectColor])
                                             Else FastWrite(sOff,14, 70, qq.Qcolor1[SelectColor]);
                     End;
               352 : Begin
                        qq.ASCII_Out_Xlate := Not qq.ASCII_Out_Xlate;
                        If qq.ASCII_Out_Xlate Then FastWrite(sON,15, 71, qq.Qcolor1[SelectColor])
                                              Else FastWrite(sOff,15, 71, qq.Qcolor1[SelectColor]);
                     End;
               353 : Begin
                        x := GetCRSelection(66,17);
                        If x > 0 then
                           qq.ASCII_Out_CR := Pred(x);
                        Case qq.ASCII_Out_CR of
                           0 : sss := 'NONE  ';
                           1 : sss := 'STRIP ';
                           2 : sss := 'ADD LF';
                        End;
                        FastWrite(sss,16, 71, qq.Qcolor1[SelectColor]);
                     End;
              354  : Begin
                        x := GetLFSelection(66,18);
                        If x > 0 then
                           qq.ASCII_Out_LF := Pred(x);
                        Case qq.ASCII_Out_LF of
                           0 : sss := 'NONE  ';
                           1 : sss := 'STRIP ';
                           2 : sss := 'ADD CR';
                        End;
                        FastWrite(sss,17, 71, qq.Qcolor1[SelectColor]);
                     End;
               349 : Begin
                        x := GetCRSelection(66,16);
                        If x > 0 then
                           qq.ASCII_In_CR := Pred(x);
                        Case qq.ASCII_In_CR of
                           0 : sss := 'NONE  ';
                           1 : sss := 'STRIP ';
                           2 : sss := 'ADD LF';
                        End;
                        FastWrite(sss,15, 70, qq.Qcolor1[SelectColor]);
                     End;
               350 : Begin
                        x := GetLFSelection(66,17);
                        If x > 0 then
                           qq.ASCII_In_LF := Pred(x);
                        Case qq.ASCII_In_LF of
                           0 : sss := 'NONE  ';
                           1 : sss := 'STRIP ';
                           2 : sss := 'ADD CR';
                        End;
                        FastWrite(sss,16, 70, qq.Qcolor1[SelectColor]);
                     End;
               357 : Begin
                        qq.ASCII_Out_Expand := Not qq.ASCII_Out_Expand;
                        If qq.ASCII_Out_Expand Then FastWrite(sON,20, 71, qq.Qcolor1[SelectColor])
                                               Else FastWrite(sOff,20, 71, qq.Qcolor1[SelectColor]);
                     End;
               358 : Begin
                        x := qq.ASCII_EOL_Ch;
                        Edit_Integer_Window(69, 20, 3, 0, 255, x);
                        qq.ASCII_EOL_Ch := x;
                     End;

               434 : qq.OverWrite     := Not qq.OverWrite;
               435 : qq.AutoIncrement := Not qq.AutoIncrement;
               436 : qq.SavePartial   := Not qq.SavePartial;
               438 : qq.BEWClear      := Not qq.BEWClear;



               {Alt-N/F}
               360 : OK := Edit_String_Window_UC(43,3, 64, 30, qq.Help_Path);
               361 : Begin
                        OK := Edit_String_Window_UC(43,4, 64, 30, qq.ScrndumpF_s);
                        ScrnDumpF := qq.Scrndumpf_s;
                     End;
               362 : Begin
                        OK := Edit_String_Window_UC(43,5, 64, 30, qq.CaptureF_s);
                        CaptureF := qq.CaptureF_s;
                     End;
               363 : Begin
                        OK := Edit_String_Window_UC(43,6 , 64, 30, qq.Log_Filename_s);
                        Log_FileN := qq.Log_Filename_s;
                     End;
               364 : Begin
                        OK := Edit_String_Window_UC(43, 7, 64, 30, qq.Scroll_Sav_s);
                        Scroll_Sav := qq.Scroll_Sav_s;
                     End;
               365 : OK := Edit_String_Window_UC(43, 8, 64, 30, qq.Browse_PGM);
               446 : OK := Edit_String_Window_UC(43, 9, 64, 30, qq.PrinterID);
               451 : qq.TimeDateStamp := not qq.TimeDateStamp;


               {Alt-N/O/M/O}
               395 : Begin
                        x := qq.MaxScrollLines;
                        Edit_Integer_Window(72, 7, 4, 0, 1000, x);
                        qq.MaxScrollLines := x;
                     End;
               398 : Begin
                        x := qq.MaxBuf;
                        Edit_Integer_Window(72, 8, 3, 8, 240, x);
                        qq.MaxBuf := (x Div 8) * 8;
                     End;
               399 : Begin
                        x := qq.ExtraOvrBuf;
                        Edit_Integer_Window(72, 9, 3, 0, 200, x);
                        qq.ExtraOvrBuf := x;
                     End;

               {Alt-N/O/S/T}
               402 : Begin
                        Edit_Integer_Window(67,10, 4, 0, 9999, qq.CTone1);
                        CTones;
                     End;
               403 : Begin
                        Edit_Integer_Window(67, 11, 4, 0, 9999, qq.CTone2);
                        CTones;
                     End;
               404 : Begin
                        Edit_Integer_Window(67, 12, 4, 0, 9999, qq.CTone3);
                        CTones;
                     End;
               439 : Begin
                        Edit_Integer_Window(67, 13, 3, 0, 999, qq.ConnectCycles);
                     End;
               405 : Begin
                        Edit_Integer_Window(72, 9, 4, 0, 9999, qq.UTone);
                        UTones;
                     End;
               406 : Begin
                        Edit_Integer_Window(72,10, 4, 0, 9999, qq.Dtone);
                        DTones;
                     End;

               {Alt-N/O/D}
               408 : Begin
                        x := qq.Status_Delay;
                        Edit_Integer_Window(71, 9, 3, 0, 999, x);
                        qq.Status_Delay := x;
                     End;
               409 : Begin
                        Edit_Integer_Window(71,10, 3, 0, 999, qq.Download_Time);
                     End;
               410 : Begin
                        Edit_Integer_Window(71,11, 4, 0, 2000, qq.BREAKdelay);
                     End;
               411 : Begin
                        Edit_Integer_Window(71,12, 4, 0, 2000, qq.DTRdelay);
                     End;


               {Alt-N/O/T}
               368 : SwapToggleCht(Xon_Xoff, qq.Xon_Xoffc);
               369 : Begin
                        qq.DirectVideo := Not qq.DirectVideo;
                        DirectVideo := qq.DirectVideo;
                     End;
               371 : SwapToggleCht(noise, qq.Noisec);
               372 : SwapToggleCht(addlf, qq.addlfc);
               373 : SwapToggleCht(Music_flag, qq.musicc);
               374 : SwapToggleCh(qq.CTSc);
               375 : qq.NoCTSDrop := not qq.NoCTSDrop;
               376 : qq.LockDTE := not qq.LockDTE;
               377 : SwapToggleCh(qq.BS_DEL_Swap);
               378 : SwapToggleCh(qq.Log_Start);
               379 : SwapToggleCht(CheckSnow, qq.CheckSnowx);
               380 : qq.Grow_Window := not qq.Grow_Window;
               381 : qq.ShowStatusLine := not qq.ShowStatusLine;
               382 : SwapToggleCh(qq.FIFOshell);
               383 : SwapToggleCh(qq.KeypadEmuls);
               384 : qq.Destruct_BS := not qq.Destruct_BS;
               385 : Begin
                        qq.LineWrap := not qq.LineWrap;
                     End;
               386 : qq.ENQ := not qq.ENQ;
               440 : qq.ClearFTags := Not qq.ClearFTags;
               448 : qq.E0Doorway := Not qq.E0Doorway;
               455 : qq.StrictColor := not qq.StrictColor;

               {Alt-N/O/R}
	       388 : qq.EMS_Ok := not qq.EMS_OK;
               389 : qq.AutoZ := not qq.AutoZ;
	       390 : Begin
			qq.UseInt16 := not qq.UseInt16;
                       { If qq.UseInt16 then
                           UseEnhancedKbd := EnhancedKbdInstalled
                        Else
                           UseEnhancedKbd := False;
                       }
                     End;
               391 : qq.UseHighSpeed := not qq.UseHighSpeed;
               392 : Begin
                        qq.Use16550 := not qq.Use16550;
                        Init_la_Port;
                     End;
               393 : qq.VideoRestore := not qq.VideoRestore;
               {$IFDEF UseMouse}
               424 : Begin
			qq.UseMouse := not qq.UseMouse;
                        If qq.UseMouse then
                           Begin
                              EnableEditMouse;
                              EnableMenuMouse;
                              EnableHelpMouse;
                              EnablePickMouse;
                              EnableEntryMouse;
                              ShowMouse;
                           End
                        Else
                           Begin
                              DisableEditMouse;
                              DisableMenuMouse;
                              DisableHelpMouse;
                              DisablePickMouse;
                              DisableEntryMouse;
                              HideMouse;
                           End
                     End;
               {$ENDIF}

               427 : Begin
                        qq.Share_IRQ  := not qq.Share_IRQ;
                        ShareIRQ      := qq.Share_IRQ;
                     End;
	       428 : qq.MaxShell      := not qq.MaxShell;
	       445 : qq.MaxDiskShell  := not qq.MaxDiskShell;
	       444 : qq.DoRecalibrate := not qq.DoRecalibrate;
	       429 : qq.GuardHangup   := not qq.GuardHangup;
	       430 : qq.IgnoreCD      := not qq.IgnoreCD;
	       431 : qq.TagAdvance    := not qq.TagAdvance;
	       432 : Begin
                        qq.JumpScroll := not qq.JumpScroll;
                        BiosScroll    := qq.JumpScroll;
                     End;
	       437 : qq.AltDStart     := not qq.AltDStart;
	       450 : qq.WriteFBK      := not qq.WriteFBK;

               {Alt-N/O/C}
               415 : EditCharTag(qq.CharBeeps,74,11);
               416 : EditCharTag(qq.CharANSI,74,12);
               417 : EditCharTag(qq.SLC,74,13);
               418 : EditCharTag(qq.CharTag,74,14);
               419 : EditCharTag(qq.NoteTag,74,15);
               413 : Begin
                        ForceUpper := False;
                        OK := Edit_String_Window_Mixed(67,15,10,10, qq.DateStr);
                        ForceUpper := True;
                     End;
               414 : Begin
                        ForceUpper := False;
                        OK := Edit_String_Window_Mixed(67,16,10,10, qq.TimeStr);
                        ForceUpper := True;
                     End;
               449 : Begin
                        ForceUpper := False;
                        OK := Edit_String_Window_Mixed(67,17,10,10, qq.ElapsedStr);
                        ForceUpper := True;
                     End;

               {Alt-N/E}
               421 : Reload_Config;
               422 : {Save changes};
            End;

            Case Integer(Key) Of
               251..
               266 : Initialize_Comm_Vars;
               82,
               221..
               225 : RedrawMenus(Key);
               67,
               287..
               345 : Begin
                        Compute_Total_Xfers;
                        Case Integer(Key) of
                           287,293,299,305,311,
                           317,323,329,335,341 : RedrawMenus(Key);
                        End;
                     End;
               395..
               399,
               421,
               422 : Begin
                       If ExistFile(SearchName(QMODEM_EXE)) Then
                          Begin
                             If Integer(Key) = 422 then
                                Begin
                                   Save_Config;
                                   Save_Memory_model(64+qq.ExtraOvrBuf, 540);
                                End;
                          End
                       Else
                          Begin
                             SetWindow2(5,5,75,10, ' Error ', False);
                             Writeln (' The '+QMODEM_EXE+' file was not found in via the SET environment');
                             Writeln (' variable or in the PATH.  This must be available to save the memory');
                             Writeln (' configuration.  No changes have been saved.');
                             Keycontinue(qq.menu2);
                             Restore_Screen;
                          End;
                    End;
            End;
         Until ((MenuCmdNum = MKSExit) Or
               ((Ch = ^M) And ((Key = 421) Or (Key = 422))));
         EraseMenu(Qinstall_Menu, False);
         DisposeMenu(Qinstall_Menu);
      End;

   Begin
      SaveCursor(3);
      InitQinsMenu;
      OldExplode := Explode;
      OldShadow := Shadow;
      Shadow := False;
      Explode := False;
      Do_Main_Menu;
      Shadow := OldShadow;
      Explode := qq.Grow_Window;
      RestoreCursor(3);
   End;


   Procedure QinstOpening;
   Var
      TmpPtr : Pointer;
   Begin
      Window(1,1,ScreenWidth,ScreenHeight);
      Clrscr;
      TmpPtr := @QinsLogo;
      If CurrentDisplay in [MonoHerc,MCGA] then
         TmpPtr := @QinsLogM;
      DispPackedWindow(TmpPtr);
      GotoXY(1,2); Delay(5);
      GotoXY(1,24);Delay(5);
      AllowMemoryChange := True;
      HiddenCursor;
      Delay(1500);
      NormalCursor;
   End;

Var
   SaveISI : Boolean;

Begin
   EntryKeyPtr   := @ReadKeyNoGreyNoHelp;
   EditKeyPtr    := @ReadKeyNoGreyNoHelp;
   MenuGetKeyPtr := @ReadKeyNoGreyNoHelp;
   PickKeyPtr    := @ReadKeyNoGreyNoHelp;
   HelpKeyPtr    := @ReadKeyNoGreyNoHelp;

   Run_Qinstall_Now := True;
   Which_Screen;
   Do_Unit_Inits;
   Save_Screen(1,1,80,25);
   AllowMemoryChange := False;
   HiddenCursor;
   ShowOpening       := True;
   NetCopy           := False;
   Administration    := False;
   x                 := ParamCount;
   While x > 0 do
      Begin
        tmp := STUpCase(Paramstr(x));
        If Tmp = 'INQMODEM' then
           ShowOpening := False
        {$IfDef Net}
        Else If Tmp = '/N' then
           NetCopy := True
        Else If Tmp = '/ADMIN' then
           Administration := True
        {$EndIf}
        ;
        dec(x);
      End;

   If ShowOpening
      {$IfDef Net}
      or NetCopy
      or Administration
      {$Endif}
      then
      QinstOpening;

   {$IfDef Net}
   If NetCopy then
      DoNetCopy;
   {$EndIf}

   If ExistFile(SearchName(QMODEM_CNF)) Then
      Load_Config
   Else
      Create_New_CNF;

   {$IfDef ISI}
   If ParamStr(1) <> 'InQmodem' then
      Begin
         Async_init;
         readptr := 0;
         writptr := 0;
         readptr2 := 0;
         writptr2 := 0;
         SaveISI := qq.Use_ISI;
         qq.Use_ISI := True;
         Init_la_Port;
         Remove_Port;
         qq.Use_ISI := SaveISI;
      End
   Else
      If str2word(Paramstr(2), ISI_Port_Count) then;
  {$EndIf}

   SetPickColors;
   SetHelpColors;
   SetVerticalPick;
   TpDir.ShowSizeDateTime := True;
   TpPick.PickSrch := StringPickSrch;

   MenuHelpPtr := @HelpRoutine;
   PickHelpPtr := @HelpRoutine;
   EntryHelpPtr := @HelpRoutine;

   If ParamStr(1) <> 'InQmodem' then
      Part2Screen;

   GoQinstall;
   Restore_Screen;
   If Force_Exit Then
      Halt(1);
   Halt(0);
End.
