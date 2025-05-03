DATA         SEGMENT BYTE PUBLIC
             EXTRN  IIR_           : word
             EXTRN  RBR_           : word
             EXTRN  IER_           : word
             EXTRN  LSR_           : word
             EXTRN  MSR_           : word
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
             pushf                     ;(INT instruct pushes flags)
             call   [OldInt1C]         ;simulate interrupt

             cmp    inuse,0            ; if alread in use, then
             jne    ciao2

             mov    inuse,1            ; set inuse flag
             sti
             mov    cx,01FFh          ; 20 bytes max per invocation
             mov    dx,Int14ComPort

L_RX:        mov    ah,3
             int    14H
             test   ah,1
             jnz    ReadIt
             jmp    $+2
             loop   L_RX    ; if no more data, then leave and reset flag
             jmp    ciao

ReadIt:      mov    ah,2
             int    14H
             test   ah,80h
             jnz    LoopHere
             test   ah,00011110B
             jnz    LoopHere

             push   cx
             mov    bx,writptr              ; load writptr
             mov    cx,bx                   ; save in cx
             mov    byte ptr ringbuf[bx],al ; store in buffer
             inc    bx                      ; inc writptr
             and    bx,Buffer_size          ; compare to bufsize
             cmp    bx,readptr              ; equal to readptr?
             jne    L002                    ; no, skip this
             mov    writptr,cx              ; restore old writptr
             pop    cx
             jmp    Ciao                    ; exit routine

L002:        mov    writptr,bx         ; save new writptr
             inc    queue_bytes        ; inc queue bytes
             pop    cx

LoopHere:    loop   L_RX               ; GO SEE IF MORE IS IN BUFFER

ciao:        mov    inuse,0            ; reset inuse flag.  we are done

Ciao2:
             pop    DS
             pop    DX
             pop    CX
             pop    BX
             pop    AX
             IRET

Int1CHandler Endp

CODE         ends
             end
