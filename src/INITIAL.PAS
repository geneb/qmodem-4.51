{$I TPDEFINE.INC}

Unit Initial;

Interface

Uses
   Dos,       TpCrt,
   {$IFDEF UseMouse}
      TpMouse,
   {$ENDIF}
   TpWindow,  TpDate,  Constant;


{ExecSwap Procedural Variables and declarations}
Type
   IEStype = Function(LastToSave : Pointer; SwapFileName : String) : Boolean;
   EWStype = Function(Path, CmdLine : String) : Word;
   SEStype = Procedure;
Var
   IES : IEStype;
   EWS : EWStype;
   SES : SEStype;
Const
   AutoZmodem  = 'rz'+#13+'**';
   AutoZmodem2 = '**B00';
   {$IfDef QLink}
   AutoQLink   = #0'QL'#255;
   {$EndIf}

   UseEmsIfAvailable : Boolean = True;  {True to use EMS if available}
   BytesSwapped : LongInt = 0;          {Bytes to swap to EMS/disk}
   EmsAllocated : Boolean = False;      {True when EMS allocated for swap}
   FileAllocated : Boolean = False;     {True when file allocated for swap}
   Override_Port : Boolean = False;     {4.2F!!}
   Override_Port_Num : Byte = 0;        {4.2F!!}

   {$IfDef ISI}
   ISI_OK : BOOLEAN = True;             {If False, then ignore ISI calls}
   {$EndIf}


{Network Variables}
Var
   ShowOpening,
   NetCopy,
   Administration : Boolean;
   tmp : String[20];


{$IfDef ISI}
Var
   ISI_Port_Count : Word;
{$EndIf}

Const
   CopyRightString = 'Copyright (C) 1992 Mustang Software, Inc.';
   {$IfNDef Bundle}

      Board_PTR : String[5] = #16#16#16#16#16;
      Board : String[50] = 'ð Unregistered Copy ð';
      Garbage  : Array[1..10] of Byte = ($21,$43,$82,$00,$01,
                                         $00,$FE,$FB,$00,$80);
   {$EndIf}

   Reg_Number : Word = 0;
   DoorwayLeader : Char = #0;
   InitStats : Boolean = False;


{$I TpMENU.IN0}

Var
   ExitSave       : Pointer;
   MyCode         : File;
   MyCodeSize     : LongInt;
   Start,
   Start_Name,
   IO,
   Start_Reg,
   Check_Reg      : Word;
   Sector_Code    : Array[1..256] of Char;
   SetEGA43Exit   : Boolean;
   RTS_On,
   LineWrap       : Boolean;
   HostViaScript  : Boolean;
   HighMemFlag    : Boolean;
   AllowMemoryChange : Boolean;
   CharWord       : Word;


Const
   Recv_Buf_Size  = 4095;{2K Buffers} {4095; 4K Buffers}  {8191; 8K Buffers}
   Buffer_Size    : Word = Recv_Buf_Size;
   Buffer_High1   : Word = Recv_Buf_Size - 50;
   Buffer_Low1    : Word = Recv_Buf_Size - 1024;

{$IfDef GG}
   Max_Phones = 20;
{$Else}
   Max_phones = 200;          { 200 Entry Dialing Directory }
{$EndIf}

   SOH            = ^A;
   STX            = ^B;
   EOT            = ^D;
   ACK            = ^F;
   NAK            = ^U;
   CAN            = ^X;

{$IfDef Int14}
Const
   ModemLeads : Byte = 0;
{$Endif}

Var
   Config_version_const : String[04];
   Version              : String[23];
   Short_Version        : String[04];
   Compile_date         : String[26];

   StartElapsed1,
   Help_Index_Loaded,
   Previous_Save,
   Last_Online_State,
   Doorway,
   CaseSensitive,

   {$Ifdef Int14}
      Int14,
   {$Endif}

   Start_Redialer : Boolean;

Const
   LastWas80 : Boolean=False;
   Wrap80    : Boolean=False;
   LastCh    : Char=#0;
   LastChAttr: Byte=0;
   StoreLastLine : Word=0;
   Pushed    : Boolean=False;


Type
   { List of modems that are in the QMODEM.MDF file }
   ModemListPointer = ^ModemListPtr;
   ModemListPtr = Record
                     Name : String[60];
                     Item : Word;
                     Next : ModemListPointer;
                  End;

Const
   ModemListBuilt : Boolean = FALSE;  {is list built or not}

Var
   MLPhead : ModemListPointer;
   ModemTotalCount : Word;

Var
   B16450, B8250, B16550, B16550A, Is16550 : Boolean;

{$IfDef QLink}
   Type
      Emulation_Mode = (TTY, ANSImode, VT100, TVI925, DEBUG_A, DEBUG_H, AVATAR, QLINK);
   Const
      TotalEmulations : Word = 7;
      QLinkMode : Boolean = False;

{$Else}
   Type
      Emulation_Mode = (TTY, ANSImode, VT100, TVI925, DEBUG_A, DEBUG_H, AVATAR);
   Const
      TotalEmulations : Word = 7;
{$EndIf}

Type
   Status_Line_Type = (WithToggles, WithCommands, WithBBSInfo);
Var
   CurrStatusLine3 : Status_Line_Type;


Type
   Transfer_Type = (Xmodem, Xmodem_CRC, Xmodem_1K, Ymodem,
                    Ymodem_G, Xmodem_1K_G, Ascii, Zmodem);

   Op_Type        = (op_qq, op_eq, op_lt, op_gt, op_le, op_ge, op_ne);

   Next_Field = (Right_Field, Left_Field, Up_Field, Down_Field,
                 Done_Edit, Still_Editing, ESC_Edit, Other_Key);

   Ymodem_Type    = Array[1..1029] Of Char;
   Xmodem_Type    = Array[1..128] Of Char;
   Crc_type       = Array[1..129] Of Char;


   { Scroll Back  --  Doubly linked list }

   Node_Line_Type = String[80];
   Scroll_Ptr     = ^scroll_line;
   scroll_line    = Record
                       Prev,
                       Next : Scroll_Ptr;
                       TxtL : Node_Line_Type;   {Text Line}
                       AttL : Node_Line_Type;   {Attributes}
                    End;

   XBP            = Array[0..30719] Of Byte; {30K}

Var
   UpSaveDir        : String;
   UpBpath          : String;
   UpFList          : SearchRec;


Const
   RBR            = $00;          { xF8   Receive Buffer Register             }
   THR            = $00;          { xF8   Transmitter Holding Register        }
   IER            = $01;          { xF9   Interrupt Enable Register           }
   IIR            = $02;          { xFA   Interrupt Identification Register   }
   LCR            = $03;          { xFB   Line Control Register               }
   MCR            = $04;          { xFC   Modem Control Register              }
   LSR            = $05;          { xFD   Line Status Register                }
   MSR            = $06;          { xFE   Modem Status Register               }
   DLL            = $00;          { xF8   Divisor Latch Least Significant     }
   DLM            = $01;          { xF9   Divisor Latch Most  Significant     }
   PICCMD         = $20;          { 8259  Priority Interrupt Controller       }
   PICMSK         = $21;          { 8259  Priority Interrupt Controller       }
   PICMSK2        = $A1;          { 8259  Priority Interrupt Controller 2     }

Type
   TBaud          = (B110,    B300,    B1200,   B2400,   B4800,
                     B9600,   B19200,  B38400,  B57600,  B115200);
   TParity        = Char;
   TDatabits      = (D7, D8);
   TStopbits      = (S1, S2);
   Str1           = String[1];
   Str2           = String[2];
   Str3           = String[3];
   Str4           = String[4];
   Str5           = String[5];
   Str8           = String[8];
   Str14          = String[14];
   Str10          = String[10];
   Str20          = String[20];
   Str40          = String[40];
   Str64          = String[64];
   Str66          = String[66];
   Str80          = String[80];
   Str160         = String[160];

   {$I CNF.PAS}

   Ini_Type =    Record            { 23 Bytes in length }
                    Emulate_Ch     : Char;
                    ModemSpeed     : LongInt;
                    SerialSpeed    : LongInt;
                    CParity        : Char;
                    Stop_Bits,
                    DBits          : Integer;
                    EchoI          : Boolean;
                    HiBitI         : Boolean;
                    AddlfI         : Boolean;
                    Xon_XoffI      : Boolean;
                    NoiseI         : Boolean;
                    MusicI         : Boolean;
                    Save_ScrollI   : Boolean;
                    PrtLogI        : Boolean;
                    SplitI         : Boolean;
                 End;

   Phone_type = Record
                   Name             : String[27];
                   Filler01         : Word;
                   Number           : String[19];
                   Filler02         : Word;
                   Dbits, Sbits     : Integer;
                   Parity           : TParity;
                   Script_File      : String[12];
      {------->}   Last_Connect     : Word;       {<----  This Changed}
                   Filler03         : String[6];
                   Times_Called     : LongInt;
                   Filler04         : Word;
                   Default_Protocol : Char;
                   Echo1            : Char;
                   Password         : String[14];
                   EntryNumber      : Integer;
                   Marked           : Boolean;
                   Emulation        : Emulation_Mode; {future expansion}
                   LearnTag         : Boolean;
                   NoteNum          : Word;           {never change this!}
                   HasNote          : Boolean;
                   NoPrefix         : Boolean;
                   ComSpeed         : LongInt;
                   Filler99         : Array[1..3] Of Byte;
                End;

Var
   Mtimes : Word;
   MST : String[1];

Var
   Buffer01       : ^XBP;
   Cursor_Emul    : Byte Absolute $40 : $87;
   Ringbuf        : Array[0..Recv_buf_size] Of Byte;
   Ringbuf2       : Array[0..Recv_buf_size] Of Byte;

   OnOffXferState : Boolean;


   LastManual,
   LM2            : String;

   Upload_Path    : String[64];
   ScrndumpF      : String[64];
   CaptureF       : String[64];
   Downld_Path    : String[64];
   Scroll_Sav     : String[64];
   LOG_FileN      : String[64];

   IVlist         : Array[1..8] Of Integer;
   IvIRQ          : Array[1..8] Of byte;

   Emulation      : Emulation_Mode;

   Save_Last_Status : String[180];

   ScrollFirst, ScrollLast    : Scroll_Ptr;

   Config_file    : File Of Config_Type;
   QQ             : Config_Type;

   INI_file       : File Of INI_Type;
   INI            : INI_Type;

   Online_Time, TimeElapsed1, SaveElapsed1, Dex : LongInt;

   Row, Col       : Array[0..3] Of Integer;

   OldShowSL      : Boolean;

   qqMaxBuf, q, x1, Phone_page, inx, Num, iny,
   outx, outy, Pnum, Crt_reg, T1, RC,
   interupt_save, CurrentPhone : Integer;

   {$IfDef Int14}
      Int14ComPort : Integer;
   {$EndIf}


   qqColor, Color_Low, Color_High, NewColor : Byte;

   Readptr, Writptr, Readptr2, Writptr2, Queue_bytes, BytesQueuedOut,
   IER_, RBR_, LSR_, DLL_, DLM_, MCR_, LCR_, MSR_, IIR_,
   LSRXXX, inttrips, U16550LOOPS, LSRtrips, MSRtrips,
   ShareTrips,
   OverrunErrors, ParityErrors, FramingErrors : Word;

   Force_Exit, DropDTR, Logging, Decom, Alt_Q,
   QuickLearn, Fon_Changed, CursorKeyMode,
   Redial_Flag, Redialing, Save_Comm : Boolean;

   SaveDBits, NewDBits, NewSBits : Word;

   Parity         : TParity;

   NewCParity, Ch, A, Dial_delay, SaveParity,
   Default_drive, CommCh, Ansi1, Ansi2, Ansi3,
   Ansi4, zz, xpr, crcbyte, Dial_mode : Char;

   Dirpath, Startdir, Auto_Script_Name, Last_Edit,
   LearnTxt, FON_Filename, FKEY_Filename, Type_Ahead : Str80;

   Hold_Str       : String[10];

   LearnFilename, Split_String, Phone : String;

   Echo, leave, Phone_c, Addlf, Rootdir, graphics, ok, log, Corrupt,
   Special, Xon_Xoff, Dial_Other_Info, Transfer, Prtlog, help_last,
   Split, CTS_, Noise, Save_scroll, Restart_Invoked,
   Hi_Bit, Auto_Script, Hold_Test, Redial, Music_flag, Buffer_full,
   Run_Qinstall_Now, ShowSL, FSEHeader, Capture : Boolean;

   B              : Str2;

   NewFSEHeader   : String[76];

   F_keys         : Array[1..48] Of String[72];

   Prefix_file, TextF, LearnF,
   Log_File, Capture_file, Screen_file : Text;
   CapFileBuf     : Array[1..4096] of Char;


   Fonefile       : File Of Phone_type;
   Phone_number   : Phone_type;

   STP            : String[2];

   Fonenum        : String[70];


Type
   PhoneBookType  = Array[1..Max_phones] Of Phone_type;
   PhoneBookPtr   = ^PhoneBookType;

Var
   Phone_Dir      : PhoneBookPtr;

   Prefix         : Array[1..10] Of String[30];


   {  Comm Vars  }
   ShareIRQ            : Boolean;
   ComBaseAddr         : Array[1..8] Of Integer;
   ComSaveVec,
   MyIntVec,
   OldInt1C            : Pointer;     { Saved Async Interrupt vector }
   ComBase             : Integer;     { Opened Com Port Base Address }
   ActiveComPort       : Byte;        { Opened Com                   }
   imvalue             : Integer;     { Interrupt Mask value in use  }
   ComPort_Open_Flag   : Boolean;     { True if Open But No Close    }
   Async_IRQ           : word;        { irq For Current open Port    }
   Async_MaxBufferUsed : Integer;

   MSR_Status             : Byte;
   Xoff_Received,
   Xoff_Sent, Send_Xoff   : Boolean;

   RetCode        : Integer;
   Byt            : Byte;
   Return_Code    : Integer;      { DOS Return Code              }
   CurrPath,
   ScriptT,
   ComSpec        : String[64];   { Comspec From DOS Environment }
   ScriptCount    : Byte;

   GetRegC        : Boolean;
   CGetReg        : Word;

Const
   OfflineString : String[9] = '_OFFLINE_';
   MultiTasker : ShortInt = -1;
   { Script Definitions }


Type
   valid_token_type =  (   { Keywords }
   Kw_chdir,      Kw_dial,       Kw_download,     Kw_dos,
   Kw_drive,      Kw_exit,       Kw_goto,         Kw_label,
   Kw_log,        Kw_DisplayLn,  Kw_Delay,        Kw_Pause,
   Kw_return,     Kw_sEnd,       Kw_script,       Kw_turn_on,
   Kw_setcomm,    Kw_turn_off,   Kw_upload,       Kw_wait_for,
   Kw_wait_until, Kw_hangup,     Kw_note,         Kw_timeout,
   Kw_beep,       Kw_capture,    Kw_clrscr,       Kw_when,
   Kw_system,     Kw_writeln,    Kw_Getr,         Kw_debug,
   Kw_write,      Kw_graphics,   Kw_loadfon,      Kw_Loadkey,
   Kw_fkey,       Kw_gosub,      Kw_If,           Kw_break,
   Kw_color,      Kw_Colorfg,    Kw_colorbg,      Kw_display,
   Kw_get,        Kw_atwrite,    Kw_box,          Kw_gotoxy,
   Kw_window,     Kw_String,     Kw_Assign,       Kw_exist,
   Kw_stamp,      Kw_Port,       Kw_incr,         Kw_decr,
   Kw_ega,        kw_downld,     Kw_Getn,         Kw_getnr,
   Kw_Getx,       kw_upld,       Kw_Inkey,        Kw_push,
   Kw_pop,        kw_flush,      kw_OpenFile,     Kw_ReadFile,
   Kw_WriteFile,  Kw_CloseFile,  kw_edit,         Kw_Host,
   Kw_Getscr,     Kw_Putscr,     kw_bigdos,

    { Miscellaneous }

   Tk_Word,       Tk_String,     Tk_Label,        Tk_Word_Plus,
   Tk_End_rec,    Tk_End_file,   Tk_UnRec,

    {Turnon/TurnOff Keywords}

   To_DOORWAY,    To_ECHO,         To_SPLIT,      To_ALTMINUS,
   To_LINEFEED,   To_NOISE,        To_8_BIT,      To_XON_XOFF,
   To_MUSIC,      To_PRINT,        To_BS_DEL,     To_ONLINE,
   To_SCROLL,     To_CASE
   );
   {96 total}


   Keyword_name = Record
                     Key_name : String[9];
                     Key_type : valid_token_type;
                  End;

   Token_record = Record
                     Token_type     : valid_token_type;
                     Position       : Integer;
                     Case Boolean Of
                        True : (str_value : String);
                        False : (Length : Byte);
                  End;

   Script_type = Record
                    S_filename     : String[64];
                    Record_num     : LongInt;
                 End;

   Script_when = Record
                    Recv_String    : Pointer;
                    Recv_String_LastChar : Char; { Speed up searches }
                    Send_String    : Pointer;
                    SLabel         : Boolean;
                 End;

   Script_String_Type = Record
                           Name,
                           Value : Pointer;
                        End;

   Script_Label_Record = Record
                            Name   : String[32];
                            LineNo : LongInt;
                            Next   : Pointer;
                         End;

   Script_Label = ^Script_Label_Record;

   Procs = Procedure;



Const
   Max_Script_Stack = 20;
   Max_Script_Strings_Set = 70;   { 10 of these are the predefined s0-s9 }
   Max_Keyword_Elements = 96;
   Max_Push_Pops  = 40;
   Max_Whens      = 30;
Var
   Keyword_Procedure  : Array [Kw_Chdir..TK_UnRec] of Procs;
   Last_Good_Token    : LongInt;
   Script_Label_Head,
   Script_Label_Ptr   : Script_Label;
   Last_Label_Script  : String;
   Keyword_Element    : Array[1..Max_Keyword_Elements] Of Keyword_name; { 2 Empty }
   Keyword_Count      : Byte;
   Token, last_token  : Token_record;
   Script_stack       : Array[1..Max_Script_Stack] Of Script_type;
   Script_Total_Whens : Byte;
   Script_when_stack  : Array[1..Max_Whens] Of Script_when;
   Script_Strings     : Array[1..Max_Script_Strings_Set] Of Script_String_Type;
   Push_Pop_Strings   : Array[1..Max_Push_Pops] Of Pointer;
   Linked_Script_Flag,
   Label_Search       : Boolean;
   Linked_Script_Num,
   Script_Strings_Set,
   Script_stack_pointer : Integer;
   Parse_input        : String;
   Push_N_Pop,
   Parse_start,
   Parse_length       : Integer;
   Last_parse_record,
   Script_error,
   Fatal_Error        : Boolean;
   Script_File        : Text;
   Script_timeout     : Integer;
   Script_parm_line   : String[128];
   Script_Goto_Str    : String[32];
   Curr_Script_Name,
   Script_to_Open,
   Script_Timeout_Label : Str64;
   Already_Initialized,
   Script_File_Open,
   Script_Upload_Active,
   When_Goto,
   Script_Debug,
   Online_Check,
   Script_Success,
   Script_Whens,
   Exit_Main          : Boolean;
   Waitfor_LastChar   : Char;
   Exit_Main_Ch       : Char;

Var
   Scripting          : Boolean;
   Linked_Protocol    : Char;
   Linked_Password    : String[15];
   Linked_Notefile    : String[65];
   Linked_Board       : String[34];
   Linked_Number      : String[30];
   Linked_Speed       : String[6];
   Linked_Comm        : String[5];
   Linked_Script_File : String[12];
   TabStops           : Array[1..255] Of Byte;

Type
   Save_Win_Type = Record
                      c1, r1,            { Upper left of window  }
                      c2, r2,            { Lower right of window }
                      co,                { color attribute       }
                      whrx, whry : Byte; { cursor position       }
                   End;
Var
   Curr_Win_Ptr,
   Virt_Win_Ptr   : Byte;
   Save_Window    : Array[1..10] Of Save_Win_Type;

Type
   Ansi_state     = (No_Esc, Got_Esc, Got_Esc_B);
   SmallStr       = String[2];
   vwin           = Array[1..20000] Of Byte;
   vwinp          = ^vwin;

Var
   Virtual_Screen : vwinp;
   xcolor         : Integer;
   T_Margin,
   B_Margin       : Integer;
   ANSI_Mode      : Ansi_state;
   Save_Ansi_Str  : String[64];
   Emul_Color,
   Save_Emul_X,
   Save_Emul_Y    : Byte;
   Cmd_Str        : String[80];

Var
   Last_Ansi_Row,
   Split_Bottom_Row,
   Split_Middle_Row,
   Real_Last_Row,Prlr
   {Stack_Top}      : Byte;
   R              : Registers;
   Last_Row, Last_Col : Byte;





   { Globals for Downld }

Type
   all_chars      = Set Of #0..#255;

Var
   ValidFileChars : Set Of Char;
   NewSpeed, Save_speed,
   DCE_Speed,                     {Actual speed sent from modem}
   dl2, Bytes_Received, WX : LongInt;
   Avg_BPS, Effective_PCT : Real;
   Valid_chars    : all_chars;
   Sec, ECount,
   TimeoutErr, ShortBlk,
   CompErr, LongBlk,
   SOHErr, ReSendErr,
   BlockNumErr, ChecksumErr,
   BlockNum,
   HiCRC, LoCRC, Block_Bytes,
   BufCnt, Tot_K,
   Time_Min, Cutoff : LongInt;
   x              : Integer;
   ShowPct        : Boolean;
   ExpectedSize   : LongInt;
   OldCursorEmulation : Byte;
   Keep_File, CTS_Flag, Stamp_Taken,
   NxBlk, Good    : Boolean;
   TF, DFile,
   SFilename, LDFile : String[80];
   InFile         : File;
   Block          : Ymodem_Type;
   Time_          : LongInt;

   tm, Transfer_Method : Transfer_Type;
   RealSpeed, RSpeed,
   Speed_X        : Real;


Var
   FBlock         : Xmodem_Type;
   YBlock         : Array[1..8] Of Xmodem_Type;
   Ymodem_1K,
   Aborted        : Boolean;
   Y, Errors, X2,
   t_Errors, TBlks: LongInt;
   I              : Word;
   BT, B1, B2,
   ChkSum, InByte : Char;

   {Globals for HostMode}

   AutoHost, Hosting : Boolean;

Const

   CRLF           = ^M^J;
   Max_Inputs     = 20;
   NonStop        = -1;         { Sets the File Display to NonStop }
   Lines_Per_PAge = 23;         { Number of Lines Per Page Default }

Type

   Str26          = String[26];
   Input_Type     = (NumberOnly, FilterInput, NoFilter, MorePrompt,
                     YesOrNo, OnlyCr);
   DataBitsType   = (Unknown, SevenBits, EightBits);

Var
   DataBits       : DataBitsType;

   Lines_Remaining,               { Number of lines Remaining before -More- Prompt }
   Inputs,
   Minutes_Passed : Integer;

   HFirstName,
   HLastName,
   HPassword      : String[25];

   Responses      : Array[1..Max_Inputs] Of String[30];

   BaudInit       : LongInt;

   LinesPerPage   : Integer;

   Cancel_Allowed,                { Is CTRL-C allowed when displaying files }
   Fixed_Rate                     { Have they Locked their DTE }
   : Boolean;

var
   GLattr : Byte;
   xInMode : Byte;
   Stxt : String[80];




Procedure KeyContinue(Tattr : Integer);
Procedure Screen_mode_check;
Procedure Screen_mode_check2;
Procedure Set_Colors;
Procedure Set_Base_Colors;
Procedure Set_split;
Procedure Split_Window_Top;
Procedure Split_Window_Middle;
Procedure Split_Window_Bottom;
Procedure Writelnb(Txt : String);
Function  DateS  : String;
Function  TimeS  : String;
Procedure Push_Window;
Procedure Pop_Window;
Procedure Beep;


Implementation


Procedure Beep;
Begin
   If not Noise then exit;
   Sound(70);
   Delay(60);
   Nosound;
End;

Procedure Push_Window;
Var
   Ch             : Char;
Begin
   If Curr_Win_Ptr < 10 Then
      Inc(Curr_Win_Ptr)
   Else
      Begin
         WriteLn('PUSH WINDOW ERROR');
         KeyContinue(31);
         Exit;
      End;
   With Save_Window[Curr_Win_Ptr] Do
      Begin
         c1 := lo(WindMin) + 1;
         r1 := hi(WindMin) + 1;
         c2 := lo(WindMax) + 1;
         r2 := hi(WindMax) + 1;
         co := TextAttr;
         whrx := WhereX;
         whry := WhereY;
      End;
End;

Procedure Pop_Window;
Begin
   If Curr_Win_Ptr = 0 Then Exit;
   With Save_Window[Curr_Win_Ptr] Do
      Begin
         Window(c1, r1, c2, r2);
         GotoXY(whrx, whry);
         TextAttr := co;
      End;
   Dec(Curr_Win_Ptr);
End;

Function DateS : String;
Begin
   DateS := TodayString(qq.DateStr);
End;

Function TimeS  : String;
Begin
   TimeS := CurrentTimeString(qq.TimeStr);
End;

Procedure Writelnb(Txt : String);
Begin
   TextAttr := QQ.InfoColor;
   Screen_mode_check;
   If WhereX > 1 Then
      WriteLn;
   WriteLn(Txt);
   Set_Colors;
   If Split Then
      Set_split;
End;

Procedure KeyContinue(Tattr : Integer);
Var
   Ch : Char;
   x  : Integer;
Begin
   TextAttr := Tattr;
   HiddenCursor;
   Write('( Tap any key to continue )');
   {$IfDef UseMouse}
      While KeyPressed or MousePressed Do
         Ch := ReadKey;
      Ch := ReadKey;
      While KeyPressed or MousePressed Do
         Ch := ReadKey;
   {$Else}
      While KeyPressed Do
         Ch := ReadKey;
      Ch := ReadKey;
      While KeyPressed Do
         Ch := ReadKey;
   {$ENDIF}
   For x := 1 To 27 Do
      Write(#8#32#8);
   TextAttr := QQ.TxtColor;
   NormalCursor;
End;

Procedure Split_Window_Top;
Begin
   Window(1, 1, Last_Col, Split_Middle_Row - 1);
End;

Procedure Split_Window_Middle;
Begin
   Window(1, Split_Middle_Row, Last_Col, Last_Row);
End;

Procedure Split_Window_Bottom;
Begin
   Window(1, Split_Middle_Row + 1, Last_Col, Last_Row);
End;


Procedure Set_Colors;
Begin
   If Emulation = TTY Then
      TextAttr := QQColor
   Else
      TextAttr := Emul_Color;
End;


Procedure Set_Base_Colors;
Begin
   Emul_Color := qq.txtColor;
   QQColor := qq.txtcolor;
   If Emulation in [ANSImode, VT100] then
      If qq.StrictColor then
         Emul_Color := 7;
   Set_Colors;
End;


Procedure Screen_mode_check;
Begin
   If Split Then
      Begin
         Split_Window_Top;
         GotoXY(inx, iny);
      End;
End;

Procedure Screen_mode_check2;
Begin
   If Split Then
      Begin
         Split_Window_Bottom;
         GotoXY(outx, outy);
      End;
End;

Procedure Set_split;
Begin
   If Split then
      Begin
         inx := WhereX;
         iny := WhereY;
         Screen_mode_check2;
      End;
End;



Begin
   CTS_           := False;
   GLAttr         := textattr;

   r.AH           := $F;
   Intr($10, R);
   xInMode        := r.al;
   SetEGA43Exit := False;
   If CurrentDisplay >= EGA then
      If ScreenHeight > 28 Then
         SetEGA43Exit := True;

   MLPhead         := NIL;

   CurrStatusLine3 := WithToggles;
   Xoff_Received   := False;
   RTS_On          := False;
   Xoff_Sent       := False;
   Send_Xoff       := False;
   FON_Changed     := False;
   Decom           := False;
   MSR_Status      := 255;
   Curr_Win_Ptr    := 0;
   Virt_Win_Ptr    := 0;
   DCE_Speed       := 0;
   ReadPtr         := 0;
   WritPtr         := 0;
   ScrollFirst     := Nil;
   ScrollLast      := Nil;
   Save_Last_Status:= '';
   LineWrap        := False;
   Run_Qinstall_Now := False;
   Ansi_Mode         := No_Esc;
   Leave             := False;
   Capture           := False;
   Script_Label_Head := Nil;
End.
