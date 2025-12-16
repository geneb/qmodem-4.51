{$A-,B-,D-,E-,F+,G-,I-,L-,N-,O+,P+,R-,S-,V+,X+}
{$M 17000,88000,655360}
{$F+}
{$IfDef OVR} {$O+} {$EndIf}
{$IfDef Int14}
   {$IfNDef Basic}
      {$IfNDef Plus}
         {$IfNDef Cross}
            {$IfNDef JnL}
               !! Need to define one of the above !!
            {$EndIf}
         {$EndIf}
      {$EndIf}
   {$EndIf}
{$EndIf}

Program Qmodem;

{$I TPDEFINE.INC}

Uses
   QmMain;

{$IFDEF OVR}
   {$I Ovr01.INC    }
{$ENDIF}


Begin
   Main;
End.
