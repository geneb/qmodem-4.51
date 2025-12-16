{$S-,R-,V-,I-,B-,F-,O-,A-}


{*********************************************************}
{*                  OPENHKBD.PAS 1.02                    *}
{*     Copyright (c) TurboPower Software 1987, 1989.     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OpEnhKbd;
  {-Enhanced keyboard routines}

interface

const
  EnableEnhanced  : Boolean = True; {Set false to temporarily disable handlers}
var
  HasEnhancedKbd  : Boolean; {True when enhanced keyboard is detected}
  FiltersEnhanced : Boolean; {True when keyboard BIOS filters enhanced keys}
  AllowE0Codes    : Boolean; {Set TRUE so handler passes E0 codes}


procedure InitializeKbdVectors;

procedure UnInitializeKbdVectors;


procedure InitKbdVectors;
  {-Save and setup interrupt vectors. This routine should be called only if
    RestoreKbdVectors has been called first!!}

  {=========================================================================}

implementation

Const
  Restored : Boolean = True;

var
  SaveExit  : Pointer;
  SaveInt09,
  SaveInt16 : Pointer;


  {$L OPENHKBD}

  procedure NewInt09; external;
  procedure NewInt16; external;
  function EnhancedKbd : Boolean; external;
  function FiltersEnhancedKeys : Boolean; external;

  {$F+}
  procedure InitKbdVectors; external;
  procedure RestoreKbdVectors; external;
  procedure FixOldBios; external;

  procedure ExitHandler;
    {-Deactive interrupt handlers}
  begin
    ExitProc := SaveExit;
    RestoreKbdVectors;
  end;
  {$F-}


  procedure InitializeKbdVectors;
  Begin
     If not Restored then
        Exit;
     InitKbdVectors;
     Restored := False;
  End;

  procedure UnInitializeKbdVectors;
  Begin
     If Restored then
        Exit;
     RestoreKbdVectors;
     Restored := True;
  End;




begin
  {Correct invalid BufferStart and BufferEnd for old BIOS chips that
   don't initialize them}
  FixOldBios; {!!.02}

  {See if enhanced keyboard BIOS installed}
  HasEnhancedKbd := EnhancedKbd;

  {See if the keyboard BIOS will try to filter out the keys we add}
  FiltersEnhanced := FiltersEnhancedKeys;

  {Initialize interrupt vectors}
  InitializeKbdVectors;

  {Install exit handler}
  SaveExit := ExitProc;
  ExitProc := @ExitHandler;
end.
