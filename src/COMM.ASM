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

              PUBLIC  Cinkey_COM, Cinkey_ISI, Clear_IN_Buffer, Clear_OUT_Buffer
              PUBLIC  Store_OUT_Buf, Store_OUT_ISI, Peek_COM, Peek_ISI

Cinkey_COM    PROC    FAR
              mov     bx,readptr                 ; load readptr
              mov     al,byte ptr ringbuf[bx]    ; get char in AL

              xor     ah,ah                      ; set ah to 0
              inc     bx                         ; inc readptr
              and     bx,Buffer_Size

              mov     Readptr,bx                 ; restore old readptr
              dec     Queue_bytes                ; dec queue bytes

              test    CTS_,1                     ; using CTS flow?
              jz      @@Cout                     ; no, skip

              test    RTS_On,1                   ; is RTS on?
              jnz     @@Cout                     ; yes, skip

              mov     bx,Queue_Bytes             ; get current count
              cmp     bx,Buffer_Low1             ; below low water mark?
              jg      @@Cout                     ; no, leave off

              push    ax
              mov     dx,MCR_                    ; get MCR register
              in      al,dx                      ; into AL
              or      al,2                       ; turn on RTS bit
              jmp     $+2                        ; delay
              out     dx,al                      ; put it back out
              pop     ax
              mov     RTS_On,1                   ; set RTS ON flag
@@Cout:       ret                                ; return the Char back too!
Cinkey_COM    ENDP

Cinkey_ISI    PROC    FAR
              mov     bx,readptr                 ; load readptr
              mov     al,byte ptr ringbuf[bx]    ; get char in AL
              xor     ah,ah                      ; set ah to 0
              inc     bx                         ; inc readptr
              and     bx,Buffer_Size
              mov     Readptr,bx                 ; restore old readptr
              dec     Queue_bytes                ; dec queue bytes
              ret                                ; return the Char back too!
Cinkey_ISI    ENDP


Peek_COM      PROC    FAR
              mov     bx,readptr                 ; load readptr
              mov     al,byte ptr ringbuf[bx]    ; get char in AL
              ret                                ; return the Char back too!
Peek_COM      ENDP

Peek_ISI      PROC    FAR
              mov     bx,readptr                 ; load readptr
              mov     al,byte ptr ringbuf[bx]    ; get char in AL
              ret                                ; return the Char back too!
Peek_ISI      ENDP


Clear_IN_Buffer  PROC    FAR
              mov     readptr,0
              mov     writptr,0
              mov     Queue_Bytes,0
              mov     dx,MCR_                    ; get MCR register
              in      al,dx                      ; into AL
              or      al,2                       ; turn on RTS bit
              jmp     $+2                        ; delay
              out     dx,al                      ; put it back out
              mov     RTS_On,1                   ; set RTS ON flag
              ret
Clear_IN_Buffer  ENDP

Clear_OUT_Buffer PROC    FAR
              mov     dx,IER_
              in      al,dx
              and     al,0FDh     ; turn off transmit bit
              jmp     $+2
              out     dx,al
              mov     readptr2,0
              mov     writptr2,0
              mov     BytesQueuedOut,0
              ret
Clear_OUT_Buffer ENDP


Store_OUT_Buf PROC    FAR
              push    bp
              mov     bp,sp
              mov     cx,[bp+6]                  ; number to move
              les     di,[bp+8]                  ; es:di point into buffer
              mov     bx,writptr2                ; points into output buffer
loophere:     mov     al,byte ptr[es:di]         ; get a character
              mov     byte ptr ringbuf2[bx],al   ; store in buffer
              inc     bx
              and     bx,buffer_size
              inc     di
              inc     BytesQueuedOut
              loop    LoopHere
              mov     writptr2,bx
              mov     dx,IER_
              in      al,dx
              or      al,2        ; turn on transmit bit
              jmp     $+2         ; small delay
              out     dx,al
              pop     bp
              ret     6
Store_OUT_Buf ENDP

Store_OUT_ISI PROC    FAR
              push    bp
              mov     bp,sp
              mov     cx,[bp+6]                  ; number to move
              les     di,[bp+8]                  ; es:di point into buffer
              mov     bx,writptr2                ; points into output buffer
loopISI:      mov     al,byte ptr[es:di]         ; get a character
              mov     byte ptr ringbuf2[bx],al   ; store in buffer
              inc     bx
              and     bx,buffer_size
              inc     di
              inc     BytesQueuedOut
              loop    LoopISI
              mov     writptr2,bx
              pop     bp
              ret     6
Store_OUT_ISI ENDP

CODE          ENDS
              END
