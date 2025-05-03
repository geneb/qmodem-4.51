Unit QDial;

Interface

Uses    Dos,       TpCrt,   TPString,
        Initial,   Comm,    Comm2,
        Procs,     Music;

Function  Parse_String(S : String) : String;
Procedure Parse_Write_Con (S : String);
Procedure Parse_Write_Modem (S : String);
Procedure Parse_Write_Modem_Paced(S : String; DelayValue : Word);
Function  Parse_Dial_CMD (    Fonenum      : String;
                          Var Entry_number : Integer;
                              Setup_Modem  : Boolean) : String;
Procedure Dial_modem (entry_num : Integer; Var Enum : Integer);
Procedure HangupPrim;
Function  PrefixSubstitute (S : String; NoSubst : Boolean) : String;
Procedure ClearAllMarks;
Function  NoMarksFound : Boolean;


Implementation


Type
   CorM = (Console, Modem);

Function NoMarksFound : Boolean;
Var
   x              : Integer;
Begin
   For x := 1 To Max_Phones Do
      If Phone_dir^[x].Marked Then
         Begin
            NoMarksFound := False;
            Exit;
         End;
   NoMarksFound := True;
End;


Procedure ClearAllMarks;
Var
   x : Integer;
Begin
   For x := 1 To Max_Phones Do
      Begin
         Phone_dir^[x].Marked := False;
         Phone_dir^[x].LearnTag := False;
         Phone_dir^[x].NoPrefix := False;
         Fon_Changed := True;
      End;
End;


Procedure HangupPrim;
Begin
   If qq.modem_hangup = 'DTR' Then
      Drop_DTR_Low
   Else
      If qq.modem_hangup = 'BREAK' Then
         Begin
            Break_Low;
            Delay(150);
         End
      Else
         Parse_Write_Modem(qq.modem_hangup);
End;

Function  Parse_String(S : String) : String;
Var
   x : integer;
   s2 : String;
Begin
   x := 1;
   s2 := '';
   While x <= Length(S) Do
      Begin
         Case S[x] Of
            '^' : If x < Length(S) Then
                     Case S[x + 1] Of
                        '^' : Begin { place this first to trap for ^ }
                                 Inc(x);
                                 s2 := s2 + '^';
                              End;
                        'a'..'z',
                        '@'..
                        '_' : Begin
                                 Inc(x);
                                 s2 := s2 + Chr(Ord(UpCase(S[x])) - 64);
                              End;
                        Else  s2 := s2 + '^';
                     End
                  Else
                     s2 := s2 + '^';
            Else  s2 := s2 + S[x];
         End;                  { case }
         Inc(x);
      End;
   Parse_String := s2;
End;


Procedure PW_ (S : String; ConOrModem : CorM; ForcedDelay : Word);
Var
   x     : Integer;
   CH    : Char;
   Skip  : Boolean;
Begin
   x := 1;
   Skip := False;
   Delay(ForcedDelay);
   While x <= Length(S) Do
      Begin
         Case S[x] Of
            '^' : If x < Length(S) Then
                     Case S[x + 1] Of
                        '^' : Begin { place this first to trap for ^ }
                                 Inc(x);
                                 CH := '^';
                              End;
                        '~' : Begin
                                 Delay(600);
                                 Inc(x);
                                 Skip := True;
                              End;
                        'a'..'z',
                        '@'..
                        '_' : Begin
                                 Inc(x);
                                 CH := Chr(Ord(UpCase(S[x])) - 64);
                              End;
                        Else  CH := '^';
                     End
                  Else
                     CH := '^';
         Else
            CH := S[x];
         End;                  { case }
         If ConOrModem = Modem then
            Begin
               If Echo And (Not Split) And (Not Redialing) Then
                  Write(Ch);
               If Not Online then
                  Delay(qq.Dial_Pacing);
               If Skip Then Skip := False
                       Else Write_Byte(CH);
            End
         Else
            Begin
               If Skip Then Skip := False
                       Else Write(CH);
            End;
         Inc(x);
         Delay(ForcedDelay);

      End;
End;


Procedure Parse_Write_Modem(S : String);
Begin
   PW_(S,Modem,0);
End;

Procedure Parse_Write_Modem_Paced(S : String; DelayValue : Word);
Begin
   PW_(S,Modem,DelayValue);
End;

Procedure Parse_Write_Con(S : String);
Begin
   PW_(S,Console,0);
End;


Function PrefixSubstitute(S : String; NoSubst : Boolean) : String;
Var
   S1 : String;
   x  : Integer;
Begin
   S1 := '';
   If (S[1] <> '`') or NoSubst then
      If qq.Dial_Prefix = 'BREAK' then
         Begin
            Break_Low;
            Delay(200);
         End
      Else
         If qq.Dial_Prefix = 'DTR' then
            Drop_DTR_Low
         Else
            S1 := qq.Dial_Prefix;
   { Do Prefix character substitution }
   For x := 1 To Length(S) Do
      If S[x] In ['A'..'J'] Then
         Begin
            If Not NoSubst then
               S1 := S1 + Prefix[Ord(S[x]) - Ord('A') + 1]
         End
      Else
         If S[x] <> '`' then
            S1 := S1 + S[x];
   PrefixSubstitute := S1;
End;


Function Parse_Dial_CMD(Fonenum      : String;
                    Var Entry_number : Integer;
                        Setup_Modem  : Boolean) : String;
Var
   x, num         : Integer;
   Phone          : String;
Begin
   Phone := '';
   Redialing := True;
   If Str2Int(Fonenum, num) Then
      Begin

         Phone := PrefixSubstitute(Phone_dir^[num].Number, Phone_Dir^[num].NoPrefix);

         If Setup_Modem Then
            Begin
               If (qq.baud_chng_before <> '') And Not Online Then
                  Parse_Write_Modem(qq.baud_chng_before);
               If Not Online Then
                  NewSpeed := Phone_dir^[num].ComSpeed;
               NewSBits := Phone_dir^[num].sbits;
               NewDBits := Phone_dir^[num].dbits;
               parity := Phone_dir^[num].parity;
               NewCParity := Parity;
               Init_Port;
               Delay(40);
               If (qq.baud_chng_after <> '') And Not Online Then
                  Parse_Write_Modem(qq.baud_chng_after);
            End;

         Entry_number := num;
         Parse_Dial_CMD := Phone;
         Redialing := False;
      End
   Else
      Parse_Dial_CMD := '';
End;

Procedure Dial_modem(entry_num : Integer; Var Enum : Integer);
Begin
   Redialing := True;
   Music_Set;
   Phone := Parse_Dial_CMD(Long2Str(entry_num), num, True) + qq.Dial_Postfix;
   If Split And Not redial Then
      Begin
         Split_Window_Top;
         GotoXY(inx, iny);
      End;
   TextAttr := qq.InfoColor;
   If redial Then
      GotoXY(5, 4)
   Else
      WriteLn;
   TextAttr := qqColor;
   Redialing := True;
   Parse_Write_Modem(Phone);
   Redialing := False;
   Enum := num;
   If Split And Not redial Then
      set_split;
End;


End.
