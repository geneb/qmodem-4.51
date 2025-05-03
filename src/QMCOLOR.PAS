
unit
  QmColor;

interface

uses
  OpCrt;

const
  QmColorSet : ColorSet = (
    TextColor       : $17; TextMono       : $07;
    CtrlColor       : $17; CtrlMono       : $07;
    FrameColor      : $1F; FrameMono      : $0F;
    HeaderColor     : $1F; HeaderMono     : $0F;
    ShadowColor     : $08; ShadowMono     : $07;
    HighlightColor  : $71; HighlightMono  : $70;
    PromptColor     : $1F; PromptMono     : $07;
    SelPromptColor  : $1F; SelPromptMono  : $07;
    ProPromptColor  : $1E; ProPromptMono  : $07;
    FieldColor      : $0F; FieldMono      : $0F;
    SelFieldColor   : $71; SelFieldMono   : $70;
    ProFieldColor   : $0F; ProFieldMono   : $07;
    ScrollBarColor  : $78; ScrollBarMono  : $07;
    SliderColor     : $1E; SliderMono     : $07;
    HotSpotColor    : $1E; HotSpotMono    : $07;
    BlockColor      : $0F; BlockMono      : $0F;
    MarkerColor     : $71; MarkerMono     : $70;
    DelimColor      : $0F; DelimMono      : $0F;
    SelDelimColor   : $70; SelDelimMono   : $70;
    ProDelimColor   : $0F; ProDelimMono   : $07;
    SelItemColor    : $71; SelItemMono    : $70;
    ProItemColor    : $00; ProItemMono    : $01;
    HighItemColor   : $0F; HighItemMono   : $0F;
    AltItemColor    : $0F; AltItemMono    : $0F;
    AltSelItemColor : $74; AltSelItemMono : $70;
    FlexAHelpColor  : $47; FlexAHelpMono  : $07;
    FlexBHelpColor  : $47; FlexBHelpMono  : $07;
    FlexCHelpColor  : $4F; FlexCHelpMono  : $0F;
    UnselXrefColor  : $09; UnselXrefMono  : $09;
    SelXrefColor    : $70; SelXrefMono    : $70;
    MouseColor      : $4E; MouseMono      : $70
  );

implementation

end.

