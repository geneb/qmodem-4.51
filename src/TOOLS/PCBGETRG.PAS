{$M 1024,200,1000}

program GETREG;              {Get the registration number}

uses tpcrt,
     tpstring;


Label Top;
Type
   RecType = Array[1..128] of Char;
var
  PCBRec : RecType;
  PCB : File of RecType;
  n,bit : byte;
  x, i,CRC,divsel : integer;
  name         : String[50];
  CRCREAL      : real;
  ch : char;
  stdin, stdout : text;
const

   { PRODUCTION CRCS }
   Divisors: array [0..31] of integer = (1215,5021,9069,10565,10627,13061,13083,
                                         15145,18911,22059,26529,29821,30491,
                                         30493,30539,30989,-31727,-27589,-25517,
                                         -23725,-22221,-21055,-20399,-19999,
                                         -17769,-16863,-14895,-13533,-9401,
                                         -9397,-7151,-865);
   { BETA CRCS }
   {
   Divisors: array [0..31] of integer = (12483,12861,15465,17917,20297,23255,
                                         27677,29549,30939,30941,30955,-31759,
                                         -27647,-27589,-20263,-20241,-20141,
                                         -17625,-17601,-15457,-15433,-13599,
                                         -13593,-10183,-7327,-7309,-2527,-2521,
                                         -1077,-1075,-205,-203);

   }

begin
  filemode := $42;
  directvideo := False;
  top:
  Name := '';
  Assign (pcb, 'PCBoard.SYS');
  Reset(PCB);
  If IOResult <> 0 then
     Begin
        Writeln ('Error accessing the PCBOARD.SYS file.  Notify SYSOP!');
        Halt;
     End;
  Read (PCB,PCBrec);
  Close(PCB);
  x := IOResult;
  For x := 85 to 109 do
     Name := Name + UpCase(PCBrec[x]);
  Name := Trim(Name);
  Writeln('');
  CRC := ((not ord(name[0]) shl 8) + (ord(name[0]) xor ord(name[1])));      {CRC seed}
  divsel := divisors[(ord(name[0]) + ord(name[2])) and 31];  {make 0-31}
  for n := 1 to ord(name[0]) do
  begin
    CRC := CRC XOR (ord(name[n]) shl 8);
    for bit := 1 to 8 do
      if CRC and $8000 <> 0 then
        CRC := CRC shl 1 XOR divsel
        else CRC := CRC shl 1;
  end;
  CRCREAL := CRC;
  if CRCREAL < 0 then CRCREAL := CRC + 65536.0;
  Writeln('Registration number for ',NAME,' is = ',CRCREAL:5:0);
  Writeln('Don''t lose this number!  It will allow you to register all future versions.');
  Writeln('');
  Write  ('Press any key to return to the board > ');
  Ch := ReadKey;
end.
