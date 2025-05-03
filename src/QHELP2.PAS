Unit Qhelp2;

Interface

Uses
   TpCrt,     tpstring,  tpwindow,  Initial,
   Comm,      Procs,     Screen,    Comm2,
   Group1,    Scripts,   Emuls,     FKeys,
   QDial,     Downld,    Upld,      OpKey,
   {$IFDEF UseMouse} TpMouse,{$ENDIF}
   Button,    Constant,  Group02;


Procedure HLPmenu;


Implementation

Uses
   Key;


   Procedure HLPmenu;
   Var
      Col, Row, x    : Integer;
      Done, flip     : Boolean;
      aa             : Word;

      Procedure msg1;
      Begin
         Display_Status(' Select a Command    F1-Help    ESC-Return to TERMINAL Mode ');
      End;

      Procedure Ask_For_More_Help;
      Var
         CharWord : Word;
      Begin
         Display_Status(' Alt Key-Function you would like more Help with   ESC-Exit ');
         Repeat
            CheckForAButton(True);
         Until Keypressed;

         CharWord := ReadKeyNoGrey;
         Msg1;
         Case CharWord of
            $4700, $7700, $4900, $7500, $5100, $3B00, $5400, $5E00,
            $6800, $3D00, $5600, $6000, $6A00, $3F00, $5800, $6200,
            $6C00, $4100, $5A00, $6400, $6E00, $4300, $5C00, $6600,
            $7000, $3C00, $5500, $5F00, $6900, $4800, $1200, $7A00,
            $3E00, $5700, $6100, $6B00, $4000, $5900, $6300, $6D00,
            $4200, $5B00, $6500, $6F00, $4400, $5D00, $6700, $7100,
            $0F00, $1E00, $2E00, $2200, $1700, $2500, $3200, $3000,
            $2000, $2100, $2300, $2400, $2600, $3100, $1800, $1900,
            $1000, $1300, $1F00, $1400, $1600, $2F00, $1100, $2D00,
            $1500, $2C00, $7800, $7900, $7B00, $7C00, $7F00, $8000,
            $8100, $8200, $8300, Alt7,  $8500, $8600, $8700, $8800,
            $8900, $8A00, $8B00, $8C00, $7D00
            : Begin
                 Case CharWord of
                    $5400..$7100 : CharWord := $3C00;
                 End;
                 If CharWord = $3100 then
                    CharWord := $5400;
                 If CharWord = $7D00 then
                    CharWord := $5900;
                 HelpTopic := Hi(CharWord);
                 HelpRoutine(0,Nil,0);
                 HelpTopic := 0;
                 aa := 0;
              End;
         End;
      End;




   Begin                          {HLPmenu}
      PushButtonList;
      HiddenCursor;
      Shadow := False;
      Setwindow2(1, 1, 80, 24, ' COMMAND MENU ',false);
      FastWrite(' '+_Qmodem_+' ' + version + ' ' + Compile_Date + ' ', 24, 20, qq.Windf);

      FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ BEFORE ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ', 2, 3, qq.Menu2);
      AddButton(2,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-D  Phone Book'    , $2000);
      AddButton(2,27,1,5,qq.Menu,qq.Menu2, 'Alt-G  Term Emulation', $2200);

      FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ DURING ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ' , 4, 3, qq.Menu2);
      AddButton(4,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-C  Clear Screen'  , $2E00);
      AddButton(5,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-F  Execute Script', $2100);
      AddButton(6,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-Q  QuickLearn'    , $1000);
      AddButton(7,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-S  Split Screen'  , $1F00);
      AddButton(8,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-T  Screen Dump'   , $1400);
      AddButton(9,2 ,1,5,qq.Menu,qq.Menu2, '      Scroll Back'   , $4800);
      AddButton(4,27,1,5,qq.Menu,qq.Menu2, '^Home  Capture File'  , $7700);
      AddButton(5,27,1,5,qq.Menu,qq.Menu2, '^End   Send BREAK'    , $7500);
      AddButton(6,27,1,5,qq.Menu,qq.Menu2, ' PgUp  Upload Files'  , $4900);
      AddButton(7,27,1,5,qq.Menu,qq.Menu2, ' PgDn  Download Files', $5100);

      FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ AFTER ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ', 11, 3, qq.Menu2);
      AddButton(11,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-H  Hangup Modem'    ,$2300);
      AddButton(11,27,1,5,qq.Menu,qq.Menu2, 'Alt-X  Exit '+_Qmodem_  ,$2D00);

      FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ SETUP ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'   , 14, 3, qq.Menu2);
      AddButton(14,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-A  Translate Table' ,$1E00);
      AddButton(15,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-J  Function Keys'   ,$2400);
      AddButton(16,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-K  Change COM Port' ,$2500);
      AddButton(14,27,1,5,qq.Menu,qq.Menu2, 'Alt-N  Configuration'   ,$3100);
      AddButton(15,27,1,5,qq.Menu,qq.Menu2, 'Alt-P  Change Baud Rate',$1900);

      FastWrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ DOS ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ'  , 19, 3, qq.Menu2);
      AddButton(19,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-L  Change Drive'    ,$2600);
      AddButton(20,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-O  Change Directory',$1800);
      AddButton(21,2 ,1,5,qq.Menu,qq.Menu2, 'Alt-R  DOS Shell'       ,$1300);
      AddButton(19,27,1,5,qq.Menu,qq.Menu2, 'Alt-V  View/Edit File'  ,$2F00);
      AddButton(20,27,1,5,qq.Menu,qq.Menu2, 'Alt-W  List Directory'  ,$1100);
      AddButton(21,27,1,5,qq.Menu,qq.Menu2, 'Alt-Y  Delete File'     ,$1500);

      FastWrite('ÄÄÄÄÄÄÄÄ TOGGLES ÄÄÄÄÄÄÄÄÄ', 2,  53, qq.Menu2);
      AddButton(2 ,52,1,5,qq.Menu,qq.Menu2, 'Alt-0  Session Log'     ,$8100);
      AddButton(3 ,52,1,5,qq.Menu,qq.Menu2, 'Alt-1  Backspace DEL/^H',$7800);
   If CurrentDisplay >= EGA Then
      AddButton(4 ,52,1,5,qq.Menu,qq.Menu2, 'Alt-2  80x25 (EGA/VGA)' ,$7900);
      AddButton(5 ,52,1,5,qq.Menu,qq.Menu2, 'Alt-3  Debug Status Info' ,$7A00);

   If CurrentDisplay >= EGA Then
      AddButton(6 ,52,1,5,qq.Menu,qq.Menu2, 'Alt-4  80x43/50 (EGA/VGA)',$7B00);

   {$IfNDef GG}
      AddButton(7 ,52,1,5,qq.Menu,qq.Menu2, 'Alt-5  Host Mode'         ,$7C00);
      AddButton(8 ,52,1,5,qq.Menu,qq.Menu2, 'Alt-6  Batch Entry Window',$7D00);
   {$EndIf}

      AddButton(9 ,52,1,6,qq.Menu,qq.Menu2, 'Alt-7  Status Line Info'  ,Alt7);
      AddButton(10,52,1,5,qq.Menu,qq.Menu2, 'Alt-8  Hi-Bit Strip'      ,$7F00);
      AddButton(11,52,1,5,qq.Menu,qq.Menu2, 'Alt-9  Printer Echo'      ,$8000);
      AddButton(12,52,1,5,qq.Menu,qq.Menu2, 'Alt-B  Beeps & Bells'     ,$3000);
      AddButton(13,52,1,5,qq.Menu,qq.Menu2, 'Alt-E  Half/Full Duplex'  ,$1200);
      AddButton(14,52,1,5,qq.Menu,qq.Menu2, 'Alt-I  Order Information' ,$1700);
      AddButton(15,52,1,5,qq.Menu,qq.Menu2, 'Alt-M  ANSI Music'        ,$3200);
      AddButton(16,52,1,5,qq.Menu,qq.Menu2, 'Alt-U  Scrollback Record' ,$1600);
      AddButton(17,52,1,5,qq.Menu,qq.Menu2, 'Alt-Z  XON/XOFF Flow Ctrl',$2C00);
      AddButton(18,52,1,5,qq.Menu,qq.Menu2, 'Alt-=  DoorWay Mode'      ,$8300);
      AddButton(19,52,1,5,qq.Menu,qq.Menu2, 'Alt--  Status Lines'      ,$8200);
      AddButton(20,52,1,5,qq.Menu,qq.Menu2, 'ShTab  CR/CRLF Mode'      ,$0F00);

      Done := False;

      MSG1;
      {$IFDEF UseMouse}
      If MouseInstalled and Not MouseCursorOn then
         ShowTheMouse;
      {$ENDIF}
      Repeat                      { Status displays }
         Repeat
            CheckForAButton(True);
            If (Queue_Bytes + Buffer_Low1 > recv_buf_size) Then
               If Not Buffer_full Then
                  Begin
                     If Xon_Xoff Then Write_Byte(^S);
                     Buffer_full := True;
                  End;
         Until Keypressed;

         aa := ReadKeyNoGrey;

         If Lo(aa) = 0 then
            Begin
               Done := False;
               Help_Last := True;
               Case Char(Hi(aa)) Of
                  #71 : ;         { Home       }
                  #59 : Ask_for_More_Help;
                  Else
                     Begin
                        Restore_Screen;
                        Shadow := True;
                        NormalCursor;
                        {$IFDEF UseMouse}
                        If MouseInstalled and MouseCursorOn then
                           HideTheMouse;
                        {$ENDIF}
                        Check_Key_Combo(Char(Hi(aa)));
                        Help_Last := False;
                        Done := True;
                     End
               End                {case}
            End
         Else
            If Char(Lo(aa)) In [#13, #27] Then
               Begin
                  Help_Last := False;
                  Done := True;
                  {$IFDEF UseMouse}
                  If MouseInstalled and MouseCursorOn then
                     HideTheMouse;
                  {$ENDIF}
                  Restore_Screen;
               End;
      Until Done;
      PopButtonList;
      NormalCursor;
      Shadow := True;
      If Buffer_full Then
         Begin
            If Xon_Xoff Then Write_Byte(^Q);
         End;
   End;                           {HLPmenu}
End.
