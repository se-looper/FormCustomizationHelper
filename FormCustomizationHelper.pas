unit FormCustomizationHelper;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes,
  FMX.Types, FMX.Forms, FMX.Graphics, FMX.Controls, FMX.Platform;

type
  TFormCustomizationHelper = class
  private type
    TSelectState = (sNone, sSizingN, sSizingS, sSizingE, sSizingW,
        sSizingNW, sSizingNE, sSizingSW, sSizingSE);
  private
    FTargetForm: TForm;
    FWinService: IFMXWindowService;

    FTargetKeyDown: TKeyEvent;
    FTargetKeyUp: TKeyEvent;
    FTargetMouseDown: TMouseEvent;
    FTargetMouseUp: TMouseEvent;
    FTargetMouseMove: TMouseMoveEvent;
    FTargetPaint: TOnPaintEvent;
    FTargetResize: TNotifyEvent;
    property TargetKeyDown: TKeyEvent read FTargetKeyDown write FTargetKeyDown;
    property TargetKeyUp: TKeyEvent read FTargetKeyUp write FTargetKeyUp;
    property TargetMouseDown: TMouseEvent read FTargetMouseDown write FTargetMouseDown;
    property TargetMouseUp: TMouseEvent read FTargetMouseUp write FTargetMouseUp;
    property TargetMouseMove: TMouseMoveEvent read FTargetMouseMove write FTargetMouseMove;
    property TargetPaint: TOnPaintEvent read FTargetPaint write FTargetPaint;
    property TargetResize: TNotifyEvent read FTargetResize write FTargetResize;
  private
    procedure KeyDown(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure KeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure Paint(Sender: TObject; Canvas: TCanvas; const ARect: TRectF);
    procedure Resize(Sender: TObject);
  private
    FTitleBarRect: TRectF;
    FCloseButtonRect: TRectF;
    FMinimizedButtonRect: TRectF;
    FOptionsButtonRect: TRectF;
    FMessageButtonRect: TRectF;
    FLogoButtonRect: TRectF;
    procedure DoLogoButtonClick;
    procedure DoMessageButtonClick;
    procedure DoOptionsButtonClick;
    procedure DoMinimizedButtonClick;
    procedure DoCloseButtonClick;
  private
    FSelectState: TSelectState;
    procedure ControlSizedN(const X, Y: Single);
    procedure ControlSizedS(const X, Y: Single);
    procedure ControlSizedE(const X, Y: Single);
    procedure ControlSizedW(const X, Y: Single);
    procedure ControlSizedNW(const X, Y: Single);
    procedure ControlSizedNE(const X, Y: Single);
    procedure ControlSizedSW(const X, Y: Single);
    procedure ControlSizedSE(const X, Y: Single);

    function GetSelectStateByMouseDown(const X, Y: Single): TSelectState;
    function GetCursorByMouseMove(const X, Y: Single): TCursor;
  public
    constructor Create(const AForm: TForm);
    destructor Destroy; override;
  end;

implementation

var
  DownXPos, DownYPos, DownL, DownT: Single;
  DownW, DownH: Integer;

{ TFormCustomizationHelper }

constructor TFormCustomizationHelper.Create(const AForm: TForm);
begin
  Assert(AForm <> nil);
  FTargetForm:= AForm;
  FTargetForm.BorderStyle:= TFmxFormBorderStyle.None;
  //接管相关事件
  Self.TargetKeyDown   := FTargetForm.OnKeyDown;
  Self.TargetKeyUp     := FTargetForm.OnKeyUp;
  Self.TargetMouseDown := FTargetForm.OnMouseDown;
  Self.TargetMouseUp   := FTargetForm.OnMouseUp;
  Self.TargetMouseMove := FTargetForm.OnMouseMove;
  Self.TargetPaint     := FTargetForm.OnPaint;
  Self.TargetResize    := FTargetForm.OnResize;

  FTargetForm.OnMouseDown := MouseDown;
  FTargetForm.OnMouseUp   := MouseUp;
  FTargetForm.OnMouseMove := MouseMove;
  FTargetForm.OnKeyDown   := KeyDown;
  FTargetForm.OnKeyUp     := KeyUp;
  FTargetForm.OnPaint := Paint;
  FTargetForm.OnResize:= Resize;

  TPlatformServices.Current.SupportsPlatformService(IFMXWindowService, FWinService);
end;

destructor TFormCustomizationHelper.Destroy;
begin
  FTargetForm.OnKeyDown   := Self.TargetKeyDown;
  FTargetForm.OnKeyUp     := Self.TargetKeyUp;
  FTargetForm.OnMouseDown := Self.TargetMouseDown;
  FTargetForm.OnMouseUp   := Self.TargetMouseUp;
  FTargetForm.OnMouseMove := Self.TargetMouseMove;
  FTargetForm.OnPaint     := Self.TargetPaint;
  FTargetForm.OnResize    := Self.TargetResize;
  inherited;
end;

procedure TFormCustomizationHelper.KeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Assigned(FTargetKeyDown) then
    FTargetKeyDown(Sender, Key, KeyChar, Shift);
  //按ESC退出全屏
  if (Key = 27) and FTargetForm.FullScreen then
    FTargetForm.FullScreen:= False;
end;

procedure TFormCustomizationHelper.KeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Assigned(FTargetKeyUp) then
    FTargetKeyUp(Sender, Key, KeyChar, Shift);
end;

procedure TFormCustomizationHelper.MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Assigned(FTargetMouseDown) then
    FTargetMouseDown(Sender, Button, Shift, X, Y);
  //
  DownXPos:= X;
  DownYPos:= Y;
  DownW:= FTargetForm.Width;
  DownH:= FTargetForm.Height;
  DownL:= FTargetForm.Bounds.Left;
  DownT:= FTargetForm.Bounds.Top;
  FSelectState:= GetSelectStateByMouseDown(X, Y);
  if FSelectState <> TSelectState.sNone then
    Exit;
  //
  if FLogoButtonRect.Contains(PointF(X, Y)) then
  begin
    DoLogoButtonClick;
    Exit;
  end;
  if FMessageButtonRect.Contains(PointF(X, Y)) then
  begin
    DoMessageButtonClick;
    Exit;
  end;
  if FOptionsButtonRect.Contains(PointF(X, Y)) then
  begin
    DoOptionsButtonClick;
    Exit;
  end;
  if FMinimizedButtonRect.Contains(PointF(X, Y)) then
  begin
    DoMinimizedButtonClick;
    Exit;
  end;
  if FCloseButtonRect.Contains(PointF(X, Y)) then
  begin
    DoCloseButtonClick;
    Exit;
  end;
  //
  if FTitleBarRect.Contains(PointF(X, Y)) then
  begin
    FTargetForm.StartWindowDrag;
    Exit;
  end;
end;

procedure TFormCustomizationHelper.MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Single);
begin
  if Assigned(FTargetMouseMove) then
    FTargetMouseMove(Sender, Shift, X, Y);
  //
  FTargetForm.Cursor:= GetCursorByMouseMove(X, Y);
  if Shift = [ssLeft] then
  begin
    FWinService.SetCapture(FTargetForm);
    case FSelectState of
      sSizingN:  ControlSizedN(X, Y);
      sSizingS:  ControlSizedS(X, Y);
      sSizingE:  ControlSizedE(X, Y);
      sSizingW:  ControlSizedW(X, Y);
      sSizingNW: ControlSizedNW(X, Y);
      sSizingNE: ControlSizedNE(X, Y);
      sSizingSW: ControlSizedSW(X, Y);
      sSizingSE: ControlSizedSE(X, Y);
    end;
  end;
end;

procedure TFormCustomizationHelper.MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if Assigned(FTargetMouseUp) then
    FTargetMouseUp(Sender, Button, Shift, X, Y);
  //
  FSelectState:= sNone;
  FTargetForm.Cursor:= crDefault;
end;

procedure TFormCustomizationHelper.Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if Assigned(FTargetPaint) then
    FTargetPaint(Sender, Canvas, ARect);
  //
  if not FTargetForm.FullScreen then
  begin
    Canvas.Stroke.Kind:= TBrushKind.Gradient;
    Canvas.Stroke.Gradient.Color:= TAlphaColorRec.Indianred;
    Canvas.Stroke.Gradient.Color1:= TAlphaColorRec.Black;
    Canvas.Stroke.Thickness:= 12;
    Canvas.DrawRect(RectF(0, 0, FTargetForm.ClientWidth, FTargetForm.ClientHeight), 0, 0, [], 1.0);
    //
    Canvas.Fill.Kind:= TBrushKind.Gradient;
    Canvas.Fill.Gradient.Color:= TAlphaColorRec.Black;
    Canvas.Fill.Gradient.Color1:= TAlphaColorRec.Indianred;
    Canvas.FillRect(FTitleBarRect, 0, 0, AllCorners, 1.0);
    //
    Canvas.Fill.Kind:= TBrushKind.Solid;
    Canvas.Fill.Color:= TAlphaColorRec.Blue;
    Canvas.FillRect(FLogoButtonRect, 25, 25, AllCorners, 1.0);

    Canvas.Fill.Color:= TAlphaColorRec.Indianred;
    Canvas.FillRect(FCloseButtonRect, 5, 5, AllCorners, 1.0);

    Canvas.Fill.Color:= TAlphaColorRec.Cornflowerblue;
    Canvas.FillRect(FMinimizedButtonRect, 5, 5, AllCorners, 1.0);

    Canvas.Fill.Color:= TAlphaColorRec.Lightslategray;
    Canvas.FillRect(FOptionsButtonRect, 5, 5, AllCorners, 1.0);

    Canvas.Fill.Color:= TAlphaColorRec.Lightslategray;
    Canvas.FillRect(FMessageButtonRect, 5, 5, AllCorners, 1.0);
  end;
end;

procedure TFormCustomizationHelper.Resize(Sender: TObject);
begin
  FTitleBarRect:= RectF(0, 0, FTargetForm.ClientWidth, 32);
  FCloseButtonRect:= Rect(FTargetForm.ClientWidth-45, 4, FTargetForm.ClientWidth-3, 28);
  FMinimizedButtonRect:= Rect(FTargetForm.ClientWidth-90, 4, FTargetForm.ClientWidth-48, 28);
  FOptionsButtonRect:= Rect(FTargetForm.ClientWidth-137, 4, FTargetForm.ClientWidth-95, 28);
  FMessageButtonRect:= Rect(FTargetForm.ClientWidth-182, 4, FTargetForm.ClientWidth-140, 28);
  FLogoButtonRect:= Rect(0, 0, 40, 28);
end;

function TFormCustomizationHelper.GetCursorByMouseMove(const X,
  Y: Single): TCursor;
var
  L, T, W, H: Single;
begin
  Result:= crDefault;
  L:= 0;
  T:= 0;
  W:= FTargetForm.ClientWidth;
  H:= FTargetForm.ClientHeight;
  //
  if (X >= L) and (X < (L + 6)) and (Y >= T) and (Y < (T + 6) ) or
     (X >= L + W - 6) and (X < (L + W)) and (Y >= T + H - 6) and (Y < (T + H)) then
    Result:= crSizeNWSE  //右下resize
  else
  if (X >= L) and (X < (L + 6)) and (Y >= T + H - 6) and (Y < (T + H)) or
     (X >= L + W - 6) and (X < (L + W)) and (Y >= T) and (Y < (T + 6)) then
    Result:= crSizeNESW  //左下resize
  else
  if (X >= L + 6) and (X < L + W - 6) and (Y >= T) and (Y < T + 6) or
     (X >= L + 6) and (X < L + W - 6) and (Y >= T + H - 6) and (Y < T + H) then
    Result:= crSizeNS    //上下resize
  else
  if (X >= L) and (X < L + 6) and (Y >= T + 6) and (Y < T + H - 6) or
     (X >= L + W - 6) and (X < L + W) and (Y >= T + 6) and (Y < T + H - 6) then
    Result:= crSizeWE    //左右resize
end;


function TFormCustomizationHelper.GetSelectStateByMouseDown(const X,
  Y: Single): TSelectState;
var
  L, T, W, H: Single;
begin
  Result:= sNone;
  L:= 0;
  T:= 0;
  W:= FTargetForm.ClientWidth;
  H:= FTargetForm.ClientHeight;
  //
  if (X >= L) and (X < (L + 6)) and (Y >= T) and (Y < (T + 6)) then
    Result:= sSizingNW;

  if (X >= L + W - 6) and (X < (L + W)) and (Y >= T + H - 6) and (Y < (T + H)) then
    Result:= sSizingSE;

  if (X >= L) and (X < (L + 6)) and (Y >= T + H - 6) and (Y < (T + H)) then
    Result:= sSizingSW;

  if (X >= L + W - 6) and (X < (L + W)) and (Y >= T) and (Y < (T + 6)) then
    Result:= sSizingNE;

  if (X >= L + 6) and (X < L + W - 6) and (Y >= T) and (Y < T + 6) then
    Result:= sSizingN;

  if (X >= L + 6) and (X < L + W - 6) and (Y >= T + H - 6) and (Y < T + H) then
    Result:= sSizingS;

  if (X >= L) and (X < L + 6) and (Y >= T + 6) and (Y < T + H - 6) then
    Result:= sSizingW;

  if (X >= L + W - 6) and (X < L + W) and (Y >= T + 6) and (Y < T + H - 6) then
    Result := sSizingE;
end;

procedure TFormCustomizationHelper.ControlSizedE(const X, Y: Single);
begin
  FTargetForm.Width:= DownW + Round(X - DownXPos);
end;

procedure TFormCustomizationHelper.ControlSizedN(const X, Y: Single);
var
  LBounds: TRect;
begin
  LBounds:= FTargetForm.Bounds;
  LBounds.Top:= Round(DownT + (Y - DownYPos));
  FTargetForm.Bounds:= LBounds;
  DownT:= LBounds.Top;
end;

procedure TFormCustomizationHelper.ControlSizedNE(const X, Y: Single);
var
  LBounds: TRect;
begin
  LBounds:= FTargetForm.Bounds;
  LBounds.Top:= Round(DownT + (Y - DownYPos));
  LBounds.Width:= DownW + Round(X - DownXPos);
  FTargetForm.Bounds:= LBounds;
  DownT:= LBounds.Top;
end;

procedure TFormCustomizationHelper.ControlSizedNW(const X, Y: Single);
var
  LBounds: TRect;
begin
  LBounds:= FTargetForm.Bounds;
  LBounds.Left:= Round(DownL + X - DownXPos);
  LBounds.Top:= Round(DownT + (Y - DownYPos));
  FTargetForm.Bounds:= LBounds;
  DownL:= LBounds.Left;
  DownT:= LBounds.Top;
end;

procedure TFormCustomizationHelper.ControlSizedS(const X, Y: Single);
begin
  FTargetForm.Height:= DownH + Round(Y - DownYPos);
end;

procedure TFormCustomizationHelper.ControlSizedSE(const X, Y: Single);
begin
  FTargetForm.Width:= DownW + Round(X - DownXPos);
  FTargetForm.Height:= DownH + Round(Y - DownYPos);
end;

procedure TFormCustomizationHelper.ControlSizedSW(const X, Y: Single);
var
  LBounds: TRect;
begin
  LBounds:= FTargetForm.Bounds;
  LBounds.Left:= Round(DownL + X - DownXPos);
  LBounds.Height:= DownH + Round(Y - DownYPos);
  FTargetForm.Bounds:= LBounds;
  DownL:= FTargetForm.Bounds.Left;
end;

procedure TFormCustomizationHelper.ControlSizedW(const X, Y: Single);
var
  LBounds: TRect;
begin
  LBounds:= FTargetForm.Bounds;
  LBounds.Left:= Round(DownL + X - DownXPos);
  FTargetForm.Bounds:= LBounds;
  DownL:= FTargetForm.Bounds.Left;
end;

procedure TFormCustomizationHelper.DoLogoButtonClick;
begin
  //showmessage('logo');
end;

procedure TFormCustomizationHelper.DoMessageButtonClick;
begin
  //showmessage('message');
end;

procedure TFormCustomizationHelper.DoMinimizedButtonClick;
begin
  FTargetForm.WindowState:= TWindowState.wsMinimized;
end;

procedure TFormCustomizationHelper.DoOptionsButtonClick;
begin
  FTargetForm.FullScreen:= True;
end;

procedure TFormCustomizationHelper.DoCloseButtonClick;
begin
  FTargetForm.Close;
end;

end.
