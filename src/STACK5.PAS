{$R-,S-}
Unit Stack5;

interface

Uses TpCrt;

const
  StackInitValue   = $DD; { the value to initialize the stack to. }
  SAFETY           = 20;  { This value is used as a safety buffer }
                          { when initializing the stack to the    }
                          { StackInitValue.  This default of 20   }
                          { is safe and shouldn't be lowered.     }

  {$IfNDef Bundle}
     IsRegisteredOK   : Boolean = True;   {4.2G!!}

                              {þ Invalid Registration or Hacked Version!}
     ErrorMsg1 : String[41] = #175#113#24#63#39#48#61#56#53#113#3#52#54#56#34#37+
                              #35#48#37#56#62#63#113#62#35#113#25#48#50#58#52#53+
                              #113#7#52#35#34#56#62#63#112;

                              {þ Execution Halted.}
     ErrorMsg2 : String[19] = #175#113#20#41#52#50#36#37#56#62#63#113#25#48#61+
                              #37#52#53#127;
  {$EndIf}


var
  Sav_ExitProc : Pointer; { to save the previous ExitProc }
  StartSPtr    : Word;    { holds the total stack size    }


Function StackSoFar : Word;


{*} Implementation {*}


Function StackSoFar : Word;
Var
   I : Word;
Begin
   I := 0;
   { step through stack from bottom looking for StackInitValue,}
   { stop when found }
   While I < SPtr do
     If Mem[SSeg:I] <> StackInitValue then
        Begin
           StackSoFar := StartSPtr - I;
           Exit;
        End
     Else
        Inc(I);  { look in next byte }
End;



{$F+} { this is an ExitProc so it must be compiled as far }
procedure StackReport;

{ This procedure may take a second or two to execute, especially }
{ if you have a large stack. The time is spent examining the     }
{ stack looking for our init value (StackInitValue). }

var
  x, I : Word;

begin
   ExitProc := Sav_ExitProc; { restore original exitProc first }

   (*
   I := 0;
   { step through stack from bottom looking for StackInitValue,}
   { stop when found }
   while I < SPtr do
      if Mem[SSeg:I] <> StackInitValue then
         begin
            { found StackInitValue so report the stack usage info }
            WriteLn('total stack space : ',StartSPtr);
            WriteLn('unused stack space: ', I);
            WriteLn('stack space used  : ',StartSPtr - I);
            I := SPtr; { end the loop }
         end
      else
         inc(I); { look in next byte }
    *)

    {$IfNDef Bundle}
    If not IsRegisteredOK then
       Begin
          Window(1,1,ScreenWidth,ScreenHeight);
          TextAttr := 7;
          Clrscr;
          for x := 1 to length(errormsg1) do
             write(Char(Byte(ErrorMsg1[x]) xor 81));
          Writeln;
          for x := 1 to length(errormsg2) do
             write(Char(Byte(ErrorMsg2[x]) xor 81));
          Writeln;
       End;
    {$EndIf}

End;
{$F-}


Begin
   StartSPtr := SPtr + 8;  { grab the current SP and account for used space }
   FillChar(Mem[SSeg:0], SPtr - SAFETY, StackInitValue); { init the stack   }
   Sav_ExitProc := ExitProc;                             { save exitproc    }
   ExitProc     := @StackReport;                         { set our exitproc }
End.
