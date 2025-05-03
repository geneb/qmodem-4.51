                 PUBLIC      DELAY
                 .Model      TPascal
                 .CODE
BiosSeg          EQU         040h
LowTick          EQU         06Ch
HighTick         EQU         LowTick + 2
OverFlow         EQU         HighTick + 2
LowOrder         DW          0
HighOrder        DW          0
Delay            Proc        Far DTime             ; let tasm take care of
                 Mov         AX,[DTime]            ; passed # MS on stack
                 Mov         CX,037h               ; ms/tick
                 Xor         DX,DX
                 Div         CX
                 Mov         Word Ptr CS:[LowOrder],AX
                 Mov         AX,BiosSeg
                 Mov         ES,AX
                 Mov         AX,ES:[LowTick]
                 Add         Word Ptr CS:[LowOrder],AX
                 Mov         AX,ES:[HighTick]
                 Mov         Word Ptr CS:[HighOrder],AX
                 Adc         Word Ptr CS:[HighOrder],0
DelayLoop:
                 Mov         AL,ES:[OverFlow]        ; set at midnight
                 Or          AL,AL
                 Jz          NoOverFlow
                 Mov         CS:[HighOrder],0
NoOverflow:
                 Mov         AX,CS:[HighOrder]
                 Cmp         AX,ES:[HighTick]
                 JL          EndDelay
                 Mov         AX,CS:[LowOrder]
                 Cmp         AX,ES:[LowTick]
                 JG          DelayLoop
EndDelay:
                 Ret
Delay            EndP
                 END
