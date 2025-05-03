Program Script_Fixer;

(*

Convert the following   '~'  to  '^~'   in SEND and WHEN commands.
                        '{'  to  '^M'
                        '.'  to  ';'

*)

Uses DOS,
     TPCRT,
     tpstring,
     strings;

Label
   Skipped, NextOne, Hmmm;
Type
   Str64 = String[64];

Var
   instr,OutStr : String[255];
   fin, fout : Text;
   enough    : Boolean;
   n, l, c   : Integer;
   Srec      : SearchRec;
   InBuf, OutBuf : Array[1..10240] of Char;
   PauseFix      : Boolean;


Function Exist (filename : str64) : boolean;
var
   fil : file;
   io : Integer;
Begin
   assign (fil, filename);
   reset (fil);
   io := ioresult;
   exist := (io = 0);
   close (fil);
   io := ioresult;
End;


Begin
   DetectMultitasking := true;
   Reinitcrt;
   PauseFix := False;
   If ParamCount < 1 then
      Begin
         Writeln;
         Writeln ('SCRFIX 1.0 - Correct usage is:');
         Writeln ('             SCRFIX ScriptFileName   (may include wildcards)');
         Halt;
      End;
   Writeln ('SCRFIX started.');
   FindFirst(Paramstr(1),$20,Srec);
   While DosError = 0 do
      Begin
         If JustExtension(Srec.Name) = 'COM' then Goto Skipped;
         If JustExtension(Srec.Name) = 'EXE' then Goto Skipped;
         If JustExtension(Srec.Name) = 'BAT' then Goto Skipped;
         If JustExtension(Srec.Name) = 'BAK' then Goto Skipped;
         If JustExtension(Srec.Name) = 'ARC' then Goto Skipped;
         If JustExtension(Srec.Name) = 'ZIP' then Goto Skipped;
         If JustExtension(Srec.Name) = 'PAS' then Goto Skipped;
         If JustExtension(Srec.Name) = 'C'   then Goto Skipped;
         If JustExtension(Srec.Name) = 'ASM' then Goto Skipped;
         If JustExtension(Srec.Name) = 'CNF' then Goto Skipped;
         If JustExtension(Srec.Name) = 'FON' then Goto Skipped;
         If JustExtension(Srec.Name) = 'PRE' then Goto Skipped;
         Assign (fin, Srec.Name);
         SetTextBuf(fin, InBuf);
         Reset(Fin);
         Assign (fout, 'SCRFIX$$.$$$');
         SetTextBuf(fout, OutBuf);
         Rewrite(fout);
         n := 0;
         Write (Srec.Name:12,' -  ');
         While not EOF(fin) do
            Begin
               Readln(fin, instr);
               Inc(n);
               L := StripCountL(instr,' ');
               If Instr > '' then
                  Begin

                     (*Convert ~ to ^~ and { to ^M *)
                     If (Pos('SEND', STupCase(Instr)) = 1) or
                        (Pos('WHEN', StupCase(Instr)) = 1) then
                        Begin
                           SwapSubString (Instr, '^~',#255,enough,255);
                           SwapSubString (Instr, '{','^M',enough,255);
                           SwapSubString (Instr, '~','^~',enough,255);
                           SwapSubString (Instr, #255,'^~',enough,255);
                        End;

                     (* convert the . to ; in first position *)
                     If InStr[1] = '.' then Instr[1] := ';';

                  End;
               Writeln(fout,CharStr(' ',L)+Instr);
               Hmmm:
            End;
         Writeln (n:4,' lines processed');
         Close(fin);
         Close(fout);
         Erase(fin);
         Rename(fout,Srec.Name);
         Goto NextOne;

         Skipped:
         Writeln(Srec.Name:12,' -       Skipped');

         NextOne:
         FindNext(Srec);
      End;
End.
