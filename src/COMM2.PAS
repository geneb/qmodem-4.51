{$O-,F+,R-}
Unit Comm2;

Interface

Uses
   Dos,   TpCrt,    TpString,
   TpDos, TpInline, Screen,
   Files, Initial,  Comm,
   Procs, ApTimer;


Procedure Init_Port;
Procedure Check_For_CTS;
Procedure Check_Parity;
Procedure Reset_Parity;
Procedure Translate_In  (var Ch : char);
Procedure Translate_Out (var Ch : char);
Procedure SetSpeedMsg(S:String);
Procedure Break;
Procedure Set_DCE_Speed(Line:String);
Procedure Write_Byte(to_send : String);
Procedure Write_Byte2(Var to_send; num : Integer);
Procedure Write_Byte3(Var to_send; num : Integer);
Function  PeekPortByte(Var B : Byte) : Boolean;

Implementation


Function  PeekPortByte(Var B : Byte) : Boolean;
Begin
   PeekPortByte := False;  {assume Failed}
   If not Commpressed then
      Exit;
   B := Peek_COM;
   PeekPortByte := True;
End;



Procedure Check_for_CTS;
Var
   Ch : Char;
Begin
   {$IfDef Int14}
    If Int14 then
       Begin
          CTS_ := True;
          Exit;
       End;
   {$EndIf}
   If CTS_ then
      Begin
         CTS_ := Test_CTS(2);
         If not CTS_ then
            Begin
               SetWindow2(14,6,66,9,'',false);
               Writeln (' The CTS signal is down.  Waiting for CTS.');
               Write   (' Press any key to continue without CTS support > ');
               Repeat
                  CTS_ := Test_CTS(5);
               Until CTS_ or Keypressed;
               If Keypressed then
                  While KeyPressed do
                     Ch := ReadKey;
               Restore_Screen;
            End
      End;
End;


Procedure Init_Port;
Begin
   Init_la_Port;
   Check_for_CTS;
End;



Procedure Write_Byte2(Var to_send; num : Integer);
var
   block2   : Array[1..4096] of byte absolute to_send;
   b, x, x2 : Integer;
   ErrorCnt : Word;
   Tmp      : String;
Begin
   {$IfDef Int14}
      If Int14 then
         Begin
            For x := 1 to num do
               Begin
                  tmp := char(block2[x]);
                  Write_Byte(tmp);
               End;
            Exit;
         End;
   {$EndIf}

   {$IfDef ISI}
      If qq.Use_ISI then
         Begin
            While (Buffer_Size - BytesQueuedOut < num) do;
            Store_Block_Buf(Block2, Num);
            ISI_Read_Write_Data;
            Exit;
         End;
   {$EndIf}

   For b := 1 to num do
      Case CTS_ of
         True  : Begin
                    If not odd(Port[MSR_] shr 4) then
                       If not Test_CTS(300) then
                          Check_for_CTS;
                    While Not odd(Port[LSR_] shr 5) do;
                    Port[DLL_] := block2[b];
                 End;
         False : Begin
                    While Not odd(Port[LSR_] shr 5) do;
                    Port[DLL_] := block2[b];
                 End;
      End;
End;


Procedure Write_Byte3(Var to_send; num : Integer);
Var
   block2   : array[1..4096] of byte absolute to_send;
   b, x, x2 : Integer;
   tmp      : String;
Begin
   If Num = 0 then exit;

   {$IfDef Int14}
      If Int14 then
         Begin
            For x := 1 to num do
               Begin
                  tmp := char(block2[x]);
                  Write_Byte(tmp);
               End;
            Exit;
         End;
   {$Endif}

   {$IfDef ISI}
      If qq.Use_ISI then
         Begin
            While (Buffer_Size - BytesQueuedOut < num) do;
            Store_Block_Buf(Block2, Num);
            ISI_Read_Write_Data;
            Exit;
         End;
   {$EndIf}

   If not qq.UseHighSpeed then
      Write_Byte2(To_Send, Num)
   Else
      Begin
         x := BytesQueuedOut;
         While (Buffer_Size - BytesQueuedOut < num) do
            Begin
               Delay(10);
               If x = BytesQueuedOut then
                  If (CTS_ and odd(Port[MSR_] shr 4)) or not CTS_ then
                     Begin
                        Port[IER_] := Port[IER_] or 2;
                        Delay(20);
                     End;
            End;
         Store_Block_Buf(Block2, Num);
      End;
End;


Procedure Write_Byte(to_send : String);
Var
   b, x, x2     : Integer;
   ET           : EventTimer;
   CheckThePort : Boolean;
   Tmp          : Array [1..255] of byte;
Label
   Retry;
Begin
   If to_Send = '' then
      Exit;

   {$IfDef Int14}
      If Int14 then
         Begin
            CheckThePort := True;
            For x := 1 to Length(To_Send) do
               Begin
                  Retry:
                  NewTimerSecs(ET,300);
                  Repeat
                     RAH := 1;
                     RAL := Ord(To_Send[x]);
                     RDX := Int14ComPort;
                     Int14BIOS;
                  Until ((RAH < 128) and CheckThePort) or TimerExpired(ET);

                  If TimerExpired(ET) then
                     Begin
                        SetWindow2(14,6,66,9,'',false);
                        Writeln (' The PORT is unavailable.  Waiting for PORT.');
                        Write   (' Press any key to skip PORT check > ');
                        While Keypressed do
                           Ch := ReadKey;

                        Repeat
                           RAH := 3;
                           RDX := Int14ComPort;
                           Int14BIOS;
                           Delay(50);
                        Until ((RAH and $20) = $20) or Keypressed;

                        Restore_Screen;

                        If Keypressed then
                           Begin
                              CheckThePort := False;
                              While KeyPressed do
                                 Ch := ReadKey;
                           End
                        Else
                           Goto Retry;
                     End;
               End;
            Exit;
         End;
   {$Endif}
   Move(To_Send[1],tmp[1],Length(To_Send));
   Write_Byte3(tmp, Length(To_Send));
End;


Procedure SetSpeedMsg(S:String);
Begin
   If Not qq.LockDTE Then
      Begin
         If SearchLeftUC(S, '300')   > 0 Then set_baud(300) Else
         If SearchLeftUC(S, '1200')  > 0 Then set_baud(1200) Else
         If SearchLeftUC(S, '2400')  > 0 Then set_baud(2400) Else
         If SearchLeftUC(S, '4800')  > 0 Then set_baud(4800) Else
         If SearchLeftUC(S, '9600')  > 0 Then set_baud(9600) Else
         If SearchLeftUC(S, '19200') > 0 Then set_baud(19200) Else
         If SearchLeftUC(S, '38400') > 0 Then set_baud(38400) Else
         If SearchLeftUC(S, '57600') > 0 Then set_baud(57600) Else
         If SearchLeftUC(S, '115200') > 0 Then set_baud(115200) Else
         If SearchLeftUC(S, 'FAST')  > 0 Then set_baud(19200) Else
                                              set_baud(300);
      End;
End;


Procedure Set_DCE_Speed(Line:String);
Begin
   If Pos('57600' ,line) > 0 then DCE_Speed := 57600 else
   If Pos('38400' ,line) > 0 then DCE_Speed := 38400 else
   If Pos('19200' ,line) > 0 then DCE_Speed := 19200 else
   If Pos('14400' ,line) > 0 then DCE_Speed := 14400 Else
   If Pos('12000' ,line) > 0 then DCE_Speed := 12000 Else
   If Pos('9600'  ,line) > 0 then DCE_Speed := 9600  Else
   If Pos('7200'  ,line) > 0 then DCE_Speed := 7200  Else
   If Pos('4800'  ,line) > 0 then DCE_Speed := 4800  Else
   If Pos('2400'  ,line) > 0 then DCE_Speed := 2400  Else
   If Pos('1200'  ,line) > 0 then DCE_Speed := 1200  Else
   If Pos('300'   ,line) > 0 then DCE_Speed := 300   Else
   If Pos('FAST'  ,line) > 0 then DCE_Speed := 19200 else
                                  DCE_Speed := 300;
End;


Procedure Check_Parity;
Begin
   If Save_Comm then Exit;
   If NewDBits < 8 then
      Begin
         SaveDBits  := NewDBits;
         SaveParity := NewCparity;
         Save_Comm  := true;
         NewDBits   := 8;
         NewCparity := 'N';
         Init_Port;
      End;
End;


Procedure Reset_Parity;
Begin
   If Save_Comm then
      Begin
         NewDBits   := SaveDBits;
         NewCparity := SaveParity;
         Save_Comm  := False;
         Init_Port;
      End;
End;


Procedure Translate_In (var Ch : char);
Begin
   Ch := Char(qq.Xlate_table_In[Byte(Ch)]);
End;


Procedure Translate_Out (var Ch : char);
Begin
   Ch := Char(qq.xlate_table_Out[Byte(Ch)]);
End;


Procedure Break;
Var
   a, b : Byte;
Begin
   Break_Low;
   Clear_Buffer;
   Writelnb ('<<BREAK>>');
   Logit ('BREAK signal sent.');
End;


Begin
   Save_Comm := False;
End.
