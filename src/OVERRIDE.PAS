Unit Override;

Interface

Uses
   TpCrt, TpWindow, TpEdit, TpPick, TpDir, TpEntry;

Implementation

Begin
  TpCrt.DetectMultitasking := True;      {Enable DESQview support}
  TpCrt.CheckBreak         := False;     {Disable ^Break  support}

  TpWindow.Shadow          := True;      {True to make shadowed windows}
  TpWindow.ShadowMode      := BigShadow; {Kind of shadow to draw}
  TpWindow.ShadowAttr      := $07;       {Attribute to apply to shadow}
  TpWindow.Explode         := False;     {True to make exploding windows}
  TpWindow.ExplodeDelay    := 2;         {Milliseconds per stage of explosion}
  TpWindow.SoundFlagW      := False;     {True to make sound during explosions}

  TpEdit.ForceUpper        := False; {force chars to uppercase?}
  TpEdit.CursorToEnd       := False; {start cursor at Beginning of string}
  TpEdit.TrimBlanks        := False; {trim leading/trailing blanks? -- forced
                                      on temporarily for the numeric reads}
  TpEdit.InsertByDefault   := False; {default to insert mode?}
  TpEdit.EditSize          := 0;     {if NOT zero, overrides MaxLen as width}
  TpEdit.ClearFirstChar    := False; {clear string if first char is ASCII}
  TpEdit.PasswordMode      := False; {suppress display of actual string?}
  TpEdit.PasswordChar      := ^G;    {character used in password mode}
  TpEdit.EditMapCtrls      := True;  {map control characters to alphabetics?}
  TpEdit.RSpadChar         := '°';   {character used to pad edit strings}
  TpEdit.HouseCursorAtEnd  := False; {extra character of width to hold cursor
                                      when string is full?}
  TpEdit.ShowReadChar      := False; {display the character pressed?}
  TpEdit.HideCursorInReadChar := False; {cursor hidden?}
  TpEdit.WindowRelative    := False;

  TpDir.FilesUpper         := True;  {True to display files uppercase}
  {TpPick.}SetVerticalPick;          {Vertical pick orientation}
  {TpPick.}PickMatrix      := 1;

  TpEntry.InsertMode       := False; {Start up Edit screens in Overwrite mode}

End.
