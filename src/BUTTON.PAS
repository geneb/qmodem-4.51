Unit Button;

{$I TpDefine.Inc}

Interface

Uses
   TpCrt,
   {$IFDEF UseMouse}
   TpMouse,
   {$ENDIF}
   Screen,
   TPString;

Type
   {This is the linked list of currently active buttons.}
   OneButton      = ^OneButtonPtr;
   OneButtonPtr   = Record
                       Row, Col : Byte;       {beginning of Button}
                       Msg      : String[32]; {text of the button}
                       ScanCode : Word;       {scancode to return when pressed}
                       Next     : OneButton;  {next button in list}
                    End;

   {This is the linked list of all button lists}
   ButtonLinkedList  = ^AllButtonListsPtr;
   AllButtonListsPtr = Record
                          BLL  : OneButton;
                          Prev,
                          Next : ButtonLinkedList;
                       End;

Var
   Buttons    : OneButton;
   ButtonList : ButtonLinkedList;



Procedure ClearAllButtons;
Procedure PushButtonList;
Procedure PopButtonList;
Procedure AddButton(Row,Col,Pos,Len,Attr1,Attr2 : Byte; Msg : String; SC : Word);
Function  IsButton(Row, Col: Byte; Flash : Boolean; Var SC : Word) : Boolean;
Procedure CheckForAButton(Flash : Boolean);


Implementation


Procedure CheckForAButton(Flash : Boolean);
Var
   Mtimes : Word;
   SC,SC2 : Word;
Begin
   SC := 0;
   {$IFDEF UseMouse}
   If MouseInstalled then
      If MousePressed then
         Begin
            Mtimes := MouseKeyWord;
            If Mtimes = $EF00 then
               Begin
                  If IsButton(MouseWhereY-1, MouseWhereX-1, Flash, SC2) then
                     Begin
                        SC := SC2;
                     End;
               End
            Else
               If MTimes = $EE00 then
                  SC := 27
               Else
                  If MTimes = $ED00 then
                     SC := $3B00;
         End;
   {$ENDIF}
   If SC <> 0 then
      StuffQueueKey(SC);
End;

Procedure ClearAButtonList(TheButton : OneButton);
          {Internal routine to clear a Button Linked List}
Var
   p1 : OneButton;
Begin
   While TheButton <> NIL do
      Begin
         p1 := TheButton^.Next;
         Dispose(TheButton);
         TheButton := p1;
      End;
End;


Procedure ClearAllButtons;
Var
   p1 : OneButton;
   p2 : ButtonLinkedList;
Begin
   While ButtonList <> NIL do
      Begin
         p2 := ButtonList^.Next;
         ClearAButtonList(ButtonList^.BLL);
         Dispose(ButtonList);
         ButtonList := p2{NIL};
      End;
End;


Procedure PushButtonList;
Var
   p1 : ButtonLinkedList;
Begin
   New(p1);
   If ButtonList = NIL then
      p1^.prev := NIL
   Else
      Begin
         p1^.prev := ButtonList;
         ButtonList^.next := p1;
      End;
   ButtonList := p1;
   ButtonList^.BLL  := NIL;
   ButtonList^.next := NIL;
   Buttons := NIL;   {current list is now empty}
End;


Procedure PopButtonList;
Var
   p2 : ButtonLinkedList;
Begin
   If ButtonList <> NIL Then
      Begin
         p2 := ButtonList^.prev;
         ClearAButtonList(ButtonList^.BLL);
         Dispose(ButtonList);
         ButtonList := p2;
      End;
End;


Procedure AddButton(Row,Col,Pos,Len,Attr1,Attr2 : Byte; Msg : String; SC : Word);
Var
   p1, p2 : OneButton;
Begin
   New(p1);
   p1^.Row      := Row;
   p1^.Col      := Col;
   p1^.Msg      := Msg;
   p1^.ScanCode := SC;
   p1^.next     := NIL;
   If ButtonList^.BLL = NIL then
      ButtonList^.BLL := p1
   Else
      Begin
         p2 := ButtonList^.BLL;
         While p2^.next <> NIL do
            p2 := p2^.next;
         p2^.next := p1;
      End;
   FastWriteWindow(Msg,Row,Col,Attr2);
   ChangeAttributeWindow(Len,Row,Col+Pos-1,Attr1);
End;


Function  IsButton(Row, Col: Byte; Flash : Boolean; Var SC : Word) : Boolean;
Var
   p1 : OneButton;
   S : String[32];
   x : Integer;
   VisiMouse : Boolean;
Begin
   If ButtonList^.BLL = NIL then
      Begin
         {No Buttons defined, return False}
         IsButton := FALSE;
         Exit;
      End;
   p1 := ButtonList^.BLL;
   While p1 <> NIL do
      Begin
         If (Row =  p1^.Row) and
            (Col >= p1^.Col) and
            (Col <  p1^.Col+Length(p1^.Msg)) then
            Begin
               SC := p1^.ScanCode;
               IsButton := TRUE;
               If Flash then
                  Begin
                     {$IFDEF UseMouse}
                     HideMouse;
                     {$ENDIF}
                     For x := 1 to 2 do
                        Begin
                           ReadAttributeWindow(Length(p1^.Msg), p1^.Row, p1^.Col, S);
                           ChangeAttributeWindow(Length(p1^.Msg), p1^.Row, p1^.Col, $0F);
                           Delay(30);
                           WriteAttributeWindow(S, p1^.Row, p1^.Col);
                           Delay(30);
                        End;
                     {$IFDEF UseMouse}
                     ShowMouse;
                     {$ENDIF}
                  End;
               Exit;
            End;
         p1 := p1^.next;
      End;
   IsButton := FALSE;
End;


Begin
   Buttons := NIL;    {no buttons in current list}
   ButtonList := NIL; {no lists of Buttons}
End.
