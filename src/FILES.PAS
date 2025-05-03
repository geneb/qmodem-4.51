Unit FILES;

Interface

{$I TPDEFINE.INC}

Uses
   Qmem,           Dos,
   TpCrt,          TpDos,
   GiveBk,

   {$IFDEF UseMouse} TpMouse, {$ENDIF}
   {$IFDEF OVR}      Overlay, {$ENDIF}

   TpWindow,
   TpString,       TpInline,
   TpDir,          TpPick,
   Stack5,         Screen,
   Constant,       Initial;


Function  Log_new_drive(CH : Char) : Boolean;
Procedure Logit(Txt : String);
Procedure FindFirstD(S              : String; { Logs the drive if specified }
                     Attr           : Byte;
                     Var R          : SearchRec);
Function  SearchName(FileToFind : String) : String;
Function  CreatePath (NewPath : String) : Boolean;
Function  IncFileName(S : String) : String;
Function  FullScriptFilename(S : String)    : String;
Function  Last_Path (S : String; DefaultStr : String) : String;
Function  Exist_Wild (filename : str64) : Boolean;
Procedure Show_Dir(Pattern : String;
                   SearchAttr : Byte;
                   Var RetString : String);
Function  Test_Create(Dfile : String) : Boolean;
Function  Test_Create_And_Keep(Dfile : String) : Boolean;
Function  ExistOnQmodemPath(FName : string; var FullName : string) : Boolean;
Function  IBMFilenameFix(S : String) : String;
Function  TimeDateStamper(Var F : Text) : Boolean;


Implementation

Function Log_new_drive(CH : Char) : Boolean;
Var
   drv : Integer;
   Ok  : Boolean;
Begin
   SelectDrive(Ch);
   Log_New_Drive := (UpCase(Ch) = DefaultDrive);
End;



Function  TimeDateStamper(Var F : Text) : Boolean;
Begin
   TimeDateStamper := True;                            {4.2G!!}
   If not qq.TimeDateStamp then                        {4.2G!!}
      Exit;                                            {4.2G!!}
   Writeln(F,'*--*  ',DateS,'  -  ',TimeS,'  *--*');
   IO := IOResult;                                     {4.2G!!}
   If IO <> 0 then                                     {4.2G!!}
      Writelnt('Error stamping file with Date/Time');  {4.2G!!}
   TimeDateStamper := (IO = 0);                        {4.2G!!}
End;


Function IBMFilenameFix(S : String) : String;
Var
  x, y : word;
  temp : String;
Begin
   Temp := '';
   If S <> '' then
      Begin
         For x := 1 to length(S) do
            Begin
               If S[x] = ' ' then
                  s[x] := '$'
               Else
                  If Not(Upcase(s[x]) In ValidFileChars) Then
                     s[x] := '_';
            End;

         If s[1] = '.' then    {check the first character for the '.'}
            s[1] := '_';       {if so, change to '_'                 }

         y := length(S);                     {now start scanning for the LAST}
         While (y > 0) and (s[y] <> '.') do  {period to make the rest of the }
            dec(y);                          {line the extension             }
         If y > 0 then                       {there WAS a '.'}
            Begin
               Dec(y);
               While (y > 0) do
                  Begin
                     If s[y] = '.' then
                        s[y] := '_';
                     dec(y);
                  End;
            End;
         temp := CleanFileName(s);
      End;
   IBMFilenameFix := temp;
End;


Function ExistOnQmodemPath(FName : string; var FullName : string) : Boolean;
   {-Return true if fname is found in
      a) current directory (returns just name, no path)
      b) program's directory (DOS 3.X only)
      c) any DOS path directory
    and return path name to file}
  type
    Environment = array[0..32766] of Char;
  const
    Null : Char = #0;
    DoubleNull : string[2] = #0#0;
    PathStr : string[7] = _QMODEMUC_+'=';
  var
    E : ^Environment;
    Elast : Word;
    Epos : Word;
    Fpos : Word;
    Found : Boolean;
  begin
    {string empty?}                 {!!.09}
    if Length(FName) = 0 then begin {!!.09}
      ExistOnQmodemPath := False;   {!!.09}
      Exit;                         {!!.09}
    end;                            {!!.09}

    {Assume success}
    ExistOnQmodemPath := True;

    {Get a pointer to the DOS environment}
    E := Ptr(MemW[PrefixSeg:$2C], 0);

    {Find the end of the environment}
    Elast := Search(E^[0], 32767, DoubleNull[1], 2);
    if Elast = $FFFF then begin
      {Something is wrong}
      ExistOnQmodemPath := False;
      Exit;
    end;

    {Check the path}
    Found := False;
    Epos := 0;
    repeat
      Fpos := Search(E^[Epos], Elast-Epos, PathStr[1], Length(PathStr));
      if Fpos <> $FFFF then begin
        {QMODEM= was found}
        Inc(Epos, Fpos);
        Found := (Epos = 0) or (E^[Pred(Epos)] = Null);
        if not(Found) then
          {Something like DPATH= was found}
          Inc(Epos);
      end;
    until (Fpos = $FFFF) or Found;

    if Found then begin
      {True QMODEM= was found, skip over the QMODEM= part}
      Inc(Epos, Length(PathStr));

      {Scan each item in the path}
      repeat

        {Find the termination of the current path entry}
        Fpos := Epos;
        while (E^[Fpos] <> ';') and (E^[Fpos] <> Null) do
          Inc(Fpos);

        if Fpos > Epos then begin
          {A path entry found}
          FullName[0] := Char(Fpos-Epos);
          Move(E^[Epos], FullName[1], Fpos-Epos);
          FullName := AddBackSlash(FullName)+FName;
          if ExistFile(FullName) then
            Exit;
        end;

        {Prepare to look at next item}
        Epos := Succ(Fpos);

      until E^[Fpos] = Null;
    end;

    {Not found, even on the path}
    ExistOnQmodemPath := False;
    FullName := FName;
  end;




Function Test_Create_And_Keep(Dfile : String) : Boolean;
Var
   Ok : Boolean;
   t  : File;
Begin
   IO := 0;
   If Not ExistFile(DFile) Then
      Begin
         Assign(T, DFile);
         Rewrite(T);
         IO := IOResult;
         If IO <> 0 Then
            Begin
               WritelnT('Error creating file '+Dfile);
               Close(T);
               IO := IOResult;
            End;
      End;
   Ok := (IO = 0);
   Close (T);
   IO := IOResult;
   Test_Create_and_Keep := Ok;
End;


Function Test_Create(Dfile : String) : Boolean;
Var
   Ok : Boolean;
   t  : File;
Begin
   Assign (t, Dfile);
   Rewrite (t);
   Ok := IOResult = 0;
   Close (t);
   IO := IOResult;
   Erase (t);
   IO := IOResult;
   Test_Create := Ok;
End;


Procedure Show_Dir(Pattern : String;
                   SearchAttr : Byte;
                   Var RetString : String);
Var
   x : Integer;
   S : String[80];
Begin
   Push_Status;
   S := ' Arrows-Scroll  Alpha-Search  Enter-Selects  ESC-Exit ';
   If (SearchAttr and Directory) = Directory then
      S := ' <dir>-Change Directory ' + S;
   Display_Status (S);
   SetVerticalPick;
   ShowSizeDateTime := True;
   x := GetFileName(Pattern, SearchAttr,
                    1,1,PRLR-1,6,
                    PickColors, RetString);
   Case x of
      0 :  ;
      1 :  Writelnt ('Path not found');
      2 :  Writelnt ('No matching files');
      3 :  Writelnt (RetString+' does not exist');
      4 :  Writelnt ('Insufficient memory');
      5 :  Writelnt ('Won''t fit on screen');
      Else Writelnt ('DOS critical error : '+Long2Str(x));
   End;
   Pop_Status;
End;


Function Exist_Wild (filename : str64) : Boolean;
Var
   sr : SearchRec;
Begin
   FindFirst(Filename, AnyFile - VolumeID - SysFile - Directory, SR);
   Exist_Wild := DosError = 0;
End;

Function Last_Path (S : String; DefaultStr : String) : String;
Var
   t : String;
Begin
   If JustPathname(S) = '' then
      Last_Path := DefaultStr
   Else
      Last_Path := JustPathname(S);
End;

Function FullScriptFilename(S : String) : String;
Begin
   If (qq.Script_Path <> '') and (pos(':', S) = 0) and (pos('\', S) = 0) Then
      FullScriptFilename := AddBackSlash(qq.Script_Path) +
      DefaultExtension(S, 'SCR')
   Else
      FullScriptFilename := DefaultExtension(S, 'SCR');
End;


Function IncFileName(S : String) : String;
Var
   D: DirStr;
   N: NameStr;
   E: ExtStr;
   OK : Boolean;
   x : Integer;
   VFC : Set of Char;
Begin
   VFC := ['!', '#', '$', '%', '&', '''', '(', ')', '-', '0'..'9', '@',
           'A'..'Z', '^', '_', '`', '{', '}', '~'];
   S := STUpCase(S);

   {First massage the filename to conform to _MY_ rules...}
   FSplit(S, D, N, E);
   For x := 1 to Length(N) do
      If not (N[x] in VFC) then
         N[x] := '_';
   S := D+N+E;

   While ExistFile(S) do
      Begin
         FSplit(S, D, N, E);
            If Length(N) < 8 then
               N := N + '0'
            Else
               Begin
                  Repeat
                     OK := True;
                     If (N[Length(N)]) >= '~' then Begin
                        N[Length(N)-1] := Char(Byte(N[Length(N)-1])+1);
                        If (N[Length(N)-1]) >= '~' then Begin
                           N[Length(N)-2] := Char(Byte(N[Length(N)-2])+1);
                           If (N[Length(N)-2]) >= '~' then Begin
                              N[Length(N)-3] := Char(Byte(N[Length(N)-3])+1);
                              If (N[Length(N)-3]) >= '~' then Begin
                                 N[Length(N)-4] := Char(Byte(N[Length(N)-4])+1);
                                 If (N[Length(N)-4]) >= '~' then Begin
                                    N[Length(N)-5] := Char(Byte(N[Length(N)-5])+1);
                                    If (N[Length(N)-5]) >= '~' then Begin
                                       N[Length(N)-6] := Char(Byte(N[Length(N)-6])+1);
                                       If (N[Length(N)-6]) >= '~' then Begin
                                          N[Length(N)-7] := Char(Byte(N[Length(N)-7])+1);
                                          If (N[Length(N)-7]) >= '~' then Begin
                                             N[Length(N)-7] := '!';
                                             End;
                                          N[Length(N)-6] := '!';
                                          End;
                                       N[Length(N)-5] := '!';
                                       End;
                                    N[Length(N)-4] := '!';
                                    End;
                                 N[Length(N)-3] := '!';
                                 End;
                              N[Length(N)-2] := '!';
                              End;
                           N[Length(N)-1] := '!';
                           End;
                        N[Length(N)] := '!';
                        End
                     Else
                        N[Length(N)] := Char(Byte(N[Length(N)])+1);
                     For x := 1 to Length(N) do
                        If not (N[x] in VFC) then
                           OK := False;
                  Until OK;
               End;
         S := D+N+E;
      End;
   IncFileName := S;
End;


Function CreatePath (NewPath : String) : Boolean;
Var
   x : Word;
   s2 : String;
   s3 : String;
   here : String;
Begin
   If NewPath = '' then
      Begin
         CreatePath := True;
         Exit;
      End;
   NewPath := STUpCase(CompleteFileName(FullPathName(NewPath)));
   GetDir(0,Here);
   CreatePath := False;  {Assume it failed}

   {Check to make sure Drive is valid}
   If NewPath[1] <> DefaultDrive Then
      {It's different than the current, so check to make sure its valid}
      Begin
         SelectDrive(NewPath[1]);
         If DefaultDrive <> NewPath[1] then
            Exit  {invalid drive}
      End;

   {We are now on the correct drive...}
   If NewPath = '' then Exit;

   {Strip the Drive:}
   NewPath := Copy(NewPath,3,Length(NewPath)-2);

   {Position to the ROOT}
   ChDir('\');

   Repeat
      s2 := '';
      x := 1;
      While (x <= Length(NewPath)) and
            (x < 13) and
            (NewPath[x] <> '\') do
            Begin
               s2 := s2+NewPath[x];
               inc(x);
            End;
      NewPath := Copy(NewPath,x+1,Length(NewPath)-x+1);
      If s2 <> '' then
         Begin
            MkDir(s2);
            IO := IOResult;
            ChDir(s2);
            IO := IOResult;
            If IO <> 0 then
               Exit;
         End;
   Until NewPath = '';
   CreatePath := True;
   ChDir(Here);
   IO := IOResult;
End;


Function  SearchName(FileToFind : String) : String;
Var
   S : String;
   N : NameStr;
   D : DirStr;
   E : ExtStr;
Begin
   FSplit(FileToFind, D, N, E);
   S := FSearch(N+E,GetEnv(_QMODEMUC_)+';'+GetEnv('PATH'));
   If S = '' then
      S := FileToFind
   Else
      S := FExpand(S);
   SearchName := S;
End;


Procedure FindFirstD(S     : String; { Logs the drive if specified }
                     Attr  : Byte;
                     Var R : SearchRec);
Begin
   If Length(S) > 2 Then
      If JustPathname(S) <> '' then
         Begin
            ChDir(JustPathname(S));
            IO := IOResult;
         End;
   FindFirst(S, Attr, R);
End;


Procedure Logit(Txt : String);
Var
  xx : Word;
Begin
   If Logging Then
      Begin
         WriteLn(Log_File, TimeS + '  ' + DateS + '  ' + Txt);
         IO := IOResult;
         If IO <> 0 Then
            Begin
               Writelnt('I/O error '+Long2Str(IO)+' Writing the Log file');
               Close(Log_File);
               IO := IOResult;
               If IO <> 0 then
                  Writelnt('I/O error '+Long2Str(IO)+' Closing the Log file');
               Logging := False;
            End;
      End;
End;


End.
