{-----------------------------------------------------------------------------
The contents of this file are subject to the Mozilla Public License
Version 1.1 (the "License"); you may not use this file except in compliance
with the License. You may obtain a copy of the License at
http://www.mozilla.org/MPL/MPL-1.1.html

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either expressed or implied. See the License for
the specific language governing rights and limitations under the License.

The Original Code is: JvPageList.PAS, released on 2003-04-25.

The Initial Developer of the Original Code is Peter Th�rnqvist [peter3 at sourceforge dot net] .
Portions created by Peter Th�rnqvist are Copyright (C) 2004 Peter Th�rnqvist.
All Rights Reserved.

Contributor(s):

You may retrieve the latest version of this file at the Project JEDI's JVCL home page,
located at http://jvcl.sourceforge.net

Known Issues:

-----------------------------------------------------------------------------}
// $Id$

{$I jvcl.inc}

unit JvPageList;

interface

uses
  SysUtils, Classes,
  {$IFDEF VCL}
  Windows, Messages, Graphics, Controls,
  {$ENDIF VCL}
  {$IFDEF VisualCLX}
  Types, QGraphics, QControls, Qt, QWindows,
  {$ENDIF VisualCLX}
  JvComponent, JvThemes;

type
  EPageListError = class(Exception);

  IPageList = interface
    ['{6BB90183-CFB1-4431-9CFD-E9A032E0C94C}']
    function CanChange(AIndex: Integer): Boolean;
    procedure SetActivePageIndex(AIndex: Integer);
    function GetPageCount: Integer;
    function GetPageCaption(AIndex: Integer): string;
  end;

  TJvCustomPageList = class;

  TJvPagePaintEvent = procedure(Sender: TObject; ACanvas: TCanvas; ARect: TRect) of object;
  TJvPageCanPaintEvent = procedure(Sender: TObject; ACanvas: TCanvas; ARect: TRect; var DefaultDraw: Boolean) of object;
  { TJvCustomPage is the base class for pages in a TJvPageList and implements the basic behaviour of such
    a control. It has support for accepting components, propagating it's Enabled state, changing it's order in the
    page list and custom painting }
  TJvCustomPage = class(TJvCustomControl)
  private
    FPageList: TJvCustomPageList;
    FPageIndex:Integer;
    FOnBeforePaint: TJvPageCanPaintEvent;
    FOnPaint: TJvPagePaintEvent;
    FOnAfterPaint: TJvPagePaintEvent;
    FOnHide: TNotifyEvent;
    FOnShow: TNotifyEvent;
  protected
    {$IFDEF VCL}
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure CreateParams(var Params: TCreateParams); override;
    {$ENDIF VCL}
    {$IFDEF VisualCLX}
    function WidgetFlags: Integer; override;
    {$ENDIF VisualCLX}
    function DoPaintBackground(Canvas: TCanvas; Param: Integer): Boolean; override;
    procedure SetPageIndex(Value: Integer);virtual;
    function GetPageIndex: Integer;virtual;
    procedure SetPageList(Value: TJvCustomPageList);virtual;
    procedure TextChanged; override;
    procedure ShowingChanged; override;
    procedure Paint; override;
    procedure ReadState(Reader: TReader); override;
    function DoBeforePaint(ACanvas: TCanvas; ARect: TRect): Boolean; dynamic;
    procedure DoAfterPaint(ACanvas: TCanvas; ARect: TRect); dynamic;
    procedure DoPaint(ACanvas: TCanvas; ARect: TRect); virtual;
    procedure DoShow; virtual;
    procedure DoHide; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property PageList: TJvCustomPageList read FPageList write SetPageList;
  protected
    property Left stored False;
    property Top stored False;
    property Width stored False;
    property Height stored False;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnBeforePaint: TJvPageCanPaintEvent read FOnBeforePaint write FOnBeforePaint;
    property OnPaint: TJvPagePaintEvent read FOnPaint write FOnPaint;
    property OnAfterPaint: TJvPagePaintEvent read FOnAfterPaint write FOnAfterPaint;
  public
    property PageIndex: Integer read GetPageIndex write SetPageIndex stored False;
  end;

  TJvCustomPageClass = class of TJvCustomPage;
  TJvPageChangingEvent = procedure(Sender: TObject; PageIndex: Integer; var AllowChange: Boolean) of object;

  {
   TJvCustomPageList is a base class for components that implements the IPageList interface.
    It works like TPageControl but does not have any tabs
   }
  TJvShowDesignCaption = (sdcNone, sdcTopLeft, sdcTopCenter, sdcTopRight, sdcLeftCenter, sdcCenter, sdcRightCenter, sdcBottomLeft, sdcBottomCenter, sdcBottomRight, sdcRunTime);
  TJvCustomPageList = class(TJvCustomControl, IUnknown, IPageList)
  private
    FPages: TList;
    FActivePage: TJvCustomPage;
    FPropagateEnable: Boolean;
    FOnChange: TNotifyEvent;
    FOnChanging: TJvPageChangingEvent;
    FShowDesignCaption: TJvShowDesignCaption;
    FHiddenPages:TList;
    {$IFDEF VCL}
    procedure CMDesignHitTest(var Msg: TCMDesignHitTest); message CM_DESIGNHITTEST;
    {$ENDIF VCL}
    procedure UpdateEnabled;
    procedure SetPropagateEnable(const Value: Boolean);
    procedure SetShowDesignCaption(const Value: TJvShowDesignCaption);
    function GetPage(Index: Integer): TJvCustomPage;
  protected
    procedure EnabledChanged; override;
    { IPageList }
    function CanChange(AIndex: Integer): Boolean;virtual;
    function GetActivePageIndex: Integer;virtual;
    procedure SetActivePageIndex(AIndex: Integer);virtual;
    function GetPageFromIndex(AIndex: Integer): TJvCustomPage;virtual;
    function GetPageCount: Integer;virtual;
    function GetPageCaption(AIndex: Integer): string;virtual;
    procedure Paint; override;

    procedure Change; dynamic;
    procedure Loaded; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    procedure ShowControl(AControl: TControl); override;
    function InternalGetPageClass: TJvCustomPageClass; virtual;

    procedure SetActivePage(Page: TJvCustomPage);virtual;
    procedure InsertPage(APage: TJvCustomPage);virtual;
    procedure RemovePage(APage: TJvCustomPage);virtual;
    property PageList: TList read FPages;
    property HiddenPageList:TList read FHiddenPages;
    property PropagateEnable: Boolean read FPropagateEnable write SetPropagateEnable;
    property ShowDesignCaption: TJvShowDesignCaption read FShowDesignCaption write SetShowDesignCaption default sdcCenter;

    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TJvPageChangingEvent read FOnChanging write FOnChanging;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function FindNextPage(CurPage: TJvCustomPage; GoForward: Boolean; IncludeDisabled: Boolean): TJvCustomPage;
    procedure PrevPage;
    procedure NextPage;
    function HidePage(Page:TJvCustomPage):TJvCustomPage; virtual;
    function ShowPage(Page:TJvCustomPage; PageIndex:integer = -1):TJvCustomPage;virtual;
    function GetPageClass: TJvCustomPageClass;
    property Height default 200;
    property Width default 300;

    property ActivePageIndex: Integer read GetActivePageIndex write SetActivePageIndex;
    property ActivePage: TJvCustomPage read FActivePage write SetActivePage;
    property Pages[Index:Integer]:TJvCustomPage read GetPage;default;
    property PageCount: Integer read GetPageCount;
  end;

  TJvStandardPage = class(TJvCustomPage)
  published
    {$IFDEF VCL}
    property BorderWidth;
    {$ENDIF VCL}
    property Caption;
    property Color;
    property DragMode;
    property Enabled;
    property Font;
    property Constraints;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property PageIndex;

    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnHide;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
    property OnShow;
    property OnStartDrag;

    property OnBeforePaint;
    property OnPaint;
    property OnAfterPaint;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnParentColorChange;
    {$IFDEF JVCLThemesEnabled}
    property ParentBackground default True;
    {$ENDIF JVCLThemesEnabled}
  end;

  TJvPageList = class(TJvCustomPageList)
  protected
    function InternalGetPageClass: TJvCustomPageClass; override;
  public
    property PageCount;
  published
    property ActivePage;
    property PropagateEnable;
    property ShowDesignCaption;

    property Action;
    property Align;
    property Anchors;
    {$IFDEF VCL}
    property BiDiMode;
    property BorderWidth;
    property DragCursor;
    property DragKind;
    property OnStartDock;
    property OnUnDock;
    property OnEndDock;
    property OnCanResize;
    property OnDockDrop;
    property OnDockOver;
    property OnGetSiteInfo;
    {$ENDIF VCL}
    property Constraints;
    property DragMode;
    property Enabled;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnMouseEnter;
    property OnMouseLeave;
    property OnParentColorChange;

    property OnChange;
    property OnChanging;
    property OnConstrainedResize;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDrag;
    {$IFDEF JVCLThemesEnabled}
    property ParentBackground default True;
    {$ENDIF JVCLThemesEnabled}
  end;

implementation

{$IFDEF VCL}
uses
  {$IFNDEF COMPILER6_UP}
  JvResources,
  {$ENDIF COMPLER6_UP}
  Forms;
{$ENDIF VCL}
{$IFDEF VisualCLX}
uses
  QForms;
{$ENDIF VisualCLX}

//=== TJvCustomPage ==========================================================

constructor TJvCustomPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPageIndex := -1;
  Align := alClient;
  ControlStyle := ControlStyle + [csOpaque, csAcceptsControls, csNoDesignVisible];
  IncludeThemeStyle(Self, [csParentBackground]);
  Visible := False;
  {$IFDEF VCL}
  DoubleBuffered := True;
  {$ENDIF VCL}
end;

{$IFDEF VCL}
procedure TJvCustomPage.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
    Style := Style and not (CS_HREDRAW or CS_VREDRAW);
end;
{$ENDIF VCL}

destructor TJvCustomPage.Destroy;
begin
  PageList := nil;
  inherited Destroy;
end;

procedure TJvCustomPage.DoAfterPaint(ACanvas: TCanvas; ARect: TRect);
begin
  if Assigned(FOnAfterPaint) then
    FOnAfterPaint(Self, ACanvas, ARect);
end;

function TJvCustomPage.DoBeforePaint(ACanvas: TCanvas; ARect: TRect): Boolean;
begin
  Result := True;
  if Assigned(FonBeforePaint) then
    FOnBeforePaint(Self, ACanvas, ARect, Result);
end;

function GetDesignCaptionFlags(Value: TJvShowDesignCaption): Cardinal;
begin
  case Value of
    sdcTopLeft:
      Result := DT_TOP or DT_LEFT;
    sdcTopCenter:
      Result := DT_TOP or DT_CENTER;
    sdcTopRight:
      Result := DT_TOP or DT_RIGHT;
    sdcLeftCenter:
      Result := DT_VCENTER or DT_LEFT;
    sdcCenter:
      Result := DT_VCENTER or DT_CENTER;
    sdcRightCenter:
      Result := DT_VCENTER or DT_RIGHT;
    sdcBottomLeft:
      Result := DT_BOTTOM or DT_LEFT;
    sdcBottomCenter:
      Result := DT_BOTTOM or DT_CENTER;
    sdcBottomRight:
      Result := DT_BOTTOM or DT_RIGHT;
  else
    Result := 0;
  end;
end;

procedure TJvCustomPage.DoPaint(ACanvas: TCanvas; ARect: TRect);
var
  S: string;
begin
  with ACanvas do
  begin
    Font := Self.Font;
    Brush.Style := bsSolid;
    Brush.Color := Self.Color;
    DrawThemedBackground(Self, Canvas, ARect);
    if (csDesigning in ComponentState) then
    begin
      Pen.Style := psDot;
      Pen.Color := clBlack;
      Brush.Style := bsClear;
      Rectangle(ARect);
      Brush.Style := bsSolid;
      Brush.Color := Color;
      if (PageList <> nil) and (PageList.ShowDesignCaption <> sdcNone) then
      begin
        S := Caption;
        if S = '' then
          S := Name;
        // make some space around the edges
        InflateRect(ARect, -4, -4);
        if not Enabled then
        begin
          {$IFDEF VCL}
          SetBkMode(Handle, Windows.TRANSPARENT);
          {$ENDIF VCL}
          Canvas.Font.Color := clHighlightText;
          {$IFDEF VisualCLX}
          SetPainterFont(Handle, Canvas.Font);
//          SetBkMode(Handle, QWindows.TRANSPARENT);
          {$ENDIF VisualCLX}
          DrawText(Handle, PChar(S), Length(S), ARect, GetDesignCaptionFlags(PageList.ShowDesignCaption) or DT_SINGLELINE);
          OffsetRect(ARect, -1, -1);
          Canvas.Font.Color := clGrayText;
        end;
        {$IFDEF VisualCLX}
        SetPainterFont(Handle, Canvas.Font);
        {$ENDIF VisualCLX}
        DrawText(Handle, PChar(S), Length(S), ARect, GetDesignCaptionFlags(PageList.ShowDesignCaption) or DT_SINGLELINE);
        InflateRect(ARect, 4, 4);
      end;
    end;
  end;
  if Assigned(FOnPaint) then
    FOnPaint(Self, ACanvas, ARect);
end;

function TJvCustomPage.GetPageIndex: Integer;
begin
  if Assigned(FPageList) then
    Result := FPageList.PageList.IndexOf(Self)
  else
    Result := FPageIndex;
end;

procedure TJvCustomPage.Paint;
var
  R: TRect;
begin
  R := ClientRect;
  if DoBeforePaint(Canvas, R) then
    DoPaint(Canvas, R);
  DoAfterPaint(Canvas, R);
end;

procedure TJvCustomPage.ReadState(Reader: TReader);
begin
  if Reader.Parent is TJvCustomPageList then
    PageList := TJvCustomPageList(Reader.Parent);
  inherited ReadState(Reader);
end;

procedure TJvCustomPage.SetPageList(Value: TJvCustomPageList);
begin
  if FPageList <> Value then
  begin
    if Assigned(FPageList) then
      FPageList.RemovePage(Self);
    FPageList := Value;
    Parent := FPageList;
    if FPageList <> nil then
      FPageList.InsertPage(Self);
  end;
end;

procedure TJvCustomPage.SetPageIndex(Value: Integer);
var
  OldIndex: Integer;
begin
  if (Value <> PageIndex) then
  begin
    OldIndex := PageIndex;
    if Assigned(FPageList) and (Value >= 0) and (Value < FPageList.PageCount) then
      FPageList.PageList.Move(OldIndex, Value);
    FPageIndex := Value;
  end;
end;

function TJvCustomPage.DoPaintBackground(Canvas: TCanvas; Param: Integer): Boolean;
begin
  {$IFDEF JVCLThemesEnabled}
  if ThemeServices.ThemesEnabled and ParentBackground then
    DrawThemedBackground(Self, Canvas.Handle, ClientRect, Parent.Brush.Handle);
  {$ENDIF JVCLThemesEnabled}
  Result := True;
end;

procedure TJvCustomPage.TextChanged;
begin
  inherited TextChanged;
  if csDesigning in ComponentState then
    Invalidate;
end;

procedure TJvCustomPage.DoHide;
begin
  if Assigned(FOnHide) then
    FOnHide(Self);
end;

procedure TJvCustomPage.DoShow;
begin
  if Assigned(FOnShow) then
    FOnShow(Self);
end;

procedure TJvCustomPage.ShowingChanged;
begin
  inherited ShowingChanged;
  if Showing then
    try
      DoShow
    except
      Application.HandleException(Self);
    end
  else
  if not Showing then
    try
      DoHide;
    except
      Application.HandleException(Self);
    end;
end;

{$IFDEF VCL}
procedure TJvCustomPage.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;
{$ENDIF VCL}

{$IFDEF VisualCLX}
function TJvCustomPage.WidgetFlags: Integer;
begin
  Result := inherited WidgetFlags or Integer(WidgetFlags_WRepaintNoErase);
end;
{$ENDIF VisualCLX}

//=== TJvCustomPageList ======================================================

constructor TJvCustomPageList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csAcceptsControls];
  IncludeThemeStyle(Self, [csParentBackground]);
  FPages := TList.Create;
  FHiddenPages := TList.Create;
  Height := 200;
  Width := 300;
  FShowDesignCaption := sdcCenter;
  ActivePageIndex := -1;
end;

destructor TJvCustomPageList.Destroy;
var
  I: Integer;
begin
  for I := FPages.Count - 1 downto 0 do
    TJvCustomPage(FPages[I]).FPageList := nil;
  FPages.Free;
  FHiddenPages.Free;
  inherited Destroy;
end;

function TJvCustomPageList.CanChange(AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < GetPageCount);
  if Result and Assigned(FOnChanging) then
    FOnChanging(Self, AIndex, Result);
end;

procedure TJvCustomPageList.Change;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{$IFDEF VCL}
procedure TJvCustomPageList.CMDesignHitTest(var Msg: TCMDesignHitTest);
var
  Pt: TPoint;
begin
  inherited;
  Pt := SmallPointToPoint(Msg.Pos);
  if Assigned(ActivePage) and PtInRect(ActivePage.BoundsRect, Pt) then
    Msg.Result := 1;
end;
{$ENDIF VCL}

procedure TJvCustomPageList.GetChildren(Proc: TGetChildProc;
  Root: TComponent);
var
  I: Integer;
  Control: TControl;
begin
  for I := 0 to FPages.Count - 1 do
    Proc(TComponent(FPages[I]));
  for I := 0 to ControlCount - 1 do
  begin
    Control := Controls[I];
    if not (Control is TJvCustomPage) and (Control.Owner = Root) then
      Proc(Control);
  end;
end;

function TJvCustomPageList.GetPageCaption(AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < GetPageCount) then
    Result := TJvCustomPage(FPages[AIndex]).Caption
  else
    Result := '';
end;

function TJvCustomPageList.InternalGetPageClass: TJvCustomPageClass;
begin
  Result := TJvCustomPage;
end;

function TJvCustomPageList.GetPageCount: Integer;
begin
  if FPages = nil then
    Result := 0
  else
    Result := FPages.Count;
end;

procedure TJvCustomPageList.InsertPage(APage: TJvCustomPage);
begin
  if (APage <> nil) and (FPages.IndexOf(APage) = -1) then
    FPages.Add(APage);
end;

procedure TJvCustomPageList.Loaded;
begin
  inherited Loaded;
  if GetPageCount > 0 then
    ActivePage := Pages[0];
end;

procedure TJvCustomPageList.Paint;
begin
  if (csDesigning in ComponentState) and (GetPageCount = 0) then
    with Canvas do
    begin
      Pen.Color := clBlack;
      Pen.Style := psDot;
      Brush.Style := bsClear;
      Rectangle(ClientRect);
    end;
end;

procedure TJvCustomPageList.RemovePage(APage: TJvCustomPage);
var
  I: Integer;
  NextPage: TJvCustomPage;
begin
  NextPage := FindNextPage(APage, True, not (csDesigning in ComponentState));
  if NextPage = APage then
    NextPage := nil;
  APage.Visible := False;
  APage.FPageList := nil;
  FPages.Remove(APage);
  SetActivePage(NextPage);
 // (ahuser) In some cases SetActivePage does not change FActivePage
 //          so we force FActivePage not to be "APage"
  if (FActivePage = APage) or (FActivePage = nil) then
  begin
    FActivePage := nil;
    for I := 0 to PageCount - 1 do
      if Pages[I] <> APage then
      begin
        FActivePage := Pages[I];
        Break;
      end;
  end;
end;

function TJvCustomPageList.GetPageFromIndex(AIndex: Integer): TJvCustomPage;
begin
  if (AIndex >= 0) and (AIndex < GetPageCount) then
    Result := TJvCustomPage(Pages[AIndex])
  else
    Result := nil;
end;

procedure TJvCustomPageList.SetActivePageIndex(AIndex: Integer);
begin
  if (AIndex > -1) and (AIndex < PageCount) then
    ActivePage := Pages[AIndex]
  else
    ActivePage := nil;
end;

procedure TJvCustomPageList.ShowControl(AControl: TControl);
begin
  if AControl is TJvCustomPage then
    ActivePage := TJvCustomPage(AControl);
  inherited ShowControl(AControl);
end;

function TJvCustomPageList.GetPageClass: TJvCustomPageClass;
begin
  Result := InternalGetPageClass;
end;

function TJvCustomPageList.HidePage(Page: TJvCustomPage): TJvCustomPage;
var I:Integer;
begin
  if (Page <> nil) and (Page.PageList = Self) then
  begin
    if ActivePage = Page then
      NextPage;
    if ActivePage = Page then
      ActivePage := nil;
    I := Page.PageIndex;
    Page.PageList := nil;
    Page.PageIndex := I;
    Result := Page;
    FHiddenPages.Add(Result);
  end
  else
    Result := nil;
end;

function TJvCustomPageList.ShowPage(Page: TJvCustomPage; PageIndex: integer): TJvCustomPage;
var I:Integer;
begin
  if (Page <> nil) and (Page.PageList = nil) then
  begin
    I := Page.PageIndex;
    Page.PageList := Self;
    Page.Parent := Self;
    if PageIndex > -1 then
      Page.PageIndex := PageIndex
    else if I > -1 then
      Page.PageIndex := I;
    Result := Page;
    FHiddenPages.Remove(Result);
  end
  else
    Result := nil;
end;

procedure TJvCustomPageList.SetActivePage(Page: TJvCustomPage);
var
  ParentForm: TCustomForm;
begin
  if (csLoading in ComponentState) or ((Page <> nil) and (Page.PageList <> Self)) then
    Exit;
  if FActivePage <> Page then
  begin
    ParentForm := GetParentForm(Self);
    if (ParentForm <> nil) and (FActivePage <> nil) and
      FActivePage.ContainsControl(ParentForm.ActiveControl) then
    begin
      ParentForm.ActiveControl := FActivePage;
      if ParentForm.ActiveControl <> FActivePage then
      begin
        ActivePage := GetPageFromIndex(FActivePage.PageIndex);
        Exit;
      end;
    end;
    if Page <> nil then
    begin
      Page.BringToFront;
      Page.Visible := True;
      if (ParentForm <> nil) and (FActivePage <> nil) and (ParentForm.ActiveControl = FActivePage) then
      begin
        if Page.CanFocus then
          ParentForm.ActiveControl := Page
        else
          ParentForm.ActiveControl := Self;
      end;
      Page.Refresh;
    end;

    if (Page = nil) or CanChange(FPages.IndexOf(Page)) then
    begin
      if FActivePage <> nil then
        FActivePage.Visible := False;
      FActivePage := Page;
      Change;
      if (ParentForm <> nil) and (FActivePage <> nil) and
        (ParentForm.ActiveControl = FActivePage) then
      begin
        FActivePage.SelectFirst;
      end;
    end;
  end;
end;

function TJvCustomPageList.GetActivePageIndex: Integer;
begin
  if ACtivePage <> nil then
    Result := ActivePage.PageIndex
  else
    Result := -1;
end;

procedure TJvCustomPageList.NextPage;
begin
  if (ActivePageIndex < PageCount - 1) and (PageCount > 1) then
    ActivePageIndex := ActivePageIndex + 1
  else
  if PageCount > 0 then
    ActivePageIndex := 0
  else
    ActivePageIndex := -1;
end;

procedure TJvCustomPageList.PrevPage;
begin
  if ActivePageIndex > 0 then
    ActivePageIndex := ActivePageIndex - 1
  else
    ActivePageIndex := PageCount - 1;
end;

procedure TJvCustomPageList.SetPropagateEnable(const Value: Boolean);
begin
  if FPropagateEnable <> Value then
  begin
    FPropagateEnable := Value;
    UpdateEnabled;
  end;
end;

procedure TJvCustomPageList.EnabledChanged;
begin
  inherited EnabledChanged;
  UpdateEnabled;
end;

function TJvCustomPageList.FindNextPage(CurPage: TJvCustomPage;
  GoForward, IncludeDisabled: Boolean): TJvCustomPage;
var
  I, StartIndex: Integer;
begin
  if PageCount <> 0 then
  begin
    StartIndex := FPages.IndexOf(CurPage);
    if StartIndex < 0 then
      if GoForward then
        StartIndex := FPages.Count - 1
      else
        StartIndex := 0;
    I := StartIndex;
    repeat
      if GoForward then
      begin
        Inc(I);
        if I >= FPages.Count - 1 then
          I := 0;
      end
      else
      begin
        if I <= 0 then
          I := FPages.Count - 1;
        Dec(I);
      end;
      Result := Pages[I];
      if IncludeDisabled or Result.Enabled then
        Exit;
    until I = StartIndex;
  end;
  Result := nil;
end;

procedure TJvCustomPageList.SetShowDesignCaption(const Value: TJvShowDesignCaption);
begin
  if FShowDesignCaption <> Value then
  begin
    FShowDesignCaption := Value;
    if HandleAllocated and (csDesigning in ComponentState) then
      {$IFDEF VCL}
      RedrawWindow(Handle, nil, 0, RDW_UPDATENOW or RDW_INVALIDATE or RDW_ALLCHILDREN);
      {$ENDIF VCL}
      {$IFDEF VisualCLX}
      Invalidate;
      {$ENDIF VisualCLX}
  end;
end;

procedure TJvCustomPageList.UpdateEnabled;

  procedure InternalSetEnabled(AControl: TWinControl);
  var
    I: Integer;
  begin
    for I := 0 to AControl.ControlCount - 1 do
    begin
      AControl.Controls[I].Enabled := Self.Enabled;
      if AControl.Controls[I] is TWinControl then
        InternalSetEnabled(TWinControl(AControl.Controls[I]));
    end;
  end;

begin
  if PropagateEnable then
    InternalSetEnabled(Self);
end;

function TJvCustomPageList.GetPage(Index: Integer): TJvCustomPage;
begin
  if (Index >= 0) and (Index < FPages.Count) then
    Result := FPages[Index]
  else
    Result := nil;
end;

//===TJvPageList =============================================================

function TJvPageList.InternalGetPageClass: TJvCustomPageClass;
begin
  Result := TJvStandardPage;
end;

end.
