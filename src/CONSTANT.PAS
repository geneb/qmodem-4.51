Unit Constant;

Interface

Const
   { One of these must be included to determine the naming }
   { conventions in Qmodem                                 }

   {$IfDef Yakcom}
      {$I \yak\YAKCOM.INC }
   {$Else}
      {$IfDef RElink}
         {$I \relink\RELINK.INC }
      {$Else}
         {$I QMODEM.INC }
      {$EndIf}
   {$EndIf}

Implementation

End.
