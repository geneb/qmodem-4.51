{$R-}    {Range checking off}
{$B-}    {Boolean short circuiting off}
{$I-}    {I/O checking on}
{$N-}    {No numeric coprocessor}
{$M 1024,0,0} {Turbo 3 default stack and heap}


Uses
  Crt;

Type
   TComPort         = (Com1, Com2, Com3, Com4, Com5, Com6, Com7, Com8);
   TBaud            = (B300, B1200, B2400, B4800, B9600, B19200, B38400);
   TParity          = (None, Even, Oddd);
   TDatabits        = (D7, D8);
   TStopbits        = (S1, S2);

   Config_Type_31a  = Record
                         { 3072 Bytes in length }
                         Speed           : Integer;
                         CParity         : Char;
                         Stop_Bits,
                         DBits           : Integer;
                         Emulate_Ch      : Char;
                         Connect,
                         Noconnect,
                         Noconnect2      : String[14];
                         Color,
                         Backcolor,
                         Border,
                         Menu,
                         Menu2,
                         Menub           : Integer;
                         Delay_amount    : Integer;
                         Addlfc,
                         Ansic,
                         Musicc          : Char;
                         Redial_delay    : Integer;
                         Downld_Path     : String[64];
                         Pulse_tone      : String[15];
                         Comport         : Integer;
                         Modminit        : String[80];
                         ScrndumpF,
                         CaptureF        : String[64];
                         Bios_Screen     : Char;
                         MaxBuf          : Byte;
                         Noconnect3,
                         Noconnect4,
                         Modem_hangup,
                         Baud_chng_before,
                         Cancel_ch       : String[14];
                         Dial_pacing     : Integer;
                         Log_Start       : Char;
                         CTSc            : Char;
                         xxxxx1          : Char;       {Unused}
                         Post_fix        : String[14];
                         Modem_ctrl      : String[1];
                         Xon_Xoffc,
                         Noisec          : Char;
                         Auto_Speedsetc  : Char;
                         Script_Path     : String[64];
                         CRTc            : Char;
                         Log_Filename    : String[64];   { needs to be added }
                         Base1, Base2,
                         Base3, Base4,
                         Base5, Base6,
                         Base7, Base8    : Integer;
                         IRQ1,  IRQ2,
                         IRQ3,  IRQ4,
                         IRQ5,  IRQ6,
                         IRQ7,  IRQ8     : Byte;
                         Upload_Path     : String[64];
                         Help_Path       : String[64];
                         Browse_PGM      : String[64];
                         Stat            : Integer;
                         Status_Delay    : Real;
                         Baud_chng_after : String[14];
                         PCjr            : Boolean;
                         Ring_Cancel     : String[14];
                         Download_Time   : Integer;
                         Dummy0a         : array [1..11] of byte;
                         Ivlist          : Array[Com1..Com8] of Integer;
                         Dummya          : array[1..103] of byte;
                         Stat2,
                         Stat2B,
                         WindF           : Integer;
                         Scroll_Sav      : String[64];
                         PCjr_Modem      : Boolean;
                         Xfer_Label,
                         Xfer_Send_Batch,
                         Xfer_receive_Batch : Array [1..10] of String[12];
                         File_Prompt,
                         Xfer_Select_Char : Array [1..10] of Char;
                         total_xfers      : Integer;
                         Xlate_Table_In   : Array [0..255] of Byte;
                         CTone1, CTone2,
                         CTone3, DTone,
                         UTone            : Integer;
                         BS_DEL_Swap      : Char;
                         ENQstr           : String[64];
                         Xlate_Table_Out  : Array [0..255] of Byte;
                         Filler           : Array [1..1006] of Byte;
                         Config_version   : String[4];
                      End;

   Config_type_30_31  = Record
                         { 2048 Bytes in length }
                         speed          : Integer;
                         cparity        : Char;
                         stop_bits,
                         dbits          : Integer;
                         dummy_001      : Char;      { not used }
                         connect,
                         noconnect,
                         noconnect2     : String[14];
                         color,
                         backcolor,
                         border,
                         menu,
                         menu2,
                         menub          : Integer;
                         delay_amount   : Integer;
                         addlfc,
                         ansic,
                         musicc         : Char;
                         Redial_delay   : Integer;
                         Downld_Path    : String[64];
                         pulse_tone     : String[15];
                         comport        : Integer;
                         modminit       : String[80];
                         scrndumpF,
                         captureF       : String[64];
                         dummy_002,
                         dummy_003      : Boolean;     { not used }
                         noconnect3,
                         noconnect4,
                         modem_hangup,
                         baud_chng_before,
                         cancel_ch      : String[14];
                         dial_pacing    : Integer;
                         nogood1        : Char;
                         CTSc           : Char;
                         grow_windowc   : Char;
                         post_fix       : String[14];
                         modem_ctrl     : String[1];
                         Xon_Xoffc,
                         Noisec         : Char;
                         auto_Speedsetc : Char;
                         Script_Path    : String[64];
                         CRTc           : Char;
                         Log_File       : String[64];   { needs to be added }
                         Base1, Base2,
                         base3, Base4,
                         Base5, Base6,
                         Base7, Base8   : Integer;
                         IRQ1,  IRQ2,
                         IRQ3,  IRQ4,
                         IRQ5,  IRQ6,
                         IRQ7,  IRQ8    : Byte;
                         Upload_Path    : String[64];
                         Help_Path      : String[64];
                         Browse_PGM     : String[64];
                         Stat           : Integer;
                         Status_Delay   : Real;
                         baud_chng_after : String[14];
                         PCjr            : Boolean;
                         Ring_Cancel     : String[14];
                         Download_Time   : Integer;
                         Kermit_Path     : String[64];
                         Wxmodem_Path    : String[64];
                         Stat2,
                         Stat2B,
                         WIndF           : Integer;
                         Scroll_Sav      : String[64];
                         PCjr_Modem      : Boolean;
                         Xfer_Label,
                         Xfer_Send_Batch,
                         Xfer_receive_Batch : Array [1..10] of String[12];
                         File_Prompt,
                         Xfer_Select_Char : Array [1..10] of Char;
                         total_xfers      : integer;
                         Xlate_Table      : Array [0..255] of Byte;
                         filler           : Array [1..314] of Byte;
                         config_version   : String[4];
                      End;


  Config_type_20_23 = Record
                         { 1368 Bytes in length }
                         speed          : Integer;
                         cparity        : Char;
                         stop_bits,
                         dbits          : Integer;
                         dummy_001      : Char;      { not used }
                         connect,
                         noconnect,
                         noconnect2     : String[14];
                         color,
                         backcolor,
                         border,
                         menu,
                         menu2,
                         menub          : Integer;
                         delay_amount   : Integer;
                         addlfc,
                         ansic,
                         musicc         : Char;
                         Redial_delay   : Integer;
                         Downld_Path    : String[64];
                         pulse_tone     : String[15];
                         comport        : Integer;
                         modminit       : String[80];
                         scrndumpF,
                         captureF       : String[64];
                         dummy_002,
                         dummy_003      : Boolean;     { not used }
                         noconnect3,
                         noconnect4,
                         modem_hangup,
                         baud_chng_before,
                         cancel_ch      : String[14];
                         dial_pacing    : Integer;
                         nogood1        : Char;
                         CTSc           : Char;
                         grow_windowc   : Char;
                         post_fix       : String[14];
                         modem_ctrl     : String[1];
                         Xon_Xoffc,
                         Noisec         : Char;
                         auto_Speedsetc : Char;
                         Script_Path    : String[64];
                         CRTc           : Char;
                         Log_File       : String[64];   { needs to be added }
                         Base1, Base2,
                         base3, Base4,
                         Base5, Base6,
                         Base7, Base8   : Integer;
                         IRQ1,  IRQ2,
                         IRQ3,  IRQ4,
                         IRQ5,  IRQ6,
                         IRQ7,  IRQ8    : Byte;
                         Upload_Path    : String[64];
                         Help_Path      : String[64];
                         Browse_PGM     : String[64];
                         Stat           : Integer;
                         Status_Delay   : Real;
                         baud_chng_after : String[14];
                         PCjr            : Boolean;
                         Ring_Cancel     : String[14];
                         Download_Time   : Integer;
                         Kermit_Path     : String[64];
                         Wxmodem_Path    : String[64];
                         Stat2,
                         Stat2B,
                         WIndF           : Integer;
                         Scroll_Sav      : String[64];
                         filler          : Array [1..303] of Byte;
                         config_version  : String[4];
                      End;

Var
  Q1 : Config_Type_20_23;
  Q2 : Config_Type_30_31;
  Q3 : Config_Type_31a;
  Q0 : Text;
  F1 : File;
  F2 : File;
  F3 : Text;
  x, y : integer;
  Conv_Type, ch : char;

Procedure Open_Old_CNF;
Begin
   Assign (F1, 'QMODEM.CNF');
   Reset  (F1, 1);
End;

Procedure Open_New_CNF;
Begin
   Assign (F2, 'NEW.CNF');
   Rewrite(F2, 1);
End;

Procedure Open_XLT;
Begin
   Assign (F3, 'QMODEM.XLT');
   {$I-}
   Reset  (F3);
   If IOResult <> 0 then
      Begin
         Writeln;
         Writeln ('File QMODEM.XLT was not found.  Aborted.');
         Halt(1);
      End;
   {$I+}
End;

Procedure Get_Conv_Type;
Begin
   Writeln;
   Writeln ('  Conversions avaliable :   [1]   Version 2.0 - 2.3  to  3.1a');
   Writeln ('                            [2]   Version 3.0 - 3.1  to  3.1a');
   Writeln ('                            [Q]   Quit conversion program.');
   Writeln ;
   Write   ('          Please choose :    ');
   Repeat
      Ch := ReadKey;
      Ch := Upcase(Ch);
   Until Ch in ['1','2','Q'];
   If Ch = 'Q' then Halt;
   Writeln (Ch);
   Conv_Type := Ch;
End;

Procedure P20_23_Msg_Prompt;
Begin
   Writeln;
   Writeln ('This MUST be executed from the default QMODEM directory and the');
   Writeln ('following files must be available :');
   Writeln ('                                        QMODEM.CNF');
   Writeln ('                                        QMODEM.XLT');
   Writeln ;
   Writeln ('This will create a file called NEW.CNF that must be renamed to');
   Writeln ('QMODEM.CNF before starting QINSTALL or QMODEM.');
   Writeln;
   Write   ('Press [Y] to continue, or any other key to abort ');
   Ch:= ReadKey;
   Ch := upcase(ch);
   If Ch <> 'Y' then
      Begin
         Writeln;
         Writeln ('Aborting per user request.');
         Exit;
     End;
End;



Begin
   Lowvideo;
   Writeln ('QMODEM CNF Conversion Program');
   Get_Conv_Type;


   Writeln;
   Writeln;
   Writeln ('Opening QMODEM.CNF');
   Open_Old_CNF;

   Writeln ('Creating NEW.CNF');
   Open_New_CNF;

   If Conv_Type = '1' then
      Begin
         Writeln ('Opening QMODEM.XLT');
         Open_XLT;
      End;

   Case Conv_Type of
      '1' : BlockRead (F1, Q1, 1368);   { 20_23 to 31a }
      '2' : BlockRead (F1, Q2, 2048);   { 30_31 to 31a }
   End;

   fillchar (Q3, Sizeof(Q3), #0);           { clear the new cnf area    }

   Writeln ('Moving old data to NEW.CNF');

   Case Conv_Type of
      '1' : Move (Q1, Q3, 1060);            { move in the old variables }
      '2' : Move (Q2, Q3, 1729);            { move in the old variables }
   End;

   Write ('Moving Version to NEW.CNF : ');
   Case Conv_Type of
      '1' : Q3.config_version := Q1.config_version;  { move version     }
      '2' : Q3.config_version := Q2.config_version;  { move version     }
   End;
   Writeln (Q3.config_version);

   If Conv_Type = '1' then
      Begin
         For x := 1 to 10 do q2.Xfer_Select_Char[x] := ' ';
         Writeln ('Moving Translate Table to NEW.CNF');
         For x := 0 to 255 do                     { Move QMODEM.XLT in too!   }
            Begin
               Readln (f3, y);
               Q3.xlate_table_In[x] := ord(chr(y));
            End;
      End;

   Writeln ('Creating new Ouput Translate Table');
   For x := 0 to 255 do
       Q3.xlate_table_Out[x] := ord(x);
   BlockWrite (F2, Q3, 3072);
   Close (f1);
   Close (f2);
   If Conv_Type = '1' then Close (f3);
   Writeln ('Done.');
   Writeln;
   Writeln ('Don''t forget to rename NEW.CNF to QMODEM.CNF!');
End.
