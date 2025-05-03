program
  QmFONCnv;

uses
  QmInt24, Dos, OpCrt, OpFrame, OpCmd, OpWindow, OpString, OpSEdit,
  QmColor, QmMisc, QmFon, QmPick, QmConv;

  procedure FillScreen;
  var
    Screen_Line: byte;
  begin
    For Screen_Line := 1 to ScreenHeight do
      FastWrite(CharStr('°', ScreenWidth), Screen_Line, 1,
        ColorMono(QmColorSet.FrameColor, QmColorSet.FrameMono));

    FastWrite(Center('Qmodem SST v' + Configuration_Version_Supported + ' Dialing Directory Conversion', ScreenWidth), 1, 1,
      ColorMono(QmColorSet.HighlightColor, QmColorSet.HighlightMono));
  end;

  function LegalFilename(Prompt, Default_String, Header_String: string): string;
  var
    Prompt_Length: byte absolute Prompt;
    Editor: SimpleLineEditor;
    Edit_Window: RawWindow;
    Edit_String: string;
    Editor_Command: word;
  begin
    Edit_String := Default_String;
    Editor_Command := ccQuit;

    if Edit_Window.InitCustom(5, 5, 75, 7, QmColorSet, DefWindowOptions or wBordered) then begin
      Edit_Window.wFrame.AddHeader(Header_String, heTC);
      Edit_Window.wFrame.AddShadow(shBR, shSeeThru);
      Edit_Window.Draw;
      HiddenCursor;

      repeat
        if Editor.init(QmColorSet) then
          with Editor do begin
            ReadString(Prompt + ': ', 6, 6, SizeOf(PathStr), 66 - succ(Prompt_Length) + 2, Edit_String);
            Editor_Command := seCmd;
            Done;
          end;
      until Editor_Command in [ccQuit, ccSelect, ccError];

      Edit_Window.Erase;
      Edit_Window.Done;
    end;

    case Editor_Command of
      ccSelect: LegalFilename := Edit_String;
      ccQuit: LegalFilename := '';
    end;

    HiddenCursor;
  end;

var
  Generic_Converter:     Converter_Pointer;
  Conversion_Selection:  word;
  Qmodem_Object_Pointer: Qmodem_FON_Pointer;
  Info_Window: RawWindowPtr;

  (* Telix specific vars *)

  Telix_File_Starting_Offset: longint;
  Telix_Continue_Proc: boolean;
  Telix_FON_File_Name: string;
  Qmodem_FON_File_Name: string;

  procedure DrawInfoLine(S: string; H: boolean);
  const
    Y: byte = 1;
  var
    A: byte;
  begin
    Inc(Y);
    A := ColorMono(QmColorSet.TextColor, QmColorSet.TextMono);

    if H then
      A := A or $08;

    Info_Window^.wFastCenter(S, Y, A);
  end;

begin
  FillScreen;

  Info_Window := New(RawWindowPtr, InitCustom(10, 12, 70, 21, QmColorSet, DefWindowOptions or wBordered));
  if Info_Window <> nil then with Info_Window^ do begin
    wFrame.AddHeader(' Program Information ', heTC);
    wFrame.AddShadow(shBR, shSeeThru);
    Draw;
    HiddenCursor;
    DrawInfoLine('Copyright (c) 1991 Mustang Software Inc.', true);
    drawinfoline('', false);
    DrawInfoLine('Select the phone book format you wish to convert from,', false);
    DrawInfoLine('then press "Enter".  You will then be asked the names of', false);
    DrawInfoLine('the source and target files.  During the conversion, you', false);
    DrawinfoLine('will be displayed a status window indicating it''s progress.', false);
    drawinfoline('', false);
    Drawinfoline('Press "Escape" to exit the program.', false);
  end;

  HiddenCursor;

  repeat
    Conversion_Selection := GetConversionType;

    case Conversion_Selection of
      0: DoClosing;

      1: begin               {Pc Plus v1.1}
        Qmodem_Object_Pointer := New(Qmodem_FON_Pointer,
          Init(LegalFileName('Qmodem .FON file', 'QMODEM.FON', ' Qmodem File Allocation ')));

        if Qmodem_Object_Pointer <> nil then begin
          Generic_Converter := New(Pcp11Ptr,
            Init(Qmodem_Object_Pointer,
              LegalFilename('Procomm Plus .DIR file', 'PCPLUS.DIR', ' Procomm Plus File Allocation ')));

          if Generic_Converter <> nil then
            with pcp11ptr(Generic_Converter)^ do begin
              processfiles;
              dispose(Generic_Converter, Done);
            end;

          dispose(Qmodem_Object_Pointer, Done);
        end;
      end;

      2: begin               {Pc Plus v2.0}
        Qmodem_Object_Pointer := New(Qmodem_FON_Pointer,
          Init(LegalFileName('Qmodem .FON file', 'QMODEM.FON', ' Qmodem File Allocation ')));

        if Qmodem_Object_Pointer <> nil then begin
          Generic_Converter := New(Pcp20Ptr,
            Init(Qmodem_Object_Pointer,
              LegalFilename('Procomm Plus .DIR file', 'PCPLUS.DIR', ' Procomm Pluss File Allocation ')));

          if Generic_Converter <> nil then
            with pcp20ptr(Generic_Converter)^ do begin
              processfiles;
              dispose(Generic_Converter, Done);
            end;

          dispose(Qmodem_Object_Pointer, Done);
        end;
      end;

      3: begin               {Telix v3.11}
        Telix_File_Starting_Offset := 64;
        Qmodem_FON_File_Name := LegalFileName('Qmodem .FON file', 'QMODEM.FON', ' Qmodem File Allocation ');
        Telix_FON_File_Name := LegalFilename('Telix .FON file', 'TELIX.FON', ' Telix File Allocation ');
        Telix_Continue_Proc := true;

        while Telix_Continue_Proc do begin
          Qmodem_Object_Pointer := New(Qmodem_FON_Pointer, Init(Qmodem_FON_File_Name));

          if Qmodem_Object_Pointer <> nil then begin
            Generic_Converter := New(Tlx311Ptr,
              Init(Qmodem_Object_Pointer, Telix_FON_File_Name, Telix_File_Starting_Offset));

            if Generic_Converter <> nil then
              with Tlx311ptr(Generic_Converter)^ do begin
                processfiles;
                Telix_Continue_Proc := Continue_Proc;
                dispose(Generic_Converter, Done);
              end;

            dispose(Qmodem_Object_Pointer, Done);
          end;

          Inc(Telix_File_Starting_Offset, Sizeof(TlxDirRec) * 200);
          Qmodem_FON_File_Name := IncFilename(Qmodem_FON_File_Name);
        end;
      end;

      4: begin               {Boyan v5.0}
        Qmodem_Object_Pointer := New(Qmodem_FON_Pointer,
          Init(LegalFileName('Qmodem .FON file', 'QMODEM.FON', ' Qmodem File Allocation ')));

        if Qmodem_Object_Pointer <> nil then begin
          Generic_Converter := New(Boyan50Ptr,
            Init(Qmodem_Object_Pointer,
              LegalFilename('Boyan .FON file', 'BOYAN.FON', ' Boyan File Allocation ')));

          if Generic_Converter <> nil then
            with Boyan50Ptr(Generic_Converter)^ do begin
              processfiles;
              dispose(Generic_Converter, Done);
            end;

          dispose(Qmodem_Object_Pointer, Done);
        end;
      end;
    end;
  until Conversion_Selection = 0;

  NormalCursor;
end.

