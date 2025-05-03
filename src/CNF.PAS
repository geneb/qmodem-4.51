   Config_Type = Record            { 3072 Bytes in length }
                    FillerSpeed    : Word;
                    CParity        : Char;
                    Stop_Bits,
                    DBits          : Integer;
                    Emulate_Ch     : Char;
                    Connect,
                    Noconnect,
                    Noconnect2     : String[14];
                    TxtColor       : Byte;
                    WriteFBK       : Boolean;
                    Editf,
                    xxxbyte2,
                    Border,
                    xxxbyte3,
                    Menu,
                    xxxbyte5,
                    Menu2,
                    xxxbyte6,
                    ScrollBar,
                    xxxbyte4       : Byte;
                    Delay_amount   : Integer;
                    Addlfc,
                    Ansic,
                    Musicc         : Char;
                    Redial_delay   : Integer;
                    Downld_Path_s  : String[64];
                    Dial_Prefix    : String[15];
                    CommPort       : Byte;
                    StrictColor    : Boolean;
                    Modminit       : String[80];
                    ScrndumpF_s,
                    CaptureF_s     : String[64];
                    DirectVideo    : Boolean;
                    MaxBuf         : Byte;
                    Noconnect3,
                    Noconnect4,
                    OKMessage,
                    Baud_chng_before,
                    Cancel_ch      : String[14]; {String to cancel a call }
                    Dial_pacing    : Integer;
                    Log_Start      : Char;
                    CTSc           : Char;
                    ShowStatusLine : Boolean;
                    Dial_Postfix   : String[14];
                    fillermc       : word;
                    Xon_Xoffc,
                    Noisec         : Char;
                    LockDTE        : Boolean;
                    Script_Path    : String[64];
                    CheckSnowx     : Char;
                    Log_Filename_s : String[64]; { needs to be added }
                    Base           : Array[1..8] of Word;
                    IRQ            : Array[1..8] of Byte;
                    Upload_Path_s   : String[64];
                    Help_Path       : String[64];
                    Browse_PGM      : String[64];
                    InfoColor,
                    xxxbyte7 : Byte;
                    Status_Delay    : LongInt;
                    FIFOshell       : Char;
                    ASCII_Pace_Ch   : Byte;
                    Baud_chng_after : String[14];
		    GuardHangup     : Boolean;
                    Host_Ring_Msg   : String[14];
                    Download_Time   : Integer;
                    Grow_Window     : Boolean;
                    Modem_Hangup    : String[22];
                    xxCharDate,
                    xxCharTime,
                    CharBeeps,
                    CharANSI,
                    SLC,
                    CharTag        : Char;
                    Share_IRQ      : Boolean;
                    UseMouse       : Boolean;
                    Edit1,
                    xxxbyte9,
                    Edit2,
                    xxxbyte10,
                    EditW,
                    xxxbyte8       : Byte;
                    NoteTag        : Char;
                    StatusLineColor2 : Byte;
                    xxxbyte11        : Byte;
                    AutoZ          : Boolean;
                    EMS_OK         : Boolean;
                    Host_Ring_Count: Integer;
                    Destruct_BS    : Boolean;
                    LineWrap       : Boolean;
                    ENQ            : Boolean;
                    HelpColors     : Array[1..8] of Byte;
                    ComSpeed       : LongInt;
                    DummyA         : Array[1..60] Of Byte;
                    DTRdelay       : Integer;
                    BREAKdelay     : Integer;
                    Qcolor1        : MenuColorArray;
                    StatusLineColor: Byte;
                    xxxbyte12        : Byte;
                    ASCII_Pace_Speed : Integer;
                    WindF          : Byte;        {Window Frame}
                    ClearFTags     : Boolean;
                    Scroll_Sav_s   : String[64];
                    IgnoreCD       : Boolean;
                    Xfer_Label,
                    Xfer_Send_Bat,
                    Xfer_Receive_Bat : Array[1..10] Of String[12];
                    Xfer_File_Prompt,
                    Xfer_Select_Chr : Array[1..10] Of Char;
                    Total_Xfers    : Integer;
                    Xlate_Table_In : Array[0..255] Of Byte;
                    CTone1, CTone2,
                    CTone3, DTone,
                    UTone           : Integer;
                    BS_DEL_Swap     : Char;
                    Host_ULPath     : String[64];
                    Xlate_Table_Out : Array[0..255] Of Byte;
                    Host_DLPath     : String[64]; {file directory}
                    Host_Connect    : String[62]; {not used}
                    Host_Answer     : String[14]; {answer string}
                    HostOpen        : Byte;       {open or closed sys}
                    HostMaxTime     : Integer;    {Max time per session}
                    HostShutDown    : String[8];  {Shutdown Password}
                    HostOffHook     : String[14];
                    Host_Filler     : Array[1..14] Of Byte;
                    HostPassword    : String[8];  {Dos Shell password}
                    HostInit        : String[62]; {initialization string}
                    DummyMaxScriptHeap,
                    MaxScrollLines,
                    DummyMaxEditHeap,
                    ExtraOvrBuf     : Word;
                    ASCII_In_Xlate,
                    ASCII_Out_Xlate : Boolean;
                    ASCII_In_CR,
                    ASCII_In_LF,
                    ASCII_Out_CR,
                    ASCII_Out_LF     : Byte;  {0,1,2}
                    ASCII_Out_Expand : Boolean;
                    ASCII_EOL_Ch    : Byte;
                    Redial_Ring_Msg : String[14];
                    KeypadEmuls     : Char;
                    NoCTSDrop       : Boolean;
                    UseInt16        : Boolean;
                    UseHighSpeed    : Boolean;
                    Use16550        : Boolean;
                    VideoRestore    : Boolean;
                    SwapDirectory   : String[64];
                    MaxShell        : Boolean;
                    TagAdvance      : Boolean;
                    JumpScroll      : Boolean;
                    OverWrite       : Boolean;
                    SavePartial     : Boolean;
                    AutoIncrement   : Boolean;
                    AltDStart       : Boolean;
                    BEWClear        : Boolean;
                    ConnectCycles   : Integer;
                    BatchUL1        : String[64];
                    BatchUL2        : String[64];
                    BatchUL3        : String[64];
                    DoRecalibrate   : Boolean;
                    MaxDiskShell    : Boolean;
                    PrinterID       : String[64];
                    AltWPick        : String[64];
                    E0Doorway       : Boolean;
                    DateStr         : String[10];
                    TimeStr         : String[10];
                    ElapsedStr      : String[10];
                    TimeDateStamp   : Boolean;
                    {$IfDef ISI}
                       ISI_Base        : Word;
                       ISI_IRQ         : Byte;
                       Use_ISI         : Boolean;
                    {$Else}
                       FillerISI       : Array[1..4] of Byte;
                    {$EndIf}
                    SendPace        : Integer;
                    Filler          : Array[1..270] Of Byte;
                    Config_version  : String[4];
                 End;
