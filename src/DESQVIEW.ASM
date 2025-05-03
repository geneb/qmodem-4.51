DATA	SEGMENT	BYTE PUBLIC

	EXTRN	IN_DV : BYTE

DATA	ENDS

CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE, DS:DATA

        Public  dv_get_version
        public  dv_pause
        public  dv_begin_critical
        public  dv_end_critical


dv_get_version  proc   far
                push   bx
                push   cx
                push   dx
                mov    cx,'DE'
                mov    dx,'SQ'
                mov    ax,2B01H
                int    21h
                cmp    al,0ffH
                je     NO_DESQVIEW
                mov    ax,bx
                mov    IN_DV,1
                jmp    short DVGV_X
NO_DESQVIEW:    sub    ax,ax
DVGV_X:         pop    dx
                pop    cx
                pop    bx
                ret
dv_get_version  endp

api_call        proc   near
                push   ax
                mov    ax,101ah
                int    15h
                mov    ax,bx
                int    15h
                mov    ax,1025h
                int    15h
                pop    ax
                ret
api_call        endp

dv_pause        Proc   far
                cmp    in_dv,1
                jne    dvp_x
                push   bx
                mov    bx,1000h
                call   api_call
                pop    bx
dvp_x:          ret
dv_pause        endp

dv_begin_critical proc far
                cmp    In_dv,1
                jne    dvbc_x
                push   bx
                mov    bx,101bh
                call   api_call
                pop    bx
dvbc_x:         ret
dv_begin_critical endp

dv_end_critical proc far
                cmp    in_dv,1
                jne    dvec_x
                push   bx
                mov    bx,101ch
                call   api_call
                pop    bx
dvec_x:         ret
dv_end_critical endp

code            ends

                end
