DATA    SEGMENT BYTE PUBLIC
        ASSUME  DS:DATA
        EXTRN   MultiTasker : BYTE
DATA    ENDS


CODE  SEGMENT  BYTE PUBLIC
      ASSUME  CS:CODE

; MultiTasker  DB  -1   ; will indicate which multitasker is running, if any
                        ;-1 means this hasn't yet been called, and
                        ;    initialization is required using GIVEINIT
                        ; 0 means no multitasker is present, only naked dos
                        ; 1 means DESQview is running
                        ; 2 means DoubleDos is running

GIVEINIT PROC	 FAR
         PUBLIC  GIVEINIT  ;the initialization routine, optional
         PUSH    AX        ; save this stuff for safety
         PUSH    BX
         PUSH    CX
         PUSH    DX
         MOV     AX,2B01H                ; DV get version request, result to AX
         MOV     CX,'DE'                 ; Illegal
         MOV     DX,'SQ'                 ;        date, on purpose
         INT     21H                     ; An error indicates DV isn't running
         CMP     AL,0FFH                 ; Are we in DV?
         JE      NO_DV                   ; Jump if not
         MOV     MultiTasker,1  	        ; 1 will mean DV is present
         JMP     SHORT InitExit
NO_DV:				; DV isn't here, maybe DD is-let's check
         MOV	AH,0E4h		; function E4h tests for presence of DoubleDos
	INT	21h  		; does nothing at all if DD not present
	CMP	AL,01  		; 1 indicates DD present, program visible
	JZ	DDhere
	CMP	AL,02 		; 2 indicates DD present, program invisible
	JZ	DDhere
        JMP     NoMultitsk      ; anything else indicates not present, so quit
DDhere: MOV	MultiTasker,2	;this value indicates DD present
        JMP     SHORT InitExit
NoMultitsk:
        MOV     MultiTasker,0        ;Neither DV nor DD running
InitExit:
        POP     DX                      ;and put it all back
        POP     CX
        POP     BX
	POP	AX
        RET
GIVEINIT ENDP


API_CALL PROC		; local DV routine that goes on stack, does whatever
         PUSH    AX	;  call is passed in BX, then goes off stack
         MOV     AX,101AH
         INT     15H                     ; OSTACK
         MOV     AX,BX
         INT     15H                     ; Parameter
         MOV     AX,1025H
         INT     15H                     ; USTACK
         POP     AX
         RET
API_CALL ENDP


GIVEBACK PROC FAR       ; Gives up the rest of its time slice when called.
                        ; GIVEINIT will be invoked automatically the first time
                        ; that GIVEBACK is called; GIVEINIT can (optionally)
                        ; be called explicitly to force initialization.
        PUBLIC  GIVEBACK
        CMP     MultiTasker,1           ;let's see what's running here
        JZ      DVrunning               ;1 means DESQview is running
        JG      DDrunning               ;2 means DoubleDos is running
        CMP     MultiTasker,0           ;only naked Dos or uninitialized state
                                        ;  remain as possibilities
        JZ      GetOutaHere             ;0 means naked Dos
        CALL    GIVEINIT                ;last remaining possibility is -1
        JMP     GIVEBACK                ;after initializing, try this again

GetOutaHere:                            ;nothing else to do, so go back
        RET

DVrunning:
        PUSH    BX
        MOV     BX,1000H                ; DV_PAUSE function call
        CALL    API_CALL
        POP     BX
        JMP     SHORT GetOutaHere


DDrunning:
        push    bp      ;save caller's base pointer register
        mov     bp,sp   ;setup to address off of base pointer register
        push    ax      ;just in case this messes up something
        mov     ax,0EE06h

Comment ~       EEh in AH is special DoubleDos giveback interrupt. 06h in AL is
six 55ms giveback intervals = 1/3 sec.  ~

        int     21h     ;invokes special DoubleDos giveback interrupt
        pop     ax      ;puts it back
	POP	BP      ;restore callers base pointer register
        JMP     SHORT GetOutaHere

GIVEBACK ENDP
CODE     ENDS
         END
