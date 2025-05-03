unit QMEM;
  {-Memory management routines for Qmodem }


interface

uses
   {$IFDEF OVR}
   Overlay,
   {$ENDIF}
   DOS;


var
  DV_Version     : Word;
  IN_DV          : Byte;
  SaveRealBreak  : Boolean;


Var
   CurrentScrollHeap,
   HighScript,
   qqMaxScrollHeap,
   MaxHeapSpace       : LongInt;
   MaxScroll     : Integer;
   DoScrollBack  : Boolean;

Function  DV_Get_version : Word;
Procedure DV_Pause;
Procedure DV_Begin_Critical;
Procedure DV_End_Critical;

Function  GetScrollHeap  (L:LongInt) : Boolean;
Procedure FreeScrollHeap (L:LongInt);


{} IMPLEMENTATION {}

Uses TpCrt, TpString;


Function  DV_Get_version : Word; External;
Procedure DV_Pause;              External;
Procedure DV_Begin_Critical;     External;
Procedure DV_End_Critical;       External;
{$L DESQVIEW}


Function GetScrollHeap(L : LongInt) : Boolean;
Begin
   If L+CurrentScrollHeap <= qqMaxScrollHeap then
      If L < MaxAvail then
         Begin
            Inc(CurrentScrollHeap,L);
            GetScrollHeap := True;
            Exit;
         End;
   GetScrollHeap := False;
End;

Procedure FreeScrollHeap(L:LongInt);
Begin
   Dec(CurrentScrollHeap, L);
End;


Begin
   GetCBreak (SaveRealBreak);
   If SaveRealBreak then
      SetCBreak(False);

   In_DV := 0;
   DV_Version := dv_Get_Version;
   dv_begin_critical;
      ReInitCrt;
   dv_end_critical;

   CurrentScrollHeap := 0;
   MaxScroll         := 0;
   DoScrollBack      := False;
end.
