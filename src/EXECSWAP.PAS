{
Copyright (c) 1988 TurboPower Software
May be used freely as long as due credit is given
Version 1.1 - 3/15/89
  save and restore EMS page map
Version 1.2 - 3/29/89
  add more compiler directives (far calls off, boolean short-circuiting)
  add UseEmsIfAvailable to disable EMS usage when desired
Version 1.3 - 12/01/89  (FORBIN ADDITIONS)
  Freed up the temporary file between uses and restored all interrupt vectors
  that could have been saved until the application was finished.
}

{$R-,S-,F+,O-,I-,B-}

UNIT ExecSwap;

  {-Memory-efficient DOS EXEC call}

interface
Uses Initial;

function ExecWithSwap(Path, CmdLine : String) : Word;
  {-DOS EXEC supporting swap to EMS or disk}

function InitExecSwap(LastToSave : Pointer; SwapFileName : String) : Boolean;
  {-Initialize for swapping, returning TRUE if successful}

procedure ShutdownExecSwap;
  {-Deallocate swap area}

implementation

Uses TpCrt;


var
  EmsHandle : Word;               {Handle of EMS allocation block}
  FrameSeg : Word;                {Segment of EMS page frame}
  FileHandle : Word;              {DOS handle of swap file}
  SwapName : String[80];          {ASCIIZ name of swap file}
  SaveExit : Pointer;             {Exit chain pointer}
Const
  AlreadySaved : Boolean = False;

  {$L EXECSWAP}
  function  ExecWithSwap(Path, CmdLine : String) : Word; external;
  procedure FirstToSave; external;
  function  AllocateSwapFile : Boolean; external;
  procedure DeallocateSwapFile; external;

  {$F+}     {These routines could be interfaced for general use}
  function  EmsInstalled : Boolean; external;
  function  EmsPageFrame : Word; external;
  function  AllocateEmsPages(NumPages : Word) : Word; external;
  procedure DeallocateEmsHandle(Handle : Word); external;
  function  DefaultDrive : Char; external;
  function  DiskFree(Drive : Byte) : LongInt; external;

  procedure ExecSwapExit;
  begin
    ExitProc := SaveExit;
    ShutdownExecSwap;
  end;
  {$F-}

  procedure ShutdownExecSwap;
  var w : word;
  begin
    if EmsAllocated then begin
      DeallocateEmsHandle(EmsHandle);
      EmsAllocated := False;
    end else if FileAllocated then begin
      DeallocateSwapFile;
      FileAllocated := False;
    end;
  end;

  function PtrDiff(H, L : Pointer) : LongInt;
  type
     OS = record O, S : Word; end;   {Convenient typecast}
  begin
     PtrDiff := (LongInt(OS(H).S) shl 4+OS(H).O)-
                (LongInt(OS(L).S) shl 4+OS(L).O);
  end;

  function InitExecSwap(LastToSave : Pointer;
                        SwapFileName : String) : Boolean;
  const
     EmsPageSize = 16384;            {Bytes in a standard EMS page}
  var
     PagesInEms : Word;              {Pages needed in EMS}
     BytesFree : LongInt;            {Bytes free on swap file drive}
     DriveChar : Char;               {Drive letter for swap file}
  begin
     InitExecSwap := False;

     if EmsAllocated or FileAllocated then
        Exit;
     BytesSwapped := PtrDiff(LastToSave, @FirstToSave);
     if BytesSwapped <= 0 then
        Exit;
     If Not AlreadySaved then
        Begin
           SaveExit := ExitProc;
           ExitProc := @ExecSwapExit;
           AlreadySaved := True;
        End;

    if UseEmsIfAvailable and EmsInstalled then begin
      PagesInEms := (BytesSwapped+EmsPageSize-1) div EmsPageSize;
      EmsHandle := AllocateEmsPages(PagesInEms);
      if EmsHandle <> $FFFF then begin
        EmsAllocated := True;
        FrameSeg := EmsPageFrame;
        if FrameSeg <> 0 then begin
          InitExecSwap := True;
          Exit;
        end;
      end;
    end;
    if Length(SwapFileName) <> 0 then begin
       SwapName := SwapFileName+#0;
       if Pos(':', SwapFileName) = 2 then
          DriveChar := Upcase(SwapFileName[1])
       else
          DriveChar := DefaultDrive;
       BytesFree := DiskFree(Byte(DriveChar)-$40);
       FileAllocated := (BytesFree > BytesSwapped) and AllocateSwapFile;
       if FileAllocated then
          InitExecSwap := True;
    end;
  end;
end.
