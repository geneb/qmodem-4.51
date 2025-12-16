{$M 3000,5000,5000}
Program HostPack;


USES   TpCrt,
       tpstring,
       Dos,
       TPDos;


Type
   MSG_Header = Record
                   MsgNum   : Integer;     {computed}
                   NameTo   : String[30];  {Name of receiver}
                   NameFrom : String[30];  {name of sender}
                   DateTime : String[19];  {message entry stats}
                   Subject  : String[30];  {Subject of message}
                   Private  : Boolean;     {for public to read?}
                   Read     : Boolean;     {read by receiver?}
                   Killed   : Boolean;     {killed message?}
                   StartPos : LongInt;
                   lines    : Integer;     {Line #'s in Detail File}
                End;

Var
   MsgFile1,msgfile2 : File of Msg_Header;
   MsgDetail1,msgdetail2 : Text;
   msghead1, msghead2 : msg_header;
   x : Longint;
   I : Integer;
   s : string;
Label
   skip2;

Begin
   DirectVideo := False;
   DetectMultitasking := True;
   ReinitCrt;
   Writeln ('QMHOSTPK 1.1 - Qmodem v4.5 TD  Host Message Base Packer');
   If Not Existfile('QMHOST.HDR') then
      Begin
         Writeln ('File QMHOST.HDR not found.  Are you sure you''re in the right directory?');
         Halt;
      End;
   Assign (MsgFile1, 'QMHOST.HDR');
   Assign (Msgdetail1, 'QMHOST.MSG');
   assign (msgfile2, 'HDR.$$$');
   assign (msgdetail2,'MSG.$$$');
   Reset(MsgFile1);
   If IOresult <> 0 then writeln ('error opening header1');
   Reset(MsgDetail1);
   If IOresult <> 0 then writeln ('error opening detail1');
   rewrite(msgfile2);
   If IOresult <> 0 then writeln ('error opening header2');
   rewrite(msgdetail2);
   If IOresult <> 0 then writeln ('error opening detail2');

   x := Filesize(msgfile1);
   If x = 0 then
      Begin
         Writeln ('Empty Header file.  Done.');
         Halt;
      End
   Else
      Begin
         Writeln (msgdetail2,'QMODEM SST HOST MESSAGE FILE');
         {find the first and last msg numbers to display}
         Repeat
         Read(msgfile1,msghead1);
         With msghead1 do
            Begin
               If Killed then
                  begin
                     writeln('#',msgnum,' deleted');
                     Goto Skip2;
                  end;
               msghead2 := msghead1;
               write('#',msghead2.msgnum,' copied');
               msghead2.StartPos := TextPos(msgdetail2);
               If TextSeek (msgdetail1,msghead1.Startpos) then
                  For x := 1 to Lines do
                     Begin
                        Readln(msgdetail1,s);
                        write('.');
                        Writeln (msgdetail2,s);
                     End
               Else
                  Writeln('Error reading Detail file');
               Write(msgfile2, msghead2);
               Writeln;
            End;
            Skip2:
         Until EOF(msgfile1);
      End;
   Close(MsgFile1);
   Erase(msgfile1);
   Close(msgfile2);
   rename (msgfile2, 'QMHOST.HDR');
   close(msgdetail1);
   erase(msgdetail1);
   Close(msgdetail2);
   rename(msgdetail2,'QMHOST.MSG');
   Writeln ('DONE');
End.
