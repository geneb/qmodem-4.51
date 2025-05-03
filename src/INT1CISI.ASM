DATA         SEGMENT BYTE PUBLIC
             EXTRN  ISI_Base0      : word
             EXTRN  ISI_Base1      : word
             EXTRN  ISI_Base2      : word
             EXTRN  ISI_Base3      : word
             EXTRN  ISI_Port_Count : byte
             EXTRN  ISI_Command    : byte
             EXTRN  ISI_CmdDone    : byte
             EXTRN  ISI_Status     : byte
             EXTRN  ISI_TX_Queue   : word
             EXTRN  ISI_RX_Queue   : word

             EXTRN  Async_IRQ      : word
             EXTRN  Queue_bytes    : word
             EXTRN  BytesQueuedOut : word
             EXTRN  Readptr        : word
             EXTRN  Writptr        : word
             EXTRN  Readptr2       : word
             EXTRN  Writptr2       : word
             EXTRN  Buffer_size    : word
             EXTRN  Ringbuf        : word
             EXTRN  Ringbuf2       : word
             EXTRN  int14comport   : word
             EXTRN  OldInt1C       : dword
             EXTRN  InUse          : byte


DATA         ENDS

CODE         SEGMENT BYTE PUBLIC
             ASSUME  CS:CODE, DS:DATA

             PUBLIC  Int1CHandler


Int1CHandler PROC  FAR
             push   ax
             push   bx
             push   cx
             push   dx
             push   ds
             mov    ax,seg data
             mov    ds,ax

             cmp    inuse,0            ; if alread in use, then
             jne    ciao2

             sti
             mov    inuse,1            ; set inuse flag
             mov    cx,4h              ; loop counter - 20 bytes max per invocation

L_RX:


             loop   L_RX                    ; GO SEE IF MORE IS IN BUFFER

ciao:
             mov    inuse,0                 ; reset inuse flag.  we are done

Ciao2:       pushf                     ;(INT instruct pushes flags)
             call   [OldInt1C]         ;simulate interrupt
             pop    DS
             pop    DX
             pop    CX
             pop    BX
             pop    AX
             IRET

Int1CHandler Endp

CODE         ends
             end
