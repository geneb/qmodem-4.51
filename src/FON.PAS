   Phone_type = Record
                           Name             : String[27];
                           Filler01         : Word;
                           Number           : String[19];
                           Filler02         : Word;
                           Dbits, Sbits     : Integer;
                           Parity           : TParity;
                           Script_File      : String[12];
                           Last_Connect     : Word;
                           Filler03         : String[6];
                           Times_Called     : LongInt;
                           Filler04         : Word;
                           Default_Protocol : Char;
                           Echo1            : Char;
                           Password         : String[14];
                           EntryNumber      : Integer;
                           Marked           : Boolean;
                           Filler           : Byte;
                           LearnTag         : Boolean;
                           NoteNum          : Word;   {never change this!}
                           HasNote          : Boolean;
                           NoPrefix         : Boolean;
                           ComSpeed         : LongInt;
                           Filler99         : Array[1..3] Of Byte;
                        End;



