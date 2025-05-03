  function IncFilename(File_Name: string): string;
  const
    Max_Name_Str_Len = 8;
    Zero_Str = '0';
  var
    New_File_Name: string;
    File_Index: longint;
    File_Index_Str: string;
    File_Index_Str_Len: byte absolute File_Index_Str;
    Dir_Str: DirStr;
    Name_Str: NameStr;
    Ext_Str: ExtStr;
    Name_Str_Len: byte absolute Name_Str;
  begin
    {Initialize our index}
    File_Index := -1;
    New_File_Name := File_Name;

    while ExistFile(New_File_Name) do begin
      {Increment our index}
      Inc(File_Index);
      {Isolate the file's name}
      FSplit(File_Name, Dir_Str, Name_Str, Ext_Str);
      {Update incremented string}
      File_Index_Str := LeftPadCh(Long2Str(File_Index), Zero_Str,
                                  Max_Name_Str_Len - Name_Str_Len);
      {Ensure length of Max_Name_Str_Len}
      Name_Str := Pad(Name_Str, Max_Name_Str_Len);
      {Update the file's name}
      move(File_Index_Str[1], Name_Str[Succ(Max_Name_Str_Len -
           File_Index_Str_Len)], File_Index_Str_Len);
      {Rebuild the file's full pathname}
      New_File_Name := Dir_Str + Name_Str + Ext_Str;
    end;

    {Return result to caller}
    IncFilename := New_File_Name;
  end;

