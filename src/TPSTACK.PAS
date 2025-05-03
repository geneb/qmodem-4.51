{$S-,R-,I-,B-,D-,F-}

{*********************************************************}
{*                   TPSTACK.PAS 1.00                    *}
{*                by TurboPower Software                 *}
{*********************************************************}

unit TpStack;
  {-Unit for monitoring stack and heap usage}

interface

const
  {If True, results are reported automatically at the end of the program. Set
   to False if you want to display results in another manner.}
  ReportStackUsage : Boolean = True;

var
  {The following variables, like the two procedures that follow, are interfaced
   solely for the purpose of displaying results. You should never alter any of
   these variables.}
  OurSS : Word;              {value of SS register when program began}
  InitialSP : Word;          {value of SP register when program began}
  LowestSP : Word;           {lowest value for SP register}
  HeapHigh : Pointer;        {highest address pointed to by HeapPtr}

procedure CalcStackUsage(var StackUsage : Word; var HeapUsage : LongInt);
  {-Calculate stack and heap usage}

procedure ShowStackUsage;
  {-Display stack and heap usage information}

{The next two routines are interfaced in case you need or want to deinstall the
 INT $8 handler temporarily, as you might when using the Exec procedure in the
 DOS unit.}

procedure InstallInt8;
  {-Save INT $8 vector and install our ISR, if not already installed}

procedure RestoreInt8;
  {-Restore the old INT $8 handler if our ISR is installed}

{The following routine allows you to alter the rate at which samples are taken.
 For it to have any effect, it must be preceded by a call to RestoreInt8 and
 followed by a call to InstallInt8.}

procedure SetSampleRate(Rate : Word);
  {-Set number of samples per second. Default is 1165, minimum is 18.}

  {==========================================================================}

implementation

type
  SegOfs =                   {structure of a 32-bit pointer}
    record
      Offset, Segment : Word;
    end;
const
  Int8Installed : Boolean = False;  {True if our INT $8 handler is installed}
  DefaultRate = 10000;        {corresponds to 1165 samples/second}
var
  SaveInt8 : ^Pointer;       {pointer to original INT $8 vector}
  SaveExitProc : Pointer;    {saved value for ExitProc}
  Vectors : array[0..$FF] of Pointer absolute $0:$0;
  Rate8253,
  Counts,
  CountsPerTick : Word;

  procedure IntsOff;
    {-Turn off CPU interrupts}
  inline($FA);

  procedure IntsOn;
    {-Turn on CPU interrupts}
  inline($FB);

  {$L TPSTACK.OBJ}

  procedure ActualSaveInt8;
    {-Actually a pointer variable in CS}
    external {TPSTACK} ;

  procedure Int8;
    {-Interrupt service routine used to monitor stack and heap usage}
    external {TPSTACK} ;

  procedure SetTimerRate(Rate : Word);
    {-Program system 8253 timer number 0 to run at specified rate}
  begin                      {SetTimerRate}
    IntsOff;
    Port[$43] := $36;
    Port[$40] := Lo(Rate);
    inline($EB/$00);         {null jump}
    inline($EB/$00);         {null jump}
    inline($EB/$00);         {null jump}
    inline($EB/$00);         {null jump}
    Port[$40] := Hi(Rate);
    IntsOn;
  end;                       {SetTimerRate}

  procedure InstallInt8;
    {-Save INT $8 vector and install our ISR, if not already installed}
  begin                      {InstallInt8}

    {make sure we're not already installed, in case we are called twice.
     if we don't do this check, SaveInt8 could get pointed to *our* ISR}

    if not Int8Installed then begin
      {save the current vector}
      SaveInt8^ := Vectors[$8];

      {Set counts til next system timer tick}
      Counts := 0;

      {Keep interrupts off}
      IntsOff;

      {Take over the timer tick}
      Vectors[$8] := @Int8;

      {Reprogram the timer to run at the new rate}
      SetTimerRate(Rate8253);

      {restore interrupts}
      IntsOn;

      {now we're installed}
      Int8Installed := True;
    end;
  end;                       {InstallInt8}

  procedure RestoreInt8;
    {-Restore the old INT $8 handler if our ISR is installed}
  begin                      {RestoreInt8}
    {if we're currently installed, then deinstall}
    if Int8Installed then begin
      {no more samples}
      IntsOff;

      {Give back the timer interrupt}
      Vectors[$8] := SaveInt8^;

      {Reprogram the clock to run at normal rate}
      SetTimerRate(0);

      {Normal interrupts again}
      IntsOn;

      {no longer installed}
      Int8Installed := False;
    end;
  end;                       {RestoreInt8}

  procedure SetSampleRate(Rate : Word);
    {-Set number of samples per second. Default is 1165, minimum is 18.}
  var
    Disable : Boolean;
  begin                      {SetSampleRate}
    if (Rate >= 18) then begin
      {deactivate Int8 temporarily if necessary}
      Disable := Int8Installed;
      if Disable then
        RestoreInt8;

      Rate8253 := LongInt($123400) div LongInt(Rate);
      CountsPerTick := LongInt($10000) div LongInt(Rate8253);

      {reactivate Int8 if necessary}
      if Disable then
        InstallInt8;
    end;
  end;                       {SetSampleRate}

  procedure CalcStackUsage(var StackUsage : Word; var HeapUsage : LongInt);
    {-Calculate stack and heap usage}
  begin                      {CalcStackUsage}
    {calculate stack usage}
    StackUsage := InitialSP-LowestSP;

    {calculate heap usage}
    HeapUsage :=
      (LongInt(SegOfs(HeapHigh).Segment-SegOfs(HeapOrg).Segment) * 16) +
       LongInt(SegOfs(HeapHigh).Offset-SegOfs(HeapOrg).Offset);
  end;                       {CalcStackUsage}

  procedure ShowStackUsage;
    {-Display stack and heap usage information}
  var
    StackUsage : Word;
    HeapUsage : LongInt;
  begin                      {ShowStackUsage}
    {calculate stack and heap usage}
    CalcStackUsage(StackUsage, HeapUsage);

    {show them}
    WriteLn('Stack usage: ', StackUsage, ' bytes.');
    WriteLn('Heap usage:  ', HeapUsage, ' bytes.');
  end;                       {ShowStackUsage}

  {$F+}  {Don't forget that exit handlers are always called FAR!}
  procedure OurExitProc;
    {-Deinstalls our INT $8 handler and reports stack/heap usage}
  begin                      {OurExitProc}
    {restore ExitProc}
    ExitProc := SaveExitProc;

    {restore INT $8}
    RestoreInt8;

    {show results if desired}
    if ReportStackUsage then
      ShowStackUsage;
  end;                       {OurExitProc}
  {$F-}

begin                        {TpStack}
  {initialize SaveInt8}
  SaveInt8 := @ActualSaveInt8;

  {initialize Rate8253 and CountsPerTick}
  SetSampleRate(DefaultRate);

  {save current value for SS}
  OurSS := SSeg;

  {save current value of SP and account for the return address on the stack}
  InitialSP := SPtr+SizeOf(Pointer);
  LowestSP := InitialSP;

  {save current position of HeapPtr}
  HeapHigh := HeapPtr;

  {install our ISR}
  InstallInt8;

  {save ExitProc and install our exit handler}
  SaveExitProc := ExitProc;
  ExitProc := @OurExitProc;
end.                         {TpStack}
