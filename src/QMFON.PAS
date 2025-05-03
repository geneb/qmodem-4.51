
unit
  QmFon;

interface

uses
  Dos,    OpRoot, OpDos, OpString,
  OpDate, OpCmd,  OpCrt, OpWindow,
  QmCnf,  QmMisc, QmColor;

  (* Qmodem .FON file record *)

type
  Qmodem_FON_Record = Record
    Name: String[27];
    xxx1: Integer;
    Phone: String[19];
    xxx2: Word;
    Data: integer;
    Stop: Integer;
    Parity: char;
    Script: String[12];
    Date: Word;
    xxx3: String[6];
    Calls: LongInt;
    xxx4: Integer;
    Protocol: Char;
    Duplex: Char;
    Password: String[14];
    EntryNumber: Integer;
    Marked: Boolean;
    Emulation: Byte;
    LearnTag: Boolean;
    NoteNum: Word;
    HasNote: Boolean;
    NoPrefix: Boolean;
    Baud: LongInt;
    xxx5: array[1..3] of byte;
  End;

type
  Qmodem_FON_Pointer = ^Qmodem_FON_Object;
  Qmodem_FON_Object = object(Root)
    FON_File:     file of Qmodem_FON_Record;
    FON_Record:   array[1..200] of ^Qmodem_FON_Record;
    FON_Filename: string;

    constructor Init(Fn: string);
    destructor  Done; virtual;
    procedure   PutRecord(N: word; R: Qmodem_FON_Record);
  end;

implementation

  (* Qmodem_FON_Object methods *)

  constructor Qmodem_FON_Object.Init(Fn: string);
  var
    S: string;
    I: byte;
    FR: Qmodem_FON_Record;
    FRP: ^Qmodem_FON_Record;

    procedure EraseFonMemory(I: byte);
    var
      J: byte;
    begin
      for J := I downto 1 do If FON_Record[J] <> nil then
        FreeMemCheck(FON_Record[J], Sizeof(Qmodem_FON_Record));
    end;

    function _not: string;
    var
      S: string;
    begin
      S := ' ';

      if not Cnf.WriteFBK then
        S := ' not ';

      _not := S;
    end;

  begin
    if Fn = '' then
      fail;
    Root.Init;
    S := FullPathname(Fn);

    if not ExistFile(S) then begin
      Assign(FON_File, S);
      Rewrite(FON_File);
      CheckIoResult('Unable to open file, ' + S);
      FillChar(FR, SizeOf(Qmodem_FON_Record), $F6);

      {Set up defaults}
      with FR do begin
        Name := '';
        Phone := '';
        Data := Cnf.Data;
        Stop := Cnf.Stop;
        Parity := Cnf.Parity;
        Script := '';
        Date := DateStringToDate(Cnf.DateStr, TodayString(Cnf.DateStr));
        Calls := 0;
        Protocol := 'X';
        Duplex := 'F';
        Password := '';
        EntryNumber := 0;
        Marked := false;
        Emulation := 0;
        LearnTag := false;
        HasNote := false;
        NoPrefix := false;
        Baud := Cnf.CommSpeed;
      end;

      for i := 1 to 200 do begin
        if not GetMemCheck(FON_Record[I], Sizeof(Qmodem_FON_Record)) then begin
          Close(FON_File);
          EraseFonMemory(I);
          fail;
        end;

        FR.NoteNum := I;
        Move(FR, FON_Record[I]^, Sizeof(Qmodem_FON_Record));
        Write(FON_File, FON_Record[I]^);
        CheckIoResult('Unable to write to file, ' + S);
      end;

      Close(FON_File);
      CheckIoResult('Unable to close file, ' + S);
    end else begin
      If Warning(S + ' already exists! (Backup will' + _not + 'be written).') then
        Fatal('Process terminated at users request');

      if Cnf.WriteFBK then
        if not Backup(S, 'FBK') then
          Fatal('Unable to backup file ' + S);
    end;

    Assign(FON_File, S);
    Reset(FON_File);

    for I := 1 to 200 do begin
      if not GetMemCheck(FON_Record[I], Sizeof(Qmodem_FON_Record)) then begin
        Close(FON_File);
        EraseFonMemory(I);
        fail;
      end;

      Read(FON_File, FON_Record[I]^);
      CheckIoResult('Unable to read file, ' + S);
    end;

    FON_Filename := FullPathname(S);
  end;

  destructor Qmodem_FON_Object.Done;
  var
    I: byte;
  begin
    for I := 1 to 200 do
      if FON_Record[I] <> nil then
        FreeMemCheck(FON_Record[I], sizeof(Qmodem_FON_Record));

    close(FON_File);
    root.done;
  end;

  procedure Qmodem_FON_Object.PutRecord(N: word; R: Qmodem_FON_Record);
  begin
    Seek(FON_File, Pred(N));
    CheckIoResult('Unable to seek file, ' + FON_Filename);
    Write(FON_File, R);
    CheckIoResult('Unable to write file, ' + FON_Filename);
  end;

end.

