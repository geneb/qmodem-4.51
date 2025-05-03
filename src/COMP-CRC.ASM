CODE         SEGMENT BYTE PUBLIC
             assume  cs:CODE

             PUBLIC  COMPUTE_CRC

COMPUTE_CRC  PROC    FAR
;
; procedure Compute_CRC (var Structure; Len, Offset : integer)
;
             push    bp
             mov     bp,sp
             push    bp
             push    ds

; ax holds crc value as it is computed - crc is passed back through ax
             mov     ax,[bp+6]            ; get offset into bx
             mov     cx,[bp+8]            ; get length into CX
             dec     ax                   ; sub 1 for pascal logic ?!?
             mov     bx,ax
             sub     cx,bx                ; use length-1 bytes
             lds     si,dword ptr[bp+10]  ; Structure OFS:SEG into DS:SI
             mov     ax,si                ; put length si in ax
             add     ax,bx                ; add in offset
             mov     si,ax                ; put back in si
             xor     bx,bx                ; get a zero
             mov     di,1021h             ; hold xor value
MainLoop:    mov     dx,cx                ; save number of bytes
             lodsb                        ; ax <-- Structure [byte]
             mov     cx,8                 ; do 8 times
InsideLoop:  shl     al,1
             rcl     bx,1
             jnb     SkipXor
             xor     bx,di               ; xor bx,1021h
SkipXor:     loop    InsideLoop
             mov     cx,dx               ; restore number of bytes
             loop    MainLoop            ; and do next character
             mov     ax,bx               ; return through AX
             xchg    ah,al               ; since crc is hi-lo
; now put the CRC into the last word of structure
             mov     bx,ds
             mov     cx,[bp+8]           ; get length again into CX
             les     di,dword ptr[bp+10] ; get addr of structure ES:DI
             add     di,cx
             sub     di,2
             stosw                       ; uses ES:DI

             pop     ds
             pop     bp
             mov     sp,bp
             pop     bp
             ret     8                   ; 8 bytes passed in
Compute_CRC  endp

CODE         ends
             end
