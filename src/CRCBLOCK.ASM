DATA   SEGMENT WORD PUBLIC
       EXTRN  CRC : WORD
DATA   ENDS


CODE   SEGMENT WORD PUBLIC
       ASSUME CS:CODE, DS:DATA
       PUBLIC CRCBLOCK

;      Procedure CRCBLOCK(Var Block; Num : WORD);

CRCBLOCK PROC    FAR
         PUSH    BP
         MOV     BP,SP
         MOV     CX,WORD PTR [BP+6]    ;Get number to compute in CX
         MOV     BX,CRC                ;load BX with last total CRC word
         LES     DI,[BP+8]             ;es:di with address of Block
OUTER:   PUSH    CX
         MOV     AL,BYTE PTR[ES:DI]
         MOV     CX,8
X10A:    SHL     AL,1
         RCL     BX,1
         JNB     X114
         XOR     BX,1021h
X114:    LOOP    X10A
         POP     CX
         INC     DI
         LOOP    OUTER
         MOV     CRC,BX
         POP     BP
         RET     6

CRCBLOCK ENDP

CODE     ENDS
         END
