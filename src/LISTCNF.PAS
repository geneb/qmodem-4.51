
program
  ListCnf;

uses
  Dos, OpDos, QmMisc;

  (* Qmodem .CNF file record *)

type
  MenuColorArray = array[1..6] of byte;

  QmCnfRec = Record
    xxx1:               word;
    Parity:             char;
    Stop,
    Data:               integer;
    EmulateCh:          char;
    ConnectStr,
    NoConnectStr1,
    NoConnectStr2:      string[14];
    TextColor:          byte;
    WriteFBK:           boolean;
    EditF,
    xxx2,
    Border,
    xxx3,
    Menu,
    xxx4,
    Menu2,
    xxx5,
    ScrollBar,
    xxx6:               byte;
    DelayVal:           integer;
    AddLFc,                   { boolean 'YN' }
    Ansic,                    {    "     "   }
    Musicc:             char; {    "     "   }
    RedialDelay:        integer;
    DownldPathStr:      string[64];
    DialPrefixStr:      string[15];
    CommPort:           byte;
    xxx7:               char;
    ModmInitStr:        string[80];
    ScreenDumpFilename,
    CaptureFilename:    string[64];
    UseDirectVideo:     boolean;
    MaxBuf: byte;
    Noconnect3Str,
    Noconnect4Str,
    OKMessageStr,
    BaudChangeBefore,
    CancelStr:          string[14]; {string to cancel a call }
    DialPacing:         integer;
    LogStart,
    CTSc:               char;
    ShowStatusLine:     boolean;
    DialPostfix:        string[14];
    ModemCtrl:          string[1];
    XonXoffc,
    Noisec:             char;
    LockDTE:            boolean;
    ScriptPathStr:      string[64];
    CheckSnowx:         char;
    LogFilenameStr:     string[64]; { needs to be added }
    BaseAddress:        array[1..8] of word;
    IRQ:                array[1..8] of byte;
    UploadPathStr,
    HelpPathStr,
    BrowsePGM:          string[64];
    InfoColor,
    xxx8:               byte;
    StatusDelay:        longint;
    FIFOshell:          char;
    ASCIIPaceCh:        byte;
    BaudChangeAfter:    string[14];
    GuardHangup:        boolean;
    HostRingMsg:        string[14];
    DownloadTime:       integer;
    GrowingWindows:     boolean;
    ModemHangupStr:     string[22];
    xxCharDate,
    xxCharTime,
    CharBeeps,
    CharANSI,
    SLC,
    CharTag:            char;
    ShareIRQs:          boolean;
    UseMouse:           boolean;
    Edit1,
    xxx9,
    Edit2,
    xxx10,
    EditW,
    xxx11:              byte;
    NoteTagChar:        char;
    StatusLineColor2,
    xxx12:              byte;
    AutoZ,
    EMSOK:              boolean;
    HostRingCount:      integer;
    DestructBS,
    LineWrap,
    ENQ:                boolean;
    HelpColors:         array[1..8] of byte;
    CommSpeed:          longint;
    xxx13:              array[1..60] of byte;
    DTRdelay,
    BREAKdelay:         integer;
    Qcolor1:            MenuColorArray;
    StatusLineColor,
    xxx14:              byte;
    ASCIIPaceSpeed:     integer;
    WindowFrame:        byte;
    ClearFonTags:       boolean;
    ScrollSaveFilename: string[64];
    IgnoreCD:           boolean;
    XferLabel,
    XferSendBat,
    XferReceiveBat:     array[1..10] of string[12];
    XferFilePrompt,
    XferSelectChar:     array[1..10] of char;
    TotalXfers:         integer;
    XlateTableIn:       array[0..255] of byte;
    CTone1,
    CTone2,
    CTone3,
    DTone,
    UTone:              integer;
    BsDelSwap:          char;
    HostUlPathStr:      string[64];
    XlateTableOut:      array[0..255] of byte;
    HostDLPathStr:      string[64]; {file directory}
    HostConnectStr:     string[62]; {not used}
    HostAnswerStr:      string[14]; {answer string}
    HostOpen:           byte;       {open or closed sys}
    HostMaxTime:        integer;    {Max time per session}
    HostShutDown:       string[8];  {Shutdown Password}
    HostOffHook:        string[14];
    xxx15:              array[1..14] of byte;
    HostPassword:       string[8];  {Dos Shell password}
    HostInit:           string[62]; {initialization string}
    DummyMaxScriptHeap,
    MaxScrollLines,
    DummyMaxEditHeap,
    ExtraOvrBuf:        word;
    ASCIIInXlate,
    ASCIIOutXlate:      boolean;
    ASCIIInCR,
    ASCIIInLF,
    ASCIIOutCR,
    ASCIIOutLF:         byte; {0, 1, 2}
    ASCIIOutExpand:     boolean;
    ASCIIEOLCh:         byte;
    RedialRingMsg:      string[14];
    KeypadEmuls:        char;
    NoCTSDrop,
    UseInt16,
    UseHighSpeed,
    Use16550,
    VideoRestore:       boolean;
    SwapDirectory:      string[64];
    MaxShell,
    TagAdvance,
    JumpScroll,
    OverWrite,
    SavePartial,
    AutoIncrement,
    AltDStart,
    BEWClear:           boolean;
    ConnectCycles:      integer;
    BatchUL1,
    BatchUL2,
    BatchUL3:           string[64];
    DoRecalibrate,
    MaxDiskShell:       boolean;
    PrinterID,
    AltWPick:           string[64];
    E0Doorway:          boolean;
    DateStr,
    TimeStr,
    ElapsedStr:         string[10];
    TimeDateStamp:      boolean;

    {$IfDef ISI}
      ISI_Base:         word;
      ISI_IRQ:          byte;
      Use_ISI:          boolean;
    {$Else}
      FillerISI:        array[1..4] of byte;
    {$EndIf}

    SendPace:           integer;
    xxx16:              array[1..270] of byte;
    ConfigVersion:      string[4];
  end;

var
  Cnf: QmCnfRec;

const
  Configuration_Filename = 'QMODEM.CNF';

var
  Configuration_File: file of QmCnfRec;
  Full_Path_String: string;

begin
  Assign(Output, '');
  rewrite(Output);

  if not ExistOnPath(Configuration_Filename, Full_Path_String) then
    Fatal(Configuration_Filename + ' not found on disk');

  Assign(Configuration_File, Full_Path_String);
  Reset(Configuration_File);
  if IoResult <> 0 then
    Fatal('Unable to open file ' + Configuration_Filename);

  Read(Configuration_File, Cnf);

  with Cnf do begin
    {List config}
  end;

  Close(Configuration_File);
end.

