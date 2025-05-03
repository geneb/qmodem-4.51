Unit Const1;

Interface

Procedure Logo;
Procedure LogoM;

Implementation

   { One of the following is used for the Opening Screen   }
   { in Qmodem                                             }

   {Use the default 4.2 logo if no special one is specified}
   {$L Logo.Obj}
   {$L LogoM.Obj}

Procedure Logo; External;
Procedure LogoM; External;

End.
