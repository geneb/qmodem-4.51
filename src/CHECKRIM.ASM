DATA   SEGMENT WORD PUBLIC
DATA   ENDS


CODE   SEGMENT WORD PUBLIC
       ASSUME CS:CODE, DS:DATA
       PUBLIC CHECKRIM

;      Function CHECKRIM : WORD;

nca_id    db   "NCA "

CHECKRIM  PROC NEAR
          push ds
          mov  ax,seg data
          mov  ds,ax
          mov  bx,14h-8
          call test_nca
          jz   good_test

          mov  cx,2
Loop01:   mov  bx,cx
          call test_nca
          jz   good_test
          inc  cx
          cmp  cx,8
          jne  Loop01
          jmp  short chk_rrim_end

test_nca: add  bl,8
          shl  bx,1
          shl  bx,1
          xor  ax,ax
          mov  es,ax
          les  bx,es:[bx]
          sub  bx,18h
          mov  ax,word ptr es:[bx+10h]
          cmp  ax,word ptr cs:nca_id
          jnz  irq_not_nca
          mov  ax,word ptr es:[bx+12h]
          cmp  ax,word ptr cs:nca_id+2

irq_not_nca:
          ret

good_test:
          mov  ax,0
          jmp  short OK

chk_rrim_end:
          mov  ax,1
OK:
          pop ds
          ret
CHECKRIM  ENDP

CODE      ENDS
          END
