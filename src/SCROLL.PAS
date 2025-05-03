Unit Scroll;

Interface

Uses
   Dos,      Qmem,
   TpCrt,    Initial,
   Comm,     Comm2,
   Screen,   Procs,
   Group1,   Group02,
   Constant, OpKey,
   Files,    TPString;


Procedure Back_Scroll;


Implementation

   Procedure Back_Scroll;
   Var
      Current,
      tos, Bos, p,
      real_last      : Scroll_Ptr;
      CH, Ch1        : Char;
      exit1, Endd    : Boolean;
      x, y, x2       : Integer;

      Procedure Show_queue;
      Var
         Hold_Queue_Bytes : Integer;
         XoffSent      : Boolean;
      Begin
         Hold_Queue_Bytes := -1;
         Xoffsent := False;
         HiddenCursor;
         Repeat
            If Queue_Bytes <> Hold_Queue_Bytes Then
               Begin
                  FastWrite(Pad(Long2Str(Queue_Bytes),2),Real_Last_Row,74 + ((Last_Col - 80) Div 2), qq.StatusLineColor);
                  Hold_Queue_Bytes := Queue_Bytes;
                  If Queue_Bytes + Buffer_Low1 > recv_buf_size Then
                     Begin
                        If Xon_Xoff then
                           Begin
                              If not XoffSent then
                                 Write_Byte(^S);
                              XoffSent := True;
                           End;
                        Buffer_full := True;
                     End;
               End;
         Until Keypressed;
      End;

      Procedure PutAt(Row, Col : Integer; T : Scroll_Ptr);
      Begin
         FastText(t^.TxtL, row,col);
         WriteAttribute(t^.Attl,row,col);
      End;

      Procedure Show_Page(q : Scroll_Ptr);
      Var
         x : Integer;
      Begin
         For x := 1 To PRLR Do
            Begin
               PutAt(x, 1, q);
               q := q^.Next;
            End;
      End;

      Procedure scroll_back_1;
      Begin
         If tos = ScrollFirst Then Exit;
         Bos := Bos^.prev;
         tos := tos^.prev;
         Show_Page(Tos);
         If tos = ScrollFirst Then Beep;
      End;

      Procedure scroll_forward_1;
      Begin
         If Bos = ScrollLast Then Exit;
         Bos := Bos^.Next;
         tos := tos^.Next;
         Show_Page(Tos);
         If Bos = ScrollLast Then Beep;
      End;

      Procedure Home_Page;
      Var
         x : Integer;
      Begin
         If tos = ScrollFirst Then Exit;
         Tos := ScrollFirst;
         Bos := ScrollFirst;
         For x := 1 To pred(PRLR) Do
            Bos := Bos^.Next;
         Show_Page(Tos);
      End;

      Procedure End_Page;
      Var
         x : Integer;
      Begin
         If Bos = ScrollLast Then Exit;
         Tos := ScrollLast;
         For x := 1 To pred(PRLR) Do
            tos := tos^.prev;
         Bos := ScrollLast;
         Show_Page(tos);
      End;

      Procedure Go_Back_Page;
      Begin
         If Tos = ScrollFirst Then Exit;
         For x1 := 1 To PRLR Do
            Begin
               Bos := Bos^.Prev;
               Tos := Tos^.Prev;
               If Tos = ScrollFirst Then
                  Begin
                     Show_Page(Tos);
                     Beep;
                     Exit;
                  End;
            End;
         Show_Page(Tos);
      End;

      Procedure Go_Forward_Page;
      Begin
         If Bos = ScrollLast Then Exit;
         For x1 := 1 To PRLR Do
            Begin
               Bos := Bos^.Next;
               Tos := Tos^.Next;
               If Bos = ScrollLast Then
                  Begin
                     Show_Page(Tos);
                     Beep;
                     Exit;
                  End;
            End;
         Show_Page(Tos);
      End;

      Procedure Save_Buffer;
      Var
         TempF, Temp    : String;
         tmp            : Scroll_Ptr;
         x              : Integer;
      Begin
         NormalCursor;
         TempF := Get_File_Name('', Scroll_Sav, '', 12,
                                'Scroll Back Capture File Allocation',True);
         If TempF = '' Then Exit;
         Display_Status(' Saving ');
         If Test_Create_And_Keep(TempF) then
            Begin
               Assign(Screen_File, TempF);
               Append(Screen_File);
               If TimeDateStamper(Screen_File) Then
                  Begin
                     tmp := ScrollFirst;
                     Repeat
                        Temp := TrimTrail(tmp^.txtL);
                        WriteLn(Screen_File, Temp);
                        IO := IoResult;
                        If IO <> 0 Then
                           Begin
                              Writelnt('Error Saving to ' + TempF);
                              HiddenCursor;
                              Close(Screen_File);
                              Exit;
                           End
                        Else
                           tmp := tmp^.Next;
                     Until tmp = Nil;
                     Write(Screen_File, ^z);
                     Close(Screen_File);
                     IO := IoResult;
                  End
               Else
                  Begin
                     Close(Screen_File);
                     Exit;
                  End
            End;
         HiddenCursor;
      End;


      Function Not_Full_Screen(Var x : Integer) : Boolean;
      Var
         P : Scroll_Ptr;
      Begin
         P := ScrollLast;
         x := 0;
         While (x <= PRLR) And (P <> Nil) Do
            Begin
               Inc(x);
               P := P^.prev;
            End;
         Not_Full_Screen := (x <= PRLR);
      End;

      Procedure BotMsg;
      Var
         S : String;
         x : Integer;
      Begin
         S := ' SCROLL-BACK  ';
         If Not_Full_Screen(x) then
            s := s +          '             '
         Else
            Begin
               If tos = ScrollFirst then
                  s := s +    '       PgDn '
               else
                  if bos = ScrollLast then
                     s := s + '  PgUp      '
                  Else
                     s := s + ' PgUp PgDn ';
            End;
         s := s + '  F1-Help  S-Save  C-Clear  ESC-Exit  Queue      ';
         Display_Status(s);
      End;

Var
   sbflag : Boolean;

   Begin
      If ScrollFirst = ScrollLast Then
         Begin
            Writelnt('No Scroll Back Data!');
            Exit;
         End;
      Save_Screen(1, 1, Last_Col, PRLR);
      HiddenCursor;
      Real_Last := ScrollLast;
      If MemAvail > 6000 then
         Begin
            Sbflag := True;
            Inc(qqMaxScrollHeap, 6000);
         End
      Else
         sbflag := False;

      Add_New_Screen;  {to the scroll back buffer}

      Bos := ScrollLast;
      tos := ScrollLast;
      Set_Full_Window;
      HelpTopic := 72;
      If Not_Full_Screen(y) Then { Show the full page and quit }
         Begin
            If Bos <> Nil Then
               Repeat
                  PutAt(y, 1, Bos);
                  Bos := Bos^.prev;
                  Dec(y);
               Until Bos = Nil;
            exit1 := False;
            Repeat
               BotMsg;
               Show_queue;
               CH := Char(ReadKeyA);
               If ExtendedChar = Normal Then
                  Case Upcase(Ch) Of
                     'S' : Save_Buffer;
                     'C' : Begin
                              Clear_All_ScrollBack;
                              exit1 := True;
                           End;
                     #27 : exit1 := True;
                  End;
            Until exit1;
         End
      Else
         Begin
            Bos := Nil;
            End_Page;
            Endd := False;
            Repeat
               BotMsg;
               Show_queue;
               CharWord := ReadKeynoGrey;
               Case CharWord of
                  PgUp   : Go_Back_Page;
                  PgDn   : Go_Forward_Page;
                  Up     : scroll_back_1;
                  Down   : scroll_forward_1;
                  Home   : Home_Page;
                  EndKey : End_Page;
                  Else
                     Case UpCase(Char(CharWord)) Of
                        'S' : Save_Buffer;
                        'C' : Begin
                                 Clear_All_ScrollBack;
                                 Endd := True;
                              End;
                        #27 : Endd := True;
                     End;
               End;
            Until Endd;
         End;
      While (ScrollLast <> Real_Last) and (ScrollLast <> NIL) do
         Begin
            p := ScrollLast^.prev;                    { set p to previous node }
            FreeScrollHeap(SizeOf(ScrollLast^));      { Free heap counter      }
            FreeMem(ScrollLast, SizeOf(ScrollLast^)); { release the memory     }
            ScrollLast := p;                          { set last to prev node  }
            ScrollLast^.Next := nil;
         End;

      If SBflag then
         Dec(qqMaxScrollHeap, 6000);

      Restore_Screen;
      If Buffer_full Then
         Begin
            If Xon_Xoff Then
               Write_Byte(^Q);
         End;
   End;

End.
