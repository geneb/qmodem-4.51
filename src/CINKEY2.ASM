DATA          SEGMENT BYTE PUBLIC
              EXTRN  IIR_           : word
              EXTRN  RBR_           : word
              EXTRN  IER_           : word
              EXTRN  LSR_           : word
              EXTRN  MSR_           : word
              EXTRN  MCR_           : word
              EXTRN  CTS_           : Byte
              EXTRN  Async_IRQ      : word
              EXTRN  Queue_bytes    : word
              EXTRN  Buffer_Low1    : word
              EXTRN  RTS_On         : Byte
              EXTRN  BytesQueuedOut : word
              EXTRN  Readptr        : word
              EXTRN  Writptr        : word
              EXTRN  Readptr2       : word
              EXTRN  Writptr2       : word
              EXTRN  Buffer_size    : word
              EXTRN  Ringbuf        : word
              EXTRN  Ringbuf2       : word
DATA          ENDS

CODE          SEGMENT BYTE PUBLIC
              ASSUME  CS:CODE, DS:DATA

              PUBLIC  Cinkey2, Cinkey2_ISI
;             Function CINKEY2(Var Block; d, block_bytes : Word) : Word;
;
;    ES:DI  point to BLOCK
;       CX  Maximum bytes to read into BLOCK
;       BX  Keeps track of ReadPtr
;

Cinkey2       PROC    Near
              push    bp
              mov     bp,sp
              les     di,[bp+8]         ; es:di point to Block
              mov     dx,word ptr[bp+6] ; get number read already
              push    dx
              add     di,dx             ; increment di to point into block
              mov     cx,word ptr[bp+4] ; get max to read
              push    cx
              mov     bx,readptr        ; bx keeps track of readptr

TOP:          cmp     Queue_Bytes,0     ; any more bytes available?
              jz      NoMore            ; no, so time to get out

              mov     al,byte ptr ringbuf[bx]    ; get char in AL
              mov     es:di,al          ; store in block
              inc     di                ; inc pointer
              inc     bx                ; inc readptr
              and     bx,Buffer_Size    ; wrap buffer if necessary
              dec     Queue_Bytes       ; show we took one byte
              loop    Top               ; go and get another

NOMORE:       mov     Readptr,bx        ; restore old readptr
              test    CTS_,1            ; using CTS flow?
              jz      Cout              ; no, skip
              test    RTS_On,1          ; is RTS on?
              jnz     Cout              ; yes, skip
              mov     bx,Queue_Bytes    ; get current count
              cmp     bx,Buffer_Low1    ; below low water mark?
              jg      Cout              ; no, leave off
              push    dx
              mov     dx,MCR_           ; get MCR register
              in      al,dx             ; into AL
              or      al,2              ; turn on RTS bit
              jmp     $+2               ; delay
              out     dx,al             ; put it back out
              pop     dx
              mov     RTS_On,1          ; set RTS ON flag

COUT:         pop     ax                ; block_bytes value into AX
              sub     ax,cx             ; subtract leftover CX to get
                                        ;  the actual number read in AX
              pop     cx                ; get initial d value
              add     ax,cx             ; add to ax to pass back new d value
              pop     bp                ; clean up stack
              ret     8
Cinkey2       ENDP

Cinkey2_ISI   PROC    Near
              push    bp
              mov     bp,sp
              les     di,[bp+8]         ; es:di point to Block
              mov     dx,word ptr[bp+6] ; get number read already
              push    dx
              add     di,dx             ; increment di to point into block
              mov     cx,word ptr[bp+4] ; get max to read
              push    cx
              mov     bx,readptr        ; bx keeps track of readptr

TOP2:         cmp     Queue_Bytes,0     ; any more bytes available?
              jz      NoMore2           ; no, so time to get out

              mov     al,byte ptr ringbuf[bx]    ; get char in AL
              mov     es:di,al          ; store in block
              inc     di                ; inc pointer
              inc     bx                ; inc readptr
              and     bx,Buffer_Size    ; wrap buffer if necessary
              dec     Queue_Bytes       ; show we took one byte
              loop    Top2              ; go and get another

NOMORE2:      mov     Readptr,bx        ; restore old readptr

              pop     ax                ; block_bytes value into AX
              sub     ax,cx             ; subtract leftover CX to get
                                        ;  the actual number read in AX
              pop     cx                ; get initial d value
              add     ax,cx             ; add to ax to pass back new d value
              pop     bp                ; clean up stack
              ret     8
Cinkey2_ISI   ENDP

CODE          ENDS
              END
