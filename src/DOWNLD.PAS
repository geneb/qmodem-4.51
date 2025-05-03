Unit Downld;

Interface

Uses Dos,       TpCrt,
     TPString,  Initial,
     Comm,      Comm2,
     Procs,     Group1,
     Downld0,   DownX,
     Screen,    Tpz,
     {$IFDEF UseMouse}
     TpMouse,
     {$ENDIF}
     Button,    Batch,
     DownY,     DownA,
     DownExt;


Procedure DownLoad(SFN : Str64;
                   CH,
                   Protocol : Char);


Implementation



   Procedure DownLoad(SFN            : Str64;
                      CH, Protocol   : Char);

   Var
      Internals, Externals : Set of Char;
      Mflag : Boolean;

   Begin                          { Procedure Downld }
      Externals := [];
      sFilename := SFN;
      Tot_K := 0;
      Effective_PCT := 0.0;
      Avg_BPS := 0.0;
      Stamp_Taken := False;
      CTS_Flag := False;
      Script_success := False;
      If qq.Downld_Path_S = '' then
         GetDir(0,Downld_Path);

      {$IfDef GG}

         Internals := [#13, #27, 'A', 'X'];
         wx := -5;
         dl2 := 6;

      {$Else}

         Internals := [#13, #27, 'A', 'X', 'C', 'R', 'O', 'Y', 'G', 'F', 'Z'];
         If CTS_ Then
            wx := 2
         Else
            Begin
               Internals := Internals - ['G', 'F'];
               wx := 0;
            End;

         For x := 1 To qq.Total_Xfers Do
            Externals := Externals + [qq.Xfer_select_chr[x]];

      {$Endif}

      If sFilename = '' Then
         sFilename := L_S_Filename;

      If Not (Scripting or Hosting) Then
         Begin
            {$IfNDef GG}
            If qq.Total_Xfers > 0 Then
               dl2 := 12 + qq.Total_Xfers + wx
            Else
            {$EndIf}
               dl2 := 11 + wx;

            Setwindow2(28, 1, 53, dl2, ' Download Protocols ',false);
            PushButtonList;
            {$IFDEF UseMouse}
            Mflag := MouseInstalled and MouseCursorOn;
            {$ENDIF}
            HelpTopic := 12;
            Display_Status(' LETTER-Select a Protocol for the File Transfer   ESC-Exit ');
            TextAttr := qq.menu2;
            GotoXY(13, 1);
            If Downld_Path <> '' Then Write(free_space(Upcase(Downld_Path[1])))
                                 Else Write(free_space(Default_Drive));

            FastWrite('Free Space', 2, 30, qq.Menu);

            If Not ('A' in Externals) then
               AddButton(2,2,1,1,qq.Menu,qq.Menu2, 'A - Ascii',    ord('A'))
            Else
               FastwriteWindow('Ascii',2,6,qq.menu2);
            If Not ('X' in Externals) then
               AddButton(3,2,1,1,qq.Menu,qq.Menu2, 'X - Xmodem',   ord('X'))
            Else
               FastwriteWindow('Xmodem',3,6,qq.menu2);

            {$IfNDef GG}

            If Not ('C' in Externals) then
               AddButton(4,2,1,1,qq.Menu,qq.Menu2, 'C - Xmodem CRC', ord('C'))
            Else
               FastwriteWindow('Xmodem CRC',4,6,qq.menu2);
            If Not ('R' in Externals) then
               AddButton(5,2,1,1,qq.Menu,qq.Menu2, 'R - Xmodem Relaxed', ord('R'))
            Else
               FastwriteWindow('Xmodem Relaxed',5,6,qq.menu2);
            If Not ('O' in Externals) then
               AddButton(6,2,1,1,qq.Menu,qq.Menu2, 'O - Xmodem-1K',   ord('O'))
            Else
               FastwriteWindow('Xmodem-1K',6,6,qq.menu2);
            If Not ('Y' in Externals) then
               AddButton(7,2,1,1,qq.Menu,qq.Menu2, 'Y - Ymodem Batch',   ord('Y'))
            Else
               FastwriteWindow('Ymodem Batch',7,6,qq.menu2);
            If Not ('Z' in Externals) then
               AddButton(8,2,1,1,qq.Menu,qq.Menu2, 'Z - Zmodem Batch',   ord('Z'))
            Else
               FastwriteWindow('Zmodem Batch',8,6,qq.menu2);
            If CTS_ Then
               Begin
                  If Not ('F' in Externals) then
                     AddButton(9, 2,1,1,qq.Menu,qq.Menu2, 'F - Xmodem-1K/G', ord('G'))
                  Else
                     FastwriteWindow('Xmodem-1K/G',9,6,qq.menu2);
                  If Not ('G' in Externals) then
                     AddButton(10,2,1,1,qq.Menu,qq.Menu2, 'G - Ymodem/G Batch', ord('G'))
                  Else
                     FastwriteWindow('Ymodem/G Batch',10,6,qq.menu2);
               End;

            {$Endif}

            {$IFDEF UseMouse}
            If MouseInstalled then
               AddButton(dl2-1,15,2,2,qq.WindF, qq.WindF, '<F1=Help>',$3B00);
            {$ENDIF}

            {$IfNDef GG}
            If qq.Total_Xfers > 0 Then
               Begin
                  FastWrite('突様様様 External 様様様裕',10 + wx, 28, qq.Windf);
                  For x := 1 To qq.Total_Xfers Do
                     AddButton(9+wx+x,2,1,1,qq.Menu,qq.Menu2,
                               qq.Xfer_select_chr[x]+' - '+qq.xfer_label[x],
                               ord(qq.Xfer_select_chr[x]));
                  GotoXY(1,10 + wx + qq.Total_Xfers);
               End
            Else
            {$EndIf}
               GotoXY(1, 9 + wx);
            TextAttr := qq.Menu;
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  MouseWindow(28, 1, 53, dl2);
                  If not Mflag then
                     ShowTheMouse;
               End;
            {$ENDIF}
            Write(' Your Choice ? ');
            Write(Protocol + #8);
            Repeat
               CheckForAButton(True);
               If KeyPressed then
                  Ch := Upcase(Char(ReadKeyA));
            Until CH In Internals+Externals;
            If CH = #13 Then
               CH := Protocol;
            PopButtonList;
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  FullMouseWindow;
                  If not Mflag then
                     HideTheMouse;
               End;
            {$ENDIF}
            Restore_Screen;
         End;
      If (CH <> #27) And (CH <> ' ') Then
         Begin
            Push_window;
            xpr := Upcase(CH);
            ShowPct := False;
            HelpTopic := 0;
            Check_Parity;
            OnOffXferState := Online;
            CH := Upcase(Ch);
            If CH in Externals then
               Download_External(CH,Not (Scripting or Hosting))
            Else
               Case CH Of
                  'A' : Begin
                           Restore_Screen;
                           Pop_window;
                           Reset_Parity;
                           Download_ascii;
                           Reset_Parity;
                           NormalCursor;
                           Exit;
                        End;
                  'X' : Download_Xmodem(False, False, False, False);
                  {$IfNDef GG}
                  'C' : Download_Xmodem(True,  False, False, False);
                  'R' : Download_Xmodem(False, True,  False, False);
                  'O' : Download_Xmodem(False, False, True,  False);
                  'F' : Download_Xmodem(False, False, True,  True );
                  'Y' : Download_Ymodem(False, False);  { Relaxed, G mode }
                  'G' : Download_Ymodem(False, True);   { Relaxed, G mode }
                  'Z' : OK := Zmodem_Receive(False);
                  {$EndIf}
               End;
            Reset_Parity;
            Restore_Screen;
            Pop_window;
         End;
      NormalCursor;
   End;

End.
