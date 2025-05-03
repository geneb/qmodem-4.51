Unit Qdial2;

Interface

Uses Qmem,     Dos,      TPDos,     TpCrt,   GiveBk,
     Sort,     Initial,  TPString,  Files,   Screen,
     tpcmdlin, TpEdit,   Comm,      Comm2,   Procs,
     Group1,   FoneStuf, Menus,     QDial,   TpDate,
     Printer2, Constant, OpKey,     BINFSE,  ApTimer;


Procedure DIAL(PassedMarks : String);
Function  Get_Modem_Message(Var rc : Char) : String;


Implementation


Type
   SortType       = (NameSort, NumberSort, CallsSort);
Var
   SortMethod     : SortType;
   WO             : Byte;
   TnoteFlag      : Boolean;

   Procedure InpRecs;  Far;
   Var
      x              : Integer;
      P              : Phone_Type;
   Begin
      For x := 1 To Max_Phones Do
         Begin
            P := Phone_dir^[x];
            If SortMethod = CallsSort Then
               If P.Name  = '' Then P.Times_Called := -1;
            If P.Name     = '' Then P.Name := #255;
            If P.Number   = '' Then P.Number := #255
                               Else P.Number := LeftPad(P.Number, 19);
            SortRelease(P);
         End;
   End;


   Function LessRecs(Var x, y : Phone_Type) : Boolean; Far;
   Begin
      Case SortMethod Of
         NameSort   : LessRecs := STupCase(x.Name) < STupCase(y.Name);
         NumberSort : LessRecs := x.Number < y.Number;
         CallsSort  : LessRecs := x.Times_Called < y.Times_Called;
      End;
   End;


   Procedure OutpRecs; Far;
   Var
      x              : Integer;
      P              : Phone_Type;
   Begin
      Case SortMethod Of
         NameSort,
         NumberSort : x := 1;
         CallsSort  : x := Max_Phones;
      End;
      Repeat
         SortReturn(P);
         If SortMethod = CallsSort Then
            If P.Name  = #255 Then
               P.Times_Called := 0;
         If P.Name = #255 Then P.Name := '';
         If P.Number = #255 Then P.Number := ''
                            Else P.Number := Trim(P.Number);
         Phone_dir^[x]  := P;
         Case SortMethod Of
            NameSort,
            NumberSort : Inc(x);
            CallsSort : Dec(x);
         End;
      Until SortEOS;
   End;


   Procedure Show_Prefix_List;
   Var
      pfs : String;
      x   : Integer;
   Begin
      pfs := '';
      For x := 1 To 10 Do
         If Prefix[x] <> '' Then pfs := pfs + Char(64 + x);
      PrtAt2(' Prefixes > ' + pfs + ''+ CharStr(' ', 10 - Length(pfs)), 3, 40, qq.Menu2, qq.menu);
   End;


   Function Get_modem_message(Var rc : Char) : String;
   Var
      x       : Integer;
      CH      : Char;
      ET      : EventTimer;
      Message : String;           {   Possible return codes   }
   Begin                          { C - Connect message match }
      Message := '';              { N - No Carrier message    }
      rc := '?';                  { ? - Status Message        }
      x  := 0;                    { K - KEYPRESS detected     }
      NewTimer(ET, 2);            { R - RING received         }
      Repeat
         If Keypressed Then
            Begin
               rc := 'K';
               Get_modem_message := '';
               Exit;
            End;
         If CommPressed Then
            Begin
               CH := Cinkeyz;
               Case CH Of
                  ^M : If Length(Message) < 1 Then
                          Ch := ' ';
               Else
                  Begin
                     Message := Message + Upcase(CH);
                     NewTimerSecs(ET, 2);
                  End;
               End;               { case }
            End;
         GiveBack;
      Until (CH = ^M) Or
            (CH = ^J) Or
            (Length(Message) > 40) Or
            TimerExpired(ET);

      If (Message = qq.Redial_Ring_Msg) and
         (qq.Redial_Ring_Msg <> '') Then
         Begin
            rc := 'R';
            Get_Modem_Message := Message;
            Exit;
         End;

      If SearchLeftUC(Message, qq.connect) > 0 Then
         Begin
            rc := 'C';
            Set_DCE_Speed(Message);
            SetSpeedMsg(Message);
            If Last_Online_State Then
               Stop_Online_Timer;
            Get_Modem_Message := Message;
            Exit;
         End;

      If (SearchLeftUC(Message, qq.noconnect) > 0)  And
         (qq.noconnect <> '')  Then rc := 'N' Else
      If (SearchLeftUC(Message, qq.noconnect2) > 0) And
         (qq.noconnect2 <> '') Then rc := 'N' Else
      If (SearchLeftUC(Message, qq.noconnect3) > 0) And
         (qq.noconnect3 <> '') Then rc := 'N' Else
      If (SearchLeftUC(Message, qq.noconnect4) > 0) And
         (qq.noconnect4 <> '') Then rc := 'N';

      Get_modem_message := Message;
   End;


   Function LastBlankEntry(x1 : Integer) : Integer;
   Var
      x : Integer;
   Begin
      For x := Max_Phones downto x1+1 do
         If (Phone_Dir^[x].Name = '') and (Phone_Dir^[x].Number = '') then
            Begin
               LastBlankEntry := x;
               Exit;
            End;
      LastBlankEntry := 0;
   End;


   Procedure ClearAnEntry(x, y : Word);
   Begin
      Phone_Dir^[x].Name := '';
      Phone_Dir^[x].Number := '';
      Phone_Dir^[x].Script_file := '';
      Phone_Dir^[x].ComSpeed := NewSpeed;
      Phone_Dir^[x].parity := 'N';
      Phone_Dir^[x].sbits := 1;
      Phone_Dir^[x].dbits := 8;
      Phone_Dir^[x].Default_Protocol := ' ';
      Phone_Dir^[x].Echo1 := 'F';
      Phone_Dir^[x].Times_Called := 0;
      Phone_Dir^[x].last_connect := BadDate;
      Phone_Dir^[x].Password := '';
      Phone_Dir^[x].Marked := False;
      Phone_Dir^[x].LearnTag := False;
      Phone_Dir^[x].HasNote := False;
      Phone_Dir^[x].NoteNum := y;
   End;



   Procedure DIAL;
   Var
      x, x1,
      Num_Good,
      Cycle, rc      : Integer;
      InRedialer,
      ManualMode     : Boolean;
      EndPhone       : String[40];
      Connected      : Boolean;
      Ch1, Ch2       : Char;

      Function NoDialMarksFound : Boolean;
      Var
         x              : Integer;
      Begin
         For x := 1 To Max_Phones Do
            If Phone_dir^[x].Marked and
               (Phone_Dir^[x].Number <> '') Then
               Begin
                  NoDialMarksFound := False;
                  Exit;
               End;
         NoDialMarksFound := True;
      End;

      Procedure TagEntry(Entry:Integer; NoPrefix : Boolean);
      Begin
         If (Entry < 1) or (Entry > Max_Phones) then
            Exit;
         Phone_Dir^[Entry].NoPrefix := NoPrefix;
         Phone_Dir^[Entry].Marked := True;
         If (not ExistFile(FullScriptFilename(Phone_dir^[Entry].Script_file))) and
            (Phone_dir^[Entry].Script_file <> '') then
            Phone_dir^[Entry].LearnTag := Phone_dir^[Entry].Marked;
         Fon_Changed := True;
      End;

      Function InsertBlank : Boolean;
      Var
         x : Integer;
      Begin
         InsertBlank := False;
         x := LastBlankEntry(CurrentPhone);
         If x = 0 then
            Begin
               WritelnT('No Blank Entries below Scrollbar');
               Exit;
            End;
         {otherwise, x points to the Last blank line after the scrollbar}
         {grab the NoteNum from the entry to be deleted}
         y := Phone_Dir^[x].NoteNum;
         Move (Phone_Dir^[CurrentPhone],    {from here}
               Phone_Dir^[CurrentPhone+1],  {to here..}
               (X - CurrentPhone)*SizeOf(Phone_Dir^[1]));
         ClearAnEntry(CurrentPhone, y);
         Fon_Changed := True;
         InsertBlank := True;
      End;

      Procedure Show_Menu;
      Begin
         Window(2, 16+wo, 79, 23+wo);
         ClrScr;
         FastWrite(         'Entries                    Dial                   FON',          16+WO,14,qq.Menu);
         PrtAt2(  '^SP/SP - Tag-P/Tag-Untag        M - Manual Dial        F - Find Text',   17+WO, 5,qq.Menu2, qq.Menu);
         PrtAt2(   'I-Ins - Insert New Entry                              A - Find Again',  18+WO,6,qq.Menu2, qq.Menu);
         PrtAt2('^D/D-Del - Delete Tagged/Bar          Edit               L - Load',        19+WO, 3,qq.Menu2, qq.Menu);
         PrtAt2(    '^R/R - Revise Tagged/Bar      E - Edit Prefixes      O - Other Info',  20+WO, 7,qq.Menu2, qq.Menu);
         PrtAt2(       'T - Tag Multiple           N - Attached Note   ^P/P - Print 132/80',21+WO,10,qq.Menu2, qq.Menu);
         PrtAt2(       'U - Untag All              V - Linked Script      S - Sort',        22+WO,10,qq.Menu2, qq.Menu);
         PrtAt2(       'Q - QuickLearn                                   ^U - Undo',        23+WO,10,qq.Menu2, qq.Menu);
         HiddenCursor;
      End;

      Procedure Show_Page;
      Var
         Out, A         : String;
         pgnum          : String[2];
         x1, Top, x, y,
         bottom         : Integer;

      Begin
         If CurrentPhone > Max_Phones Then Dec(CurrentPhone, Max_Phones);
         If CurrentPhone < 1 Then Inc(CurrentPhone, Max_Phones);
         phone_page := Succ(Pred(CurrentPhone) Div (10 + WO));
         TextAttr := qq.menu2;
         Str(phone_page:2, pgnum);
         FastWrite(CharStr(' ', 49), 2, 16, qq.Menu2);
         FastWrite('Page ' + pgnum + ' of ' + FON_Filename, 2, 3, qq.Menu2);
         y := 0;
         For x := 1 To Max_Phones Do
            If Phone_dir^[x].Marked Then Inc(y);
         PrtAt2('Total Tags > ' + Long2Str(y) + '  ', 3, 3, qq.Menu2, qq.Menu);
         FastWrite('[D]   Name', 4, 2, qq.Menu);
         If Dial_Other_Info Then
            FastWrite('Password        LastCall    Total  P D', 4, 40, qq.Menu)
         Else
            FastWrite(' Number          Port       Script    ', 4, 40, qq.Menu);
         Top := phone_page * (10 + WO) - (9 + WO);
         bottom := phone_page * (10 + WO);
         x1 := 5;
         For x := Top To bottom Do With Phone_dir^[x] Do
            Begin
               Out := Pad(Long2Str(x), 3);
               If HasNote then Out := Out + qq.NoteTag
                          else Out := Out + ' ';
               If LearnTag Then Out := Out + 'Q ' Else
                  If NoPrefix and Marked Then Out := Out + 'P ' Else
                     If Marked Then Out := Out + qq.CharTag + ' ' Else
                        Out := Out + '  ';
               Out := Out + Pad(Name, 27);
               If Dial_Other_Info Then
                  Begin
                     Out := Out + '     ' + Pad(Password, 14) + ' ';
                     Out := Out + ' ' + Pad(DatetoDateString(qq.DateStr,last_connect),10);
                     Out := Out + '  ' +
                     Pad(Long2Str(Times_Called), 5) + '  ' +
                     Default_Protocol + ' ' +
                     Echo1 + '  ';
                  End
               Else
                  Begin
                     Out := Out + ' ' + LeftPad(Number, 19) + ' ';
                     Str(ComSpeed:6, A);
                     Out := Out + A+' ';
                     Str(dbits:1, A); Out := Out + A + Phone_dir^[x].parity;
                     Str(sbits:1, A); Out := Out + A + '  ';
                     If Script_file = '' Then
                        Out := Out + '            '
                     Else
                        Out := Out + Pad(Script_file, 12);
                  End;
               If x = CurrentPhone Then
                  FastWrite(Out, x1, 2, qq.ScrollBar)
               Else
                  If Marked Then
                     FastWrite(Out, x1, 2, qq.Menu)
                  Else
                     FastWrite(Out, x1, 2, qq.Menu2);
               Inc(x1);
            End;
      End;                        {Show_Page}


      Procedure Redialer(StartNum : Integer);
      Var
         Cycle, Cnt, x, y,
         num, BD,
         Sb, Db, Enum   : Integer;
         aborted        : Boolean;
         Message        : String;
         RC             : Char;
         P              : TParity;
         RedialDelayET,
         DelayAmountET  :EventTimer;
      Label
         EExit;

         Procedure Cancel_Call;
         Begin
            Redialing := True;
            If qq.Cancel_Ch = 'BREAK' Then
               Break_Low
            Else
               If qq.Cancel_Ch = 'DTR' Then
                  Drop_DTR_Low
               Else
                  Parse_Write_Modem(qq.Cancel_Ch);
            Redialing := False;
            Delay(250);
         End;


         Procedure Clear_Status;
         Begin
            GotoXY(15, 6);
            Write(Pad(' ', 41));
            GotoXY(15, 6);
         End;

         Procedure Main_Disp_Line;
         Begin
            Display_Status(' C-Cycle   K-Kill   X-Extend Timer   ESC-Exit ');
         End;

         Procedure Status_Message(x : Integer);
         Var
            CH             : Char;
         Begin
            GotoXY(15, 7);
            TextAttr := qq.Menu;
            Case x Of
               1 : Write(Pad('Manual Cycle', 36));
               2 : Write(Pad('Number has been un-tagged', 36));
               4 : Write(Pad('Dial timing period expired', 36));
               5 : Write(Pad('Line busy or modem timed out', 36));
               7 : Write(Pad('CONNECTED, press a key to continue', 36));
               8 : Write(Pad('Redial pausing', 36));
               9 : Write(Pad('Dialing halted. Incoming call detected', 36));
               11 : Write(Pad('    Seconds remain until Cycle', 36));
            End;

            Case x of
               1,2,4,5,7,9 : Delay(250);
            End;

            Case x Of
               8 : Display_Status(' C-Cycle   K-Kill   ESC-Exit ');
               11,
               12 : Main_Disp_Line;
               Else Display_Status('');
            End;
         End;

         Procedure Show_Modem_Message;
         Var
            x : Integer;
         Begin
            If Length(Message) > 2 Then
               Begin
                  Clear_Status;
                  For x := 1 To Min(Length(Message),40) Do
                     If Message[x] <> ^J Then Write(Message[x]);
               End
            Else
               Message := '';
         End;

         Procedure Open_Window;
         Begin
            Window(2, 16 + WO, 79, 23 + WO);
            ClrScr;
            HiddenCursor;
            FastWrite('Name   :', 17 + WO, 7, qq.Menu2);
            FastWrite('Last On :', 17 + WO, 57, qq.Menu2);
            FastWrite('Number :', 18 + WO, 7, qq.Menu2);
            FastWrite('Total # :', 18 + WO, 57, qq.Menu2);
            FastWrite('Script :', 19 + WO, 7, qq.Menu2);
            FastWrite('Attempt :', 19 + WO, 57, qq.Menu2);

            FastWrite('Modem  :', 21 + WO, 7, qq.Menu2);
            FastWrite('Start   :', 21 + WO, 57, qq.Menu2);
            FastWrite('Status :', 22 + WO, 7, qq.Menu2);
            FastWrite('Current :', 22 + WO, 57, qq.Menu2);

            Main_Disp_Line;
         End;

         Procedure Show_Stats(num : Integer);
         Begin
            TextAttr := qq.Menu;
            GotoXY(15, 2);
            Write(Pad(Phone_Dir^[num].Name, 27));
            GotoXY(15, 3);
            Write(Pad(Phone_Dir^[num].Number, 19));
            GotoXY(15, 4);
            Write(Pad(Phone_Dir^[num].Script_file, 12));
            GotoXY(66, 2);
            Write(Pad(DatetoDateString(qq.DateStr,Phone_Dir^[num].Last_Connect), 10));
            GotoXY(66, 3);
            Write(Pad(Long2Str(Phone_Dir^[num].Times_Called), 5));
         End;

         Procedure Do_Connect_Stuff;
         Var
            Ncount : Integer;
         Begin
            NoSound;
            Status_Message(7);
            If Phone_Dir^[Enum].Times_Called < 99999 then
               Inc(Phone_Dir^[Enum].Times_Called);
            Phone_Dir^[Enum].last_connect := Today;
            If Phone_Dir^[Enum].Echo1 = 'H' Then
               Echo := True
            Else
               Echo := False;
            Linked_Protocol := Phone_Dir^[Enum].Default_Protocol;
            Linked_Password := Phone_Dir^[Enum].Password;
            Linked_board    := Phone_Dir^[Enum].Name;
            Linked_number   := Phone_Dir^[Enum].Number;
            Linked_Notefile := ForceExtension(FON_Filename,
                               Long2Str(Phone_Dir^[Enum].Notenum));
            Linked_comm     := Long2Str(NewDBits) + '-' + NewCparity +
                                        '-' + Long2Str(NewSBits);
            Str(NewSpeed, Linked_Speed);

            Script_to_Open := Trim(Phone_Dir^[Enum].Script_file);
            Linked_script_file := JustFilename(
                                  FullScriptFilename(
                                  Script_to_Open));

            If Not QuickLearn then
               If Phone_Dir^[Enum].LearnTag Then
                  Learn(Script_to_Open);

            Write_Fon_Entry(Enum);

            If (Script_to_Open <> '') and (Not QuickLearn) Then
               Begin
                  If not Scripting then
                     Begin
                        Scripting := True;
                        Already_Initialized := False;
                     End;
               End;

            If Noise Then
               Begin
                  Ncount := 1;
                  While (Ncount <= qq.ConnectCycles) and
                        (Not KeyPressed) do
                     Begin
                        Sound(qq.CTone1); Delay(100); NoSound;
                        Sound(qq.CTone2); Delay(100); NoSound;
                        Sound(qq.CTone3); Delay(100); NoSound;
                        GiveBack;
                        Inc(Ncount);
                     End;
                  Flush_KBD;
               End;

            Logit('Connected With  : ' + Linked_board);
            Logit('++ Phone Number : ' + Linked_number);
            Logit('++ Comm Speed   : ' + Linked_speed + '-' + Linked_comm);

            Phone_Dir^[Cycle].Marked := False;
            Phone_Dir^[Cycle].LearnTag := False;
         End;

         Procedure Check_for_IO;
         Begin
            Status_Message(11);
            If qq.DoRecalibrate then
               CalibrateDelay;
            NewTimerSecs(RedialDelayET, qq.Redial_Delay);
            Repeat
               GotoXY(15, 7);
               TextAttr := qq.Menu;
               Write(RemainingTimeInSecs(RedialDelayET),'  ');
               GiveBack;

               If Keypressed Then
                  Begin
                     Ch := Upcase(Char(ReadKeyA));
                     Case Ch Of
                        { extend} 'X' : NewTimerSecs(RedialDelayET, Min(RemainingTimeInSecs(RedialDelayET) + 5, 999));
                        { Cycle } 'C' : Begin
                                           Cancel_Call;
                                           Status_Message(1);
                                           Clear_Buffer;
                                           NewTimerSecs(RedialDelayET,0);
                                           Exit;
                                        End;
                        { Kill  } 'K' : Begin { Kill entry }
                                           Cancel_Call;
                                           Status_Message(2);
                                           Clear_Buffer;
                                           Fon_Changed := True;
                                           Phone_Dir^[Cycle].Marked := False;
                                           Phone_Dir^[Cycle].LearnTag := False;
                                           NewTimerSecs(RedialDelayET,0);
                                           Exit;
                                        End;
                       { Escape } #27 : Begin
                                           Clear_Buffer;
                                           Cancel_Call;
                                           Aborted := True;
                                           Exit;
                                        End;
                     End;
                  End;
               If CommPressed Then
                  Begin
                     Message := Get_Modem_Message(rc);
                     Show_Modem_Message;
                  End;
               GiveBack;
            Until (rc In ['N', 'C', 'E', 'R']) Or
                  Aborted Or
                  TimerExpired(RedialDelayET);
         End;

      Begin                       { Redial }
         Ch := ' ';
         If NoDialMarksFound Then
            Begin
               WritelnT ('All tagged entries have blank Number fields.');
               Exit;
            End;
         InRedialer := True;
         Open_Window;
         aborted := False;
         redial := True;
         x := 0;
         Cycle := Pred(StartNum);
         GotoXY(66, 6);
         TextAttr := qq.Menu;
         Write(TimeS);
         num := 0;
         FastWrite(' Redialer ', 15 + WO, 36, qq.Windf);
         FastWrite ('อออออออ',24+wo,70, qq.Windf);
         Repeat
            If qq.DoRecalibrate then
               DelayCalibrate;  {Recalibrate the OneMS variable under DV}
            If NoDialMarksFound Then
               Exit;

            {Select the next number to Dial}
            Inc(Cycle);
            If Cycle > Max_Phones Then
               Cycle := 1;
            While (Not Phone_Dir^[Cycle].Marked) or (Phone_Dir^[Cycle].Number = '') Do
               Begin
                  Inc(Cycle);
                  If Cycle > Max_Phones Then
                     Cycle := 1;
               End;
            Inc(x);
            CurrentPhone := Cycle;
            Show_page;
            TextAttr := qq.Menu;
            GotoXY(66, 4);
            Write(x);
            GotoXY(66, 7);
            Write(TimeS);
            Clear_Status;
            Status_Message(0);
            Parse_Dial_CMD(Long2Str(Cycle), num, False);
            Show_Stats(num);
            Main_Disp_Line;
            Clear_Buffer;
            Dial_modem(Cycle, Enum);
            rc := ' ';
            Check_for_IO;
            If Not Aborted Then
               Begin
                  If (rc = 'N') Or TimerExpired(RedialDelayET) then
                     Begin
                        Cancel_Call;
                        If Ch in ['C', 'K'] Then
                           Ch := ' '
                        Else
                           Begin
                              If TimerExpired(RedialDelayET) Then
                                 Status_Message(4)
                              Else
                                 Status_Message(5);
                              If CommPressed Then
                                 Begin
                                    Message := Get_modem_message(rc);
                                    Show_Modem_Message;
                                 End;
                              Clear_Buffer;
                           End;

                        { here is where we put the time between calls Delay }

                        If not NoDialMarksFound then
                           Begin
                              If qq.Delay_Amount > 0 then
                                 Begin
                                    Status_Message(8);
                                    NewTimerSecs(DelayAmountET, qq.Delay_Amount);
                                    Repeat
                                       GotoXY(31, 7);
                                       TextAttr := qq.Menu;
                                       Write(RemainingTimeInSecs(DelayAmountET),'  ');
                                       If CommPressed Then
                                          Begin
                                             Message := Get_Modem_Message(rc);
                                             Show_Modem_Message;
                                             If rc = 'R' then
                                                Begin
                                                   Status_Message(9);
                                                   goto EExit;
                                                End;
                                          End;

                                       If Keypressed Then
                                          Begin
                                             Ch := Upcase(Char(ReadKeyA));
                                             Case Ch Of
                                                'C' : Begin
                                                         Cancel_Call;
                                                         Clear_Buffer;
                                                         NewTimerSecs(DelayAmountET, 0);
                                                      End;
                                                'K' : Begin { Kill entry }
                                                         Cancel_Call;
                                                         Status_Message(2);
                                                         Clear_Buffer;
                                                         Fon_Changed := True;
                                                         Phone_Dir^[Cycle].Marked := False;
                                                         Phone_Dir^[Cycle].LearnTag := False;
                                                         NewTimerSecs(DelayAmountET, 0);
                                                      End;
                                                #27 : Begin
                                                         Cancel_Call;
                                                         Clear_Buffer;
                                                         Aborted := True;
                                                      End;
                                             End; { case }
                                          End;
                                       GiveBack;
                                    Until TimerExpired(DelayAmountET) or Aborted;
                                 End
                           End
                     End
               End
         Until (rc in ['C','R']) Or aborted;
         If Not aborted and (rc <> 'R') Then
            Begin
               Connected := True;
               Fon_Changed := True;
               Do_Connect_Stuff;
            End
         Else
            Begin
               EExit:
               Linked_Protocol := ' ';
               Linked_Password := '';
               Linked_board := '';
               Linked_number := '';
               Linked_speed := '';
               Linked_comm := '';
               Linked_Notefile := '';
               Linked_script_file := '';
            End;
      End;

      Procedure Edit_Prefix;
      Var
         x  : Integer;
      Begin
         NewGetPrefixes;
         Assign(Prefix_File, SearchName(QMODEM_PRE));
         Rewrite(Prefix_File);
         For x := 1 To 10 Do
            WriteLn(Prefix_File, Prefix[x]);
         Close(Prefix_File);
         IO := IoResult;
      End;


      Procedure ClearOneEntry(x1 : Integer);
      Var
         y : Word;
      Begin
         If x1 < Max_Phones then
            Begin
               y := Phone_Dir^[x1].NoteNum;
               Move (Phone_Dir^[x1+1],Phone_Dir^[x1],(Max_Phones-x1)*SizeOf(Phone_Dir^[1]));
            End
         Else
            y := Phone_Dir^[Max_Phones].NoteNum;
         ClearAnEntry(Max_Phones,y);
         Fon_Changed := True;
      End;


      Procedure Revise_Number(IsRevise : Boolean);
      Var
         Untag : Boolean;
         x1 : Integer;
      Begin
         Show_Menu;
         {Mark the current entry if no others are tagged}
         Untag := False;
         If NoMarksFound Then
            Begin
               Untag := True;
               TagEntry(CurrentPhone, False);
            End;
         If Ch2 <> ^R then
            Begin
               ReviseNumber := CurrentPhone;
               If NewReviseFonEntry(IsRevise) then
                  Phone_Dir^[CurrentPhone].Script_File :=
                        STUpCase(CleanPathName(
                                 Phone_Dir^[CurrentPhone].Script_File))
               Else
                  If not IsRevise then
                     ClearOneEntry(CurrentPhone);
            End
         Else
            For x1 := 1 To Max_Phones Do
               If Phone_dir^[x1].Marked Then
                  Begin
                     ReviseNumber := x1;
                     CurrentPhone := x1;
                     Show_Page;
                     If NewReviseFonEntry(False) then
                        Phone_Dir^[x1].Script_File := STUpCase(CleanPathName(Phone_Dir^[x1].Script_File));
                  End;
         Fon_Changed := True;
         If Untag then
            ClearAllMarks;
         Write_Fon_File;
      End;

      Procedure Edit_Linked_Scripts;
      Begin
         If Phone_dir^[CurrentPhone].Script_file <> '' Then
            Begin
               NormalCursor;
               FSE(FullScriptFilename(Phone_dir^[CurrentPhone].Script_file),
                   0,2,Pred(Last_Row),false);
               HiddenCursor;
            End;
      End;

      Procedure Edit_Attached_Notes;
      Var
         Srec : SearchRec;
         NoteFile : String;
         F : File;
      Begin
         NoteFile := ForceExtension(FON_Filename,Long2Str(Phone_Dir^[CurrentPhone].NoteNum));
         NormalCursor;
         FSEHeader := True;
         NewFSEHeader := ' Notes for '+Phone_Dir^[CurrentPhone].Name+' ';
         FSE(NoteFile, 0, 16+WO, Pred(Last_Row), False);
         {Delete the note if ZERO byte file}

         Phone_Dir^[CurrentPhone].HasNote := False;
         If ExistFile(NoteFile) then
            Begin
               FindFirst(NoteFile, $3F, Srec);
               If Srec.Size < 2 then
                  Begin
                     Assign(F, NoteFile);
                     Erase(F);
                  End
               Else
                  Phone_Dir^[CurrentPhone].HasNote := True;
            End;
         FSEHeader := False;
         HiddenCursor;
      End;

      Function Clean(S : String)    : String;
      Var
         SS : String;
         x  : Integer;
      Begin
         SS := '';
         For x := 1 To Length(S) Do
            If Not(S[x] In ['`','A'..'J']) Then
               SS := SS + S[x];
         Clean := SS;
      End;


      Function SearchNote (x : Integer; Stxt : String) : Boolean;
      Var
         f : Text;
         Found : Boolean;
         InString : String;
      Label
         EExit;
      Begin
         Found := False;
         Assign (f, ForceExtension(FON_Filename,Long2Str(x)));
         Reset  (f);
         If IOResult <> 0 then
            Goto EExit;
         While (not EOF(f)) and (not Found) do
            Begin
               Readln(f,Instring);
               Instring := STUpCase(Instring);
               If Pos(Stxt,Instring) > 0 then
                  Found := True;
            End;
         EExit:
         CLose(F);
         IO := IOResult;
         SearchNote := Found;
      End;

      Procedure SetMarks(S : String);
         {This overrides the Prefix/Suffix chars without writing to disk}
      Var
         x, z, C, y, x1 : Integer;
         S2, SS, Sp, St : String;
         DoWrite : Boolean;
      Begin
         DoWrite := False;
         For x1 := 1 To Paramcnt(S) Do
            Begin
               S2 := ParamStrPos(S, x1, y);
               If Not(Upcase(S2[1]) In ['P', 'T']) Then
                  Begin
                     If Str2Int(S2, C) Then
                        TagEntry(C, False);
                  End
               Else
                  Begin
                     If Upcase(S2[1]) = 'T' Then
                        Begin
                           Stxt := STUpCase(Copy(S2, 2, Pred(Length(S2))));
                           If Stxt <> '' Then
                              Begin
                                 Display_Status(' Searching ');
                                 For x := 1 To Max_Phones Do
                                    If (pos(Stxt, STUpCase(Phone_dir^[x].Name)) > 0) Or
                                       (pos(Stxt, STUpCase(Phone_dir^[x].Number)) > 0) then
                                       TagEntry(x, False)
                                    Else
                                       If Phone_Dir^[x].HasNote then
                                          If SearchNote(Phone_Dir^[x].NoteNum,Stxt) Then
                                             TagEntry(x, False);
                              End;
                        End
                     Else
                     Begin
                        {else it is a Prefix change}
                        SS := '';
                        Sp := '';
                        St := '';
                        z := 2;
                        While (Upcase(S2[z]) In ['`','A'..'J', 'P']) And (z <= Length(S2)) Do
                           Begin
                              Sp := Sp + Upcase(S2[z]);
                              Inc(z);
                           End;
                        While Not(Upcase(S2[z]) In ['`','A'..'J']) And (z <= Length(S2)) Do
                           Begin
                              St := St + Upcase(S2[z]);
                              Inc(z);
                           End;
                        While (Upcase(S2[z]) In ['`','A'..'J']) And (z <= Length(S2)) Do
                           Begin
                              SS := SS + Upcase(S2[z]);
                              Inc(z);
                           End;
                        If Str2Int(St, C) Then
                           Begin
                              TagEntry(C, False);
                              Phone_dir^[C].Number := Sp + Clean(Phone_dir^[C].Number) + SS;
                              DoWrite := True;
                           End;
                     End;
                  End;
            End;
         If DoWrite then
            Write_Fon_File;
      End;

      Procedure Select_Entries;
      Var
         S : String;
      Begin
         Setwindow2(3, 19, 75, 21, ' Select Entries ',false);
         TextAttr := qq.Menu;
         Write(' Numbers to TAG > ');
         Display_Status(' Enter line #''s,  P[prefixes]#[suffixes],  T-Text  ESC-Exit ');
         S := '';
         HelpTopic := 103;
         Edit_String_Window2(20, 19, 52, 52, S);
         If S <> '' Then
            SetMarks(S);
         Restore_Screen;
      End;

      Procedure ManualDial;
      Var
         x     : Integer;
         Found : Boolean;
      Begin
         Setwindow2(13, 19, 62, 21, ' Manual Dial ',false);
         TextAttr := qq.Menu;
         Write(' Phone number > ');
         HelpTopic := 28;
         Display_Status(' Enter the phone number to call   ESC-Exit ');
         TextAttr := qq.menu2;
         LastManual := LM2;
         Found := Edit_String_Window_UC(28, 19, 30, 30, LastManual);
         LM2 := LastManual;
         If (LastManual <> '') and Found Then
            Begin
                LastManual := STUpCase(LastManual);
                ManualMode := True;
            End
         Else
            ManualMode := False;
         Restore_Screen;
      End;


      Procedure FindText;
      Var
         x              : Integer;
         Found          : Boolean;
      Label
         EExit;
      Begin
         Setwindow2(21, 19, 64, 21, ' Find Text ',false);
         TextAttr := qq.Menu;
         Write(' Search for > ');
         HelpTopic := 104;
         Display_Status(' Enter the text to scan for   ESC- Exit ');
         Stxt := '';
         Edit_String_Window2(34, 19, 27, 27, Stxt);
         If Stxt = '' Then GoTo EExit;
         Stxt := STUpCase(Stxt);
         x := 1;
         Found := False;
         While (Not Found) And (x <= Max_Phones) Do
            Begin
               If (pos(Stxt, STUpCase(Phone_dir^[x].Name)) > 0) Or
               (pos(Stxt, STUpCase(Phone_dir^[x].Number)) > 0) Then
                  Found := True
               Else
                  If Phone_Dir^[x].HasNote and
                     SearchNote(Phone_Dir^[x].NoteNum,Stxt) then
                        Begin
                           TnoteFlag := True;
                           Found := True;
                        End
                  Else
                     Inc(x);
            End;
         If x <= Max_Phones Then CurrentPhone := x
                     Else WritelnT(' Text not found ');
         HiddenCursor;
         EExit:
         Restore_Screen;
      End;


      Procedure FindNext;
      Var
         x              : Integer;
         Found          : Boolean;
      Begin
         If Stxt = '' Then
            Begin
               Beep;
               Exit;
            End;
         x := Succ(CurrentPhone);
         Found := False;
         While (Not Found) And (x <= Max_Phones) Do
            Begin
               If (pos(Stxt, STUpCase(Phone_dir^[x].Name)) > 0) Or
               (pos(Stxt, STUpCase(Phone_dir^[x].Number)) > 0) Then
                  Found := True
               Else
                  If Phone_Dir^[x].HasNote and
                     SearchNote(Phone_Dir^[x].NoteNum,Stxt) then
                        Begin
                           TnoteFlag := True;
                           Found := True;
                        End
                  Else
                     Inc(x);
            End;
         If x <= Max_Phones Then CurrentPhone := x
                     Else WritelnT(' No more matches ');
         HiddenCursor;
      End;


      Procedure Clear_Entry;
      Var
         x1 : Integer;
         Ch : Char;
         f : File;
         Untag : Boolean;
      Label
         Loop, EExit;

         Procedure ClearOneEntryNote(x1 : integer);
         Begin
            Phone_Dir^[x1].Marked := False;
            Phone_Dir^[x1].LearnTag := False;
            If ExistFile( ForceExtension
                      (FON_Filename,Long2Str(Phone_Dir^[x1].NoteNum))) then
               Begin
                  Assign(f,ForceExtension(FON_Filename,Long2Str(Phone_Dir^[x1].NoteNum)));
                  Erase(f);
                  Phone_Dir^[x1].HasNote := False;
               End;
         End;


      Begin
         {Mark the current entry if no others are tagged}
         If NoMarksFound Then
            Begin
               TagEntry(CurrentPhone, False);
               Untag := True;
            End
         Else
            Untag := False;
         Setwindow2(25, 13, 58, 20, ' Delete Entries and/or Notes ',false);
         FastWrite ('Notes Only',15,36,qq.Menu2);
         FastWrite ('Entries & Notes',16,36,qq.Menu2);
         FastWrite ('Return to Directory',17,36,qq.Menu2);
         FastWrite ('1.',15,32,qq.Menu);
         FastWrite ('2.',16,32,qq.Menu);
         FastWrite ('ESC.',17,30,qq.Menu);
         NormalCursor;
         GotoXY(2,6);
         TextAttr := qq.Menu2;
         HelpTopic := 42;
         Write  ('Your Choice ? ');
         Display_Status(' 1-Delete Attached Notes   2-Delete Entries and Notes   ESC-Exit ');
         TextAttr := qq.Menu;
         Repeat
            CH := Char(ReadKeyA);
         Until CH In ['1','2',#27];
         Restore_Screen;
         HiddenCursor;
         If Ch = #27 then goto EExit;
         Display_Status(' Clearing ');
         If Ch2 <> ^D then
            Begin
               x1 := CurrentPhone;
               ClearOneEntryNote(x1);
               If Ch = '2' then
                  ClearOneEntry(x1);
               Show_Page;
            End
         Else
            For x1 := 1 To Max_Phones Do
               Begin
                  Loop:
                  If Phone_dir^[x1].Marked Then
                     Begin
                        CurrentPhone := x1;
                        Show_Page;
                        ClearOneEntryNote(x1);
                        If Ch = '2' then
                           Begin
                              ClearOneEntry(x1);
                              Goto Loop;
                           End;
                        Show_Page;
                     End;
               End;
         EExit:
         If Untag then
            Begin
               Phone_dir^[CurrentPhone].Marked := False;
               Phone_dir^[CurrentPhone].LearnTag := False;
            End;
         If Ch = '2' then
            Write_Fon_File;
      End;

      Procedure PrintPhoneBook;
      Var
         Lst   : Text;
         x,
         Cnt,
         Page   : Integer;
         ostr   : String;
      Label
         EExit;


         Function Do_Heading : Boolean;
         Label Err1;
         Begin
            WriteLn(LST, ^M^J+CharStr(' ', 21) + _Qmodem_+' '+version+' Phone Book');
            If IOResult <> 0 then Goto Err1;
            WriteLn(LST, CharStr(' ', 21) + CharStr('=', Length(_Qmodem_)+Length(version)+12)+^M^J);
            If IOResult <> 0 then Goto Err1;
            WriteLn(LST, 'Page ',LeftPad(Long2Str(Page),2),'   File : '+FON_Filename+^M^J);
            If IOResult <> 0 then Goto Err1;
            Write  (LST, '           Name                           Number          Com      Script');
            If Ch2 = ^P then Writeln (LST, '        Password        LastCall  Total  Prot  Dup')
                        Else Writeln (LST,'');
            If IOResult <> 0 then Goto Err1;
            If Ch2 <> ^P then WriteLn (LST, CharStr('-', 78))
                         Else WriteLn (LST, CharStr('-', 123));
            If IOResult <> 0 then Goto Err1;
            Do_Heading := True;
            Inc(Page);
            Cnt := 0;
            Exit;
            Err1:
            Do_Heading := False;
         End;

         Function Do_Footing : Boolean;
         Label Err1;
         Begin
            Write(LST, ^M^J^L);
            If IOResult <> 0 then
               Goto Err1;
            Do_Footing := True;
            Exit;
            Err1:
            Do_Footing := False;
         End;

         Procedure PrintAttachedNote(num : Integer);
         Var
            F : text;
            s : String;
         Label
            EExit;
         Begin
            If ExistFile( ForceExtension
                      (FON_Filename,Long2Str(Phone_Dir^[num].NoteNum))) then
               Begin
                  Assign(f,ForceExtension(FON_Filename,Long2Str(Phone_Dir^[num].NoteNum)));
                  Reset(f);
                  While Not EOF(f) do
                     Begin
                        If Cnt=50 then
                           Begin
                              If not Do_Footing then goto EExit;
                              If not Do_Heading then goto EExit;
                           End;
                        Readln(f, s);
                        Writeln(LST, '    '+qq.NoteTag+' '+s);
                        If IOresult <> 0 then goto EExit;
                        Inc(Cnt);
                     End;
                  EExit:
                  Close(f);
               End;
         End;

      Begin
         Setwindow2(3, 19, 77, 21, ' Print Phone Book ',false);
         TextAttr := qq.Menu;
         Write(' Device or File > ');
         Display_Status(' Enter the destination device or filename.   ESC-Exit ');
         If qq.PrinterID = '' then
            Stxt := 'PRN'
         Else
            Stxt := qq.PrinterID;

         HelpTopic := 105;
         Edit_String_Window2(22, 19, 50, 50, Stxt);
         If Stxt = '' Then
            GoTo EExit;
         Stxt := STUpCase(Stxt);
         Display_Status (' PRINTING - Any Key to Stop ');
         If not OpenPrinter(Lst, Stxt) then
            WritelnT ('Invalid Device or Filename')
         Else
            Begin
               Write (LST,^L);
               Page := 1;
               If not Do_Heading then goto EExit;
               For x := 1 To Max_Phones Do With Phone_dir^[x] Do
                  Begin
                     If KeyPressed then
                        Begin
                           Ch := Char(ReadKeyA);
                           Goto EExit;
                        End;
                     If Cnt = 50 Then
                        Begin
                           If not Do_Footing then Goto EExit;
                           If not Do_Heading then Goto EExit;
                        End;
                     If (Name <> '') or (Number <> '') Then
                        Begin
                           Write   (LST, Pad(Long2Str(x), 3) +
                                    ' ' +
                                    Pad(Name, 29) +
                                    LeftPad(Number, 19) +
                                    LeftPad(Long2Str(ComSpeed), 7) + '-' +
                                    Long2Str(dbits) + '-' +
                                    Parity + '-' +
                                    Long2Str(sbits) + '  ' +
                                    Pad(Script_file,12));
                           If Ch2 = ^P then Writeln (LST, '  '+Pad(Password,14) +
                                                     LeftPad(DatetoDateString(qq.DateStr,last_connect),10) +
                                                     LeftPad(Long2Str(Times_Called),7) +
                                                     LeftPad(Default_Protocol,4) +
                                                     LeftPad(Echo1,6))
                                       Else Writeln (LST, '');
                           IO := IoResult;
                           If IO <> 0 then goto EExit;
                           Inc(Cnt);
                           If Phone_Dir^[x].HasNote then
                              PrintAttachedNote(x);
                        End;
                  End;
               If not Do_Footing then goto EExit;
               IO := IoResult;
               If IO <> 0 then goto EExit;
            End;
         EExit:
         ClosePrinter(Lst);
         IO := IoResult;
         Restore_Screen;
      End;


      Procedure Sort_Entries;
      Var
         SortResult : Integer;
         x1, T      : Integer;
      Begin
         T := GetSortSelection (29, 17);
         If (T < 1) Or (T > 3) Then
            Exit;
         Case T Of
            1 : SortMethod := NameSort;
            2 : SortMethod := NumberSort;
            3 : SortMethod := CallsSort;
         End;
         Display_Status(' SORTING ');
         SortResult := TurboSort(SizeOf(Phone_Type),
                                 @InpRecs, @LessRecs, @OutpRecs);
         Fon_Changed := True;
         Write_Fon_File;
         If SortResult <> 0 Then
            Beep;
      End;


      Procedure X_ClearAllMarks;
      Begin
         If qq.ClearFTags then
            ClearAllMarks;
         Fon_Changed := True;
         Write_Fon_File;
      End;

   Label
      ForceDial;
   Var
      W : Word;
   Begin                          { DIAL }
      Fonenum := '';
      TnoteFlag := False;
      If Last_Row > 35 Then WO := 10
                       Else WO := 0;
      x := 0;
      Ok := True;
      Setwindow2(1, 1, 80, 24 + WO, ' Phone Book ',false);
      FastWrite('ฦ' + CharStr('อ', 34) + ' Commands ' + CharStr('อ', 34) + 'ต', 15 + WO, 1, qq.Windf);
      Connected := False;
      ManualMode := False;
      Window(2, 16 + WO, 79, 23 + WO);
      TextAttr := qq.Menu;
      ClrScr;
      Show_Menu;
      Show_Prefix_List;
      If PassedMarks <> '' Then
         Begin
            ClearAllMarks;
            SetMarks(PassedMarks);
            HelpTopic := 0;
            Show_Page;
            Redialer(1);
            If Scripting Then
               Begin
                  Restore_Screen;
                  display_Status('');
                  Exit;
               End
            Else
               Show_Menu;
         End;
      Repeat
         FastWrite ('F1 Help',24+wo,70, qq.Windf);
         HelpTopic := 26;
         HiddenCursor;
         InRedialer := False;
         If TnoteFlag then
            Begin
               WritelnT('Text found in attached Note');
               TnoteFlag := False;
               HiddenCursor;
            End;
         FastWrite(' Commands ', 15 + WO, 36, qq.Windf);
         Display_Status (' ,PgUp/Dn,^PgUp/Dn-Move Scroll Bar   ENTER-Dial   ESC-Exit ');
         TextAttr := qq.menu2;
         Show_Page;
         W := ReadKeyNoGrey;
         Ch2 := Upcase(Char(W));
         Case W Of
            CtrlPgDn : CurrentPhone := Max_Phones;
            CtrlPgUp : CurrentPhone := 1;
            Down     : Inc(CurrentPhone);
            Up       : Dec(CurrentPhone);
            PgDn     : Inc(CurrentPhone, 10 + WO);
            PgUp     : Dec(CurrentPhone, 10 + WO);
            Ins      : If InsertBlank then            {!!4.2G}
                          Revise_Number(False);       {!!4.2G}
            Del      : Clear_Entry;
            F2       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F2}');
                           Goto ForceDial;
                       End;
            F3       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F3}');
                           Goto ForceDial;
                       End;
            F4       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F4}');
                           Goto ForceDial;
                       End;
            F5       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F5}');
                           Goto ForceDial;
                       End;
            F6       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F6}');
                           Goto ForceDial;
                       End;
            F7       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F7}');
                           Goto ForceDial;
                       End;
            F8       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F8}');
                           Goto ForceDial;
                       End;
            F9       : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F9}');
                           Goto ForceDial;
                       End;
            F10      : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F10}');
                           Goto ForceDial;
                       End;
            F11      : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F11}');
                           Goto ForceDial;
                       End;
            F12      : Begin
                           X_ClearAllMarks;
                           SetMarks('T{F12}');
                           Goto ForceDial;
                       End;
            Else
               Case Ch2 of
                   #13  : Begin
                             HelpTopic := 0;
                             If NoMarksFound Then
                                Begin
                                   If QuickLearn then
                                      WriteLearn ('Dial     "'+Long2Str(CurrentPhone)+'"');
                                   TagEntry(CurrentPhone, False);
                                   Redialer(CurrentPhone);
                                   Phone_dir^[CurrentPhone].Marked   := False;
                                   Phone_dir^[CurrentPhone].LearnTag := False;
                                End
                             Else
                                ForceDial:
                                Redialer(CurrentPhone);
                             If Not Connected Then
                                Show_Menu;
                             Ch2 := #0;
                          End;

                   ' '  : Begin
                             Fon_Changed := True;
                             If (KBDflags and 4) <> 0 then
                                Begin
                                   Phone_dir^[CurrentPhone].Marked :=
                                   Not Phone_dir^[CurrentPhone].Marked;
                                   If Phone_Dir^[CurrentPhone].Marked then
                                      TagEntry(CurrentPhone, True)
                                   Else
                                      Phone_Dir^[CurrentPhone].LearnTag := False;
                                End
                             Else
                                Begin
                                   Phone_Dir^[CurrentPhone].Marked :=
                                   Not Phone_Dir^[CurrentPhone].Marked;
                                   If Phone_Dir^[CurrentPhone].Marked then
                                      TagEntry(CurrentPhone, False)
                                   Else
                                      Phone_Dir^[CurrentPhone].LearnTag := False;
                                End;
                             If qq.TagAdvance then
                                Inc(CurrentPhone);
                          End;
               'Q' : Begin
                        Fon_Changed := True;
                        If Phone_Dir^[CurrentPhone].Script_file <> '' Then
                           Begin
                              Phone_Dir^[CurrentPhone].LearnTag :=
                              Not Phone_Dir^[CurrentPhone].LearnTag;
                              Phone_Dir^[CurrentPhone].Marked :=
                              Phone_Dir^[CurrentPhone].LearnTag;
                              If qq.TagAdvance then
                                 Inc(CurrentPhone);
                           End
                        Else
                           Begin
                              Beep;
                              Writelnt('Script file must be specified to QuickLearn');
                           End;
                     End;
               'E' : Begin
                        Edit_Prefix;
                        Show_Prefix_List;
                        Display_Status('');
                     End;
               'R',
               ^R  : Revise_Number(True);             {!!4.2G}
               'D',
               ^D  : Clear_entry;
               'I' : If InsertBlank then              {!!4.2G}
                        Revise_Number(False);         {!!4.2G}
               'S' : Sort_Entries;
               'T' : Select_Entries;
               'U' : ClearAllMarks;
               'F' : FindText;
               'M' : ManualDial;
               'N' : Edit_Attached_Notes;
               'P',
               ^P  : PrintPhoneBook;
               'A' : FindNext;
               ^U  : Undo_Fon_Changes;
               'L' : Load_New_FON;
               'O' : Dial_Other_Info := Not Dial_Other_Info;
               'V' : Edit_Linked_Scripts;
            End;
         End;
      Until (W = Esc) Or Connected Or ManualMode;
      Restore_Screen;
      If ManualMode Then
         Begin
            LastManual := PrefixSubstitute(LastManual,False) + qq.Dial_PostFix;
            Writelnb('MANUAL DIAL > ' + LastManual);
            Logit('MANUAL DIAL > ' + LastManual);
            Parse_Write_Modem(LastManual);
         End;
      HelpTopic := 0;
   End;

End.
