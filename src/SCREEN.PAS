Unit SCREEN;

Interface

{$I TPDEFINE.INC}

Uses
   Qmem,           Dos,
   TpCrt,          TpDos,
   GiveBk,         OpKey,
   TpEntry,        TpEdit,
   TpMenu,         TpPick,
   TpHelp,

   {$IFDEF UseMouse} TpMouse, {$ENDIF}
   {$IFDEF OVR}      Overlay, {$ENDIF}

   TpWindow,       TpDir,
   TpString,       TpInline,
   Stack5,         Initial;


Var
   Qinstall_Menu  : Menu;

   WPtr           : Array[0..20] Of WindowPtr;
   HelpP          : HelpPtr;
   HelpTopic      : Word;
   InternalHelp   : Boolean;


Const
   sON             = 'ON ';
   sOFF            = 'OFF';
   Save_Status_CNT : Byte = 0;

Type
   KeyPressType   = (Normal, KeyPad, x00_Extended, xE0_Extended);
Var
   ExtendedChar    : KeyPressType;
   Save_Status     : Array[1..10] of Pointer;
   SSC             : Array[1..10] of Record
                                        c1,r1,c2,r2 : Integer;
                                     End;
{$IFDEF UseMouse}
Var
   LmouseR1,
   LmouseC1,
   LmouseR2,
   LmouseC2 : byte;
{$ENDIF}

Type
   KeyPointer  = ^KeyQueuePtr;
   KeyQueuePtr = Record
                    TheKey : Word;
                    Next   : KeyPointer;
                  End;
Var
   KeyQueueHead,
   KeyQueueTail : KeyPointer;




Procedure StuffQueueKey(W : Word);
Function  NextQueueKey(Var W : Word) : Boolean;
Function  KeyPressed : Boolean;
Function  ReadKeyA : Word;         {all characters}
Function  ReadKeyNoGrey : Word;
Function  ReadKeyNoGreyNoHelp : Word;

Procedure Save_Screen(r1,c1,r2,c2 : Integer);
Procedure Restore_screen;
Procedure Frame (S : String; x1, y1, x2, y2 : Byte);
Procedure Drawbox3 (x1,y1,x2,y2,fg : Integer; Boxname : Str80);
Procedure SetWindow2 (r1,c1, r2,c2 : integer;  S : String; IsScroll : Boolean);
Procedure SetWindow1 (r1,c1, r2,c2, Attr : integer; S : String; IsScroll : Boolean);
Procedure SetWindow3 (r1,c1, r2,c2, Attr : integer; S : String);
Procedure SetWindow4 (r1,c1, r2,c2 : integer;  S : String);

Procedure WindowSaveExit;
{$IFDEF UseMouse}
Procedure MouseToggleEntry(Row, Col, Attr : Byte; Num : Word);
Procedure LMouseWindow;
{$ENDIF}


Procedure Push_Status;
Procedure Pop_Status;
Function  Make_Status(S : String) : String;
Procedure Display_Status(S : String);
Procedure Display_Status2(S : String);
Procedure Display_Status_2(S : String);

Procedure Show_Script_Status_Line;

Procedure WritelnT(txt : String);

{PickList @ Functions}
Function  PortsAvailable(Item : Word) : String;
Function  ModemsAvailable(Item : Word) : String;
Function  ColorsAvailable(Item : Word) : String;
Function  CharsAvailable(Item : Word) : String;
Function  EmulationsAvailable(Item : Word) : String;
Function  BaudsAvailable(Item : Word) : String;
Function  LFAvailable(Item : Word) : String;
Function  CRAvailable(Item : Word) : String;
Function  SortAvailable(Item : Word) : String;
Function  SBitsAvailable(Item : Word) : String;
Function  DBitsAvailable(Item : Word) : String;
Function  ParitysAvailable(Item : Word) : String;


Procedure HelpRoutine(UnitCode : Byte; IdPtr : Pointer; HelpIndex : Word);
Function  OpenHelp : Boolean;

Function  CurrentDisplaySt : String;

Procedure SetVGA (S:String);
Procedure SetVEGAVGA (S:String);
Procedure Show_All_Allocations;
Function  Is_External(Ch : Char) : Integer;
Procedure SetPickColors;
Procedure SetHelpColors;

procedure RestoreCursor(x : Integer);
procedure SaveCursor(x : Integer);

Function  EmulationT(Em : Emulation_Mode) : String;
Function  Asc2int(NumStr : String) : Integer;
Function  Asc2int2(NumStr : String) : Integer;
Procedure Add_Ch_to_Ansi(CH : Char);
Procedure PrtTab;

Var
   Newline,
   G0_Graphics,
   Save_Graphics,
   G0_Mode,
   VT52compat,
   G1_Graphics,
   Do_Graphics    : Boolean;
   Last_Emulation : Emulation_Mode;

   bc, xx_b : Integer;
   xx_c     : Byte;



Var
   PickColors : PickColorArray;
   HelpColors : HelpColorArray;



Implementation


Procedure Frame (S : String; x1, y1, x2, y2 : Byte);
Var
   x : Integer;
   Nattr : Byte;
Begin
   FrameWindow(x1,y1, x2,y2, TextAttr, TextAttr, S);
   inc(x1);
   inc(y1);
   dec(x2);
   dec(y2);
   window (x1, y1, x2, y2);
   GotoXY(1,1);
   Clrscr;
end;

Procedure Save_Screen(r1,c1,r2,c2 : Integer);
Var
   a : Byte;
   b : Boolean;
Begin
   Push_Window;
   b := Explode;
   Explode := False;
   If Virt_Win_Ptr < 50 then
      Begin
         Set_Colors;
         Inc(Virt_Win_Ptr);
         If MakeWindow (WPtr[Virt_Win_Ptr],r1,c1,r2,c2,
                        False,False,False,a,a,a,'') Then
            If DisplayWindow (WPtr[Virt_Win_Ptr]) Then
               Push_Status;
      End;
   Explode := b;
   Pop_Window;
End;


Procedure Drawbox3 (x1,y1,x2,y2,fg : Integer; Boxname : Str80);
Begin
   TextAttr := fg;
   Frame (BoxName, x1, y1, x2, y2);
End;

Procedure Show_Script_Status_Line;
Begin
   Str(Script_Stack_pointer:2,stp);
   Curr_Script_Name := STUpCase(Curr_Script_Name);
   Display_Status (' Script file "'+ Curr_Script_Name + '" at level ' + STP + '.  [ESC] to ABORT ');
End;


Function  EmulationT(Em : Emulation_Mode) : String;
Begin
   Case Em of
      TTY         : EmulationT := 'TTY';
      ANSImode    : EmulationT := 'ANSI';

      {$IfNDef GG}

      VT100       : EmulationT := 'VT100';
      DEBUG_A     : EmulationT := 'DBUG_A';
      DEBUG_H     : EmulationT := 'DBUG_H';
      TVI925      : EmulationT := 'TVI925';

      {$EndIf} {GG}

      AVATAR      : EmulationT := 'AVATAR';
      Else          EmulationT := '';
   End;
End;



Procedure PrtTab;
Var
   x : Integer;
Begin
   x := WhereX+1;

   {$IfDef GG}

      While (TabStops[x] = 0) And (x < Last_Col+1) Do
         Begin
            Inc(x);
            Write(' ');
         End;
      Write(' ');

   {$Else}

      While (TabStops[x] = 0) And (x < Last_Col+1) Do
         Begin
            Inc(x);
            If Emulation <> VT100 then
               Write(' ');
         End;
      If Emulation <> VT100 then
         Write(' ');
      If Emulation = VT100 then
         GotoXY(x mod Last_Col, WhereY);

   {$EndIf}

End;

Function Asc2int(NumStr : String) : Integer;
Var
   rc, x          : Integer;
Begin
   Val(Trim(NumStr), x, rc);
   If rc > 0 Then Asc2int := -1
             Else Asc2int := x;
End;

Function Asc2int2(NumStr : String) : Integer;
Var
   rc, x          : Integer;
Begin
   Val(Trim(NumStr), x, rc);
   If rc > 0 Then Asc2int2 := -1
   Else
   Begin
      If x = 0 Then x := 1;
      Asc2int2 := x;
   End;
End;

Procedure Add_Ch_to_Ansi(CH : Char);
Begin
   Save_Ansi_Str := Save_Ansi_Str + CH;
End;



Procedure SaveCursor(x : Integer);
Begin
   row[x] := wherey;
   col[x] := wherex;
End;

Procedure RestoreCursor(x : Integer);
Begin
   GotoXY (Col[x],Row[x]);
End;



Procedure WritelnT (txt : String);
Var
   x,b1,b2,b3,b4 : Byte;
Begin
   If Scripting then exit;
   If qq.Status_Delay = 0 then exit;
   HiddenCursor;
   b1 := 40 - Length(txt) div 2 - 2;
   b2 := 11;
   b3 := 40 + Length(txt) div 2 + 2;
   If b3 < 46 then b3 := 46;
   b4 := 13;
   SetWindow2(b1,b2,b3,b4,' Status ',false);
   ClrScr;
   FastWrite (txt, 12, b1+2, qq.Menu);
   For x := 1 to 10 do
      Begin
         Delay(qq.Status_Delay);
         If Keypressed then;
      End;
   Restore_Screen;
   NormalCursor;
End;


Procedure SetPickColors;
Begin
   PickColors[WindowAttr] := qq.Qcolor1[BodyColor];
   PickColors[FrameAttr]  := qq.Qcolor1[FrameColor];
   PickColors[HeaderAttr] := qq.Qcolor1[FrameColor];
   PickColors[SelectAttr] := qq.Qcolor1[SelectColor];
   PickColors[AltNormal]  := qq.Qcolor1[FrameColor];
   PickColors[AltHigh]    := qq.Qcolor1[SelectColor];
End;

Procedure SetHelpColors;
Begin
   HelpColors[FrAttr] := qq.HelpColors[1];
   HelpColors[TeAttr] := qq.HelpColors[2];
   HelpColors[HeAttr] := qq.HelpColors[1];
   HelpColors[XsAttr] := qq.HelpColors[4];
   HelpColors[XrAttr] := qq.HelpColors[5];
   HelpColors[SpAtt1] := qq.HelpColors[6];
   HelpColors[SpAtt2] := qq.HelpColors[7];
   HelpColors[SpAtt3] := qq.HelpColors[8];
End;


Function Is_External(Ch : Char) : Integer;
Var
   x : Integer;
Begin
   Ch := UpCase(Ch);
   For x := 1 To qq.Total_Xfers Do
      If qq.Xfer_select_chr[x] = Ch Then
         Begin
            Is_External := x;
            Exit;
         End;
   Is_External := 0;
End;


Procedure Show_All_Allocations;
Const
   DS = ' DEBUG Status ';
Begin
   {HiddenCursor;}
   Push_Status;
   {$IfDef ISI}
   If qq.Use_ISI then
      SetWindow2(12,1,67,17,DS,false)
   Else
   {$EndIf}
      SetWindow2(12,1,67,21,DS,false);
   Display_Status(' Internal Use Only ');
   Writeln (' ---Type------Total------Alloc------Free--');
   Writeln ('   Scroll   ',qqMaxScrollHeap:6,'     ',CurrentScrollHeap:6,'     '
            ,(qqMaxScrollHeap-CurrentScrollHeap):6);
   {$IfDEF OVR}
   Writeln ('   OvrBuf   ',OvrGetBuf:6);
   Writeln ('   OvrTrap  ',OvrTrapCount:6);
   Writeln ('   OvrLoad  ',OvrLoadCount:6);
   {$ELSE}
   Writeln;writeln;writeln;
   {$ENDIF}
   Writeln (' ',CharStr('-',52));
   WriteLn ('   Stack Used    ',StackSoFar:6,'     CheckSnow   ',CheckSnow);
   Writeln ('   MemAvail      ',MemAvail:6,  '     DirectVideo ',DirectVideo);
   Write   ('   MaxAvail      ',MaxAvail:6,  '     DESQview    ');
   If IN_DV <> 0 then         Writeln     (Hi(DV_Version),'.',Lo(DV_Version))
                 else         Writeln     ('n/a');
   Write   ('   File Handles  ',FileHandlesOpen(True):6,'     UART        ');
   If B8250 then
      Writeln ('8250')
   Else
      If B16450 then
         Writeln('8250A/16450')
      Else
         If B16550 then
            Writeln ('16550')
         Else
            If B16550A then
               Writeln('16550A')
            Else
               {$IfDef ISI}
               If qq.Use_ISI then
                  Writeln('ISI ',ISI_Port_Count,' Port')
               Else
               {$EndIf}
                  Writeln('-unknown-');

   Writeln (' ',CharStr('-',52));
   {
   FastText(Hexw(Seg(ComSaveVec^))+':'+HexW(Ofs(ComSaveVec^))+'--'+
            Hexw(Seg(MyIntVec^))+':'+HexW(Ofs(MyIntVec^)),13,41);
   }
   {$IfDef ISI}
   If not qq.Use_ISI then
   {$EndIf}
      Begin
         Writeln ('   UART IER     ',BinaryB(Port[IER_]),  '     UART MCR     ',BinaryB(Port[MCR_]));
         Writeln ('   UART IIR     ',BinaryB(Port[IIR_]),  '     UART MSR     ',BinaryB(Port[MSR_]));
         Writeln ('   UART LCR     ',BinaryB(Port[LCR_]),  '     UART LSR     ',BinaryB(Port[LSR_]));
      End;
   Writeln ('   PICMSK       ',BinaryB(Port[Picmsk]),'     PICMSK2      ',BinaryB(Port[picmsk2]));
   Writeln ('   InTrips    ',Inttrips:5,     ' Loop Trips ',LSRXXX:5  ,      '  OutTrips ',U16550loops:5);
   Writeln ('   MSR Trips  ',MSRtrips:5,     ' LSR Trips  ',LSRtrips:5,      '  ShrTrips ',ShareTrips:5);
   {$IfDef ISI}
   If not qq.Use_ISI then
   {$EndIf}
      Writeln ('   Frame Err  ',FramingErrors:5,' Parity Err ',ParityErrors:5,  '  Overruns ',OverrunErrors:5);
   Write   (Pad('',15));
   Keycontinue(textattr);
   Restore_Screen;
   NormalCursor;
   Pop_Status;
End;


Procedure LowVEGAVGA (v : Byte);
Begin
   r.AH := $6F;
   r.AL := $05;
   r.BL := v;
   Intr($10,R);
End;

Procedure LowVGA (v : Byte);
Begin
   r.AH := 0;
   r.AL := v;
   Intr($10, R);
End;

Procedure SetVEGAVGA (S:String);
Var
   v : Integer;
Begin
   If Str2Int(S,v) then
      LowVEGAVGA(Lo(v));
   ReinitCRT;
   CheckSnow := qq.CheckSnowx = 'Y';
End;


Procedure SetVGA (S:String);
Var
   v : Integer;
Begin
   If Str2Int(S,v) then
      LowVGA(Lo(v));
   ReinitCRT;
   CheckSnow := qq.CheckSnowx = 'Y';
End;


Function CurrentDisplaySt : String;
Begin
   Case CurrentDisplay Of
      MonoHerc : CurrentDisplaySt := 'Monochrome';
      CGA      : CurrentDisplaySt := 'CGA';
      EGA      : CurrentDisplaySt := 'EGA';
      VGA      : CurrentDisplaySt := 'VGA';
      MCGA     : CurrentDisplaySt := 'MCGA';
      Else       CurrentDisplaySt := 'Unknown';
   End;
End;

Function Make_Status(S : String) : String;
Var
   x, y : Integer;
Begin
   y := 0;
   for x := 1 to Length(s) do
      If s[x] in [^A,^B,^C] then Inc(y);
   x := (Last_Col div 2) - ((Length(S)-y) div 2);
   If x < 0 then x := 0;
   S := CharStr(qq.SLC,x)+ S + CharStr(qq.SLC,x);
   S[0] := Chr(Last_Col+y);
   Make_Status := S;
End;

Procedure Display_Status(S : String);
Begin
   If not ShowSL then Exit;
   Save_Last_Status := S;
   S := Make_Status(S);
   FastWrite(S, Real_Last_Row, 1, qq.StatusLineColor);
End;


Procedure Display_Status_2(S : String);
Begin
   If not ShowSL then Exit;
   Save_Last_Status := S;
   s := Pad(S,Last_Col);
   FastWrite(S, Real_Last_Row, 1, qq.StatusLineColor);
End;

Procedure Display_Status2(S : String);
Var
   Flex : FlexAttrs;
   x, y : Integer;
Begin
   If not ShowSL then Exit;
   y := 0;
   for x := 1 to Length(s) do
      If s[x] in [^A,^B,^C] then Inc(y);
   S := PadCh(S,' ',Last_Col+y);
   If S <> Save_Last_Status then
      Begin
         Save_Last_Status := S;
         Flex[0] := qq.StatusLineColor;
         Flex[1] := qq.StatusLineColor2;
         FlexWrite(S,Real_Last_Row, 1, Flex);
      End;
End;



{$IFDEF UseMouse}
Procedure LMouseWindow;
Begin
   If MouseInstalled then
      MouseWindow(LmouseR1,LmouseC1,LmouseR2,LmouseC2);
End;
{$ENDIF}



   {$F+}
   Function LFAvailable(Item : Word) : String;
   Begin
      Case Item of
         1 : LFAvailable := ' NONE ';
         2 : LFAvailable := ' STRIP ';
         3 : LFAvailable := ' ADD CR ';
      End;
   End;
   {$F-}

   {$F+}
   Function CRAvailable(Item : Word) : String;
   Begin
      Case Item of
         1 : CRAvailable := ' NONE ';
         2 : CRAvailable := ' STRIP ';
         3 : CRAvailable := ' ADD LF ';
      End;
   End;
   {$F-}

   {$F+}
   Function SortAvailable(Item : Word) : String;
   Begin
      Case Item of
         1 : SortAvailable := ' 1 - Name (ascending) ';
         2 : SortAvailable := ' 2 - Number (ascending) ';
         3 : SortAvailable := ' 3 - Total Calls (descending) ';
      End;
   End;
   {$F-}

   {$F+}
   Function SBitsAvailable(Item : Word) : String;
   Begin
      Case Item of
         1 : SBitsAvailable := '   1';
         2 : SBitsAvailable := '   2';
      End;
   End;
   {$F-}


   {$F+}
   Function DBitsAvailable(Item : Word) : String;
   Begin
      Case Item of
         1 : DBitsAvailable := '   8';
         2 : DBitsAvailable := '   7';
      End;
   End;
   {$F-}


   {$F+}
   Function ParitysAvailable(Item : Word) : String;
   Begin
      Case Item of
         1 : ParitysAvailable := ' None';
         2 : ParitysAvailable := ' Even';
         3 : ParitysAvailable := ' Odd';
         4 : ParitysAvailable := ' Mark';
         5 : ParitysAvailable := ' Space';
      End;
   End;
   {$F-}




{$F+}
Function EmulationsAvailable(Item : Word) : String;
Var
   S : String[15];
Begin

   {$IfDef GG}
      Case Item of
         1 : S := 'TTY';
         2 : S := 'ANSI';
         3 : S := 'AVATAR';
      End;
   {$Else}
      Case Item of
         1 : S := 'TTY';
         2 : S := 'ANSI';
         3 : S := 'VT100';
         4 : S := 'TVI 925';
         5 : S := 'DEBUG_A';
         6 : S := 'DEBUG_H';
         7 : S := 'AVATAR';
      End;
   {$EndIf}
   EmulationsAvailable := '   '+S;
End;
{$F-}


{$F+}
Function BaudsAvailable(Item : Word) : String;
Begin
   Case Item of
      1 : BaudsAvailable := 'A    110';
      2 : BaudsAvailable := 'B    300';
      3 : BaudsAvailable := 'C   1200';
      4 : BaudsAvailable := 'D   2400';
      5 : BaudsAvailable := 'E   4800';
      6 : BaudsAvailable := 'F   9600';
      7 : BaudsAvailable := 'G  19200';
      8 : BaudsAvailable := 'H  38400';
      9 : BaudsAvailable := 'I  57600';
     10 : BaudsAvailable := 'J 115200';
   End;
End;
{$F-}



{$F+}
Function CharsAvailable(Item : Word) : String;
Begin
   CharsAvailable := ' '+Chr(Lo(Item-1))+'  ';
End;
{$F-}

Function ModemsAvailable(Item : Word) : String;
Var
   Mptr : ModemListPointer;
Begin
   Mptr := MLPhead;
   While (item <> Mptr^.Item) and (Mptr <> NIL) do
      Mptr := Mptr^.Next;
   ModemsAvailable := ' '+Mptr^.Name+' ';
End;

Function PortsAvailable(Item : Word) : String;
Var
   x,y : Integer;
Begin
   x := 0;
   For y := 1 to 8 do
      If qq.irq[y] <> 0 then
         Begin
            inc(x);
            If x = Item then
               Begin
                  PortsAvailable := ' COM'+Long2Str(y)+
                                    '  Base('+Hexw(qq.Base[y])+')'+
                                    '  IRQ('+HexB(qq.IRQ[y])+')';
                  Exit;
               End;
         End;
   {$IfDef ISI}
   For y := 1 to ISI_Port_Count do
      Begin
         Inc(x);
            If x = Item then
               Begin
                  PortsAvailable := ' ISI'+Long2Str(y)+
                                    '  Base('+Hexw(qq.ISI_Base)+')'+
                                    '  IRQ('+HexB(qq.ISI_IRQ)+')';
                  Exit;
               End;
      End;
   {$EndIf}
End;


Function ColorsAvailable(Item : Word) : String;
Begin
   Case Item of
      1 : ColorsAvailable := ' Pulldown normal text ';
      2 : ColorsAvailable := ' Pulldown first letter ';
      3 : ColorsAvailable := ' Pulldown selection bar ';
      4 : ColorsAvailable := ' Pulldown window border ';
      5 : ColorsAvailable := ' Pulldown edit field ';
      6 : ColorsAvailable := ' Window border ';
      7 : ColorsAvailable := ' Window primary text ';
      8 : ColorsAvailable := ' Window secondary text ';
      9 : ColorsAvailable := ' Window Scroll Bar ';
     10 : ColorsAvailable := ' Screen border ';
     11 : ColorsAvailable := ' Screen text ';
     12 : ColorsAvailable := ' Information text ';
     13 : ColorsAvailable := ' Status Line primary';
     14 : ColorsAvailable := ' Status Line secondary';
     15 : ColorsAvailable := ' Help border ';
     16 : ColorsAvailable := ' Help normal text ';
     17 : ColorsAvailable := ' Help selected xref ';
     18 : ColorsAvailable := ' Help unselected xref ';
     19 : ColorsAvailable := ' Help highlite text ';
     20 : ColorsAvailable := ' Editor primary text ';
     21 : ColorsAvailable := ' Editor marked text ';
     22 : ColorsAvailable := ' Editor window border ';
   End;
End;


Procedure HelpRoutine(UnitCode : Byte; IdPtr : Pointer; HelpIndex : Word);
Begin
   AllowE0Codes := False;
   If not OpenHelp then
      Exit;
   Case UnitCode of
      HelpForPick  : If IdPtr = @ModemsAvailable     then HelpIndex := 71 Else
                     If IdPtr = @ColorsAvailable     then HelpIndex := 80 Else
                     If IdPtr = @BaudsAvailable      then HelpIndex := 94 Else
                     If IdPtr = @CharsAvailable      then HelpIndex := 75 Else
                     If IdPtr = @EmulationsAvailable then HelpIndex := 92 Else
                     If IdPtr = @CRAvailable         then HelpIndex := 95 Else
                     If IdPtr = @LFAvailable         then HelpIndex := 96 Else
                     If IdPtr = @SortAvailable       then HelpIndex := 97 Else
                     If IdPtr = @SBitsAvailable      then HelpIndex := 98 Else
                     If IdPtr = @DBitsAvailable      then HelpIndex := 99 Else
                     If IdPtr = @ParitysAvailable    then HelpIndex := 100 Else
                     If IdPtr = @SendFileName        then HelpIndex := HelpTopic Else

                     ;
      HelpForEdit  : ; {HelpIndex := 5;}
      HelpForEntry : ;
      HelpForMenu  : Case Integer(HelpIndex) of
                        {Alt-N/V}
                        221..225                 : HelpIndex := 87;

                        {Alt-N/V/T}
                        369, 372, 379..381, 384,
                        385, 393, 432, 424, 455  : HelpIndex := 85;

                        {Alt-N/M/C}
                        228..237, 454            : HelpIndex := 77;

                        {Alt-N/M/M}
                        239..249                 : HelpIndex := 76;

                        {Alt-N/M/P}
                        251..266                 : HelpIndex := 74;

                        {Alt-N/M/T}
                        368, 374, 375, 382,
                        376, 391, 392, 430       : HelpIndex := 86;

                        {Alt-N/D}
                        269..271, 426,
                        441..443, 447            : HelpIndex := 70;

                        {Alt-N/H}
                        273..284                 : HelpIndex := 69;

                        {Alt-N/P/externals}
                        67,287..345              : HelpIndex := 67;

                        {Alt-N/P/A/R}
                        348..350                 : HelpIndex := 65;

                        {Alt-N/P/A/T}
                        352..358                 : HelpIndex := 64;

                        {Alt-N/P/T}
                        389, 434..436, 438       : HelpIndex := 41;

                        {Alt-N/F}
                        360..365,446,451         : HelpIndex := 63;

                        {Alt-N/O/T}
                        371, 373, 377, 378, 383,
                        429, 448,
                        386                      : HelpIndex := 61;

                        {Alt-N/O/T/F}
                        431, 437, 440, 450       : HelpIndex := 102;

                        {Alt-N/O/R}
                        388,390, 427, 428, 444,
                        445                      : HelpIndex := 60;

                        {Alt-N/O/M}
                        395, 398, 399            : HelpIndex := 59;

                        {Alt-N/O/S}
                        401..406, 439            : HelpIndex := 58;

                        {Alt-N/O/D}
                        408..411                 : HelpIndex := 57;

                        {Alt-N/O/E}
                        412                      : HelpIndex := 92;

                        {Alt-N/O/C}
                        413..419,449             : HelpIndex := 49;

                        {Alt-N/E}
                        421..422                 : HelpIndex := 56;
                     End;
      HelpForEntry : ;
      HelpForMacEd : ;
   End;

   If HelpTopic = 59 then
      HelpTopic := 91;

   Case HelpTopic of
      60..68,
      133..140 : HelpTopic := 36;
   End;

   If ((HelpTopic <> 0) and (UnitCode = 0)) or (UnitCode = 2) then
      HelpIndex := HelpTopic;

   Push_Status;
   Display_Status (' F1-Topic Index    AltF1-Previous Topic   ESC-Exit ');
   {FastWrite(Long2Str(UnitCode)+'+'+Long2Str(HelpIndex),25,75,$4F);}
   PickMatrix := 2;
   If Not ShowHelp(HelpP, HelpIndex) then
      Begin
         FastWrite(Long2Str(UnitCode)+'+'+Long2Str(HelpIndex),25,75,$4F);
         If Not ShowHelp(HelpP, 1) then ;
      End;
   Pop_Status;
   CloseHelp(HelpP);
   PickMatrix := 1;
   AllowE0Codes := True;
End;


Function  OpenHelp : Boolean;
Var
   Status : Word;
Begin
   Status := OpenHelpFile(qq.Help_Path,
                          1,1,
                          24,2,
                          HelpColors,
                          HelpP);
   OpenHelp := (Status = 0);
   If Status <> 0 then
      Begin
         Case Status of
              2 : WritelnT ('Help file not found');
            100 : WritelnT ('Unexpected end of HLP file');
            106 : WritelnT ('HLP file is not a valid help file');
            203 : WritelnT ('Insufficient heap space for Help System');
            Else  WritelnT ('Help Init Error : '+Long2Str(Status));
         End;
      End;
End;



Procedure Push_Status;
{$IFDEF UseMouse}
Var
   mio : Boolean;
{$ENDIF}
Begin
   If (Save_Status_CNT < 10) then
      Begin
         {$IFDEF UseMouse}
         Mio := MouseInstalled and MouseCursorOn;
         If Mio then
            HideMouse;
         {$ENDIF}
         Inc(Save_Status_CNT);
         With SSC[Save_Status_CNT] do
            Begin
               c1 := 1;
               r1 := Real_Last_Row;
               c2 := Last_Col;
               r2 := Real_Last_Row;
            End;
         If not SaveWindow(1,Real_Last_Row,Last_Col,Real_Last_Row,True, Save_Status[Save_Status_CNT]) then ;
         {$IFDEF UseMouse}
         If Mio then
            ShowMouse;
         {$ENDIF}
      End;
End;

Procedure Pop_Status;
{$IFDEF UseMouse}
Var
   mio : Boolean;
{$ENDIF}
Begin
   If Save_Status_CNT > 0 then
      Begin
         {$IFDEF UseMouse}
         Mio := MouseInstalled and MouseCursorOn;
         If Mio then
            HideMouse;
         {$ENDIF}
         With SSC[Save_Status_CNT] do
            RestoreWindow(c1,R1,c2,r2,True, Save_Status[Save_Status_CNT]);
         Dec(Save_Status_CNT);
         {$IFDEF UseMouse}
         If Mio then
            ShowMouse;
         {$ENDIF}
      End;
End;

Procedure WindowSaveExit;
Begin
   FastText(' <Save> <Exit> ',WindowP(WPtr[Virt_Win_Ptr])^.YH+1,
                              WindowP(WPtr[Virt_Win_Ptr])^.XH-15);
End;

{$IFDEF UseMouse}
Procedure MouseToggleEntry(Row, Col, Attr : Byte; Num : Word);
Var
   S : String;
   mio : Boolean;
   x : Integer;
Begin
   If Scripting then Exit;
   Mio := MouseInstalled and MouseCursorOn;
   If Mio then
      HideMouse;
   For x := 1 to 2 do
      Begin
         ReadAttribute(Num, Row, Col, S);
         ChangeAttribute(Num, Row, Col, Attr);
         Delay(30);
         WriteAttribute(S, Row, Col);
         Delay(30);
      End;
   If Mio then
      ShowMouse;
End;
{$ENDIF}

Procedure SetWindowLow (r1,c1,r2,c2 : integer;
                        S : String;
                        atr1, atr2, atr3 : Word;
                        IsScroll : Boolean;
                        qcol : Word
                         );
{$IFDEF UseMouse}
Var
   Mio : Boolean;
{$ENDIF}
Begin
   {$IFDEF UseMouse}
   Mio := MouseInstalled and MouseCursorOn;
   If Mio then
      HideMouse;
   {$ENDIF}
   If Virt_Win_Ptr < 10 then
      Begin
         Inc(Virt_Win_Ptr);
         If MakeWindow (WPtr[Virt_Win_Ptr],r1,c1,r2,c2,
                       True,True,False,atr1,atr2,atr3, S) Then
            If DisplayWindow(WPtr[Virt_Win_Ptr]) then
               Begin
                  Push_Status;
                  If IsScroll then
                     FastWrite('',c2,r2-3,atr3);
                  TextAttr := Qcol;
               End;
       End;
   {$IFDEF UseMouse}
   LMouseR1 := r1;
   LMouseC1 := c1;
   LMouseR2 := r2;
   LMouseC2 := c2;
   If Mio then
      ShowMouse;
   {$ENDIF}
End;


Procedure SetWindow2 (r1,c1,r2,c2 : integer;  S : String; IsScroll : Boolean);
Begin
   SetWindowLow(r1,c1,r2,c2,
                S,
                qq.menu, qq.WindF, qq.WindF,
                IsScroll, qq.menu);
End;

Procedure SetWindow1(r1,c1, r2,c2, attr : integer;  S : String; IsScroll : Boolean);
Begin
   SetWindowLow(r1,c1,r2,c2,
                S,
                attr, attr, attr,
                IsScroll, attr);
End;


Procedure SetWindow3(r1,c1, r2,c2, attr : integer;  S : String);
Begin
   SetWindowLow(r1,c1,r2,c2,
                S,
                attr, attr, attr,
                False, attr);
End;


Procedure SetWindow4(r1,c1, r2,c2 : integer;  S : String);
{$IFDEF UseMouse}
Var
   Mio : Boolean;
{$ENDIF}
Begin
  {$IFDEF UseMouse}
   Mio := MouseInstalled and MouseCursorOn;
   If Mio then
      HideMouse;
  {$ENDIF}
   If Virt_Win_Ptr < 10 then
      Begin
         Inc(Virt_Win_Ptr);
         If MakeWindow (WPtr[Virt_Win_Ptr],r1,c1,r2,c2, True,True,False,
                       qq.Qcolor1[BodyColor],
                       qq.Qcolor1[FrameColor],
                       qq.Qcolor1[FrameColor],
                       S) Then
            If DisplayWindow(WPtr[Virt_Win_Ptr]) then
               Begin
                  Push_Status;
                  TextAttr := qq.Menu;
               End;
      End;
  {$IFDEF UseMouse}
   If Mio then
      ShowMouse;
  {$ENDIF}
End;

Procedure Restore_Screen;
{$IFDEF UseMouse}
Var
   Mio : Boolean;
{$ENDIF}
Begin
   {$IFDEF UseMouse}
   Mio := MouseInstalled and MouseCursorOn;
   If Mio then
      HideMouse;
   {$ENDIF}
   If Virt_Win_Ptr > 0 then
      Begin
         Dec(Virt_Win_Ptr);
         DisposeWindow(EraseTopWindow);
         Pop_Status;
      End;
   {$IFDEF UseMouse}
   If Mio then
      ShowMouse;
   {$ENDIF}
End;


Function KeyPressed : Boolean;
Begin
   KeyPressed := TpCrt.KeyPressed or (KeyQueueHead <> NIL);
End;



Procedure StuffQueueKey(W : Word);
Var
   q : KeyPointer;
Begin
   If MemAvail < LongInt(5000) then
      Exit;
   New(q);
   q^.TheKey := W;
   q^.Next := NIL;
   If KeyQueueTail <> NIL then
      KeyQueueTail^.Next := q;
   KeyQueueTail := q;
   If KeyQueueHead = NIL then
      KeyQueueHead := q;
End;



Function NextQueueKey(Var W : Word) : Boolean;
Var
   q : KeyPointer;
Begin
   NextQueueKey := False;
   If KeyQueueHead <> NIL then
      Begin
         W := KeyQueueHead^.TheKey;
         q := KeyQueuehead;
         KeyQueueHead := KeyQueueHead^.Next;
         If KeyQueueHead = NIL then
            KeyQueueTail := NIL;
         Dispose(q);
         NextQueueKey := True;
      End;
End;


Function NewReadKey : Word;
Var
   Key : Word;
Label
   Jump;
Begin
   If NextQueueKey(Key) then
      Goto Jump;

   {$IFDEF UseMouse}
      repeat until TPCrt.KeyPressed or MousePressed;

      If MouseInstalled then
         Key := ReadKeyOrButton
      Else
         Key := ReadKeyWord;
   {$ELSE}
      Key := ReadKeyWord;
   {$ENDIF}

   Jump:
   {FastWrite(HexW(Key),1,77,$1E);}

   Case Key of

      {$IfDef GG}
         PgUp,PgDn,
         Home,EndKey,Ins,Del,
      {$EndIf}

       Up,Down,Left,Right  : {If qq.KeypadEmuls = 'Y' then
                                ExtendedChar := KeyPad
                             Else }
                                ExtendedChar := X00_Extended;
       ShUp,ShDown,ShLeft,ShRight,ShHome,ShEnd,
       ShPgUp,ShPgDn,ShIns,ShDel,ShPad5         : ExtendedChar := KeyPad;

      {$IfNDef GG}
         PgUp,PgDn,
         Home,EndKey,Ins,Del,
      {$EndIf}

       F1, ShF1,  CtrlF1,  AltF1,
       F2, ShF2,  CtrlF2,  AltF2,
       F3, ShF3,  CtrlF3,  AltF3,
       F4, ShF4,  CtrlF4,  AltF4,
       F5, ShF5,  CtrlF5,  AltF5,
       F6, ShF6,  CtrlF6,  AltF6,
       F7, ShF7,  CtrlF7,  AltF7,
       F8, ShF8,  CtrlF8,  AltF8,
       F9, ShF9,  CtrlF9,  AltF9,
      F10, ShF10, CtrlF10, AltF10,
      F11, ShF11, CtrlF11, AltF11,
      F12, ShF12, CtrlF12, AltF12,

      CtrlUp,AltUp,CtrlDown,AltDown,
      CtrlLeft,AltLeft,CtrlRight,AltRight,
      CtrlHome,AltHome,CtrlEnd,AltEnd,
      CtrlPgUp,AltPgUp,CtrlPgDn,AltPgDn,
      CtrlIns,AltIns,CtrlDel,AltDel,Pad5,
      CtrlPad5,AltPad5,AltMinus,AltPlus,
      CtrlPadMinus,AltPadMinus,CtrlPadPlus,AltPadPlus,
      CtrlPadStar,AltPadStar,CtrlPadSlash,AltPadSlash,
      CtrlPadEnter,
      AltA,AltB,AltC,AltD,AltE,AltF,
      AltG,AltH,AltI,AltJ,AltK,AltL,
      AltM,AltN,AltO,AltP,AltQ,AltR,
      AltS,AltT,AltU,AltV,AltW,AltX,
      AltY,AltZ,
      Alt1,Ctrl2,Alt2,Alt3,Alt4,Alt5,
      Alt6,Alt7,Alt8,Alt9,Alt0,
      ShTab,CtrlTab,AltTab,AltEnter,AltEsc   : ExtendedChar := x00_Extended;

      GreyUp,GreyDown,GreyLeft,GreyRight,
      GreyCtrlLeft,GreyCtrlRight,GreyHome,
      GreyCtrlHome,GreyEndKey,GreyCtrlEnd,
      GreyPgUp,GreyCtrlPgUp,GreyPgDn,
      GreyCtrlPgDn,GreyIns,GreyDel           : ExtendedChar := xE0_Extended;

      Else                                     ExtendedChar := Normal;

   End;

   If not Doorway then
      If Hi(Key)=$0E then
         Begin
            If qq.BS_DEL_Swap = 'Y' Then
               Key := $0E7F
            Else
               Key := $0E08;
         End;

   {$IFDEF UseMouse}
   If Hi(Key) in [$E9..$EF] then
      Begin
         Case Key of
            $EF00 : Key := Enter;
            $EE00 : Key := Esc;
         End;
      End;
   {$ENDIF}

   NewReadKey := Key;

   If InternalHelp then
      If (HelpTopic <> 0) and (Key = F1) then
         Begin
            {Invoke the correct Help Process with value of HelpTopic}
            HelpRoutine(0, Nil, HelpTopic);
            NewReadKey := 0;
         End;
End;


Function ReadKeyA : Word;
Begin
   ReadKeyA := NewReadKey;
End;


Function ReadKeyNoGrey : Word;
Var
   W : Word;
Begin
   W := NewReadKey;
   If ExtendedChar = xE0_Extended Then
      Begin
         W := W and $FF00;
         ExtendedChar := x00_Extended;
      End;
   ReadkeyNoGrey := W;
End;


Function ReadKeyNoGreyNoHelp : Word;
Var
   W : Word;
Begin
   InternalHelp := False;
   W := NewReadKey;
   If ExtendedChar = xE0_Extended Then
      Begin
         W := W and $FF00;
         ExtendedChar := x00_Extended;
      End;
   ReadkeyNoGreyNoHelp := W;
   InternalHelp := True;
End;


Begin
   InternalHelp := True;
   Do_Graphics := False;
   HelpTopic := 0;
   KeyQueueHead    := Nil;
   KeyQueueTail    := Nil;
End.
