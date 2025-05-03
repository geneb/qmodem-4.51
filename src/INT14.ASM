            .MODEL  TPASCAL

            .DATA
            EXTRN  ral : BYTE
            EXTRN  rah : BYTE
            EXTRN  rdx : WORD

            .CODE
Int14BIOS   PROC FAR
            PUBLIC Int14BIOS;
            mov   al, ral
            mov   ah, rah
            mov   dx, rdx
            int   14h
            mov   ral, al
            mov   rah, ah
            mov   rdx, DX
            ret
Int14BIOS   ENDP
CODE        ENDS
            END
