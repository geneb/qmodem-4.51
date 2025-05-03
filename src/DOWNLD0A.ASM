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

              PUBLIC  Cinkey2

Cinkey2       PROC    Near
              mov     bx,readptr                 ; load readptr
              mov     al,byte ptr ringbuf[bx]    ; get char in AL
              xor     ah,ah                      ; set ah to 0
              inc     bx                         ; inc readptr
              and     bx,Buffer_Size             ; compare to bufsize
;             cmp     bx,Buffer_Size             ; compare to bufsize
;             jl      C001                       ; too high?
;             xor     bx,bx                      ; yes, set to zero

C001:         mov     Readptr,bx                 ; restore old readptr
              dec     Queue_bytes                ; dec queue bytes
              test    CTS_,1                     ; using CTS flow?
              jz      Cout                       ; no, skip
              test    RTS_On,1                   ; is RTS on?
              jnz     Cout                       ; yes, skip
              mov     bx,Queue_Bytes             ; get current count
              cmp     bx,Buffer_Low1             ; below low water mark?
              jg      Cout                       ; no, leave off
              push    ax
              mov     dx,MCR_                    ; get MCR register
              in      al,dx                      ; into AL
              or      al,2                       ; turn on RTS bit
              jmp     $+2                        ; delay
              out     dx,al                      ; put it back out
              pop     ax
              mov     RTS_On,1                   ; set RTS ON flag
Cout:         ret                                ; return the Char back too!
Cinkey2       ENDP

CODE          ENDS
              END
