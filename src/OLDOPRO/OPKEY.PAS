{$S-,R-,V-,I-,B-,F-,O-,A-}


{*********************************************************}
{*                    OPKEY.PAS 1.01                     *}
{*               TurboPower Software 1990.               *}
{*             Released to the public domain.            *}
{*********************************************************}

unit OpKey;
  {-Keystroke definitions}

interface

{Notes:
  * keys returned only with OPCRT or OPENHKBD enhanced keyboard support
  # keys returned only with OPENHKBD extra key support
}

const

{Function keys}
    F1 = $3B00;       ShF1 = $5400;      CtrlF1 = $5E00;      AltF1 = $6800;
    F2 = $3C00;       ShF2 = $5500;      CtrlF2 = $5F00;      AltF2 = $6900;
    F3 = $3D00;       ShF3 = $5600;      CtrlF3 = $6000;      AltF3 = $6A00;
    F4 = $3E00;       ShF4 = $5700;      CtrlF4 = $6100;      AltF4 = $6B00;
    F5 = $3F00;       ShF5 = $5800;      CtrlF5 = $6200;      AltF5 = $6C00;
    F6 = $4000;       ShF6 = $5900;      CtrlF6 = $6300;      AltF6 = $6D00;
    F7 = $4100;       ShF7 = $5A00;      CtrlF7 = $6400;      AltF7 = $6E00;
    F8 = $4200;       ShF8 = $5B00;      CtrlF8 = $6500;      AltF8 = $6F00;
    F9 = $4300;       ShF9 = $5C00;      CtrlF9 = $6600;      AltF9 = $7000;
   F10 = $4400;      ShF10 = $5D00;     CtrlF10 = $6700;     AltF10 = $7100;
   F11 = $8500;{*}   ShF11 = $8700;{*}  CtrlF11 = $8900;{*}  AltF11 = $8B00;{*}
   F12 = $8600;{*}   ShF12 = $8800;{*}  CtrlF12 = $8A00;{*}  AltF12 = $8C00;{*}

{Numeric keypad}
{Note that ShUp is an "8", ShPad5 is a "5", and so on}
    Up = $4800;       ShUp = $4838;      CtrlUp = $8D00;{*}   AltUp = $9800;{#}
  Down = $5000;     ShDown = $5032;    CtrlDown = $9100;{*} AltDown = $A000;{#}
  Left = $4B00;     ShLeft = $4B34;    CtrlLeft = $7300;    AltLeft = $9B00;{#}
 Right = $4D00;    ShRight = $4D36;   CtrlRight = $7400;   AltRight = $9D00;{#}
  Home = $4700;     ShHome = $4737;    CtrlHome = $7700;    AltHome = $9700;{#}
EndKey = $4F00;      ShEnd = $4F31;     CtrlEnd = $7500;     AltEnd = $9F00;{#}
  PgUp = $4900;     ShPgUp = $4939;    CtrlPgUp = $8400;    AltPgUp = $9900;{#}
  PgDn = $5100;     ShPgDn = $5133;    CtrlPgDn = $7600;    AltPgDn = $A100;{#}
   Ins = $5200;      ShIns = $5230;     CtrlIns = $9200;{*}  AltIns = $A200;{#}
   Del = $5300;      ShDel = $532E;     CtrlDel = $9300;{*}  AltDel = $A300;{#}
  Pad5 = $4C00;{*}  ShPad5 = $4C35;    CtrlPad5 = $8F00;{*} AltPad5 = $9C00;{#}

PadMinus = $4A2D;                  CtrlPadMinus = $8E00;{*} AltPadMinus= $4A00;{#}
 PadPlus = $4E2B;                   CtrlPadPlus = $9000;{*} AltPadPlus = $4E00;{#}
    Star = $092A;
 PadStar = $372A;                   CtrlPadStar = $9600;    AltPadStar = $3700;{#}
 PadSlash= $E02F;                  CtrlPadSlash = $9500;   AltPadSlash = $9500;
 PadEnter= $E00D;                  CtrlPadEnter = $E00A;



{Grey Keys}
    GreyUp = $48E0;
  GreyDown = $50E0;
  GreyLeft = $4BE0;     GreyCtrlLeft = $73E0;
 GreyRight = $4DE0;    GreyCtrlRight = $74E0;
  GreyHome = $47E0;     GreyCtrlHome = $77E0;
GreyEndKey = $4FE0;      GreyCtrlEnd = $75E0;
  GreyPgUp = $49E0;     GreyCtrlPgUp = $84E0;
  GreyPgDn = $51E0;     GreyCtrlPgDn = $76E0;
   GreyIns = $52E0;
   GreyDel = $53E0;

{Alphabetic keys}
  LowA = $1E61;        UpA = $1E41;       CtrlA = $1E01;       AltA = $1E00;
  LowB = $3062;        UpB = $3042;       CtrlB = $3002;       AltB = $3000;
  LowC = $2E63;        UpC = $2E43;       CtrlC = $2E03;       AltC = $2E00;
  LowD = $2064;        UpD = $2044;       CtrlD = $2004;       AltD = $2000;
  LowE = $1265;        UpE = $1245;       CtrlE = $1205;       AltE = $1200;
  LowF = $2166;        UpF = $2146;       CtrlF = $2106;       AltF = $2100;
  LowG = $2267;        UpG = $2247;       CtrlG = $2207;       AltG = $2200;
  LowH = $2368;        UpH = $2348;       CtrlH = $2308;       AltH = $2300;
  LowI = $1769;        UpI = $1749;       CtrlI = $1709;       AltI = $1700;
  LowJ = $246A;        UpJ = $244A;       CtrlJ = $240A;       AltJ = $2400;
  LowK = $256B;        UpK = $254B;       CtrlK = $250B;       AltK = $2500;
  LowL = $266C;        UpL = $264C;       CtrlL = $260C;       AltL = $2600;
  LowM = $326D;        UpM = $324D;       CtrlM = $320D;       AltM = $3200;
  LowN = $316E;        UpN = $314E;       CtrlN = $310E;       AltN = $3100;
  LowO = $186F;        UpO = $184F;       CtrlO = $180F;       AltO = $1800;
  LowP = $1970;        UpP = $1950;       CtrlP = $1910;       AltP = $1900;
  LowQ = $1071;        UpQ = $1051;       CtrlQ = $1011;       AltQ = $1000;
  LowR = $1372;        UpR = $1352;       CtrlR = $1312;       AltR = $1300;
  LowS = $1F73;        UpS = $1F53;       CtrlS = $1F13;       AltS = $1F00;
  LowT = $1474;        UpT = $1454;       CtrlT = $1414;       AltT = $1400;
  LowU = $1675;        UpU = $1655;       CtrlU = $1615;       AltU = $1600;
  LowV = $2F76;        UpV = $2F56;       CtrlV = $2F16;       AltV = $2F00;
  LowW = $1177;        UpW = $1157;       CtrlW = $1117;       AltW = $1100;
  LowX = $2D78;        UpX = $2D58;       CtrlX = $2D18;       AltX = $2D00;
  LowY = $1579;        UpY = $1559;       CtrlY = $1519;       AltY = $1500;
  LowZ = $2C7A;        UpZ = $2C5A;       CtrlZ = $2C1A;       AltZ = $2C00;

{Number keys, on top row of keyboard}
  Num1 = $0231;                                                Alt1 = $7800;
  Num2 = $0332;                           Ctrl2 = $0300;       Alt2 = $7900;
  Num3 = $0433;                                                Alt3 = $7A00;
  Num4 = $0534;                                                Alt4 = $7B00;
  Num5 = $0635;                                                Alt5 = $7C00;
  Num6 = $0736;                           Ctrl6 = $071E;       Alt6 = $7D00;
  Num7 = $0837;                                                Alt7 = $7E00;
  Num8 = $0938;                                                Alt8 = $7F00;
  Num9 = $0A39;                                                Alt9 = $8000;
  Num0 = $0B30;                                                Alt0 = $8100;
 Minus = $0C2D;                  CtrlMinus = $0C1F;        AltMinus = $8200;
                     Plus = $0D2B;                          AltPlus = $8300;
                                                           AltEqual = $8300;

{Miscellaneous}
   Space = $3920;
    BkSp = $0E08;                   CtrlBkSp = $0E7F;       AltBkSp = $0E00;{*}
     Tab = $0F09;   ShTab = $0F00;  CtrlTab  = $9400;{*}     AltTab = $A500;{*}
   Enter = $1C0D;                   CtrlEnter= $1C0A;      AltEnter = $1C00;{*}
     Esc = $011B;                                            AltEsc = $0100;{*}

  {==========================================================================}

implementation

{$IFDEF InitAllUnits}
begin
{$ENDIF}
end.
