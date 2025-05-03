
unit
  QmConv;

interface

uses
  Dos,      OpRoot, OpCrt,   OpDos,
  OpString, OpDate, OpFrame, OpWindow,
  QmFon,    QmMisc, QmColor;

  (* PC Plus v2.0 *)

type
  tDuplex = (Full, Half);
  tParity = (_None, _Even, _Odd, _Mark, _Space);

  tBaud =
    (Baud_300,   Baud_1200,  Baud_2400,  Baud_4800, Baud_9600,
     Baud_19200, Baud_38400, Baud_57600, Baud_115200);

  pcp20_Protocol =
    (Pcp20_Modem7,  Pcp20_1kXmodem,  Pcp20_Telink,  Pcp20_Xmodem,
     Pcp20_Ymodem,  Pcp20_Kermit,    Pcp20_Ascii,   Pcp20_CisB,
     Pcp20_Wxmodem, Pcp20_1kXmodemG, Pcp20_YmodemG, Pcp20_Imodem,
     Pcp20_Sealink, Pcp20_Ext1,      Pcp20_Ext2,    Pcp20_Ext3,
     Pcp20_Zmodem,  Pcp20_RawAscii);

  pcp20_Terminal =
    (Pcp20_TTY,      Pcp20_VT52,    Pcp20_VT100,   Pcp20_VT102,
     Pcp20_VT220,    Pcp20_VT320,   Pcp20_ANSI,    Pcp20_IBMPC,
     Pcp20_WYSE75,   Pcp20_ATT605,  Pcp20_ATT4410, Pcp20_TVI922,
     Pcp20_HEATH19,  Pcp20_IBM3101, Pcp20_IBM3161, Pcp20_DGD100,
     Pcp20_DBD200,   Pcp20_DGD210,  Pcp20_ADDS60,  Pcp20_ADDS90,
     Pcp20_ADM3A,    Pcp20_ADM5,    Pcp20_ADM31,   Pcp20_ESPRIT3,
     Pcp20_3270_950, Pcp20_TVI910,  Pcp20_TVI912,  Pcp20_TVI920,
     Pcp20_TVI925,   Pcp20_TVI950,  Pcp20_TVI955,  Pcp20_WYSE50,
     Pcp20_WYSE100);

  PcPlus20 = record
    Name:       array[1..25] of char;
    Phone:      array[1..21] of char;
    Baud:       integer;
    Parity:     tParity;
    Data:       byte;
    Stop:       byte;
    Duplex:     tDuplex;
    Script:     array[1..9] of char;
    Date:       array[1..9] of char;
    Calls:      integer;
    Protocol:   Pcp20_Protocol;
    Terminal:   Pcp20_Terminal;
    Mode:       byte;
    Password:   array[1..11] of char;
    Macro:      array[1..9] of char;
    Keyboard:   array[1..9] of char;
    Port:       byte;
    Notefile:   array[1..9] of char;
  end;

  (* PC Plus v1.1 *)

type
  Pcp11_Protocol =
    (Pcp11_None,   Pcp11_Modem7,    Pcp11_YModem,  Pcp11_Telink,
     Pcp11_Xmodem, Pcp11_YmodemBAT, Pcp11_Kermit,  Pcp11_Ascii,
     Pcp11_CISB,   Pcp11_WXmodem,   Pcp11_YmodemG, Pcp11_YmodemGBAT,
     Pcp11_Imodem, Pcp11_Sealink,   Pcp11_Ext1,    Pcp11_Ext2,
     Pcp11_Ext3);

  Pcp11_Terminal =
    (Pcp11_vt52,    Pcp11_vt102,   Pcp11_ansi,   Pcp11_heath19,
     Pcp11_ibm3101, Pcp11_addsVP,  Pcp11_adm5,   Pcp11_tvi910,
     Pcp11_tvi920,  Pcp11_tvi925,  Pcp11_tvi950, Pcp11_tvi955,
     Pcp11_wyse50,  Pcp11_wyse100, Pcp11_3270,   Pcp11_tty);

  Pcp11_DirRec = record
    Name:     array[1..25] of char;
    Phone:    array[1..21] of char;
    Baud:     integer;
    Parity:   tParity;
    Data:     byte;
    Stop:     byte;
    Duplex:   tDuplex;
    Script:   array[1..9] of char;
    Date:     array[1..9] of char;
    Calls:    integer;
    Protocol: Pcp11_Protocol;
    Terminal: Pcp11_Terminal;
  end;

  (* Telix v3.11 *)

type
  Tlx311_Terminal =
    (Tlx311_TTY,  Tlx311_AnsiBBS, Tlx311_Vt102,
     Tlx311_Vt52, Tlx311_Avatar);

  TlxDirRec = record
    name:     array[1..25] of char;
    phone:    array[1..17] of char;
    baud:     TBaud;
    parity:   TParity;
    data:     byte;
    stop:     byte;
    script:   array[1..12] of char;
    Date:     array[1..6] of char;      {'MMDDYY' format}
    Calls:    word;
    terminal: tlx311_Terminal;
    protocol: char;
    Duplex:   byte;                     {if 0 bit set then echo = true}
    fill:     word;
    prefix:   byte;                     {prefix + ord('1')}
    password: array[1..14] of char;
  end;

  (* Boyan 5.0 *)

type
  Boyan50Rec = record
    _byte: byte;
    name: string[29];
    number: string[16];
    script: string[8];
    baud: byte;   {ord 00=300, 01=1200, 03=4800, 04=9600, 05=19200, 06=38400}
    parity: byte; {ord 00=None, 01=Even, 02=Odd}
    BAM: char;
    LastCall: array[1..5] of char;
    Protocol: char;
    _longint: longint;
  end;

  boyan50pwd = record
    password: string[14];
  end;

  (* Converters *)

type
  Converter_Pointer = ^Converter;
  Converter = object(Root)
    Status_Window: RawWindowPtr;

    procedure ConvertFonRec(RecNo: word); virtual;
    procedure CheckGetMem(var P; Size: word); virtual;
    procedure ShowStatus(Percent: real); virtual;
    procedure ProcessFiles; virtual;
  end;

  Pcp20Ptr = ^Pcp20Dir;
  Pcp20Dir = object(Converter)
    FON_Pointer:           Qmodem_FON_Pointer;
    Procomm_Plus_File:     file;
    Procomm_Plus_Filename: string;
    File_IO_Buffer:        pointer;

    constructor Init(var P: Qmodem_FON_Pointer; S: string);
    destructor  Done; virtual;
    procedure   ConvertFonRec(RecNo: word); virtual;
    procedure   processfiles; virtual;
  end;

  Pcp11Ptr = ^Pcp11Dir;
  Pcp11Dir = object(Converter)
    FON_Pointer:           Qmodem_FON_Pointer;
    Procomm_Plus_File:     file;
    Procomm_Plus_Filename: string;
    File_IO_Buffer:        pointer;

    constructor Init(var P: Qmodem_FON_Pointer; S: string);
    destructor  Done; virtual;
    procedure   ConvertFonRec(RecNo: word); virtual;
    procedure   processfiles; virtual;
  end;

  Tlx311Ptr = ^Tlx311Dir;
  Tlx311Dir = object(Converter)
    FON_Pointer:    Qmodem_FON_Pointer;
    Telix_File:     file;
    Telix_Filename: string;
    File_IO_Buffer: pointer;
    Telix_File_Ofs: longint;
    Continue_Proc: boolean;

    constructor Init(var P: Qmodem_FON_Pointer; S: string; O: longint);
    destructor  Done; virtual;
    procedure   ConvertFonRec(RecNo: word); virtual;
    procedure   processfiles; virtual;
  end;

  Boyan50Ptr = ^Boyan50Dir;
  Boyan50Dir = object(Converter)
    FON_Pointer:    Qmodem_FON_Pointer;
    Boyan_File:     file;
    Boyan_Filename: string;
    File_IO_Buffer: pointer;

    constructor Init(var P: Qmodem_FON_Pointer; S: string);
    destructor  Done; virtual;
    procedure   ConvertFonRec(RecNo: word); virtual;
    procedure   processfiles; virtual;
  end;

implementation

  procedure Abstract;
  begin RunError(211); end;

  (* Converter methods *)

  procedure Converter.ConvertFonRec(RecNo: word);
  begin abstract end;

  procedure Converter.Processfiles;
  begin abstract end;

  procedure Converter.CheckGetMem(var P; Size: word);
  begin
    if not GetMemCheck(P, Size) then
      Fatal('Unable to allocate file buffer(S).');
  end;

  procedure Converter.ShowStatus(Percent: real);
  const
    L = 50;
  begin
    HiddenCursor;
    if Status_Window <> nil then with Status_Window^ do
      wFastCenter(
        PadCh(CharStr(#219, trunc(L * Percent)), #176, L) + ' ' + Real2Str(Percent*100, 3, 0) + '%', 3,
          ColorMono(QmColorSet.ProPromptColor, QmColorSet.ProPromptMono));
  end;

  (* specific to pc plus v2.0 *)

  constructor Pcp20Dir.Init(var P: Qmodem_FON_Pointer; S: string);
  begin
    if (not Converter.Init) or (P = nil) or (not ExistFile(S)) then
      fail;

    Procomm_Plus_Filename := S;
    FON_Pointer := Qmodem_FON_Pointer(P);
  end;

  destructor Pcp20Dir.Done;
  begin
    Converter.Done;
  end;

  procedure Pcp20Dir.ConvertFonRec(RecNo: word);
    {-Do the file record conversion. }
  var
    Size: byte;
  const
    _Parity:   array[0.. 4] of char = 'NOEMS';
    _Duplex:   array[0.. 1] of char = 'FH';
    _Protocol: array[0..18] of char = '  O XY A  FG     ZA';
    _Baud: array[0..8] of longint = (300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115600);
  begin
    Size := sizeof(Qmodem_FON_Record);
    blockread(Procomm_Plus_File, File_IO_Buffer^, Sizeof(PcPlus20));
    CheckIoResult('Unable to read file, ' + Procomm_Plus_Filename);

    with FON_Pointer^ do begin
      FON_Record[RecNo]^.Name :=     AsciiZ2String(PcPlus20(File_IO_Buffer^).Name);
      FON_Record[RecNo]^.Phone :=    AsciiZ2String(PcPlus20(File_IO_Buffer^).Phone);
      FON_Record[RecNo]^.Baud :=     _Baud[ord(PcPlus20(File_IO_Buffer^).Baud)];
      FON_Record[RecNo]^.Parity :=   _Parity[ord(PcPlus20(File_IO_Buffer^).Parity)];
      FON_Record[RecNo]^.Data :=     PcPlus20(File_IO_Buffer^).Data;
      FON_Record[RecNo]^.Stop :=     PcPlus20(File_IO_Buffer^).Stop;
      FON_Record[RecNo]^.Duplex :=   _Duplex[ord(PcPlus20(File_IO_Buffer^).Duplex)];
      FON_Record[RecNo]^.Script :=   AsciiZ2String(PcPlus20(File_IO_Buffer^).Script);
      FON_Record[RecNo]^.Date :=     DateStringToDate('MM/DD/YY', AsciiZ2String(PcPlus20(File_IO_Buffer^).Date));
      FON_Record[RecNo]^.Calls :=    Longint(PcPlus20(File_IO_Buffer^).Calls);
      FON_Record[RecNo]^.Protocol := _Protocol[ord(PcPlus20(File_IO_Buffer^).Protocol)];
      PutRecord(RecNo, FON_Record[RecNo]^);
    end;
  end;

  procedure Pcp20Dir.processfiles;
  var
    I: byte;
  begin
    Status_Window := New(RawWindowPtr,
      InitCustom(10, 5, 70, 7, QmColorSet, DefWindowOptions or wBordered));

    if Status_Window <> nil then with Status_Window^ do begin
      with wframe do begin
        AddShadow(shBR, shSeeThru);
        AddHeader(' Status ', heTC);
        AddHeader(' ' + Procomm_Plus_Filename + ' --> ' + FON_Pointer^.FON_Filename + ' ', heBC);
      end;

      Draw;
      HiddenCursor;
      wFastWrite('Procomm Plus v2.0                 Qmodem v4.5 TD', 2, 4,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
    end;

    CheckGetMem(File_IO_Buffer, sizeof(PcPlus20));
    assign(Procomm_Plus_File, Procomm_Plus_Filename);
    reset(Procomm_Plus_File, 1);
    CheckIoResult('Unable to open file, ' + Procomm_Plus_Filename);
    seek(Procomm_Plus_File, 250);
    CheckIoResult('Unable to seek file, ' + Procomm_Plus_Filename);

    for I := 1 to 200 do begin
      ShowStatus(I/200);
      ConvertFonRec(I);
    end;

    close(Procomm_Plus_File);
    CheckIoResult('Unable to close file, ' + Procomm_Plus_Filename);
    FreeMemCheck(File_IO_Buffer, sizeof(PcPlus20));

    if Status_Window <> nil then with Status_Window^ do begin
      ClrScr;
      wFastCenter('Conversion completed. Press any key to continue.', 2,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
      EatKey;
      Dispose(Status_Window, Done);
    end;
  end;

  (* specific to pc plus v1.1x *)

  constructor Pcp11Dir.Init(var P: Qmodem_FON_Pointer; S: string);
  begin
    if (not Converter.Init) or (P = nil) or (not ExistFile(S)) then
      fail;

    Procomm_Plus_Filename := S;
    FON_Pointer := Qmodem_FON_Pointer(P);
  end;

  destructor Pcp11Dir.Done;
  begin
    Converter.Done;
  end;

  procedure Pcp11Dir.ConvertFonRec(RecNo: word);
    {-Do the file record conversion. }
  var
    Size: byte;
    BR: word;
  const
    _Parity:   array[0.. 4] of char = 'NOEMS';
    _Duplex:   array[0.. 1] of char = 'FH';
    _Protocol: array[0..16] of char = '  Y CY A  GG     ';
  begin
    Size := sizeof(Qmodem_FON_Record);
    blockread(Procomm_Plus_File, File_IO_Buffer^, Sizeof(Pcp11_DirRec));
    CheckIoResult('Unable to read file, ' + Procomm_Plus_Filename);

    with FON_Pointer^ do begin
      FON_Record[RecNo]^.Name :=     AsciiZ2String(PcPlus20(File_IO_Buffer^).Name);
      FON_Record[RecNo]^.Phone :=    AsciiZ2String(PcPlus20(File_IO_Buffer^).Phone);
      FON_Record[RecNo]^.Baud :=     longint(PcPlus20(File_IO_Buffer^).Baud);
      FON_Record[RecNo]^.Parity :=   _Parity[ord(PcPlus20(File_IO_Buffer^).Parity)];
      FON_Record[RecNo]^.Data :=     PcPlus20(File_IO_Buffer^).Data;
      FON_Record[RecNo]^.Stop :=     PcPlus20(File_IO_Buffer^).Stop;
      FON_Record[RecNo]^.Duplex :=   _Duplex[ord(PcPlus20(File_IO_Buffer^).Duplex)];
      FON_Record[RecNo]^.Script :=   AsciiZ2String(PcPlus20(File_IO_Buffer^).Script);
      FON_Record[RecNo]^.Date :=     DateStringToDate('MM/DD/YY', AsciiZ2String(PcPlus20(File_IO_Buffer^).Date));
      FON_Record[RecNo]^.Calls :=    Longint(PcPlus20(File_IO_Buffer^).Calls);
      FON_Record[RecNo]^.Protocol := _Protocol[ord(PcPlus20(File_IO_Buffer^).Protocol)];
      PutRecord(RecNo, FON_Record[RecNo]^);
    end;
  end;

  procedure Pcp11Dir.processfiles;
  var
    I: byte;
  begin
    Status_Window := New(RawWindowPtr,
      InitCustom(10, 5, 70, 7, QmColorSet, DefWindowOptions or wBordered));

    if Status_Window <> nil then with Status_Window^ do begin
      with wframe do begin
        AddShadow(shBR, shSeeThru);
        AddHeader(' Status ', heTC);
        AddHeader(' ' + Procomm_Plus_Filename + ' --> ' + FON_Pointer^.FON_Filename + ' ', heBC);
      end;

      Draw;
      HiddenCursor;
      wFastWrite('Procomm Plus v1.1                 Qmodem v4.5 TD', 2, 4,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
    end;

    CheckGetMem(File_IO_Buffer, sizeof(PcPlus20));
    assign(Procomm_Plus_File, Procomm_Plus_Filename);
    reset(Procomm_Plus_File, 1);
    CheckIoResult('Unable to open file, ' + Procomm_Plus_Filename);
    seek(Procomm_Plus_File, 250);
    CheckIoResult('Unable to seek file, ' + Procomm_Plus_Filename);

    for I := 1 to 200 do begin
      ShowStatus(I/200);
      ConvertFonRec(I);
    end;

    close(Procomm_Plus_File);
    CheckIoResult('Unable to close file, ' + Procomm_Plus_Filename);
    FreeMemCheck(File_IO_Buffer, sizeof(PcPlus20));

    if Status_Window <> nil then with Status_Window^ do begin
      ClrScr;
      wFastCenter('Conversion completed. Press any key to continue.', 2,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
      Delay(2000);
      EatKey;
      Dispose(Status_Window, Done);
    end;
  end;

  (* specific to Telix v3.11 *)

  constructor Tlx311Dir.Init(var P: Qmodem_FON_Pointer; S: string; O: longint);
  begin
    if (not Converter.Init) or (P = nil) or (not ExistFile(S)) then
      fail;

    Telix_Filename := S;
    Telix_File_Ofs := O;
    Continue_Proc := false;
    FON_Pointer := Qmodem_FON_Pointer(P);
  end;

  destructor Tlx311Dir.Done;
  begin
    Converter.Done;
  end;

  procedure Tlx311Dir.ConvertFonRec(RecNo: word);
    {-Do the file record conversion. }
  var
    Size: byte;
    S: string;
  const
    _Baud: array[0..8] of longint = (300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200);
    _Parity:   array[0.. 4] of char = 'NOEMS';
    _Duplex:   array[0.. 1] of char = 'FH';
    _Protocol: string[13] = 'A     XOFYGZ ';
    _TlxProtocol: string[13] = 'ACKMSTX1GYEZQ';
  begin
    Size := sizeof(Qmodem_FON_Record);
    blockread(Telix_File, File_IO_Buffer^, Sizeof(TlxDirRec));
    CheckIoResult('Unable to read file, ' + Telix_Filename);

    with FON_Pointer^ do begin
      FON_Record[RecNo]^.Name :=     AsciiZ2String(TlxDirRec(File_IO_Buffer^).Name);
      FON_Record[RecNo]^.Phone :=    AsciiZ2String(TlxDirRec(File_IO_Buffer^).Phone);
      FON_Record[RecNo]^.Baud :=     _Baud[ord(TlxDirRec(File_IO_Buffer^).Baud)];
      FON_Record[RecNo]^.Parity :=   _Parity[ord(TlxDirRec(File_IO_Buffer^).Parity)];
      FON_Record[RecNo]^.Data :=     TlxDirRec(File_IO_Buffer^).Data;
      FON_Record[RecNo]^.Stop :=     TlxDirRec(File_IO_Buffer^).Stop;
      FON_Record[RecNo]^.Duplex :=   _Duplex  [ord(odd(TlxDirRec(File_IO_Buffer^).Duplex))];
      FON_Record[RecNo]^.Script :=   AsciiZ2String(TlxDirRec(File_IO_Buffer^).Script);
      FON_Record[RecNo]^.Date :=     DateStringToDate('MMDDYY', AsciiZ2String(TlxDirRec(File_IO_Buffer^).Date));
      FON_Record[RecNo]^.Calls :=    Longint(TlxDirRec(File_IO_Buffer^).Calls);
      FON_Record[RecNo]^.Protocol := _Protocol[Pos(TlxDirRec(File_IO_Buffer^).Protocol, _TlxProtocol)];
      PutRecord(RecNo, FON_Record[RecNo]^);
    end;
  end;

  procedure Tlx311Dir.processfiles;
  var
    I: byte;
  begin
    Status_Window := New(RawWindowPtr,
      InitCustom(10, 5, 70, 7, QmColorSet, DefWindowOptions or wBordered));

    if Status_Window <> nil then with Status_Window^ do begin
      with wframe do begin
        AddShadow(shBR, shSeeThru);
        AddHeader(' Status ', heTC);
        AddHeader(' ' + Telix_Filename + ' --> ' + FON_Pointer^.FON_Filename + ' ', heBC);
      end;

      Draw;
      HiddenCursor;
      wFastWrite('Telix v3.11                       Qmodem v4.5 TD', 2, 4,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
    end;

    CheckGetMem(File_IO_Buffer, sizeof(PcPlus20));
    assign(Telix_File, Telix_Filename);
    reset(Telix_File, 1);
    CheckIoResult('Unable to open file, ' + Telix_Filename);
    seek(Telix_File, Telix_File_Ofs);
    CheckIoResult('Unable to seek file, ' + Telix_Filename);

    for I := 1 to 200 do begin
      ShowStatus(I/200);
      ConvertFonRec(I);
    end;

    if not eof(Telix_File) then
      Continue_Proc := true;

    close(Telix_File);
    CheckIoResult('Unable to close file, ' + Telix_Filename);
    FreeMemCheck(File_IO_Buffer, sizeof(PcPlus20));

    if Status_Window <> nil then with Status_Window^ do begin
      ClrScr;
      wFastCenter('Conversion completed. Press any key to continue.', 2,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
      EatKey;
      Dispose(Status_Window, Done);
    end;
  end;

  (* specific to boyan 5.0 *)

  constructor Boyan50Dir.Init(var P: Qmodem_FON_Pointer; S: string);
  begin
    if (not Converter.Init) or (P = nil) or (not ExistFile(S)) then
      fail;

    Boyan_Filename := S;
    FON_Pointer := Qmodem_FON_Pointer(P);
  end;

  destructor Boyan50Dir.Done;
  begin
    Converter.Done;
  end;

  procedure Boyan50Dir.ConvertFonRec(RecNo: word);
    {-Do the file record conversion. }
  var
    Size: byte;
  const
    _Parity:   array[0.. 2] of char = 'NEO';
    _Protocol: array[0..7] of char = ' XCROYGA';
    _Baud: array[0..8] of longint = (300, 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115600);
    _BoyanProtocol: string[7] = 'XCR1YGA';
  begin
    Size := sizeof(Qmodem_FON_Record);
    blockread(Boyan_File, File_IO_Buffer^, Sizeof(Boyan50Rec));
    CheckIoResult('Unable to read file, ' + Boyan_Filename);

    with FON_Pointer^ do begin
      FON_Record[RecNo]^.Name :=     Boyan50Rec(File_IO_Buffer^).Name;
      FON_Record[RecNo]^.Phone :=    Boyan50Rec(File_IO_Buffer^).Number;
      FON_Record[RecNo]^.Script :=   Boyan50Rec(File_IO_Buffer^).Script;
      FON_Record[RecNo]^.Baud :=     _Baud[ord(Boyan50Rec(File_IO_Buffer^).Baud)];
      FON_Record[RecNo]^.Parity :=   _Parity[ord(Boyan50Rec(File_IO_Buffer^).Parity)];
      FON_Record[RecNo]^.Protocol := _Protocol[Pos(Boyan50Rec(File_IO_Buffer^).Protocol, _BoyanProtocol)];

      if FON_Record[RecNo]^.Parity = 'E' then
        FON_Record[RecNo]^.Data := 7
      else FON_Record[RecNo]^.Data := 8;

      PutRecord(RecNo, FON_Record[RecNo]^);
    end;
  end;

  procedure Boyan50Dir.processfiles;
  var
    I: byte;
  begin
    Status_Window := New(RawWindowPtr,
      InitCustom(10, 5, 70, 7, QmColorSet, DefWindowOptions or wBordered));

    if Status_Window <> nil then with Status_Window^ do begin
      with wframe do begin
        AddShadow(shBR, shSeeThru);
        AddHeader(' Status ', heTC);
        AddHeader(' ' + Boyan_Filename + ' --> ' + FON_Pointer^.FON_Filename + ' ', heBC);
      end;

      Draw;
      HiddenCursor;
      wFastWrite('Boyan v5.0                        Qmodem v4.5 TD', 2, 4,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
    end;

    CheckGetMem(File_IO_Buffer, sizeof(Boyan50Rec));
    assign(Boyan_File, Boyan_Filename);
    reset(Boyan_File, 1);
    CheckIoResult('Unable to open file, ' + Boyan_Filename);

    for I := 1 to 200 do begin
      ShowStatus(I/200);
      ConvertFonRec(I);
    end;

    close(Boyan_File);
    CheckIoResult('Unable to close file, ' + Boyan_Filename);
    FreeMemCheck(File_IO_Buffer, sizeof(Boyan50Rec));

    if Status_Window <> nil then with Status_Window^ do begin
      ClrScr;
      wFastCenter('Conversion completed. Press any key to continue.', 2,
        ColorMono(QmColorSet.HeaderColor, QmColorSet.HeaderMono));
      EatKey;
      Dispose(Status_Window, Done);
    end;
  end;

end.


