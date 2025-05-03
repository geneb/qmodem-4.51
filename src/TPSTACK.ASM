;******************************************************
;                  TPSTACK.ASM 1.00
;               by TurboPower Software
;******************************************************

;****************************************************** Equates

Ofst            EQU     (WORD PTR 0)
Segm            EQU     (WORD PTR 2)

;****************************************************** Data

DATA    SEGMENT WORD PUBLIC

        EXTRN   OurSS : WORD            ;value of SS when program began
        EXTRN   LowestSP : WORD         ;lowest value for SP
        EXTRN   HeapHigh : DWORD        ;highest address pointed to by HeapPtr
        EXTRN   HeapPtr : DWORD
        EXTRN   CountsPerTick : WORD
        EXTRN   Counts : WORD

DATA    ENDS

;****************************************************** Code

CODE    SEGMENT BYTE PUBLIC

        ASSUME  CS:CODE,DS:DATA

        PUBLIC  ActualSaveInt8, Int8

ActualSaveInt8  DD      0               ;stores previous INT 8 handler

;****************************************************** Int8

;procedure Int8;
;Interrupt service routine used to monitor stack and heap usage

Flags   EQU     WORD PTR [BP+6]         ;position of pushed flags

Int8    PROC NEAR

        PUSH    BP                      ;set up stack frame
        MOV     BP,SP
        PUSH    AX                      ;save registers used
        PUSH    DI
        PUSH    DS
        MOV     AX,SEG DATA             ;set up DS
        MOV     DS,AX

        MOV     AX,SS                   ;make sure we're in the right SS
        CMP     AX,OurSS
        JNE     WrongSS

        LEA     DI,Flags                ;flags are where SS:SP was when the
        CMP     DI,LowestSP             ;interrupt occurred
        JNB     WrongSS
        MOV     LowestSP,DI

WrongSS:
        ;compare HeapPtr and HeapHigh; both are normalized
        MOV     AX,HeapPtr.Segm         ;HeapPtr into AX:DI
        MOV     DI,HeapPtr.Ofst
        CMP     AX,HeapHigh.Segm        ;if the segment is higher,
        JA      IsHigher                ;HeapPtr points higher
        JNE     Done                    ;check offsets only if segments equal
        CMP     DI,HeapHigh.Ofst        ;done if offset isn't higher
        JNA     Done

IsHigher:
        MOV     HeapHigh.Ofst,DI        ;HeapHigh = HeapPtr
        MOV     HeapHigh.Segm,AX

Done:   INC     Counts                  ;increment counter
        MOV     AX,CountsPerTick        ;see if we need to chain to old ISR
        CMP     Counts,AX
        JAE     Chain
        MOV     AL,20h                  ;send EOI to interrupt controller
        OUT     20h,AL
        POP     DS                      ;restore registers used
        POP     DI
        POP     AX
        POP     BP
        IRET

Chain:  MOV     Counts,0                ;reset counter
        POP     DS                      ;restore registers used
        POP     DI
        POP     AX
        POP     BP
        JMP     DWORD PTR ActualSaveInt8 ;chain to old INT $8 handler

Int8    ENDP

CODE    ENDS

        END
