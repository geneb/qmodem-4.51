DATA    SEGMENT BYTE PUBLIC

             EXTRN  Is16550        : byte
             EXTRN  RTS_On         : byte
             EXTRN  MSR_Status     : byte
             EXTRN  IIR_           : word
             EXTRN  RBR_           : word
             EXTRN  IER_           : word
             EXTRN  LSR_           : word
             EXTRN  MSR_           : word
             EXTRN  MCR_           : word
             EXTRN  CTS_           : byte
             EXTRN  Async_IRQ      : word
             EXTRN  Queue_bytes    : word
             EXTRN  BytesQueuedOut : word
             EXTRN  Readptr        : word
             EXTRN  Writptr        : word
             EXTRN  Readptr2       : word
             EXTRN  Writptr2       : word
             EXTRN  Buffer_size    : word
             EXTRN  Buffer_High1   : word
             EXTRN  Ringbuf        : word
             EXTRN  Ringbuf2       : word
             EXTRN  LSRXXX         : word
             EXTRN  U16550Loops    : word
             EXTRN  OverrunErrors  : word
             EXTRN  ParityErrors   : word
             EXTRN  FramingErrors  : word
             EXTRN  INTtrips       : word
             EXTRN  LSRtrips       : word
             EXTRN  ShareTrips     : word
             EXTRN  MSRtrips       : word
             EXTRN  ComSaveVec     : dword
             EXTRN  ShareIRQ       : byte
DATA    ENDS

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE, DS:DATA

        PUBLIC  Asynch_Interrupt
	PUBLIC	GetIntVec2

;CS-relative variables,	easily accessible to interrupt handlers
PrevIntVec	LABEL DWORD
PrevIntVecOfs	DW ?
PrevIntVecSeg	DW ?

;*********************************************************** GetIntVec2

;Return	an interrupt vector
;procedure GetIntVec2(IntNo : Byte; var Vector : pointer);

GetIntVec2 PROC FAR

	PUSH	BP
	MOV	BP,SP
	MOV	AL,[BP+10]		;Get interrupt number
	MOV	AH,35h
	INT	21h
	MOV	AX,ES			;Save interrupt	segment
	LES	DI,[BP+6]		;ES:DI => result
	MOV	ES:[DI],BX		;Offset
	MOV	ES:[DI+2],AX		;Segment
        mov     PrevIntVecOfs,bx        ; save in CS var
        mov     PrevIntVecSeg,ax        ; save in CS var
        MOV	SP,BP
	POP	BP
	RETF	6

GetIntVec2 ENDP

;*********************************************************** Asynch_Interrupt

Asynch_Interrupt  PROC  FAR

        push  ax
        push  bx
        push  cx
        push  dx
        push  ds
        mov   ax,seg data
        mov   ds,ax
        mov   dx,IIR_         ; Find out who rung my bell
        in    al,dx           ; get the byte
                              ; first see if it was my chip
                              ; doing the interrupting...
        test  al,1            ; Was it my UART?
        jz    Mine            ; No, handle it in here

Others: test  ShareIRQ,1
        jz    MyExit
        inc   ShareTrips
        pop   ds
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        JMP   PrevIntVec      ; jump to previous interrupt vector

Loop01: mov   dx,IIR_         ; Find out who rung my bell
        in    al,dx           ; get the byte
        test  al,1
        jnz   MyExit

Mine:
        and   al,00000110b    ; mask off all but bits 1 & 2
        xor   bx,bx
        mov   bl,al
        jmp   word ptr cs:jmptble[bx]

jmptble label word           ;values correspond to 0, 2, 4 and 6 (divided by 2)
        dw    L_MS           ;offset 0 = modem status interrupt
        dw    L_TX           ;offset 1 = transmitter empty interrupt
        dw    L_RX           ;offset 2 = received data interrupt
        dw    L_LS           ;offset 3 = line status interrupt


MyExit: mov   ax,Async_IRQ
        cmp   al,8
        jb    Exit1
        mov   al,20h
        out   0A0h,al                ; tell chip about it

Exit1:  mov   al,20h
        out   020h,al                ; tell chip about it
        pop   ds
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        IRET


;
; ------------------- Line Status Interrupt ---------------------
;

L_LS:   mov   dx,LSR_           ; get the LSR status
        in    al,dx             ; in AL
        test  al,2
        jz    L_LS4
        inc   OverrunErrors
        jmp   Loop01
L_LS4:  test  al,4
        jz    L_LS8
        inc   ParityErrors
        jmp   Loop01
L_LS8:  test  al,8
        jz    L_LS16
        inc   FramingErrors
        jmp   Loop01
L_LS16: inc   LSRtrips
        jmp   Loop01

;
;------------ Modem Status Interrupt --------------
;

L_MS:   mov   dx,MSR_
        in    al,dx
        mov   MSR_Status,al   ; save for future reference
        inc   MSRtrips
        cmp   BytesQueuedOut,0
        jz    Loop01

        mov   dx,IER_         ; enable THRE interrupt just in case
        in    al,dx
        or    al,2
        jmp   $+2
        out   dx,al
        jmp   Loop01



;
; ---------------------  transmit a character ------------------------
;


L_TX:   cmp   BytesQueuedOut,0
        je    TXoff         ; no data to send, so turn the interrupt off

        test  CTS_,1        ; are we using CTS flow control?
        jz    CTSOK         ; no, skip hardware check...

        mov   dx,MSR_
        in    al,dx
        test  al,16
        jnz   CTSOK

TXoff:  mov   dx,IER_       ; Turn off THRE interrupt
        in    al,dx
        and   al,0FDh
        jmp   $+2
        out   dx,al
        jmp   Loop01

CTSOK:  inc   U16550loops

        mov   dx,LSR_
TXthre: in    al,dx
        test  al,32       ; make sure the brain damaged early 8250's
        jnz   threOK      ; are really ready to receive a byte of data
        jmp   TXthre

THREok: mov   bx,readptr2
        mov   dx,RBR_
        mov   al,byte ptr ringbuf2[bx]  ; get character to send
        out   dx,al                     ; and send it!
        dec   BytesQueuedOut            ; show we have less
        inc   bx                        ;
        and   bx,Buffer_size            ; wrap if necessary
        mov   readptr2,bx               ; save back to readptr2
        jmp   Loop01


;
; -------------------  Receive a character --------------------
;

L_RX:   inc   INTtrips
        mov   dx,RBR_                 ; load port in dx
        in    al,dx                   ; get the byte

        mov   bx,writptr              ; load writptr
        mov   cx,bx                   ; save in cx
        mov   byte ptr ringbuf[bx],al ; store in buffer
        inc   bx                      ; inc writptr
        and   bx,Buffer_Size          ; reset to 0 if buffer wraps

L001:   cmp   bx,readptr              ; equal to readptr?
        jne   L002                    ; no, skip this
        mov   writptr,cx              ; restore old writptr
        jmp   Loop01                  ; exit routine

L002:   mov   Writptr,bx              ; save new writptr
        inc   Queue_Bytes             ; inc queue bytes
        test  CTS_,1                  ; are we using CTS flow?
        jz    L_RX4                   ; no skip hardware flow
        mov   bx,Buffer_High1         ; get High1 watermark
        cmp   bx,Queue_bytes          ; check against current level
        jg    L_RX4                   ; Still plenty of room, skip

        mov   dx,MCR_                 ; get MCR register
        in    al,dx
        and   al,0FDh                 ; reset the RTS line
        jmp   $+2                     ; small delay
        out   dx,al                   ; and store it back out
        mov   RTS_On,0                ; set the RTS flag

L_RX4:  jmp Loop01

;        mov   dx,LSR_                 ; now check the LSR for more data
;        in    al,dx                   ;
;        test  al,1                    ; is there more?
;        jnz   L_RX                    ; YES!  go get it!
;        jmp   Loop01                  ; No, exit

Asynch_Interrupt ENDP

CODE    ends
        end
