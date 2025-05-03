{$O-,F+,R-}
Unit Comm;

Interface

Uses
   Dos,      TpCrt,     TpInt,   TpString,
   TpDos,    TpInline,  GiveBk,  QMem,
   ApTimer,  Initial;


Procedure Initialize_Comm_Vars;
Function  CommPressed : Boolean;
Function  Cinkeyz : Char;
Procedure Store_Block_Buf (Var Block2; Num: word);
Function  Test_CTS(SecondsToWait : Word) : Boolean;
Procedure Turn_Off_RTS;
Procedure Turn_On_RTS;
Procedure TurnOffFIFO;
Procedure TurnOnFIFO;
Procedure Clear_Buffer;
Procedure Clear_Buffer2;
Procedure OpenCom(ComPortx : byte;     Baud     : tBaud;
                  Parity   : tParity;  Databits : tDatabits;
                  Stopbits : tStopbits);
Procedure Init_la_Port;
Procedure Set_Baud (S : LongInt);
Procedure Term_Ready (State : Boolean);
Function  Online : Boolean;
Procedure Remove_Port;
Procedure Drop_DTR_Low;
Procedure Break_Low;
Procedure CloseCom (Shelled, RTS_UP, DTR_UP : Boolean);
Procedure Int14BIOS;

{$ifdef Int14}
   Procedure SetupInt1C;
   Procedure Int1CHandler;
{$endif}

Procedure GetIntVec2 (IntNo : Byte; Var Vector : Pointer);
Procedure ClearComCounters;
Procedure Asynch_Interrupt;
Function  Get_Ch (Var Ch : Char) : Boolean;
Function  Peek_COM : Byte;
Function  Peek_ISI : Byte;

{$ifdef ISI}
   Procedure ISI_Read_Write_Data;
   Procedure Initialize_ISI_Vars;
   Procedure ISI_Poll_Busy;
   Procedure ISI_Fiddle;
{$endif}


Var
   cExitSave : pointer;
   InUse     : Byte;
   ral, rah  : byte;
   rdx       : word;
   CurrentMCR,
   CurrentPICMSK,
   CurrentIER,
   CurrentLCR,
   CurrentDLM,
   CurrentDLL : Byte;
   CurrentInitSaved : Boolean;
   OtherMCRs,
   OtherMCRsChanged : Array [1..8] of Byte;


{$ifdef ISI}
Var
   ISI_Base0,
   ISI_Base1,
   ISI_Base2,
   ISI_Base3 : Word;
   ISI_Port,
   ISI_Command    : byte;
   ISI_CmdDone    : Boolean;
   ISI_Status     : byte;
   ISI_Control    : Byte;
   ISI_TX_Queue   : word;
   ISI_RX_Queue   : word;
Const
   FlipFlop : Byte = 0;
{$endif}


Implementation


Uses
   Screen, Procs;

   {$ifdef ISI}
      Procedure ISI_Out_to_Lunch;
      Var
         Ch : Char;
         x : Word;
      Begin
         SetWindow2(14,6,66,9,' Attention ',false);
         Writeln (' The ISI board is not responding.  Press any key');
         Write   (' to continue without ISI support > ');
         x := 0;
         Repeat
            Inc(x);
            Delay(100);
         Until Keypressed or (x >=50);
         If Keypressed then
            While KeyPressed do
               Ch := ReadKey;
         Restore_Screen;
      End;


      Procedure ISI_Poll_Busy;
      Var
         ISI_Type : Byte;
         x : Word;
      Begin
         If Not ISI_OK then
            Exit;
         {FastWrite(HexB(ISI_Command),Real_Last_Row,Last_Col-1,$07);}
         x := 0;
         DV_Begin_Critical;
         Repeat
            {Flipflop := succ(flipflop) and $0F;
            FastWrite('!',25,77,flipflop);}
            Inc(x);
            delay(1);
         Until ((Port[ISI_Base0] and 1) = 0) or
               (x > 4000);
         If x > 4000 then
            Begin
               ISI_Out_to_Lunch;
               ISI_OK := False;
            End;
      End;


      Procedure ISI_Fiddle; { Waiting for ISI_CmdDone to become TRUE}
      Var
         x : Word;
      Begin
         If Not ISI_OK then
            Exit;
         x := 0;
         Repeat
            {Flipflop := succ(flipflop) and $0F;
             FastWrite('F',25,76,flipflop);}
            Inc(x);
            Delay(1);
         Until ISI_CmdDone or
               (x > 4000);
         If x > 4000 then
            Begin
               ISI_Out_to_Lunch;
               ISI_OK := False;
            End;
         DV_End_Critical;
      End;


      Procedure ISI_Read_Write_Data;
      Var
         X,Loop1 : Word;
      Begin
         If not ISI_OK then
            Exit;
         If (BytesQueuedOut > 0) then {Check for outgoing}
            While (BytesQueuedOut > 0) do
            Begin
               ISI_CmdDone := False;
               ISI_Command := $10 + ISI_Port;

               ISI_Poll_Busy;
               Port[ISI_Base0] := ISI_Command;
               If BytesQueuedOut > 254 then
                  Port[ISI_Base0] := 254
               Else
                  Port[ISI_Base0] := BytesQueuedOut;
               Port[ISI_Base1] := ISI_Command;
               ISI_Fiddle;
               Delay(1);
            End;

         If Queue_Bytes > 16 then Exit;
         If (Buffer_Size - Queue_Bytes) > 512 then
            Begin
               For loop1 := 1 to 1 do
                  begin
                     {Check for Incoming Data}
                     ISI_CmdDone := False;
                     ISI_Command := $20 + ISI_Port;
                     ISI_Poll_Busy;
                     Port[ISI_Base0] := ISI_Command;
                     Port[ISI_Base0] := 255;
                     Port[ISI_Base1] := ISI_Command;
                     ISI_Fiddle;
                  End;
            End;
      End;
   {$endif}

   Function Get_Ch(Var Ch : Char) : Boolean;
   Var
      x : word;
   Begin
      x := 0;
      Repeat
         If not CommPressed then
            Begin
               inc(x);
               delay(90);
            End;
      Until CommPressed or (X = 10);
      If CommPressed then
         Begin
            Ch := Cinkeyz;
            Get_Ch := True;
         End
      Else
         Get_Ch := False;
   End;


Procedure Asynch_Interrupt; External;
Procedure GetIntVec2(IntNo : Byte; var Vector : Pointer); external;
{$L COM8250}

Procedure Asynch_Interrupt_16550; External;
Procedure GetIntVec2_16550(IntNo : Byte; var Vector : Pointer); external;
{$L COM16550}

{$ifdef ISI}
   Procedure Asynch_Interrupt_ISI; External;
   Procedure GetIntVec2_ISI(IntNo : Byte; var Vector : Pointer); external;
   {$L COMISI}
{$endif}


Procedure ClearComCounters;
Begin
   framingerrors := 0;
   parityerrors  := 0;
   overrunerrors := 0;
   u16550loops   := 0;
   lsrxxx        := 0;
   inttrips      := 0;
   lsrtrips      := 0;
   MSRtrips      := 0;
   ShareTrips    := 0;
End;


Procedure Initialize_Comm_Vars;
Begin
   ComBaseAddr[1] := qq.Base[1];
   ComBaseAddr[2] := qq.Base[2];
   ComBaseAddr[3] := qq.Base[3];
   ComBaseAddr[4] := qq.Base[4];
   ComBaseAddr[5] := qq.Base[5];
   ComBaseAddr[6] := qq.Base[6];
   ComBaseAddr[7] := qq.Base[7];
   ComBaseAddr[8] := qq.Base[8];

   ivIRQ[1] := qq.IRQ[1];
   ivIRQ[2] := qq.IRQ[2];
   ivIRQ[3] := qq.IRQ[3];
   ivIRQ[4] := qq.IRQ[4];
   ivIRQ[5] := qq.IRQ[5];
   ivIRQ[6] := qq.IRQ[6];
   ivIRQ[7] := qq.IRQ[7];
   ivIRQ[8] := qq.IRQ[8];

   If qq.IRQ[1] < 8 Then ivlist[1] := qq.IRQ[1] + 8
                    Else ivlist[1] := qq.IRQ[1] + 104;
   If qq.IRQ[2] < 8 Then ivlist[2] := qq.IRQ[2] + 8
                    Else ivlist[2] := qq.IRQ[2] + 104;
   If qq.IRQ[3] < 8 Then ivlist[3] := qq.IRQ[3] + 8
                    Else ivlist[3] := qq.IRQ[3] + 104;
   If qq.IRQ[4] < 8 Then ivlist[4] := qq.IRQ[4] + 8
                    Else ivlist[4] := qq.IRQ[4] + 104;
   If qq.IRQ[5] < 8 Then ivlist[5] := qq.IRQ[5] + 8
                    Else ivlist[5] := qq.IRQ[5] + 104;
   If qq.IRQ[6] < 8 Then ivlist[6] := qq.IRQ[6] + 8
                    Else ivlist[6] := qq.IRQ[6] + 104;
   If qq.IRQ[7] < 8 Then ivlist[7] := qq.IRQ[7] + 8
                    Else ivlist[7] := qq.IRQ[7] + 104;
   If qq.IRQ[8] < 8 Then ivlist[8] := qq.IRQ[8] + 8
                    Else ivlist[8] := qq.IRQ[8] + 104;
End;


{$ifdef ISI}
Procedure Initialize_ISI_Vars;
Begin
   ISI_Base0 := qq.ISI_Base;
   ISI_Base1 := qq.ISI_Base+1;
   ISI_Base2 := qq.ISI_Base+2;
   ISI_Base3 := qq.ISI_Base+3;
   ISI_Port  := Ord(qq.CommPort)-1;
   If qq.ISI_IRQ < 8 Then ivlist[1] := qq.ISI_IRQ + 8
                     Else ivlist[1] := qq.ISI_IRQ + 104;
End;
{$endif}


Procedure Int14BIOS; External;
{$L Int14}


Procedure Drop_DTR_Low;
Begin
   Term_Ready(False);
   Delay(qq.DTRdelay);
   Term_Ready(True);
End;




Procedure TurnOffFIFO;
Begin
   {$ifdef Int14}
      If Int14 then Exit;
   {$endif}

   {$ifdef ISI}
   If qq.Use_ISI then Exit;  {Does not apply to ISI card}
   {$endif}

   If B16550 or B16550A then
      Port[IIR_] := 0;
End;


Procedure TurnOnFIFO;
Var
   x : Byte;
Begin
   {$ifdef Int14}
      If Int14 then Exit;
   {$endif}

   {$ifdef ISI}
   If qq.Use_ISI then Exit;  {Does not apply to ISI card}
   {$endif}

   B8250   := False;
   B16450  := False;
   Is16550 := False;
   B16550  := False;              { set some boolean flags        }
   B16550A := False;              {          "                    }

   If qq.Use16550 then
      Begin
         Port[IIR_] := $81;       { Write Hex 81 to IIR_ port  }
         x := Port[IIR_];         { read the port                 }
         If x >= 192 then         { Is bits 6 & 7 set ?           }
            B16550A := True       { Yes, this is a 16550A         }
         Else
            If x >= 128 then      { Is bit 7 set ?                }
               B16550 := True;    { Yes, there is a 16550         }
         Is16550 := B16550 or B16550A;
      End;
   If not (B16550A or B16550) then
      Begin
         Port[MSR_+1] := 123;
         If Port[MSR_+1] = 123 then
            B16450 := True
         Else
            B8250 := True;
      End;
End;


Procedure CloseCom(Shelled, RTS_UP, DTR_UP : Boolean);
Var
   i, m : Integer;
   xc : Byte;
   LCRreg : Byte;
Begin
   {$ifdef Int14}
      If Int14 then Exit;
   {$endif}

   If ComPort_Open_Flag then     { disable the IRQ on the 8259 }
      Begin

         Inline($FA);            { disable interrupts }

         m := CurrentPICMSK;     { get the interrupt mask register }
         If Async_IRQ < 8 then
            Begin
               i := Port[PicMsk];
               Port[PicMsk] := i or m;
            End
         Else
            Begin
               i := Port[PicMsk2];
               Port[PicMsk2] := i or m;
            End;

         {$ifdef ISI}
         If qq.Use_ISI then
            Begin
               SetIntVec(ivlist[1], ComSaveVec)  {ISI always uses 1};
            End
         Else
         {$endif}
            Begin
               Port[IER_] := 0;
               If RTS_UP then Port[MCR_] := Port[MCR_] and 3
                         Else Port[MCR_] := Port[MCR_] and 1;
               SetIntVec(ivlist[ActiveComPort], ComSaveVec);
            End;

         Inline($FB);  { enable interrupts }

         ComPort_Open_Flag := FALSE;

         {$ifdef ISI}
         If qq.Use_ISI then Exit;
         {$endif}

         If Shelled    then Exit;

         TurnOffFIFO;

         Inline($FA); { Disable interrupts }

         For xc := 1 to 8 do
            If OtherMCRsChanged[xc] = 1 then
               Begin
                  Port[ComBaseAddr[xc]+MCR] := OtherMCRs[xc];
                  OtherMCRsChanged[xc] := 0;
               End;
         If CurrentInitSaved then
            Begin
               If DTR_UP then
                  CurrentMCR := CurrentMCR Or 1
               else
                  CurrentMCR := CurrentMCR and $FE; {force it off}
               Port[MCR_] := CurrentMCR;
               Port[IER_] := CurrentIER;
               LCRreg := $80;              {  Set Divisor Latch Access Bit in LCR }
               LCRreg := LCRreg or CurrentLCR;
               PORT[LCR_] := LCRreg;       {  Set Parity, Data and Stop Bits }
               PORT[DLM_] := CurrentDLM;
               PORT[DLL_] := CurrentDLL;
               PORT[LCR_] := LCRreg and $7F;                {  Reset DLAB    }
               CurrentInitSaved := False;
            End;
         Inline($FB); { enable interrupts }
      End;
End;


Procedure OpenCom(ComPortx : byte;
                  Baud     : tBaud;
                  Parity   : tParity;
                  Databits : tDatabits;
                  Stopbits : tStopbits);
                  { open a communications Port }

Var
   x, y, i, m : word;
   Comparm : Byte;
   xc : Byte;
   LCRreg : Byte;

   Procedure RS232_Init(Comval : Byte; baud : tBaud);
   Const
      baudcode    :  array[b110..b115200] of integer  =
                     ($300, $180, $60, $30, $18, $0C, $06, $03, $02, $01);
   Begin
      LCRreg := $80;                    { Set Divisor Latch Access Bits }
      LCRreg := LCRreg or ComVal;
      PORT[LCR_] := LCRreg;             { Set Parity, Data and Stop and DLAB }
      PORT[DLM_] := Hi(baudcode[Baud]); { Set Baud rate }
      PORT[DLL_] := Lo(baudcode[Baud]); { Set Baud rate }
      PORT[LCR_] := LCRreg and $7F;     { Reset DLAB    }
   End; { BIOS_RS232_Init }

Begin
   ActiveComPort := ComPortx;

   {$ifdef ISI}
      If qq.Use_ISI then
         Begin
            Async_IRQ := qq.ISI_IRQ;
            CurrentPICMSK := Port[PicMsk] and (1 shl Async_IRQ);
         End
      Else
   {$endif}

      Begin
         Async_IRQ := qq.IRQ[ComPortx];

         ComBase := ComBaseAddr[ComPortx];

         IIR_ := IIR + ComBase;     { Interupt Idendification Register}
         LSR_ := LSR + ComBase;     { Line Status Register }
         LCR_ := LCR + ComBase;     { Line Status Register }
         IER_ := IER + ComBase;     { Interupt Enable Register }
         DLL_ := DLL + ComBase;     { DIvisor Line Latch }
         DLM_ := DLM + ComBase;     { DIvisor Line Latch }
         MSR_ := MSR + ComBase;     { Modem Status Register }
         RBR_ := RBR + ComBase;     { Receive Buffer register }
         MCR_ := MCR + ComBase;     { Modem control Register }

         If Not CurrentInitSaved then
            Begin
               CurrentMCR := Port[MCR_];
               CurrentIER := Port[IER_];
               LCRreg := $80;              {  Set Divisor Latch Access Bit in LCR }
               CurrentLCR := Port[LCR_];
               PORT[LCR_] := LCRreg or CurrentLCR;
               CurrentDLM := Port[DLM_];
               CurrentDLL := Port[DLL_];
               PORT[LCR_] := LCRreg and $7F;                {  Reset DLAB    }
               If Async_IRQ < 8 then
                  CurrentPICMSK := Port[PicMsk] and (1 shl Async_IRQ)
               Else
                  CurrentPICMSK := Port[PicMsk2] and (1 shl (Async_IRQ-8));
               CurrentInitSaved := True;
            End;

         Port[IIR_] := 0;
         x := Port[IIR_];   {dummy read}

         ComParm := 0;

         Case Parity of
            'E' : ComParm := ComParm or $18;
            'O' : ComParm := ComParm or $08;
            'M' : ComParm := ComParm or $28;
            'S' : ComParm := ComParm or $38;
         End;

         Case DataBits of
            d7 : ComParm := ComParm or $02;
            d8 : ComParm := ComParm or $03;  { default to 8 data bits }
         End;

         Case StopBits of
            s2 : ComParm := ComParm or $04;
         End;

         RS232_Init (ComParm, Baud);

         Port[IER_] := 0;

         Inline($FA); { disable interrupts }

         TurnOnFIFO;
      End;

   If NOT ComPort_Open_Flag then
      Begin

         {$ifdef ISI}
         If qq.Use_ISI then
            Begin
               InterruptsOFF;
               ISI_Status := Port[ISI_Base3];
               GetIntVec2_ISI(ivlist[1], ComSaveVec);
               SetIntVec(ivlist[1], @Asynch_Interrupt_ISI);
               InterruptsON;
            End
         Else
         {$endif}

            If Is16550 then
               Begin
                  GetIntVec2_16550(ivlist[ActiveComPort], ComSaveVec);
                  SetIntVec(ivlist[ActiveComPort], @Asynch_Interrupt_16550);
               End
            Else
               Begin
                  GetIntVec2(ivlist[ActiveComPort], ComSaveVec);
                  SetIntVec(ivlist[ActiveComPort], @Asynch_Interrupt);
               End;

         ComPort_Open_Flag := TRUE;
      End;

   If Async_IRQ < 8 then
      Begin
         y := 0;
         Repeat
            i := Port[PicMsk];
            m := (1 shl Async_IRQ) xor $00FF; { get the interrupt mask register }
            Port[PicMsk] := i and m;
            inc(y);
         Until (Port[PicMsk] and (1 shl Async_IRQ) = 0) or (y > 10);
      End
   Else
      Begin
         y := 0;
         Repeat
            i := Port[PicMsk2];
            m := (1 shl (Async_IRQ - 8)) xor $00FF; { get the interrupt mask register }
            Port[PicMsk2] := i and m;
            inc(y);
         Until (Port[PicMsk2] and (1 shl (Async_IRQ - 8)) = 0) or (y > 10);
      End;

   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         Term_Ready(True);
         Turn_On_RTS;
      End
   Else
   {$endif}
      Begin
         Port[MCR_] := $0B; {OUT2, RTS & DTR}

         { enable the data ready interrupt on the UART }
         Port[IER_] := 13;

         { read the Line Status Register to reset any errors it indicates }
         i := Port[LSR_] and 15;

         { read the Modem Status Register to reset any errors it indicates }
         i := Port[MSR_] and 15;

         { read the IIR and RBR to clear any queued data }
         i := Port[IIR_] and 15;
         m := Port[RBR_];

         MSR_Status      := 255;

         For xc := 1 to 8 do
            If xc <> ActiveComPort then
               If (ivIRQ[xc] = ivIRQ[ActiveComPort]) and
                  (OtherMCRsChanged[xc] = 0) then
                  Begin
                     OtherMCRs[xc] := Port[ComBaseAddr[xc]+MCR];
                     OtherMCRsChanged[xc] := 1;
                     Port[ComBaseAddr[xc]+MCR] := Port[ComBaseAddr[xc]+MCR] and $F7;
                  End;

         Inline($FB); { enable interrupts }
      End
End; { Async_Open }


Procedure Turn_Off_RTS;
Begin
   {$ifdef Int14}
      If Int14 then
         Begin
            {$ifdef JNL}
               ModemLeads := ModemLeads and $FD;  {Turn off the RTS bit 2}
               RDX := Int14ComPort;
               RAL := ModemLeads;
               RAH := $FB;                       {Extended Int14 Call   }
               Int14BIOS;
            {$endif}

            {$ifdef Cross}
               RDX := Int14ComPort;
               RAH := $04;
               RAL := $0B;
               Int14BIOS;
            {$endif}
            Exit;
         End;
   {$endif}

   {$ifdef ISI}
      If qq.Use_ISI then Exit;
   {$endif}

   If CTS_ then
      Port[MCR_] := Port[MCR_] and 29;   { 11101 Binary }
End;

Procedure Turn_On_RTS;
Begin
   {$ifdef Int14}
      If Int14 then
         Begin
            {$ifdef JNL}
               ModemLeads := ModemLeads or 2; {Turn ON the RTS bit 2}
               RDX := Int14ComPort;
               RAL := ModemLeads;
               RAH := $FB;                   {Extended Int14 Call   }
               Int14BIOS;
            {$endif}

            {$ifdef Cross}
               RDX := Int14ComPort;
               RAH := $04;
               RAL := $0F;
               Int14BIOS;
            {$endif}
            Exit;
         End;
   {$endif}

   {$ifdef ISI}
      If qq.Use_ISI then Exit;
   {$endif}

   If CTS_ then
      Port[MCR_] := Port[MCR_] or 2;   { 00010 Binary }
End;


Procedure Init_la_Port;
var
   comm : Byte;
   baud : tbaud;
   prty : tparity;
   dbts : tdatabits;
   sbts : tstopbits;
Begin
   {$ifdef ISI}
   If qq.Use_ISI then
      Initialize_ISI_Vars
   Else
   {$endif}
      Initialize_COMM_Vars;

   Comm := qq.CommPort;

   If NewSpeed = 110   then  baud := B110 else
   If NewSpeed = 300   then  baud := B300 else
   If NewSpeed = 1200  then  baud := B1200 else
   If NewSpeed = 2400  then  baud := B2400 else
   If NewSpeed = 4800  then  baud := B4800 else
   If NewSpeed = 9600  then  baud := B9600 else
   If NewSpeed = 19200 then  baud := B19200 Else
   If NewSpeed = 38400 then  baud := B38400 Else
   If NewSpeed = 57600 then  baud := B57600 Else
                             Baud := B115200;

   Prty := NewCParity;

   If NewDBits = 7 then dbts := d7
                   Else dbts := d8;

   If NewSBits = 1 then sbts := s1
                   Else sbts := s2;

   {$ifdef Int14}
      {$ifdef Basic}
         If Int14 then
            Begin
               Int14Comport := qq.CommPort-1;
               r.AL := 0;
               Case Baud of
                  B110   : ; {nothing as these bits are normally 0's}
                  B300   : r.AL := r.AL or $40;
                  B1200  : r.AL := r.AL or $80;
                  B2400  : r.AL := r.AL or $A0;
                  B4800  : r.AL := r.AL or $C0;
                  Else     r.AL := r.AL or $E0; {Max of 9600 for Int14}
               End;

               Case Prty of
                  'E' : r.AL := r.AL or $18;
                  'O' : r.AL := r.AL or $8;
               End;

               If sbts = s2 then
                  r.AL := r.AL or 4;

               If dbts = d7 then
                  r.AL := r.AL or 2
               Else
                  r.AL := r.AL or 3;
               rAL := r.al;
               rDX := Int14ComPort;
               rAH := 0;
               Int14BIOS;
            End
         Else
      {$endif}

      {$ifdef Plus}
         If Int14 then
            Begin
               Int14Comport := qq.CommPort-1;
               r.AL := 0;
               Case Baud of
                  B110   : ; {nothing as these bits are normally 0's}
                  B300   : r.AL := r.AL or $40;
                  B1200  : r.AL := r.AL or $80;
                  B2400  : r.AL := r.AL or $A0;
                  B4800  : r.AL := r.AL or $C0;
                  Else     r.AL := r.AL or $E0; {Max of 9600 for Int14}
               End;

               Case Prty of
                  'E' : r.AL := r.AL or $18;
                  'O' : r.AL := r.AL or $8;
                  'M' : r.AL := r.AL or $28;
                  'S' : r.AL := r.AL or $38;
               End;

               If sbts = s2 then
                  r.AL := r.AL or 4;

               If dbts = d7 then
                  r.AL := r.AL or 2
               Else
                  r.AL := r.AL or 3;
               rAL := r.al;
               rDX := Int14ComPort;
               rAH := 0;
               Int14BIOS;
            End
         Else
      {$endif}

      {$ifdef Cross}
         If Int14 then
            Begin
               Int14Comport := qq.CommPort-1;
               r.AL := 0;
               Case Baud of
                  B300   : r.AL := r.AL or $40;
                  B1200  : r.AL := r.AL or $80;
                  B2400  : r.AL := r.AL or $A0;
                  B4800  : r.AL := r.AL or $C0;
                  B9600  : r.AL := r.AL or $E0;
                  B19200 : ;
               End;

               Case Prty of
                  'E' : r.AL := r.AL or $18;
                  'O' : r.AL := r.AL or $8;
                  'M' : r.AL := r.AL or $28;
                  'S' : r.AL := r.AL or $38;
               End;

               If sbts = s2 then
                  r.AL := r.AL or 4;

               If dbts = d7 then
                  r.AL := r.AL or 2
               Else
                  r.AL := r.AL or 3;
               rAL := r.al;
               rDX := Int14ComPort;
               rAH := 0;
               Int14BIOS;
            End
         Else
      {$endif}

      {$ifdef JNL}
         If Int14 then
            Begin
               Int14Comport := qq.CommPort-1;
               r.AL := 0;
               Case Baud of
                  B300   : r.AL := r.AL or $40;
                  B1200  : r.AL := r.AL or $80;
                  B2400  : r.AL := r.AL or $A0;
                  B4800  : r.AL := r.AL or $C0;
                  B9600  : r.AL := r.AL or $E0;
                  B19200 : ;
               End;

               Case Prty of
                  'E' : r.AL := r.AL or $18;
                  'O' : r.AL := r.AL or $8;
                  'M' : r.AL := r.AL or $28;
                  'S' : r.AL := r.AL or $38;
               End;

               If sbts = s2 then
                  r.AL := r.AL or 4;

               If dbts = d7 then
                  r.AL := r.AL or 2
               Else
                  r.AL := r.AL or 3;
               rAL := r.al;
               rDX := Int14ComPort;
               rAH := 0;
               Int14BIOS;
            End
         Else
      {$endif}
   {$endif}

       Begin
         CloseCom (False, False, True);
         OpenCOM (comm,baud,prty,dbts,sbts);

         {$ifdef ISI}
         If qq.Use_ISI and ISI_OK then
            Begin
               ISI_CmdDone := False;
               ISI_Port_Count := 0;
               ISI_Command := $90;
               ISI_Poll_Busy;
               Port[ISI_Base0] := ISI_Command;
               Port[ISI_Base1] := ISI_Command;
               ISI_Fiddle;

               ISI_CmdDone := False;
               ISI_Command := $80 + ISI_Port;
               ISI_Poll_Busy;
               Port[ISI_Base0] := ISI_Command;

               If NewSpeed = 110   then  Port[ISI_Base0] := $02 Else
               If NewSpeed = 300   then  Port[ISI_Base0] := $05 Else
               If NewSpeed = 1200  then  Port[ISI_Base0] := $07 Else
               If NewSpeed = 2400  then  Port[ISI_Base0] := $0A Else
               If NewSpeed = 4800  then  Port[ISI_Base0] := $0C Else
               If NewSpeed = 9600  then  Port[ISI_Base0] := $0E Else
               If NewSpeed = 19200 then  Port[ISI_Base0] := $0F Else
               If NewSpeed = 38400 then  Port[ISI_Base0] := $10 Else
               If NewSpeed = 57600 then  Port[ISI_Base0] := $11 Else
               If NewSpeed = 115200 then Port[ISI_Base0] := $12;

               Case Prty of
                  'N' : Port[ISI_Base0] := 0;
                  'E' : Port[ISI_Base0] := 3;
                  'O' : Port[ISI_Base0] := 1;
                  'M' : Port[ISI_Base0] := 3;
                  'S' : Port[ISI_Base0] := 3;
               End;

               Case Dbts of
                  d7 : Port[ISI_Base0] := 2;
                  d8 : Port[ISI_Base0] := 3;
               End;

               Case Sbts of
                  s1  : Port[ISI_Base0] := 0;
                  s2  : Port[ISI_Base0] := 1;
               End;

               Port[ISI_Base0] := 2;   {Set CTS/RTS Flow}
               Port[ISI_Base1] := 0;
               ISI_Fiddle;
            End;
         {$endif}
      End;
   Clear_Buffer;
   Clear_Buffer2;
End;

Procedure Set_Baud(S : LongInt);
Begin
   NewSpeed := S;
   Init_la_Port;
End;


Procedure Term_Ready (state : boolean); {send a true for ON, false for OFF}
Var
   A : Byte;
Begin
   {$ifdef Int14}
      If Int14 then
         Begin
            {$ifdef JNL}
               If State then ModemLeads := ModemLeads or 1
                        else ModemLeads := ModemLeads and $FE;
               ModemLeads := ModemLeads or $10;
               RDX := Int14ComPort;
               RAL := ModemLeads;
               RAH := $FB;
               Int14BIOS;
            {$endif}

            {$ifdef Cross}
               RDX := Int14ComPort;
               RAH := $04;
               If State then
                  RAL := $0F
               Else
                  RAL := $0D;
               Int14BIOS;
            {$endif}

            Exit;
         End;
   {$endif}

   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         If not ISI_OK then
            Exit;

         ISI_CmdDone := False;
         ISI_Command := $70 + ISI_Port;
         If State then ISI_Control := ISI_Control or 4
                  else ISI_Control := ISI_Control and 27;
         ISI_Poll_Busy;
         Port[ISI_Base0] := ISI_Command;
         Port[ISI_Base0] := ISI_Control;
         Port[ISI_Base1] := ISI_Command;
         ISI_Fiddle;
         Exit;
      End;
   {$endif}

   A := Port[MCR_];
   Case State of
      True  : A := A or 1;
      False : A := A and 254;
   End;
   Port[MCR_] := A;
End;


Function Online : Boolean;
Begin
   If not Comport_Open_Flag then
      Begin
         Online := False;
         Exit;
      End;

   {$ifdef Int14}
   If Int14 then
      Begin
         rDX := Int14Comport;
         rAH := 3;
         Int14BIOS;
         Online := (rAL shr 7) = 1;
         Exit;
      End;
   {$endif}

   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         If not ISI_OK then
            Begin
               Online := False;
               Exit;
            End;
         ISI_CmdDone := False;
         ISI_Command := $30 + ISI_Port;
         ISI_Poll_Busy;
         Port[ISI_Base0] := ISI_Command;
         Port[ISI_Base1] := ISI_Command;
         ISI_Fiddle;
         Online := (ISI_Status shr 7) = 1;
         Exit;
      End;
   {$endif}

   Online := (Port[MSR_] shr 7) = 1;
End;


Procedure Remove_Port;
Begin
   If DropDTR then
      Term_Ready(False);
   CloseCom(False,False,(Not DropDTR));
End;


Procedure Break_Low;
var
   a, b : Byte;
Begin
   {$ifdef Int14}
      If Int14 then
         Begin
            {$ifdef JNL}
               rDX := Int14ComPort;
               rAH := $FA;
               Int14BIOS;
            {$endif}

            {$ifdef Cross}
               RDX := Int14ComPort;
               RAH := $04;
               RAL := $07;
               Int14BIOS;
               Delay (qq.BREAKdelay);
               RDX := Int14ComPort;
               RAH := $04;
               RAL := $0F;
               Int14BIOS;

            {$endif}
            Exit;
         End;
   {$endif}

   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         If not ISI_OK then
            Exit;

         ISI_CmdDone := False;
         ISI_Command := $70 + ISI_Port;
         ISI_Control := ISI_Control or 1;
         ISI_Poll_Busy;
         Port[ISI_Base0] := ISI_Command;
         Port[ISI_Base0] := ISI_Control;
         Port[ISI_Base1] := ISI_Command;
         ISI_Fiddle;

         Delay (qq.BREAKdelay);

         ISI_CmdDone := False;
         ISI_Command := $70 + ISI_Port;
         ISI_Control := ISI_Control and 254;
         ISI_Poll_Busy;
         Port[ISI_Base0] := ISI_Command;
         Port[ISI_Base0] := ISI_Control;
         Port[ISI_Base1] := ISI_Command;
         ISI_Fiddle;
         Exit;
      End;
   {$endif}

   a := Port[lcr_];
   b := a;
   If b > 127 then
      b := b - 128;
   If b <= 63 then
      b := b + 64;
   Port[lcr_] := b;
   Delay (qq.BREAKdelay);
   Port[lcr_] := a;
End;


Function CommPressed : Boolean;
Begin
   {$ifdef ISI}
   If qq.Use_ISI then
      ISI_Read_Write_Data;
   {$endif}

   CommPressed := ReadPTR <> WritPTR;
End;


{$F+}
Procedure Clear_IN_buffer;     External;
Procedure Clear_OUT_buffer;    External;
Function  Cinkey_COM : Char;   External;
Function  Cinkey_ISI : Char;   External;
Function  Peek_COM : Byte;     External;
Function  Peek_ISI : Byte;     External;
Procedure Store_OUT_Buf(Var Block2;
                        Num: Word); External;
Procedure Store_OUT_ISI(Var Block2;
                        Num: Word); External;
{$L COMM}


Function Cinkeyz : Char;
Begin
   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         ISI_Read_Write_Data;
         Cinkeyz := Cinkey_ISI;
         Exit;
      End;
   {$endif}

   Cinkeyz := Cinkey_COM;
End;


Procedure Clear_Buffer;
Begin
   {$IfDef Int14}
      If Int14 then
         Begin
            {$IfDef Cross}
               RDX := Int14ComPort;
               RAH := $04;
               RAL := $1F;
               Int14BIOS;
            {$EndIf}
         End;
   {$Endif}

   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         If not ISI_OK then
            Exit;
         ISI_CmdDone := False;
         ISI_Command := $60 + ISI_Port;
         ISI_Poll_Busy;
         Port[ISI_Base0] := ISI_Command;
         Port[ISI_Base1] := ISI_Command;
         ISI_Fiddle;
      End;
   {$endif}

   Clear_IN_Buffer;
End;


Procedure Clear_Buffer2;
Begin
   {$IfDef Int14}
      If Int14 then
         Begin
            {$IfDef Cross}
               RDX := Int14ComPort;
               RAH := $04;
               RAL := $2F;
               Int14BIOS;
            {$EndIf}
         End;
   {$Endif}

   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         If not ISI_OK then
            Exit;
         ISI_CmdDone := False;
         ISI_Command := $40 + ISI_Port;
         ISI_Poll_Busy;
         Port[ISI_Base0] := ISI_Command;
         Port[ISI_Base1] := ISI_Command;
         ISI_Fiddle;
      End;
   {$endif}
   Clear_OUT_Buffer;
End;


Procedure Store_Block_Buf(Var Block2; Num: word);
Begin
   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         If not ISI_OK then
            Exit;
         Store_OUT_ISI(Block2,Num);
         Exit;
      End;
   {$endif}

   Store_OUT_Buf(Block2,Num);
End;


Function Test_CTS(SecondsToWait : Word) : Boolean;
Var
   Ok : Boolean;
   ET : EventTimer;
Begin
   {$ifdef Int14}
      If Int14 then
         Begin
            Test_CTS := True;
            Exit;
         End;
   {$endif}

   {$ifdef ISI}
   If qq.Use_ISI then
      Begin
         Test_CTS := True;
         Exit;
      End;
   {$endif}

   Ok := False;
   NewTimerSecs(ET, SecondsToWait);
   While (not TimerExpired(ET)) and (not Ok) do
      Begin
         If Odd(Port[MSR_] shr 4) then
            Ok := TRUE;
      End;
   Test_CTS := Ok;
End;


{$ifdef Int14}

   Procedure Int1CExitHandler;   { Restore the original Int1C handler }
   Begin
      ExitProc := cExitSave;
      SetIntVec($08,OldInt1C);
   End;

   Procedure Int1CHandler; External;
   {$L Int1C}

   Procedure SetupInt1C;
   Begin
      cExitSave := ExitProc;
      ExitProc  := @Int1CExitHandler;
      GetIntVec($08,OldInt1C);
      SetIntVec($08,@Int1CHandler);
   End;
{$endif}


Begin
   {$ifdef ISI}
      ISI_CmdDone := True;
      ISI_Command := 0;
      ISI_Port_Count := 0;
      ISI_Control := 0;
   {$endif}

   Async_MaxBufferUsed := 0;
   ComPort_Open_Flag := FALSE;
   BytesQueuedOut := 0;
   Queue_Bytes := 0;
   InUse := 0;
   B16550  := False;  { set some boolean flags        }
   B16550A := False;
   B8250   := False;
   B16450  := False;
   Is16550 := False;
   CurrentInitSaved := False;
   FillChar(OtherMCRs,8,#0);
   FillChar(OtherMCRsChanged,8,#0);
   ClearComCounters;
End.
