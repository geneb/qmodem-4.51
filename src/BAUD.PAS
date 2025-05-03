Unit Baud;

Interface

Uses
   Dos,      TpCrt,     TPString,

   {$IFDEF UseMouse}
      TpMouse,
   {$ENDIF}

   Initial,  Screen,    Comm,     Comm2,
   Procs,    Group1,    QDial,    Button;


Procedure Change_Baud(Cmds : String);


Implementation

   Procedure Change_Baud(Cmds : String);
   Label zzz;
   Type
      Headings       = (Sp, Pa, Db, Sb);
      Speed_Mode     = (s110,  s300,   s1200,  s2400,  s4800,
                        s9600, s19200, s38400, s57600, s115200);
      Parity_Mode    = (pEven, pOdd, pNone, pMark, pSpace);
      Data_Mode      = (dd7, dd8);
      Stop_Mode      = (ss1, ss2);
   Var
      Col_, Row_, x  : Integer;
      Save_Speed     : LongInt;
      Save_dbits,
      Save_Sbits     : Word;
      Save_Parity,
      Special_Ch,
      Ch,
      BaudRate       : Char;
      Curr_Head      : Headings;
      Curr_Speed     : Speed_Mode;
      Curr_Parity    : Parity_Mode;
      Curr_Data      : Data_Mode;
      Curr_Stop      : Stop_Mode;
      Special,
      MouseVisable   : Boolean;
      QLS            : String;

      Procedure Save_Settings;
      Begin
         Save_Speed := NewSpeed;
         If Save_Speed = 110   Then Curr_Speed := s110   Else
         If Save_Speed = 300   Then Curr_Speed := s300   Else
         If Save_Speed = 1200  Then Curr_Speed := s1200  Else
         If Save_Speed = 2400  Then Curr_Speed := s2400  Else
         If Save_Speed = 4800  Then Curr_Speed := s4800  Else
         If Save_Speed = 9600  Then Curr_Speed := s9600  Else
         If Save_Speed = 19200 Then Curr_Speed := s19200 Else
         If Save_Speed = 38400 Then Curr_Speed := s38400 Else
         If Save_Speed = 57600 Then Curr_Speed := s57600 Else
                                    Curr_Speed := s115200;
         Save_Parity := NewCparity;
         Case Save_Parity Of
            'E' : Curr_Parity := pEven;
            'O' : Curr_Parity := pOdd;
            'N' : Curr_Parity := pNone;
            'M' : Curr_Parity := pMark;
            'S' : Curr_Parity := pSpace;
         End;
         Save_dbits := NewDBits;
         Case Save_dbits Of
            7 : Curr_Data := dd7;
            8 : Curr_Data := dd8;
         End;
         Save_Sbits := NewSBits;
         Case NewSBits Of
            1 : Curr_Stop := ss1;
            2 : Curr_Stop := ss2;
         End;
      End;

      Procedure Set_Settings;
      Begin
         NewSpeed := Save_Speed;
         NewCparity := Save_Parity;
         NewDBits := Save_dbits;
         NewSBits := Save_Sbits;
      End;


      Procedure Show_Speed(speed : Speed_Mode);
      Begin
         {$IfDef Int14}
            If Int14 then
               Begin
                  {$IfDef Cross}
                  If Speed = s110 then
                     Speed := s19200;
                  {$EndIf}
                  {$IfDef Plus}
                  If Speed = s110 then
                     Speed := s19200;
                  {$EndIf}
               End;
         {$EndIf}
         Case speed Of
            s110   : Save_Speed := 110;
            s300   : Save_Speed := 300;
            s1200  : Save_Speed := 1200;
            s2400  : Save_Speed := 2400;
            s4800  : Save_Speed := 4800;
            s9600  : Save_Speed := 9600;
            s19200 : Save_Speed := 19200;
            s38400 : Save_Speed := 38400;
            s57600 : Save_Speed := 57600;
            s115200: Save_Speed := 115200;
         End;
      End;


      Procedure Show_Parity(parity : Parity_Mode);
      Begin
         Case parity Of
            pEven : Save_Parity := 'E';
            pOdd  : Save_Parity := 'O';
            pNone : Save_Parity := 'N';
            {$IfNDef Int14}
               pMark : Save_Parity := 'M';
               pSpace: Save_Parity := 'S';
            {$EndIf}
         End;
      End;

      Procedure Show_Dbits(dbits : Data_Mode);
      Begin
         Case dbits Of
            dd7 : Save_dbits := 7;
            dd8 : Save_dbits := 8;
         End;
      End;

      Procedure Show_Sbits(sbits : Stop_Mode);
      Begin
         Case sbits Of
            ss1 : Save_Sbits := 1;
            ss2 : Save_Sbits := 2;
         End;
      End;

      Procedure Show_Current_Selections;
      Begin
         Show_Speed(Curr_Speed);
         Show_Parity(Curr_Parity);
         Show_Dbits(Curr_Data);
         Show_Sbits(Curr_Stop);
         GotoXY(15,1);
         TextAttr := qq.menu2;
         Write('Port ');
         {$IfDef ISI}
         If qq.USE_ISI then
            write ('ISI')
         else
         {$EndIf}
            write ('COM');
         Write(qq.CommPort, '  ');         {4.2F!!}
         TextAttr := qq.Menu;
         Write(Save_Speed:6);
         Write(',', Save_DBITS, ',', Save_Parity, ',', Save_Sbits);
      End;

      Procedure Set_Menu_Letter(BaudRate : Char);
      Begin
         {$IfDef Int14}
            If Int14 then
               Begin
                   If BaudRate in ['A','H'..'J','M','O'] then
                      BaudRate := ' ';
               End;
         {$EndIf}
         Case BaudRate Of
            'A' : Begin
                     Curr_Speed := s110;
                     Save_Speed := 110;
                  End;
            'B' : Begin
                     Curr_Speed := s300;
                     Save_Speed := 300;
                  End;
            'C' : Begin
                     Curr_Speed := s1200;
                     Save_Speed := 1200;
                  End;
            'D' : Begin
                     Curr_Speed := s2400;
                     Save_Speed := 2400;
                  End;
            'E' : Begin
                     Curr_Speed := s4800;
                     Save_Speed := 4800;
                  End;
            'F' : Begin
                     Curr_Speed := s9600;
                     Save_Speed := 9600;
                  End;
            'G' : Begin
                     Curr_Speed := s19200;
                     Save_Speed := 19200;
                  End;
            'H' : Begin
                     Curr_Speed := s38400;
                     Save_Speed := 38400;
                  End;
            'I' : Begin
                     Curr_Speed := s57600;
                     Save_Speed := 57600;
                  End;
            'J' : Begin
                     Curr_Speed :=s115200;
                     Save_Speed :=115200;
                  End;
            'K' : Begin
                     Curr_Parity := pEven;
                     Save_Parity := 'E';
                     Set_Menu_Letter('P');
                  End;
            'L' : Begin
                     Curr_Parity := pOdd;
                     Save_Parity := 'O';
                     Set_Menu_Letter('P');
                  End;
            'N' : Begin
                     Curr_Parity := pNone;
                     Save_Parity := 'N';
                     Set_Menu_Letter('Q');
                  End;
            'M' : Begin
                     Curr_Parity := pMark;
                     Save_Parity := 'M';
                     Set_Menu_Letter('P');
                  End;
            'O' : Begin
                     Curr_Parity := pSpace;
                     Save_Parity := 'S';
                     Set_Menu_Letter('P');
                  End;
            'P' : Begin
                     Curr_Data := dd7;
                     Save_dbits := 7;
                  End;
            'Q' : Begin
                     Curr_Data := dd8;
                     Save_dbits := 8;
                  End;
            'R' : Begin
                     Curr_Stop := ss1;
                     Save_Sbits := 1;
                  End;
            'S' : Begin
                     Curr_Stop := ss2;
                     Save_Sbits := 2;
                  End;
         End;
         Case BaudRate Of
            'A'..'J' : Curr_Head := Sp;
            'K'..'O' : Curr_Head := Pa;
            'P'..'Q' : Curr_Head := Db;
            'R'..'S' : Curr_Head := Sb;
         End;
      End;

   Var
      Here : Integer;

   Begin
      Save_Settings;
      If Not Scripting Then
         Begin
            PushButtonList;
            Setwindow2(12, 7, 65, 17, ' Communications Port Setup ',false);

            {$IFDEF UseMouse}
            MouseVisable := MouseInstalled and MouseCursorOn;
            {$ENDIF}

            FastWrite('Speed             Parity      Data     Stop', 10, 20, qq.Menu);

            {$IfDef Int14}
               If Int14 then
                  Begin
                     AddButton(4,2 ,1,1,qq.Menu,qq.Menu2, 'A - n/a' ,Byte('A'));
                     AddButton(5,12,1,1,qq.Menu,qq.Menu2, 'G - n/a' ,Byte('G'));
                     AddButton(6,12,1,1,qq.Menu,qq.Menu2, 'H - n/a' ,Byte('H'));
                     AddButton(7,12,1,1,qq.Menu,qq.Menu2, 'I - n/a' ,Byte('I'));
                     AddButton(8,12,1,1,qq.Menu,qq.Menu2, 'J - n/a' ,Byte('J'));
                     {$IfDef Cross}
                        AddButton(5,12,1,1,qq.Menu,qq.Menu2, 'G - 19200' ,Byte('G'));
                     {$EndIf}
                     {$IfDef Plus}
                        AddButton(5,12,1,1,qq.Menu,qq.Menu2, 'G - 19200' ,Byte('G'));
                     {$EndIf}
                  End
               Else
                  Begin
                     AddButton(4,2 ,1,1,qq.Menu,qq.Menu2, 'A - 110'   ,Byte('A'));
                     AddButton(5,12,1,1,qq.Menu,qq.Menu2, 'G - 19200' ,Byte('G'));
                     AddButton(6,12,1,1,qq.Menu,qq.Menu2, 'H - 38400' ,Byte('H'));
                     AddButton(7,12,1,1,qq.Menu,qq.Menu2, 'I - 57600' ,Byte('I'));
                     AddButton(8,12,1,1,qq.Menu,qq.Menu2, 'J - 115200',Byte('J'));
                  End;
            {$Else}
               AddButton(4,2 ,1,1,qq.Menu,qq.Menu2, 'A - 110'   ,Byte('A'));
               AddButton(5,12,1,1,qq.Menu,qq.Menu2, 'G - 19200' ,Byte('G'));
               AddButton(6,12,1,1,qq.Menu,qq.Menu2, 'H - 38400' ,Byte('H'));
               AddButton(7,12,1,1,qq.Menu,qq.Menu2, 'I - 57600' ,Byte('I'));
               AddButton(8,12,1,1,qq.Menu,qq.Menu2, 'J - 115200',Byte('J'));
            {$EndIf}

            AddButton(5,2,1,1,qq.Menu,qq.Menu2,  'B - 300'   ,Byte('B'));
            AddButton(6,2,1,1,qq.Menu,qq.Menu2,  'C - 1200'  ,Byte('C'));
            AddButton(7,2,1,1,qq.Menu,qq.Menu2,  'D - 2400'  ,Byte('D'));
            AddButton(8,2,1,1,qq.Menu,qq.Menu2,  'E - 4800'  ,Byte('E'));
            AddButton(4,12,1,1,qq.Menu,qq.Menu2, 'F - 9600'  ,Byte('F'));

            AddButton(4,25,1,1,qq.Menu,qq.Menu2, 'K - Even' ,Byte('K'));
            AddButton(5,25,1,1,qq.Menu,qq.Menu2, 'L - Odd'  ,Byte('L'));
            {$IfDef Int14}
            If Int14 then
               Begin
                  AddButton(6,25,1,1,qq.Menu,qq.Menu2, 'M - n/a' ,Byte('M'));
                  AddButton(8,25,1,1,qq.Menu,qq.Menu2, 'O - n/a' ,Byte('O'));
               End
            Else
               Begin
                  AddButton(6,25,1,1,qq.Menu,qq.Menu2, 'M - Mark' ,Byte('M'));
                  AddButton(8,25,1,1,qq.Menu,qq.Menu2, 'O - Space',Byte('O'));
               End;
            {$Else}
               AddButton(6,25,1,1,qq.Menu,qq.Menu2, 'M - Mark' ,Byte('M'));
               AddButton(8,25,1,1,qq.Menu,qq.Menu2, 'O - Space',Byte('O'));
            {$EndIf}
            AddButton(7,25,1,1,qq.Menu,qq.Menu2, 'N - None' ,Byte('N'));

            AddButton(4,37,1,1,qq.Menu,qq.Menu2, 'P - 7' ,Byte('P'));
            AddButton(5,37,1,1,qq.Menu,qq.Menu2, 'Q - 8' ,Byte('Q'));

            AddButton(4,46,1,1,qq.Menu,qq.Menu2, 'R - 1' ,Byte('R'));
            AddButton(5,46,1,1,qq.Menu,qq.Menu2, 'S - 2' ,Byte('S'));

            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  AddButton(10,29,2,2,qq.WindF, qq.WindF, '<Exit>' ,27);
                  AddButton(10,36,2,2,qq.WindF, qq.WindF, '<Save>' ,13);
                  AddButton(10,43,2,2,qq.WindF, qq.WindF, '<F1=Help>' ,$3B00);
               End;
            {$ENDIF}

            HelpTopic := 25;
            Show_Current_Selections;
            Display_Status(' LETTER-Select a Parameter   ENTER-Save Changes   ESC-Exit ');
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  MouseWindow(12, 7, 65, 17);
                  If not MouseVisable then
                     ShowTheMouse;
               End;
            {$ENDIF}

            Repeat
               GotoXY(37,8);               {4.2F!!}
               Write ('Your choice : ');   {4.2F!!}

               Ch := ' ';
               Repeat
                  CheckForAButton(True);
                  If KeyPressed then
                     Ch := UpCase(Char(ReadKeyA));
               Until Ch In ['A'..'S', #13, #27];
               Set_Menu_Letter(Ch);
               Show_Current_Selections;
            Until Ch In [#13, #27];
            PopButtonList;
            {$IFDEF UseMouse}
            If MouseInstalled then
               Begin
                  FullMouseWindow;
                  If not MouseVisable then
                     HideTheMouse;
               End;
            {$ENDIF}
            If Ch = #27 Then GoTo zzz;
         End
      Else
         { Parse off characters...}
         For x := 1 To Length(Cmds) Do
            Set_Menu_Letter(Upcase(Cmds[x]));

      Set_Settings;

      DCE_Speed := Save_Speed;   {reset to a known value}

      If qq.baud_chng_before <> '' Then
         Parse_Write_Modem(qq.baud_chng_before);

      If QuickLearn then
         Begin
            qls := Long2Str(Save_Speed)+' '+Long2Str(Save_DBits)+' ';
            Case Save_Parity of
               'E' : qls := qls+'EVEN';
               'O' : qls := qls+'ODD';
               'N' : qls := qls+'NONE';
            End;
            qls := qls+' '+Long2Str(Save_SBits);
            WriteLearn('SetComm  '+qls);
         End;

      Init_Port;

      If qq.baud_chng_after <> '' Then
         Parse_Write_Modem(qq.baud_chng_after);

   zzz:
      If Not Scripting Then
         Restore_Screen;
   End;

End.
