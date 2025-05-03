   Function Connected : Boolean;
   Begin
      Connected := Online or Local;
   End;

   Procedure Parse(Var Parse_Line : Str80);
   Var
      x : Integer;
   Begin
      Parse_Line := Trim(Parse_Line);
      FillChar(Responses, SizeOf(Responses), 0);
      Inputs := 1;
      x := 1;
      While x <= Length(Parse_Line) Do
         If (Parse_Line[x] In [',', ' ', ';']) And (Inputs <= Max_Inputs) Then
            Begin
               Inputs := Succ(Inputs);
               If Inputs > Max_Inputs Then
                  Exit;
               While (Parse_Line[x] In [',', ' ', ';']) And
                     (x <= Length(Parse_Line)) Do
                     Inc(x);
            End
         Else
            Begin
               If Length(Responses[Inputs]) < 30 then
                  Responses[Inputs] := Responses[Inputs] + Parse_Line[x];
               Inc(x);
            End;
   End;

   Function Receive(Var C : Char) : Boolean;
   Var
      CC : Char;
   Begin
      CC := #0;
      If Keypressed Then
         Begin
            CC := #0;
            CharWord := ReadKeyA;
            Case CharWord Of
               F5 : SysopToDOS;
               Else If ExtendedChar=Normal then
                    CC := Char(CharWord);
            End;
         End;
      If (CC = #0) And CommPressed Then
         Case DataBits Of
            Unknown   : CC := Determine_Bits;
            EightBits : CC := Cinkeyz;
            SevenBits : CC := Chr(Ord(Cinkeyz) And $7F);
         End;
      C := CC;
      Receive := (CC <> #0)
   End;

   {  Parses a time in the form "14:51" to yield minutes since midnite  }

   Function FTime : Integer;
   Begin
      FTime := CurrentTime div 60;
   End;


   Function TimeLeft : Integer;
   Begin
      TimeLeft := qq.HostMaxTime - (FTime - LogonTime);
   End;

   {  Return the numeric (integer) value of a string  }

   Function Value(Original_String : String) : Word;
   Var
      Number         : Word;
   Begin
      If Str2Word(Original_String, Number) then
         Value := Number
      Else
         Value := 0;
   End;

   {  Translate any integer or real into a string  }

   Function Sc(A : Real)      : Str80;
   Var
      s              : Str80;
   Begin
      Str(A:1:0, s);
      Sc := s
   End;

   Procedure Reset_Page;
   Begin
      Lines_Remaining := Lines_Per_PAge;
   End;


   Function Stop_Flow : Boolean;
   Var
      CT             : Boolean;
      S_Char         : Char;

         Function Prompt_For_More : Char;
         Var
            C              : Char;
            CStr           : String[2];
            Valid_Char     : Set Of Char;
         Begin
            Valid_Char := ['C', 'S', 'N', ^M];
            If Not Cancel_Allowed Then
               Valid_Char := Valid_Char - ['S'];
            SendText('- More - [C]ontinue, [N]onStop');
            If Cancel_Allowed Then
               SendText(', [S]top? ');
            Repeat
               CStr := STUpcase(GetPromptKey);
               If CStr = '' Then
                  C := 'C'
               Else
                  C := CStr[1];
            Until (C In Valid_Char) Or Not Connected;
            SendText(CharStr(#8,  40 + Ord(CStr[0])));
            Clreol;
            Prompt_For_More := C
         End;


         Procedure Start_Stop;       { User hits <CTRL> S }
         Var
            TimeMark       : Integer;
            CH             : Char;
         Begin
            TimeMark := FTime;
            Repeat
               Repeat
               Until Receive(CH) Or Not Connected Or (FTime - TimeMark > 5);
               CT := (CH In [^K, ^C, #32]) And Cancel_Allowed;
            Until (CH In [^s, ^q, ^K, ^C, #32]) Or Not Connected Or (FTime - TimeMark > 6);
         End;

   Begin
      CT := False;
      If LinesPerPage = 0 Then
         Lines_Remaining := NonStop;
      If Receive(S_Char) Then
         Begin
            Case S_Char Of
               ^S : Start_Stop;
               ^K, ^C, #32 :
                  Begin
                     If Cancel_Allowed Then
                        Begin
                           CT := True;
                           SendCRLF;
                        End;
                  End;
            End;                  { Case }
         End
      Else
         If Lines_Remaining <> NonStop Then
            If Lines_Remaining = 0 Then
               Begin
                  Case Prompt_For_More Of
                     ^m, 'C' : Reset_Page;
                     'S' :
                        Begin
                           Reset_Page;
                           CT := True;
                        End;
                     'N' : Lines_Remaining := NonStop;
                  End             { case }
               End;               { if lines > 0 }
      Stop_Flow := CT;
   End;


   Function Send_File(FName : String) : Boolean;
   Var
      Done,
      Count_Lines : Boolean;
      CH, EX      : Char;
      Text_File   : Text;
      ss          : String;
      x           : Word;
   Begin                          { Send File }
      CH := ' ';
      Reset_Page;
      Done := False;
      Count_Lines := (LinesPerPage <> 0);
      Cancel_Allowed := True;
      If ExistFile(FName) Then
         Begin
            Assign(Text_File, FName);
            Reset(Text_File);
            Send_File := True;
            While Connected And (Not Done) And (Not EOF(Text_File)) Do
               Begin
                  Readln(Text_File, ss);
                  ss := ss + ^M^J;
                  SendText(ss);
                  For x := 1 to length(ss) do
                     Case ss[x] of
                        ^J : If Count_Lines Then
                                Dec(Lines_Remaining);
                        ^L : Begin
                                If Lines_Remaining >= 0 Then { In case they set Nonstop }
                                   Reset_Page
                             End;
                      End;            { Case }
                  Done := Stop_Flow;
               End;               { until done }
            Close(Text_File);
         End
      Else Send_File := False;
      SendCRLF;
      Cancel_Allowed := True;
   End;


  {=============================
  =>
  =>  Prompt user for a line.
  =>
  =============================}

   Function Ask_A_Question(Question       : String;
                           Security, HotKey, FinalCR : Boolean;
                           GoodChar : Input_Type) : Str80;

   Var
      SpecialSet     : Set Of Char;
      Beeped         : Boolean;
      Temp           : Str80;
      x              : Integer;
      C              : Char;
   Begin
      Temp := '';
      If Connected Then
         Begin
            Beeped := False;
            Case GoodChar Of
               NumberOnly : SpecialSet := ['0'..'9', ^H, ^m, #127];
               FilterInput : SpecialSet := [#32..#126, ^H, ^m, #127];
               MorePrompt : SpecialSet := ['N', 'n', 'C', 'c', 'S', 's', ^m];
               NoFilter : SpecialSet := [#0..#255];
               YesOrNo : SpecialSet := ['Y', 'y', 'N', 'n', ^m, ^H, #127];
               OnlyCr : SpecialSet := [^m]
            End;
            SendText(Question);
            Repeat
               Repeat
                  Minutes_Passed := FTime;
                  Repeat
                     If FTime < Minutes_Passed Then
                        x := (FTime + 1440) - Minutes_Passed
                     Else
                        x := FTime - Minutes_Passed;

                     If x >= 6 Then
                        Begin
                           SendCRLF;
                           SendLine('Keyboard Timeout!  Logging you off');
                           Logit ('@HOST > Keyboard Timeout');
                           HangupHost;
                        End
                     Else
                        If (x >= 5) And Not Beeped Then
                           Begin
                              SendCRLF;
                              SendLine(^G'You will be logged off if you do not continue within 60 seconds');
                              Beeped := True;
                           End;
                  Until Receive(C) Or (Not Connected);
               Until (C In SpecialSet) Or Not Connected;
               If Connected Then
                  Case C Of
                     ^H, #127 : If Length(Temp) > 0 Then
                                   Begin
                                      Temp[0] := Pred(Temp[0]);
                                      SendText(^H' '^H);
                                   End;
                     ' '..'~' : If Length(Temp) < 80 Then
                                   Begin
                                      Temp := Temp + C;
                                      If Security Then
                                         Begin
                                            If Online Then
                                               Write_Byte('*'); { Send a '*' to the caller but }
                                            Write('*');
                                         End
                                      Else SendText(C);
                                   End;
                  End;            { Case }
            Until (C = ^m) Or (HotKey And (Length(Temp) > 0)) Or Not Connected;
            If FinalCR And Connected Then SendCRLF;
            Parse(Temp);
         End;
      Ask_A_Question := Temp;
   End;

  {=============================
  =>
  =>  Get Answers the Easy Way!
  =>
  =============================}

   Function GetSecurity(What : String) : Str80;
   Begin
      GetSecurity := Ask_A_Question(What, True, False, True, FilterInput);
   End;

   Function GetLine(What : String) : Str80;
   Begin
      GetLine := Ask_A_Question(What, False, False, True, FilterInput);
   End;

   Function GetYesNo(What : String) : Str80;
   Begin
      GetYesNo := Ask_A_Question(What, False, False, True, YesOrNo);
   End;

   Function GetCR(What : String) : Str80;
   Begin
      GetCR := Ask_A_Question(What, False, False, True, OnlyCr);
   End;

   Function GetNumber(What : String) : Str80;
   Begin
      GetNumber := Ask_A_Question(What, False, False, True, NumberOnly);
   End;

   Function GetPromptKey : Str80;
   Begin
      GetPromptKey := Ask_A_Question('', False, True, False, MorePrompt);
   End;
