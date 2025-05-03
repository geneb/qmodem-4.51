
unit
  QmPick;

interface

uses
  OpCrt,  OpFrame, OpCmd,  OpWindow,
  OpPick, QmFon,   QmMisc, QmColor;

  function GetConversionType: word;

implementation

type
  Qmodem_FON_List = object(PickList)
    constructor Init(X1, Y1, X2, Y2: Byte);
    procedure ItemString(FON_Item: Word;
                         Pick_Mode: pkMode;
                         var Item_Type: pkItemType;
                         var Item_String: String); virtual;
  end;

  constructor Qmodem_FON_List.Init(X1, Y1, X2, Y2: Byte);
  begin
    if not PickList.InitAbstractDeluxe(X1, Y1, X2, Y2,
                                       QmColorSet,
                                       DefWindowOptions or wBordered,
                                       78, 4, PickVertical, SingleChoice,
                                       DefPickOptions and not pkAlterPageRow and not pkStick) then
      Fail;
  end;

  procedure Qmodem_FON_List.ItemString(FON_Item: Word;
                                       Pick_Mode: pkMode;
                                       var Item_Type: pkItemType;
                                       var Item_String: String);
  const
    Display_String: array[1..4] of string = (
      ' Procomm Plus v1.1x ',
      ' Procomm Plus v2.0  ',
      ' Telix v3.11        ',
      ' Boyan v5.0         ');
  begin
    Item_String := Display_String[FON_Item];
  end;

  procedure CnvStatus(FON_List: PickListPtr); far;
  var
    Display_String: string;
  begin
    case FON_List^.GetLastChoice of
      1: Display_String := 'Convert a Procomm Plus v1.1 .DIR file to Qmodem v4.5 TD .FON format';
      2: Display_String := 'Convert a Procomm Plus v2.0 .DIR file to Qmodem v4.5 TD .FON format';
      3: Display_String := 'Convert a Telix v3.11 .FON file to Qmodem v4.5 TD .FON format';
      4: Display_String := 'Convert a Boyan v5.0 .FON file to Qmodem v4.5 TD .FON format';
    end;

    StatusLine(Display_String);
  end;

  function GetConversionType: word;
  var
    Conversion_PickList: Qmodem_FON_List;
  begin
    GetConversionType := 0;

    with Conversion_PickList do
      if Init(5, 5, 24, 9) then begin
        SetMoveProc(CnvStatus);

        With wFrame do begin
          AddHeader(' Select ', heTL);
          AddShadow(shBR, shSeeThru);
        end;

        repeat
          Process;
        until GetLastCommand in [ccQuit, ccSelect, ccError];

        if GetLastCommand = ccSelect then
          GetConversionType := GetLastChoice;

        Done;
      end;
  end;

end.

