{$S-,R-,V-,I-,B-}

{$IFDEF Ver40}
  {$F-}
{$ELSE}
  {$F+}
  {.$I OPLUS.INC}
  {.$I AMINUS.INC}
{$ENDIF}

{Conditional defines that may affect this unit}
{$I TPDEFINE.INC}

{*********************************************************}
{*                   TPMENU.PAS 5.11                     *}
{*        Copyright (c) TurboPower Software 1987.        *}
{* Portions copyright (c) Sunny Hill Software 1985, 1986 *}
{*     and used under license to TurboPower Software     *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit TPMenu0;
  {-Pulldown menu routines}

interface

uses
  TPMemChk,
  TPString,
  TPCrt,
  TPCmd,
  {$IFDEF UseMouse}
  TPMouse,
  {$ENDIF}
  TPWindow,
  Initial;

  {Interfaced type declarations, constants, data}
  {.$I TPMENU.IN0}

procedure CheckMenuStatus(Mstatus : MenuStatusType);
  {-Check menu status, report and halt on any error}

function MenuStatus : MenuStatusType;
  {-Return status of previous operation}

function NewMenu(SelectKeys : MenuCharSet; UserFunc : Pointer) : Menu;
  {-Initialize a new menu system by returning a pointer to a new menu}

procedure SetMenuSelectKeys(Mnu : Menu; Skeys : MenuCharSet);
  {-Change the select key set of existing menu system as specified}

procedure SubMenu(XLP, YLP, YhelpP : Byte;
                  OrientP : Orientation;
                  FrameP : FrameArray;
                  ColorsP : MenuColorArray;
                  HeaderStr : string
                  );
  {-Add a submenu to currently active item of currently active submenu
    of currently active menu}

procedure PopSubLevel;
  {-Pop active menu from top of menu stack}

procedure MenuItem(NameStr : string; {Name of item}
                   DisplayPosP : Byte; {Offset from upper left corner of menu for item}
                   SelectPosP : Byte; {Position within namestr to hilite and select from}
                   KeyP : MenuKey; {Key to return when item is selected}
                   HelpStr : string {Help string for item}
                   );
  {-Add an item to currently active submenu of currently active menu.
    Name space is allocated on heap}

procedure MenuWidth(Width : Byte);
  {-Set width of submenu currently being built}

procedure MenuHeight(Height : Byte);
  {-Set height of submenu currently being built}

procedure MenuMode(Explode, Shadow, Noise : Boolean);
  {-Set mode of submenu currently being built}

procedure MenuItemPtr(NamePtr : Pointer; {Pointer to name of item}
                      DisplayPosP : Byte;
                      SelectPosP : Byte;
                      KeyP : MenuKey;
                      HelpPtr : Pointer {Pointer to help for item}
                      );
  {-Add an item to currently active submenu of currently active menu.
    Name space is NOT allocated on heap}

procedure SetMenuMode(Mnu : Menu; Explode, Shadow, Noise : Boolean);
  {-Change display mode of an entire menu system}

procedure SetMenuDelay(Mnu : Menu; ExpDelay : Word);
  {-Change explosion delay for entire menu system}

procedure DisposeMenu(Mnu : Menu);
  {-Dispose of all menu heap space}

procedure ResetMenu(Mnu : Menu);
  {-Set all selections to first item}

function MenuChoice(Mnu : Menu; var SelectKey : Char) : MenuKey;
  {-Display menu system, let user browse it, return menukey of selected item,
    return keystroke used to select item, leave menu on screen}

procedure EraseMenu(Mnu : Menu; ResetSelections : Boolean);
  {-Erase active menus from the screen, reset selections to base if desired}

procedure EraseCurrentSubMenu(Mnu : Menu);
  {-Erase the currently displayed submenu}

procedure EraseMenuOntoStack(Mnu : Menu; var TStack : MenuStackP);
  {-Erase a menu system, saving the path of current selection on a stack}

procedure DrawMenuFromStack(Mnu : Menu; var TStack : MenuStackP);
  {-Draw a menu system using previously saved stack of items}

procedure SelectMenuItem(Mnu : Menu; MKey : MenuKey);
  {-Visibly update the menu system to select item MKey}

procedure RedrawMenu(Mnu : Menu);
  {-Redraw the entire active menu system, including all active submenus}

function AddMenuCommand(Cmd : MKType; NumKeys : Byte; Key1, Key2 : Word) : Boolean;
  {-Add a new command key assignment or change an existing one}

function GetMenuItemName(Mnu : Menu; MKey : MenuKey; var Name : string) : Boolean;
  {-Return the string describing the specified menu item. The function value
    is TRUE if the item exists and FALSE if it does not}

function SetMenuItemName(Mnu : Menu; MKey : MenuKey; NewName : string) : Boolean;
  {-Change the string describing the specified menu item to the new string.
    The new string is forced to be the same length as the old, either by
    truncation or by padding with blanks}

function FindMenuItem(Mnu : Menu; MKey : MenuKey; var Item : ItemP) : Boolean;
  {-Search for item key MKey, returning True and pointer to item if found}

function GetCurrentMenuKey(Mnu : Menu) : MenuKey;
  {-Return the key of the currently selected item}

  {$IFDEF Tpro5Menu}
procedure EnableMenuItem(Mnu : Menu; MKey : MenuKey);
  {-Allow the user to select the specified menu item in the specified menu}

procedure DisableMenuItem(Mnu : Menu; MKey : MenuKey);
  {-Prevent the user from selecting the specified item in the specified menu}
  {$ENDIF}

  {$IFDEF UseMouse}
procedure EnableMenuMouse;
  {-Enable and set cursor for mouse control of menus}

procedure DisableMenuMouse;
  {-Disable mouse control and hide mouse cursor}
  {$ENDIF}

  {--------------------------------------------------------------------------}
  {Following routines are for writing and reading menu library files         }

procedure WriteMenuLib(Mnu : Menu; Fname : string; ID : string);
  {-Write a menu system to a binary menu library}

function ReadMenuLib(Fname : string; ID : string; UserFunc : Pointer) : Menu;
  {-Read a menu system from a binary menu library}

procedure PackMenuLib(Iname, Oname : string);
  {-Remove obsolete menu entries from library Iname, creating Oname}

  {--------------------------------------------------------------------------}
  {Following routines are primarily for internal use, interfaced for MAKEMENU}

procedure ClearWindow(XL, YL, XH, YH, Attr : Byte);
  {-Clear a region with specified attribute}

procedure DrawFrame(XL, YL, XH, YH, Attr : Byte; Frame : FrameArray);
  {-Draw a frame around a window}

procedure PushSubMenu(Mnu : Menu; SubMnu : SubMenuP);
  {-Put submenu onto active stack of the menu}

procedure PopSubMenu(Mnu : Menu);
  {-Remove submenu from active stack}

procedure DisposeSubMenu(var SubMnu : SubMenuP);
  {-Dispose of submenu and its children}

procedure DrawItem(SubMnu : SubMenuP; Item : ItemP; UserFunc : Pointer);
  {-Draw one item in a submenu}

procedure DrawSubMenu(SubMnu : SubMenuP; UserFunc : Pointer);
  {-Draw a submenu on-screen}

procedure EraseSubMenu(SubMnu : SubMenuP);
  {-Erase a submenu from the screen}

  {==================================================================}

implementation

  {$I TPMENU.IN1}            {Most menu routines}
  {$I TPMENU.IN2}            {Routines for menu library files}

begin
  {Initialize the status flag}
  PrevMenuStatus := MenuSuccess;

  {No menu currently being built}
  CurrMenu := nil;

  {Initialize procedure pointers}
  MenuHelpPtr := nil;
  MenuGetKeyPtr := @ReadKeyWord;

  {$IFDEF UseMouse}
  {Mouse is not in control until EnableMenuMouse is called}
  MenuMouseEnabled := False;
  {$ENDIF}
end.
