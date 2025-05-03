Unit Music;

   {Optimized  3-15-88    Now uses Inc, Dec, Succ, Pred}

Interface

Uses
   TpCrt,
   Initial,
   Comm,
   Screen,
   Procs;



Var
   { Music Vars }
   Note_Octave    : Integer;
   Note_Fraction  : Real;
   Note_Duration  : Integer;
   Note_Length    : Real;
   Note_Quarter   : Real;


Procedure Music_Set;
Procedure Music_Maker(Var Ch1 : Char);
Procedure Play_Music(S : String);


Implementation


   Procedure Play_Music(S : String);
   Const
      Note_Offset : Array['A'..'G'] Of Integer = (9, 11, 0, 2, 4, 5, 7);
      Note_Freqs : Array[0..84] Of Integer = (
                                              0,
                                              65, 69, 73, 78, 82, 87, 92, 98, 104, 110, 116, 123,
                                              131, 139, 147, 156, 165, 175, 185, 196, 208, 220, 233, 247,
                                              262, 278, 294, 312, 330, 350, 370, 392, 416, 440, 466, 494,
                                              524, 556, 588, 624, 660, 700, 740, 784, 832, 880, 932, 988,
                                              1048, 1112, 1176, 1248, 1320, 1400, 1480, 1568, 1664, 1760, 1864, 1976,
                                              2096, 2224, 2352, 2496, 2640, 2800, 2960, 3136, 3328, 3520, 3728, 3952,
                                              4192, 4448, 4704, 4992, 5280, 5600, 5920, 6272, 6656, 7040, 7456, 7904);

      Quarter_Note   = 0.25;      (* Length of a quarter note *)

   Var
      Play_Freq      : Integer;
      Play_Duration  : Integer;
      Rest_Duration  : Integer;
      I              : Integer;
      C              : Char;
      Freq           : Array[0..6, 0..11] Of Integer Absolute Note_Freqs;
      N              : Integer;
      XN             : Real;
      K              : Integer;

      Function GetInt : Integer;
      Var
         N              : Integer;
      Begin
         N := 0;
         While (S[I] In ['0'..'9']) Do
         Begin
            N := N * 10 + Ord(S[I]) - Ord('0');
            Inc(I);
         End;
         Dec(I);
         GetInt := N;
      End;

   Begin
      S := S + ' ';
      I := 1;
      While (I < Length(S)) Do
         Begin                    (* Interpret Music *)
            C := Upcase(S[I]);
            Case C Of
               'A'..'G' : Begin (* A Note *)
                             N := Note_Offset[C];
                             Play_Freq := Freq[Note_Octave, N];
                             XN := Note_Quarter * (Note_Length / Quarter_Note);
                             Play_Duration := Trunc(XN * Note_Fraction);
                             Rest_Duration := Trunc(XN * (1.0 - Note_Fraction));
                             If S[Succ(I)] In ['#', '+', '-'] Then
                                Begin
                                   Inc(I);
                                   Case S[I] Of
                                      '#' : Play_Freq :=
                                            Freq[Note_Octave, N + 1];
                                      '+' : Play_Freq :=
                                            Freq[Note_Octave, N + 1];
                                      '-' : Play_Freq :=
                                            Freq[Note_Octave, N - 1];
                                   Else ;
                                   End (* Case *) ;
                                End;
                             If S[Succ(I)] In ['0'..'9'] Then
                                Begin
                                   Inc(I);
                                   N := GetInt;
                                   If N > 0 then
                                      XN := (1.0 / N) / Quarter_Note;
                                   Play_Duration := Trunc(Note_Fraction * Note_Quarter * XN);
                                   Rest_Duration := Trunc((1.0 - Note_Fraction) * XN * Note_Quarter);
                                End;
                             If S[Succ(I)] = '.' Then
                                Begin
                                   XN := 1.0;
                                   While (S[Succ(I)] = '.') Do
                                      Begin
                                         XN := XN * 1.5;
                                         Inc(I);
                                      End;
                                   Play_Duration := Trunc(Play_Duration * XN);
                                End;
                             Sound(Play_Freq);
                             Delay(Play_Duration);
                             NoSound;
                             Delay(Rest_Duration);
                          End (* A Note *) ;
               'M' : Begin (* 'M' Commands *)
                        Inc(I);
                        C := S[I];
                        Case C Of
                           'F' : ;
                           'B' : ;
                           'N' : Note_Fraction := 0.875;
                           'L' : Note_Fraction := 1.000;
                           'S' : Note_Fraction := 0.750;
                        Else ;
                        End (* Case *) ;
                     End (* 'M' Commands *) ;
               'O' :
               Begin (* Set Octave *)
                        Inc(I);
                        N := Ord(S[I]) - Ord('0');
                        If (N < 0) Or (N > 6) Then N := 4;
                        Note_Octave := N;
                     End (* Set Octave *) ;
               '<' : Begin (* Drop an octave *)
                        If Note_Octave > 0 Then Dec(Note_Octave);
                     End (* Drop an octave *) ;
               '>' : Begin (* Ascend an octave *)
                        If Note_Octave < 6 Then Inc(Note_Octave);
                     End (* Ascend an octave *) ;
               'N' : Begin (* Play Note N *)
                        Inc(I);
                        N := GetInt;
                        If (N > 0) And (N <= 84) Then
                           Begin
                              Play_Freq := Note_Freqs[N];
                              XN := Note_Quarter * (Note_Length / Quarter_Note);
                              Play_Duration := Trunc(XN * Note_Fraction);
                              Rest_Duration := Trunc(XN * (1.0 - Note_Fraction));
                           End
                        Else If (N = 0) Then
                           Begin
                              Play_Freq := 0;
                              Play_Duration := 0;
                              Rest_Duration := Trunc(Note_Fraction *
                                                     Note_Quarter *
                                                     (Note_Length / Quarter_Note));
                           End;
                        Sound(Play_Freq);
                        Delay(Play_Duration);
                        NoSound;
                        Delay(Rest_Duration);
                     End (* Play Note N *) ;
               'L' : Begin (* Set Length of Notes *)
                        Inc(I);
                        N := GetInt;
                        If N > 0 Then Note_Length := 1.0 / N;
                     End (* Set Length of Notes *) ;
               'T' : Begin (* # of quarter notes in a minute *)
                        Inc(I);
                        N := GetInt;
                        If (N >= 32) and (N <= 255) Then
                           Note_Quarter := (1092.0 / 18.2 / N) * 1000.0;
                     End (* # of quarter notes in a minute *) ;
               'P' : Begin (* Pause *)
                        Inc(I);
                        N := GetInt;
                        If (N < 1) Then
                           N := 1
                        Else
                           If (N > 64) Then
                              N := 64;
                        Play_Freq := 0;
                        Play_Duration := 0;
                        Rest_Duration := Trunc(((1.0 / N) / Quarter_Note) * Note_Quarter);
                        Sound(Play_Freq);
                        Delay(Play_Duration);
                        NoSound;
                        Delay(Rest_Duration);
                     End (* Pause *) ;
            Else
            End (* Case *) ;
            Inc(I);
         End (* Interpret Music *) ;
      NoSound;
   End;

   Procedure Music_Set;
   Begin
      Note_Octave   := 4;
      Note_Fraction := 0.875;
      Note_Length   := 0.25;
      Note_Quarter  := 500.0;
   End;

   Procedure Music_Maker(Var Ch1 : Char);
   Var
      CH             : Char;
      music_string   : String;
   Begin
      ansi3 := ansi2;
      ansi2 := ansi1;
      ansi1 := Ch1;
      If ansi3 = #27 Then
         If ansi2 = '[' Then
            If ansi1 = 'M' Then
               Begin
                  music_string := ansi1;
                  Repeat
                     Repeat
                     Until CommPressed Or Keypressed;
                     If CommPressed Then
                        Begin
                           If Length(music_string) = 255 Then
                              Begin
                                 music_string := '';
                                 CH := #27
                              End
                           Else
                              Begin
                                 CH := Cinkeyz;
                                 music_string := music_string + CH;
                              End
                        End
                     Else
                        Begin
                           If Ch <> #27 then
                              Begin
                                 CH := Char(ReadkeyA);
                                 Music_String := Music_String + CH;
                              End;
                        End;
                  Until CH In [#14, #27];
                  If (CH = #14) And noise Then
                     Play_Music(music_string);
                  Ch1 := 'M'
               End
   End;

End.
