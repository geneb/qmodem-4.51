Unit EmulDBug;

Interface

Uses
   Dos,
   TpCrt,
   TPString,
   Initial,
   Comm,
   Screen,
   Procs;

Procedure outkey_DEBUG(CH : String);


Implementation

   Procedure WriteBracket (S:String);
   Begin
      Write ('[',S,']');
   End;


   Procedure outkey_debug(CH : String);
   Var
      x : Integer;
   Begin                          {Outkey_DBUG}
      For x := 1 To Length(CH) Do
         Begin
            Store_Cinkey(Ch[x]);
            Case Ch[x] of
               #32..#254 : Write(Ch[x]);
               #0        : WriteBracket('NUL');
               #1        : WriteBracket('SOH');
               #2        : WriteBracket('STX');
               #3        : WriteBracket('ETX');
               #4        : WriteBracket('EOT');
               #5        : WriteBracket('ENQ');
               #6        : WriteBracket('ACK');
               #7        : WriteBracket('BEL');
               #8        : WriteBracket('BS');
               #9        : WriteBracket('HT');
               #10       : WriteBracket('LF');
               #11       : WriteBracket('VT');
               #12       : WriteBracket('FF');
               #13       : WriteBracket('CR');
               #14       : WriteBracket('SO');
               #15       : WriteBracket('SI');
               #16       : WriteBracket('DLE');
               #17       : WriteBracket('DC1');
               #18       : WriteBracket('DC2');
               #19       : WriteBracket('DC3');
               #20       : WriteBracket('DC4');
               #21       : WriteBracket('NAK');
               #22       : WriteBracket('SYN');
               #23       : WriteBracket('ETB');
               #24       : WriteBracket('CAN');
               #25       : WriteBracket('EN');
               #26       : WriteBracket('SUB');
               #27       : WriteBracket('ESC');
               #28       : WriteBracket('FS');
               #29       : WriteBracket('GS');
               #30       : WriteBracket('RS');
               #31       : WriteBracket('US');
               #255      : WriteBracket('0xFF');
            End; { Case }
         End;
   End;

End.
