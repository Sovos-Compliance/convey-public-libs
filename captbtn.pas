{*************************************************************}
{            TCaptionButton Components for Delphi 16/32       }
{ Version:   1.01                                             }
{ Author:    Aleksey Kuznetsov, Kiev, Ukraine                 }
{            Алексей Кузнецов (Xacker), Киев, Украина         }
{ E-Mail:    xacker@phreaker.net                              }
{ Homepage:  http://www.angen.net/~xacker/                    }
{ Created:   March, 3, 1999                                   }
{ Modified:  March, 12, 1999                                  }
{ Legal:     Copyright (c) 1999 by Aleksey Xacker             }
{*************************************************************}
{   TCaptionButton (English):                                 }
{ Additional button on form's title.                          }
{*************************************************************}
{   TCaptionButton (Russian):                                 }
{ Дополнительная кнопка на заголовке окна.                    }
{*************************************************************}
{ If at occurrence of any questions concerning these          }
{ components, mail me: xacker@phreaker.net.                   }
{ For updated versions visit my H-page: www.angen.net/~xacker }
{*************************************************************}
unit CaptBtn;

interface

uses
  {$IfDef Win32} Windows, {$Else} WinTypes, WinProcs, {$EndIf}
  Classes, Controls, Forms, Messages, Graphics;

type
  TCaptionButton = class(TComponent)
  private
    Canvas: TCanvas;
    ParentForm: TForm;
    PrevParentWndProc: Pointer;
    FRightMargin: Integer;
    FGlyph: TBitmap;
    FVisible: Boolean;
    FChecked: Boolean;
    FSysMenu: string; //AGA 7/19/99
    ButtonRect: TRect;
    FOnClick: TNotifyEvent;
    FDown, FButtonDown: Boolean;
    SeekAndDestroy: Boolean;
//AGA 7/19/99    CtrlMsg: Word;

    procedure NewParentWndProc(var Msg: TMessage);
    procedure SetRightMargin(Value: Integer);
    procedure SetGlyph(Value: TBitmap);
    procedure SetVisible(Value: Boolean);
//AGA -- Begin 7/19/99
    procedure SetItem(ASysMenu : string; AChecked, AVisible : boolean);
    procedure SetChecked(Value: Boolean);
    procedure SetSysMenu(Value: string);
//AGA -- End
    procedure PaintCaption(Down: Boolean);
  protected
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Glyph: TBitmap read FGlyph write SetGlyph;
    property RightMargin: Integer read FRightMargin write SetRightMargin;
    property Visible: Boolean read FVisible write SetVisible;
//AGA -- Begin 7/19/99
    property Checked: Boolean read FChecked write SetChecked;
    property SysMenu: string read FSysMenu write SetSysMenu;
//AGA -- End

    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

procedure Register;

implementation

const
  OwnMessage = 7777;

constructor TCaptionButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  SeekAndDestroy := false; //AGA 7/19/99
  ParentForm := TForm(aOwner);
  FGlyph := TBitmap.Create;
  Canvas := TCanvas.Create;
  FVisible := false;
{AGA  7/19/99
  CtrlMsg := NotUsedCtrlMsg;
  inc(NotUsedCtrlMsg);
}
end;

destructor TCaptionButton.Destroy;
begin
  if not SeekAndDestroy {ParentForm.HandleAllocated} then
//AGA 7/19/99    begin
      Visible := False;
{AGA 7/19/99
      SetWindowLong(ParentForm.Handle, GWL_WNDPROC, LongInt(PrevParentWndProc));
     end;
}
  Canvas.Free;
  FGlyph.Free;
  inherited Destroy;
end;

procedure TCaptionButton.NewParentWndProc(var Msg: TMessage);
var
  Pnt: TPoint;
begin
  with Msg do
   begin
    Result := CallWindowProc(PrevParentWndProc, ParentForm.Handle, Msg,
                             WParam, LParam);
    if FVisible then
     if (Msg = wm_NCPaint) or
        (Msg = wm_NCActivate) then PaintCaption(False)
     else
      if Msg = wm_NCHitTest then
       if Result = htCaption then
        begin
         Pnt.x := LoWord(lParam);
         ScreenToClient(ParentForm.Handle, Pnt);
         if (Pnt.x > ButtonRect.Left) and (Pnt.x < ButtonRect.Right) then
          begin
           if not FDown and FButtonDown then PaintCaption(True);
           Result := OwnMessage //AGA 7/19/99 CtrlMsg
          end
         else
          if FDown then PaintCaption(False);
        end
       else if FDown then PaintCaption(False) else
      else
       if (Msg = wm_NCLButtonDown) or (Msg = wm_NCLButtonDblClk) then
        if wParam = OwnMessage then //AGA 7/19/99 CtrlMsg then
         begin
          if not FDown then PaintCaption(True);
          if not FButtonDown then
           begin
            FButtonDown := True;
            SetCapture(ParentForm.Handle);
           end;
         end
        else
         begin
          if FDown then PaintCaption(False);
          if FButtonDown then
           begin
            FButtonDown := False;
            ReleaseCapture;
           end;
         end
       else
        if (Msg = wm_NCLButtonUp) or (Msg = wm_LButtonUp) then
         begin
          if FButtonDown then
           begin
            FButtonDown := False;
            ReleaseCapture;
            if FDown and Assigned(FOnClick) then
             FOnClick(Self);
           end;
          if FDown then PaintCaption(False);
         end
        else
         if (Msg = wm_Close) or (Msg = wm_Destroy) then
          SeekAndDestroy := True
//AGA -- Begin 7/19/99
         else
           if (Msg = WM_SYSCOMMAND) then
            if (OwnMessage = wParam) and Assigned(FOnClick) then
             FOnClick(Self);
//AGA -- End
   end;
end;

procedure TCaptionButton.PaintCaption(Down: Boolean);
var
  DC: hDC;
  R: TRect;
  Image: TBitmap;
  LeftX, x, y, FrameY: Integer;
  Shift: Byte;

  procedure DrawUpFrame;
  begin
    with Canvas do
     begin
      Pen.Color := clBtnHighlight;
      MoveTo(LeftX, FrameY + y + 1);
      LineTo(LeftX, FrameY);
      LineTo(LeftX + x + 3, FrameY);
      Pen.Color := clBlack;
      MoveTo(LeftX, FrameY + y + 2);
      LineTo(LeftX + x + 2, FrameY + y + 2);
      LineTo(LeftX + x + 2, FrameY - 1);
      Pen.Color := clGray;
      MoveTo(LeftX + x + 1, FrameY + 1);
      LineTo(LeftX + x + 1, FrameY + y + 1);
      LineTo(LeftX, FrameY + y + 1);
      Shift := 1;
     end;
  end;

  procedure DrawDownFrame;
  begin
    with Canvas do
     begin
      Pen.Color := clBlack;
      MoveTo(LeftX, FrameY + y + 1);
      LineTo(LeftX, FrameY);
      LineTo(LeftX + x + 3, FrameY);
      Pen.Color := clWhite;
      MoveTo(LeftX, FrameY + y + 2);
      LineTo(LeftX + x + 2, FrameY + y + 2);
      LineTo(LeftX + x + 2, FrameY - 1);
      Pen.Color := clGray;
      MoveTo(LeftX + x, FrameY + 1);
      LineTo(LeftX + 1, FrameY + 1);
      LineTo(LeftX + 1, FrameY + y + 1);
      Pen.Color := clSilver;
      MoveTo(LeftX + x + 1, FrameY + 1);
      LineTo(LeftX + x + 1, FrameY + y + 1);
      LineTo(LeftX, FrameY + y + 1);
      Shift := 2;
     end;
  end;

begin
  DC := 0;
  FDown := Down;
  if FVisible then
   try
    DC := GetWindowDC(ParentForm.Handle);
    Canvas.Handle := DC;
    Image := TBitmap.Create;
    GetWindowRect(ParentForm.Handle, R);
    R.Right := R.Right - R.Left;

    if ParentForm.BorderStyle = bsSingle then
     {$IFDEF WIN32}
     FrameY := GetSystemMetrics(sm_cyFrame) + 1
     {$ELSE}
     FrameY := GetSystemMetrics(sm_cyBorder) + 2
     {$ENDIF}
    else
     if ParentForm.BorderStyle = bsDialog then
      FrameY := GetSystemMetrics(sm_cyBorder) + 4
     else
      {$IFDEF WIN32}
      if ParentForm.BorderStyle = bsSizeToolWin then
       FrameY := GetSystemMetrics(sm_cySizeFrame) + 2
      else
       if ParentForm.BorderStyle = bsToolWindow then
        FrameY := GetSystemMetrics(sm_cyBorder) + 4
       else
       {$ENDIF}
        FrameY := GetSystemMetrics(sm_cyFrame) + 2;

    LeftX := R.Right - RightMargin - FrameY;
    {$IFDEF WIN32}
    if (ParentForm.BorderStyle = bsSizeToolWin) or
       (ParentForm.BorderStyle = bsToolWindow) then
     begin
      y := GetSystemMetrics(sm_cySMCaption) - 8;
      x := GetSystemMetrics(sm_cxSMSize) - 5;
     end
    else
     begin
      y := GetSystemMetrics(sm_cyCaption) - 8;
      x := GetSystemMetrics(sm_cxSize) - 5;
     end;
    {$ELSE}
    y := GetSystemMetrics(sm_cyCaption) - 9;
    x := GetSystemMetrics(sm_cxSize) - 5;
    {$ENDIF}
    with ButtonRect do
     begin
      Left := LeftX - FrameY;
      Top := FrameY;
      Right := Left + x + 3;
      Bottom := y + 2;
     end;
    if Down then DrawDownFrame
    else DrawUpFrame;
    StretchBlt(DC, LeftX + Shift,
               FrameY + Shift,
               x, y,
               FGlyph.Canvas.Handle, 0, 0,
               FGlyph.Width, FGlyph.Height,
               srcCopy);
    Image.Free;
   finally
    ReleaseDC(ParentForm.Handle, DC);
   end;
end;

procedure TCaptionButton.SetRightMargin(Value: Integer);
begin
  if FRightMargin <> Value then
   begin
    FRightMargin := Value;
    SendMessage(ParentForm.Handle, wm_NCActivate, 0, 0);
   end;
end;

procedure TCaptionButton.SetGlyph(Value: TBitmap);
begin
  if FGlyph <> Value then
   begin
    FGlyph.Assign(Value);
    SendMessage(ParentForm.Handle, wm_NCActivate, 0, 0);
   end;
end;

procedure TCaptionButton.SetVisible(Value: Boolean);
var
  p: Pointer;
begin
  if FVisible <> Value then
   begin
//AGA 7/19/99
    FVisible := Value;
    SendMessage(ParentForm.Handle, wm_NCActivate, 0, 0);
    SetItem(FSysMenu, FChecked, Value); //AGA 7/19/99
//AGA -- Begin 7/19/99
    if not FVisible then
      SetWindowLong(ParentForm.Handle, GWL_WNDPROC, LongInt(PrevParentWndProc))
    else begin
      { Setting hook on parent form }
      PrevParentWndProc := Pointer(GetWindowLong(ParentForm.Handle, GWL_WNDPROC));
      P := MakeObjectInstance(NewParentWndProc);
      SetWindowLong(ParentForm.Handle, GWL_WNDPROC, LongInt(p));
    end;
//AGA -- End
   end;
end;

//AGA -- Begin 7/19/99
procedure TCaptionButton.SetItem;
var
  FFlags : integer;
begin
  if FVisible and (FSysMenu <> '') then
    GetSystemMenu(ParentForm.Handle, True);
  FVisible := AVisible;
  FSysMenu := ASysMenu;
  FChecked := AChecked;
  if FVisible and (FSysMenu <> '') then begin
    FFlags := MF_BYPOSITION+MF_STRING;
    if FChecked then
      FFlags := FFlags + MF_CHECKED;
    InsertMenu(GetSystemMenu(ParentForm.Handle, False), 0, FFlags, OwnMessage, PChar(FSysMenu));
  end;
end;

procedure TCaptionButton.SetChecked;
begin
  if FChecked = Value then exit;
  SetItem(FSysMenu, Value, FVisible);
end;

procedure TCaptionButton.SetSysMenu;
begin
  if FSysMenu = Value then exit;
  SetItem(Value, FChecked, FVisible);
end;
//AGA -- End

procedure Register;
begin
  RegisterComponents('Samples', [TCaptionButton]);
end;

end.
