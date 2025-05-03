DATA   SEGMENT WORD PUBLIC

       EXTRN  CRC : WORD

DATA   ENDS


CODE   SEGMENT WORD PUBLIC

       ASSUME CS:CODE, DS:DATA

       PUBLIC UPDCRC

;      Procedure UPDCRC ( CH : CHAR );

UPDCRC PROC    FAR
       PUSH    BP
       MOV     BP,SP
       MOV     AL,BYTE PTR [BP+6]    ;get character into AL
       MOV     BX,CRC                ;load BX with last total CRC word
       MOV     CX,8
X10A:  SHL     AL,1
       RCL     BX,1
       JNB     X114
       XOR     BX,1021h
X114:  LOOP    X10A
       MOV     CRC,BX
       POP     BP
       RET     2

UPDCRC ENDP
CODE   ENDS
       END
