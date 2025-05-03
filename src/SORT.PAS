{$R-}

(****************************************************************)
(*                     DATABASE TOOLBOX 4.0                     *)
(*     Copyright (c) 1984, 87 by Borland International, Inc.    *)
(*                                                              *)
(*                    TURBO SORT UNIT                           *)
(*                                                              *)
(*  Purpose: Toolbox of routines to implement a general         *)
(*           purpose QuickSort for up to 32K data items.        *)
(*                                                              *)
(****************************************************************)
unit Sort;


interface

Uses TpCrt;

type
  ProcPtr = Pointer; { ProcPtr holds the address of a procedure }

function TurboSort(ItemLength : integer;
                   InpPtr, LessPtr, OutPtr : ProcPtr) : integer;
{ InpPtr, LessPtr,  and OutPtr are procedure pointers which hold the
  address of the user input procedure, less function, and output procedure,
  respectively.  ItemLength is the size of the item to be sorted (in bytes).
  Use SizeOf(MyRec) to calculate this value. }

procedure SortRelease(var ReleaseRecord);
{ Called by the user's input routine to pass a record in to be
  sorted. }

procedure SortReturn(var ReturnRecord);
{ Called by the user's output routine to retrieve the next
  record from the sort. }

function SortEOS : boolean;
{ Called by the user's output routine, SortEOS returns true if all
  of the sorted records have been returned. }

implementation

var
  GluePtr : ProcPtr;

{$F+}
procedure CallProc;
inline($FF/$1E/GluePtr);  {CALL DWORD PTR GluePtr}

function Less(var x, y):boolean;
inline($FF/$1E/GluePtr);  {CALL DWORD PTR GluePtr}
{$F-}

Type
   SortPointer = ^Byte;

Var
   SortRecord : Record  { Global variables used by all routines }
                   { variables concerning paging }
                   N           : Integer; { no of records to be sorted      }
                   B           : Integer; { no of records pr page           }
                   Pages       : 0..10;   { No of pages in memory           }
                   SecPrPage,             { no of sectors pr page           }
                   NDivB,
                   NModB       : Integer; { = M Div B, N Mod B respectively }

                   Buf         : Array[0..10] Of SortPointer;
                                          { Addresses of buffers            }
                   Page        : Array[0..10] Of Integer;
                                          { Nos of pages in workarea        }
                   W           : Array[0..10] Of Boolean;
                                          { dirty-bits : is page changed ?  }

                   Udix        : Integer; { Udix points to the next record
                                             to be returned }

                   F           : File;    { File used for external sorting  }

                   FileCreated : Boolean; { Is external file used           }

                   Error     : Integer; { Has an i/o error occurred       }

                   ItemLength     : Integer; { Length of record                }
             End;



   Procedure SortPut(Addr: SortPointer; PageNo: Integer);
      { Write page PageNo on file, address of page in memory is Addr }
   var
     BW : integer;
   Begin
      If SortRecord.Error=0 Then Begin  { No i/o error }
         Seek(SortRecord.F, PageNo*SortRecord.SecPrPage);
         BlockWrite(SortRecord.F, Addr^, SortRecord.SecPrPage, BW);
         If BW = 0 Then SortRecord.Error:=10  { write error }
      End
   End;


   Procedure SortFetchAddr( Ix: Integer; Var Adr: SortPointer);
      { Find address in memory for record no Ix. It is assumed
        that record Ix is in memory }

      Var IxPage : Integer;
          I      : 0..10;

   Begin
      IxPage:= Ix Div SortRecord.B;
      I:= 0;
      While SortRecord.Page[i] <> IxPage Do I:=I+1;
      { IxPage = SortRecord.Page [I] }
      Adr:=Ptr(Seg(SortRecord.Buf[I]^),
               Ofs(SortRecord.Buf[I]^) +
               (Ix Mod SortRecord.B)* SortRecord.ItemLength);
   End;


   Procedure SortFetchPage( Ix: Integer; U1, U2: Integer);
      { After call of SortFetchPage the record Ix is in memory.
        If records U1 and U2 are in memory before call, then 
        they are not overwritten since we soon will need them   }

      Var U1Page,
          U2Page,
          IxPage : Integer;
          Victim : 0..10;   { The chosen page to be written to file }

      Procedure SOget(Addr: SortPointer; Pageno: Integer);
         { Read page PageNo into memory at address Addr }
      var
        BR : integer;
      Begin
         If SortRecord.Error=0 Then Begin
            Seek(SortRecord.F, Pageno*SortRecord.SecPrPage);
            BlockRead(SortRecord.F, Addr^, SortRecord.SecPrPage, BR);
            If BR = 0 Then SortRecord.Error:=11  { read error }
         End;
      End;

      Function InMem( Ix: Integer): Boolean;
         { InMem returns true if record ix is in memory }
         Var I,IxPage : Integer;
             Flag     : Boolean;
      Begin
         IxPage:= Ix Div SortRecord.B;
         Flag:=False;
         For I:=0 To SortRecord.Pages-1 Do
            If Ixpage=SortRecord.Page[I] Then Flag:=True;
         InMem:=Flag
      End;

   Begin   { SortFetchPage }
      If (Not InMem(Ix)) Then Begin
         { Record Ix not in memory }
         IxPage:= Ix Div SortRecord.B;
         Victim:=0; 
         U1Page:=U1 Div SortRecord.B;
         U2Page:=U2 Div SortRecord.B;
         While ((SortRecord.Page[Victim]=U1Page) Or
               (SortRecord.Page[Victim]=U2Page)) Do  
            Victim:=Victim+1;
         { SortRecord.Page[Victim] not in U }
         If SortRecord.W[Victim] Then     { Dirty bit set }
            SortPut(SortRecord.Buf[Victim],SortRecord.Page[Victim]);
         SoGet(SortRecord.Buf[Victim],IxPage);
         SortRecord.Page[Victim]:= IxPage;
         SortRecord.W[Victim]:= False;
      End
   End;

function TurboSort(ItemLength : integer;
                   InpPtr, LessPtr, OutPtr : ProcPtr) : integer;
   { Function TurboSort returns an integer specifying the result of 
     the sort
     TurboSort=0  : Sorted
     TurboSort=3  : Workarea too small
     TurboSort=8  : Illegal itemlength
     TurboSort=9  : More than maxint records
     TurboSort=10 : Write error during sorting ( disk full )
     TurboSort=11 : Read error during sorting
     TurboSort=12 : Impossible to create new file ( directory full ) }

   Const 
      SecSize = 128;
      UserStack = 2000.0;          { Minimum  memory for user        }

   Var
      SaveZ,
      SwopPost : SortPointer;
      SafetyP,
      WorkArea : Real;            { No of bytes internal memory    }
      I,
      PageSize : Integer;         { No of bytes pr page            }

   Function Convert(I:Integer):Real;
      { Convert negative integers to positive reals }
   Begin
      If I<0.0 Then   { I greater than MaxInt }
         Convert:=I+65536.0
      Else
         Convert:=I
   End;

   Function SortAvail:Real;
      { Redefine MaxAvail to return real result }
      Var I : Real;
   Begin
   (*
      I:=Convert(MaxAvail);
      I:=16.0*I; *)

      SortAvail:= MaxAvail;
   End;


   Procedure QuickSort;
      { Non-recursive version of quicksort algorithm as given
        in Nicklaus Wirth : Algorithms + Data Structures = Programs }

      Procedure Exchange(I,J: Integer);
         { Change records I and J }
         Var
            P,R,S   : Integer;
            K,L     : 0..10;
            IAddr,
            JAddr   : SortPointer;
   
      Begin
         P:= I Div SortRecord.B;
         K:=0;
         While SortRecord.Page[k]<>P Do K:=K+1;
         P:= J Div SortRecord.B;
         L:=0;
         While SortRecord.Page[L]<>P Do L:=L+1;
         R:= I Mod SortRecord.B; 
         S:= J Mod SortRecord.B;
         IAddr:= Ptr(Seg(SortRecord.Buf[K]^),
                     Ofs(SortRecord.Buf[K]^) + R*ItemLength);
         JAddr:= Ptr(Seg(SortRecord.Buf[L]^),
                     Ofs(SortRecord.Buf[L]^) + S*ItemLength);
         Move(IAddr^,SwopPost^,ItemLength);
         Move(JAddr^,IAddr^,ItemLength);
         Move(Swoppost^,JAddr^,ItemLength);
         SortRecord.W[K]:= True;
         SortRecord.W[L]:= True;
      End;
   
      Const 
         MaxStack = 20; { Log2(N) = MaxStack, i. e. for MaxStack = 20
                           it is possible to sort 1 million records    }
      Var 
         { The stacks }
         LStack : Array[1..MaxStack] Of Integer; { Stack of left  index }
         RStack : Array[1..MaxStack] Of Integer; { Stack of right index }
         Sp     : Integer;                       { Stack SortPointer        }

         M,L,R,I,J         : Integer;
         XAddr,YAddr,ZAddr : SortPointer;

   Begin
      { The quicksort algorithm }
      If SortRecord.N>0 Then 
      Begin
         LStack[1]:=0;
         RStack[1]:=SortRecord.N-1;
         Sp:=1
      End Else Sp:=0;

      While Sp>0 do
      Begin
         { Pop(L,R) }
         L:=LStack[Sp]; 
         R:=RStack[Sp]; 
         Sp:=Sp-1;
         Repeat
            I:=L; J:=R;
            M:=(I+J) shr 1;
            SortFetchPage(M,I,J);       { get M, hold I and J }
            { record M in memory}
            If SortRecord.Error<>0 Then Exit; { End program }
            SortFetchAddr(M,ZAddr);
            Move(ZAddr^,SaveZ^,ItemLength);
            Repeat
               SortFetchPage(I,J,M);    { get I, hold J and M }
               { I and M in memory }
               If SortRecord.Error<>0 Then Exit; { End program }
               SortFetchAddr(I,XAddr);
               While Less(XAddr^,SaveZ^) do
               Begin
                  I:=I+1;
                  SortFetchPage(I,J,M);
                  SortFetchAddr(I,XAddr);
                  If SortRecord.Error<>0 Then Exit; { End program }
               End;
               { I and M in memory }
               SortFetchPage(J,I,M);     { Get J, hold I and M }
               { I, J and M in memory }
               If SortRecord.Error<>0 Then Exit;  { End program }
               SortFetchAddr(J,YAddr);
               While Less(SaveZ^,YAddr^) do
               Begin
                  J:=J-1;
                  SortFetchPage(J,I,M);
                  SortFetchAddr(J,YAddr);
                  If SortRecord.Error<>0 Then Exit;  { End program }
               End;
               { I, J and M in memory }
               If I<=J Then
               Begin
                  If I<>J Then Exchange(I,J);
                  I:=I+1;
                  J:=J-1;
               End;
            Until I>J;
            { Push longest interval on stack }
            If J-L < R-I Then
            Begin
               If I<R Then
               Begin
                  { Push(I,R) }
                  Sp:=Sp+1;
                  LStack[Sp]:=I;
                  RStack[Sp]:=R;
               End;
               R:=J
            End
            Else
            Begin
               If L<J Then
               Begin
                  { Push(L,J) }
                  Sp:=Sp+1;
                  LStack[Sp]:=L;
                  RStack[Sp]:=J;
               End;
               L:=I
            End;

          Until L>=R
       End;
    End  { QuickSort };



Begin { TurboSort }
   If ItemLength>1 Then Begin
      SortRecord.ItemLength := ItemLength;
      WorkArea:=SortAvail-ItemLength-ItemLength-UserStack;

      { No of pages to be kept in memory }
      SortRecord.Pages:=Trunc(WorkArea/(2.0*MaxInt)+1.0); 
      If SortRecord.Pages<3 Then                   { Must be at least 3 }
         SortRecord.Pages:=3;

      SortRecord.SecPrPage:=Trunc(WorkArea / SecSize) Div SortRecord.Pages;
      If SortRecord.SecPrPage > 20 Then
         SortRecord.SecPrPage:=4*(SortRecord.SecPrPage div 4);

      PageSize:=SortRecord.SecPrPage*SecSize; { May be negative or 0 }
      If (PageSize=0) And (SortRecord.SecPrPage>0) Then
         SafetyP:=65536.0    { = 2*MaxInt }
      Else
         SafetyP:=Convert(PageSize);
      SortRecord.B:= Trunc(SafetyP/ItemLength);

      If SortRecord.B > 0 Then Begin { Enough memory }

         GetMem(SwopPost,ItemLength);
         GetMem(SaveZ,ItemLength);
         For I:=0 To SortRecord.Pages-1 Do
            GetMem(SortRecord.Buf[I],PageSize);

         TurboSort:=0;

         SortRecord.Error:=0;
         SortRecord.FileCreated:=False;
         SortRecord.N:=0;
         SortRecord.NModB:=0;
         SortRecord.NDivB:=0;
         For I:=0 To SortRecord.Pages-1 Do
            SortRecord.Page[I]:=I;
         GluePtr := InpPtr;
         CallProc;   { call user defined input procedure }
         { all records are read }
    
         If SortRecord.Error = 0 Then Begin
            { No errors while reading records }
            { Initialize virtual system }
            For I:=0 To SortRecord.Pages-1 Do
               SortRecord.W[I]:=True;
   
            If SortRecord.Error=0 Then
            begin
              GluePtr := LessPtr;
              Quicksort;
            end;   
            { End sort, return all records }
            SortRecord.Udix:=0;
            If SortRecord.Error=0 Then
            begin
              GluePtr := OutPtr;
              CallProc; { call user defined output procedure }
            end;
         End;

         If SortRecord.FileCreated Then 
         Begin
            Close(SortRecord.F);
            Erase(SortRecord.F)
         End;

         { Release allocated memory }
         For I:=SortRecord.Pages-1 DownTo 0 Do
            FreeMem(SortRecord.Buf[I],PageSize);
         FreeMem(SaveZ,ItemLength);
         FreeMem(SwopPost,ItemLength);

      End Else SortRecord.Error:=3; { Too little memory  }
   End Else SortRecord.Error:=8;    { Illegal itemlength }
   TurboSort:=SortRecord.Error;
End; { TurboSort }


{ Procedures used by user routines }

   Procedure SortRelease(Var ReleaseRecord);
     { Accept record from user }
     Var
        I,BufNo : Integer;
        Point : SortPointer;
   Begin
      If SortRecord.Error=0 Then Begin
         If SortRecord.N=MaxInt Then  { Only possible to sort MaxInt records }
            SortRecord.Error:=9;    
         If ((SortRecord.NModB=0) and (SortRecord.NDivB >= SortRecord.Pages)) Then
         Begin
            { Write out last read page }
            If SortRecord.NDivB=SortRecord.Pages Then Begin
               { create user file }
               Assign(SortRecord.F,'SOWRK.$$$');
               Rewrite(SortRecord.F);
               If IOResult<>0 Then SortRecord.Error:=12
               Else SortRecord.FileCreated:=True;
               { Fill page 0 to Pages-2 }
               For I:=0 To SortRecord.Pages-2 Do
                  SortPut(Ptr(DSeg,0), I);
            End;
            { Write user record in last page }
            SortPut(SortRecord.Buf[SortRecord.Pages-1],
                    SortRecord.Page[SortRecord.Pages-1]);
            SortRecord.Page[SortRecord.Pages-1]:=
                SortRecord.Page[SortRecord.Pages-1]+1;
         End;

         If SortRecord.NDivB>=SortRecord.Pages Then
            BufNo:=SortRecord.Pages-1
         Else 
            BufNo:=SortRecord.NDivB;
         Point:= Ptr(Seg(SortRecord.Buf[BufNo]^),
                     Ofs(SortRecord.Buf[BufNo]^) + 
                     SortRecord.NModB*SortRecord.ItemLength);
         Move(ReleaseRecord,Point^,SortRecord.ItemLength);

         SortRecord.N:= SortRecord.N+1;
         SortRecord.NModB:=SortRecord.NModB + 1;
         If SortRecord.NModB=SortRecord.B Then Begin
            SortRecord.NModB:=0;
            SortRecord.NDivB:=SortRecord.NDivB+1
         End;
      End;
   End   { SortRelease };


   Procedure SortReturn(Var ReturnRecord);
      { Return record to user }
      Var AuxAddr : SortPointer;
   Begin
      If SortRecord.Error=0 Then Begin
         SortFetchPage(SortRecord.Udix,SortRecord.N-1,-SortRecord.B);
         SortFetchAddr(SortRecord.Udix,AuxAddr);
         Move(AuxAddr^,ReturnRecord,SortRecord.ItemLength);
         SortRecord.Udix:= SortRecord.Udix+1
      End
   End   { SortReturn };


   Function SortEOS:Boolean;
      { Returns True if all records are returned }
   Begin
      SortEOS:= (SortRecord.Udix >= SortRecord.N) Or (SortRecord.Error<>0);
   End;

end.

