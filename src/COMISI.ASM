DATA    SEGMENT BYTE PUBLIC

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


             EXTRN  Buffer_size    : word
             EXTRN  Queue_bytes    : word
             EXTRN  BytesQueuedOut : word
             EXTRN  Readptr        : word
             EXTRN  Writptr        : word
             EXTRN  Readptr2       : word
             EXTRN  Writptr2       : word
             EXTRN  Ringbuf        : word
             EXTRN  Ringbuf2       : word
             EXTRN  U16550Loops    : word
             EXTRN  INTtrips       : word
             EXTRN  ShareTrips     : word
             EXTRN  ComSaveVec     : dword
             EXTRN  ShareIRQ       : byte
DATA    ENDS

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE, DS:DATA

        PUBLIC  Asynch_Interrupt_ISI
	PUBLIC	GetIntVec2_ISI

;CS-relative variables,	easily accessible to interrupt handlers
PrevIntVec	LABEL DWORD
PrevIntVecOfs	DW ?
PrevIntVecSeg	DW ?

;*********************************************************** GetIntVec2

;Return	an interrupt vector
;procedure GetIntVec2(IntNo : Byte; var Vector : pointer);

GetIntVec2_ISI PROC FAR

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

GetIntVec2_ISI ENDP

;*********************************************************** Asynch_Interrupt

Asynch_Interrupt_ISI  PROC  FAR
        push  ax
        push  bx
        push  cx
        push  dx
        push  ds
        mov   ax,seg data
        mov   ds,ax
        mov   al,ISI_CmdDone
        cmp   al,0            ; Was it my ISI Command active?
        jz    Mine            ; Yes, go handle it in here

        test  ShareIRQ,1      ; Share with other ISI software?
        jnz   DoShare         ; no, send EOI and get out.
        jmp   done
DoShare:
        inc   ShareTrips      ; yes!
        pop   ds
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        JMP   PrevIntVec      ; jump to previous ISI IRQ handler

Mine:
        mov   dx,ISI_Base3    ; Find out which CMD is executing
        in    al,dx           ; ISI Acknowledge
        xor   bx,bx           ; clear BH register
        mov   bl,ISI_Command  ; Which command?
        and   bl,0F0h         ;
        mov   cl,3
        shr   bl,cl
        jmp   word ptr cs:jmptble[bx]


jmptble label word
        dw    cmd00h     ; End Of Interrupt for ISI / Cleanup Code
        dw    cmd10h     ; Send Segment (255 bytes max)
        dw    cmd20h     ; Get Segment  (255 bytes max)
        dw    cmd30h     ; Get TX Queue Count
        dw    cmd40h     ; Kill TX Queue
        dw    cmd50h     ; Get RX Queue Count
        dw    cmd60h     ; Kill RX Queue
        dw    cmd70h     ; Set RS232 Signals / Send BREAK
        dw    cmd80h     ; Configure Port
        dw    cmd90h     ; How many ports on ISI?

;
; ------------------- cmd10h : Send Segment ---------------------
;

cmd10h:
        xor   ch,ch
        mov   dx,ISI_Base1
        in    al,dx         ; read in byte count ISI can take
        cmp   al,0          ; is ISI full?
        jnz   cont10        ;   no, go get the data!
        jmp   done
Cont10:
        mov   cl,al         ; save byte count in cl (ready for loop!)
        mov   dx,ISI_BASE0
        mov   bx,readptr2
TXcont:
        inc   U16550loops
        mov   al,byte ptr ringbuf2[bx]  ; get character to send
        out   dx,al                     ; and send it!
        dec   BytesQueuedOut            ; show we have less
        inc   bx                        ;
        and   bx,Buffer_size            ; wrap if necessary
        loop  txcont                    ; loop to send more
        mov   readptr2,bx               ; save back to readptr2
        jmp   done


;
; -------------------  cmd20h : Receive data --------------------
;

cmd20h:
        xor   ch,ch
        mov   dx,ISI_Base1
        in    al,dx                   ; number of bytes to receive
        cmp   al,0                    ; nothing to receive...
        jnz   cont20                  ;  so exit...
        jmp   done

Cont20:
        mov   cl,al                   ; load CX reg for loop!
        mov   bx,writptr              ; load writptr
Loop20:
        inc   INTtrips
        in    al,dx                   ; get a byte
        mov   byte ptr ringbuf[bx],al ; store in buffer
        inc   bx                      ; inc writptr
        and   bx,Buffer_Size          ; reset to 0 if buffer wraps
        inc   Queue_Bytes             ; inc queue bytes
        loop  loop20                  ; go back for more!

        mov   Writptr,bx              ; save new writptr
        jmp   done

;
; -------------------  cmd30h : Get TX Queue Count ------------------
;

cmd30h:
        mov   dx,ISI_Base1
        in    al,dx
        mov   cl,al
        jmp   $+2
        in    al,dx
        mov   ch,al
        mov   ISI_TX_Queue,cx
        jmp   $+2
        in    al,dx
        mov   ISI_Status,al
        jmp   done


;
; -------------------  cmd40h : Purge TX Queue ------------------
;

cmd40h:
        jmp   done



;
; -------------------  cmd50h : Get RX Queue Count --------------
;

cmd50h:
        mov   dx,ISI_Base1
        in    al,dx
        mov   cl,al
        jmp   $+2
        in    al,dx
        mov   ch,al
        mov   ISI_RX_Queue,cx
        jmp   done


;
; -------------------  cmd60h : Purge TX Queue ------------------
;

cmd60h:
        jmp  done


;
; -------------------  cmd70h : Set RS232 Signals / Send BREAK --
;

cmd70h:
        jmp  done

;
; -------------------  cmd80h : Configure Port ------------------
;

cmd80h:
        jmp  done

;
; -------------------  cmd90h : How many ports? -----------------
;

cmd90h:
        mov   dx,ISI_Base1
        in    al,dx
        mov   ISI_Port_Count,al
        jmp   done


cmd00h:
  done: mov   al,1
        mov   ISI_CmdDone,al   ; tell program this Command is done

       ;cmp   al,8             ;if/when ISI board supports IRQ > 7
       ;jb    Exit1            ;
       ;mov   al,20h           ;
       ;out   0A0h,al          ; tell chip about it

Exit1:  mov   al,20h
        out   20h,al           ; tell chip about it
        pop   ds
        pop   dx
        pop   cx
        pop   bx
        pop   ax
        IRET


Asynch_Interrupt_ISI ENDP

CODE    ends
        end
