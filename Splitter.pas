Unit Splitter;

Interface

Uses
  Classes,Windows,Controls,ExtCtrls,Forms,Graphics,Messages;

Type

  { TSplitter }

  TAdvancedSplitterStyle = ( spUnknown,spHorizontal,spVertical );

  TAdvancedSplitter = Class( TCustomPanel )
  Private
    FControlFirst : TControl;
    FControlSecond : TControl;
    FSizing : Boolean;
    FStyle : TAdvancedSplitterStyle;
    FPrevOrg : TPoint;
    FMoveRect : TRect;
    FOnMove : TNotifyEvent;
    Procedure PaintInverseRect( RectOrg,RectEnd : TPoint );
    Procedure Move( X,Y : Integer );
    procedure StartInverseRect;
    procedure EndInverseRect( X,Y : Integer );
    procedure MoveInverseRect( X,Y : Integer );
    procedure ShowInverseRect( X,Y : Integer; Clear : Boolean );
    function GetStyle : TAdvancedSplitterStyle;
    function GetCursor : TCursor;
    procedure SetControlFirst( Value : TControl );
    procedure SetControlSecond( Value : TControl );
    Procedure WMMove( Var Message : TWMMove ); Message WM_MOVE;
    Procedure GetMoveRect;
  Protected
    Procedure Loaded; Override;
    Procedure Notification( AComponent : TComponent; AOperation : TOperation); Override;
    Procedure MouseDown( Button : TMouseButton; Shift : TShiftState; X,Y : Integer ); Override;
    Procedure MouseMove( Shift : TShiftState; X,Y : Integer ); Override;
    Procedure MouseUp( Button : TMouseButton; Shift : TShiftState; X,Y : Integer); Override;
    Procedure Resize; Override;
  Public
    Constructor Create( AOwner : TComponent ); Override;
    Procedure MoveTo( X,Y : Integer );
    Property Cursor Read GetCursor;
  Published
    property ControlFirst: TControl read FControlFirst write SetControlFirst;
    property ControlSecond: TControl read FControlSecond write SetControlSecond;
    Property OnMove : TNotifyEvent Read FOnMove Write FOnMove;
    property Align;
    property BevelInner;
    property BevelOuter;
    property BevelWidth;
    property DragCursor;
    property DragMode;
    property Enabled;
    property Color;
    property Ctl3D;
    property Locked;
    property ParentColor;
    property ParentCtl3D;
    property ParentShowHint;
    property ShowHint;
    property Visible;
    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;

Procedure Register;

Implementation

Uses
  WinProcs;

{ TSplitter }

Constructor TAdvancedSplitter.Create( AOwner : TComponent );
Begin
  Inherited Create( AOwner );
  ControlStyle := [csCaptureMouse,csClickEvents,csOpaque,csDoubleClicks];
  Width := 185;
  Height := 2;
  FSizing := False;
  FControlFirst := Nil;
  FControlSecond := Nil;
  FOnMove := Nil;
End;

Procedure TAdvancedSplitter.Loaded;
Begin
  Inherited Loaded;
  FStyle := GetStyle;
  GetMoveRect;
  GetCursor;
End;

Procedure TAdvancedSplitter.GetMoveRect;
Var
  CR1,CR2 : TRect;
Begin
  If Not Assigned( ControlFirst ) Or Not Assigned( ControlSecond ) Then
  Begin
    FMoveRect := ClientRect;
    Exit;
  End;
  CR1 := ControlFirst.ClientRect;
  With CR1 Do
  Begin
    TopLeft := ControlFirst.ClientToScreen( TopLeft );
    BottomRight := ControlFirst.ClientToScreen( BottomRight );
    TopLeft := Parent.ScreenToClient( TopLeft );
    BottomRight := Parent.ScreenToClient( BottomRight );
  End;
  CR2 := ControlSecond.ClientRect;
  With CR2 Do
  Begin
    TopLeft := ControlSecond.ClientToScreen( TopLeft );
    BottomRight := ControlSecond.ClientToScreen( BottomRight );
    TopLeft := Parent.ScreenToClient( TopLeft );
    BottomRight := Parent.ScreenToClient( BottomRight );
  End;
  With CR2 Do
    If Top = Bottom Then
    Begin
      Dec( Top );
    End;

  UnionRect( FMoveRect,CR1,CR2 );
End;

Procedure TAdvancedSplitter.PaintInverseRect;
Var
  DC : HDC;
Begin
  RectOrg := Parent.ClientToScreen( RectOrg );
  RectEnd := Parent.ClientToScreen( RectEnd );
  DC := GetDC( 0 );
  Try
    SetROP2( DC,R2_Not );
    MoveToEx( DC,RectOrg.X,RectOrg.Y,Nil );
    LineTo( DC,RectEnd.X,RectOrg.Y );
    LineTo( DC,RectEnd.X,RectEnd.Y );
    LineTo( DC,RectOrg.X,RectEnd.Y );
    LineTo( DC,RectOrg.X,RectOrg.Y );
  Finally
    ReleaseDC( 0,DC );
  End;
End;

Procedure TAdvancedSplitter.MoveTo;
Var
  P : TPoint;
Begin
  P := Point( X,Y );
  P := Parent.ClientToScreen( P );
  P := ScreenToClient( P );
  Move( P.X,P.Y );
End;

Procedure TAdvancedSplitter.Move;
Var
  MoveRect : TRect;
Begin
  MoveRect := FMoveRect;
  With MoveRect Do
  Begin
    TopLeft := Parent.ClientToScreen( TopLeft );
    BottomRight := Parent.ClientToScreen( BottomRight );
    TopLeft := ScreenToClient( TopLeft );
    BottomRight := ScreenToClient( BottomRight );
    If X < Left Then X := Left;
    If X > Right Then X := Right;
    If Y < Top Then Y := Top;
    If Y > Bottom Then Y := Bottom;
  End;

  {
  If ( ControlFirst.Align = alRight ) Or
    ( ControlSecond.Align = alRight ) Then X := -X;
  If ( ControlFirst.Align = alBottom ) Or
    ( ControlSecond.Align = alBottom ) Then Y := -Y;
  }

  Parent.DisableAlign;
  Case FStyle Of
    spHorizontal :
    Begin
      ControlFirst.Height := ControlFirst.Height+Y;
      Top := Top+Y;
      With ControlSecond Do
	SetBounds( Left,Top+Y,Width,Height-Y );
    End;
    spVertical :
    Begin
      ControlFirst.Width := ControlFirst.Width+X;
      Left := Left+X;
      With ControlSecond Do
	SetBounds( Left+X,Top,Width-X,Height );
    End;
  End;
  Parent.EnableAlign;
  { Notify parent that controls are realigned }
  If Assigned( FOnMove ) Then FOnMove( Self );
End;

Procedure TAdvancedSplitter.StartInverseRect;
Begin
  ShowInverseRect( 0,0,False );
End;

Procedure TAdvancedSplitter.EndInverseRect( X,Y : Integer );
Begin
  ShowInverseRect( 0,0,True );
  Move( X,Y );
End;

Procedure TAdvancedSplitter.MoveInverseRect( X,Y : Integer );
Begin
  ShowInverseRect( 0,0,True );
  ShowInverseRect( X,Y,False );
End;

Procedure TAdvancedSplitter.ShowInverseRect( X,Y : Integer; Clear : Boolean );
Var
  P : TPoint;
  W,H : Integer;
Begin
  P := Point( 0,0 );
  If FStyle = spHorizontal Then
  Begin
    W := FMoveRect.Right-FMoveRect.Left-1;
    H := 1;
    P.Y := Y;
  End Else
  Begin
    W := 1;
    H := FMoveRect.Bottom-FMoveRect.Top-1;
    P.X := X;
  End;
  If Clear Then P := FPrevOrg Else
  Begin
    P := ClientToScreen( P );
    P := Parent.ScreenToClient( P );
    With P,FMoveRect Do
    Begin
      If X < Left Then X := Left;
      If X > Right Then X := Right;
      If Y < Top Then Y := Top;
      If Y > Bottom Then Y := Bottom;
    End;
    FPrevOrg := P;
  End;
  PaintInverseRect( P,Point( P.X+W,P.Y+H ) );
End;

Function TAdvancedSplitter.GetStyle : TAdvancedSplitterStyle;
Begin
  Result := spUnknown;
  If ( ControlFirst = Nil ) Or ( ControlSecond = Nil ) Then Exit;
  If ControlFirst.Top = ControlSecond.Top Then Result := spVertical;
  If ControlFirst.Left = ControlSecond.Left Then Result := spHorizontal;
end;

Function TAdvancedSplitter.GetCursor : TCursor;
Begin
  Result := crDefault;
  Case GetStyle Of
    spHorizontal : Result := crVSplit;
    spVertical : Result := crHSplit;
  End;
  Inherited Cursor := Result;
End;

Procedure TAdvancedSplitter.SetControlFirst( Value : TControl );
Begin
  If Value = FControlFirst Then Exit;
  If Value = Self Then FControlFirst := Nil Else FControlFirst := Value;
  GetCursor;
End;

Procedure TAdvancedSplitter.SetControlSecond( Value : TControl );
Begin
  If Value = FControlSecond Then Exit;
  If Value = Self Then FControlSecond := Nil Else FControlSecond := Value;
  GetCursor;
End;

Procedure TAdvancedSplitter.Notification( AComponent : TComponent; AOperation : TOperation );
Begin
  If AOperation = opRemove Then
    If AComponent = ControlFirst Then ControlFirst := Nil Else
      If AComponent = ControlSecond Then ControlSecond := Nil;
end;

Procedure TAdvancedSplitter.MouseDown( Button : TMouseButton; Shift : TShiftState; X,Y : Integer );
Begin
  Inherited MouseDown( Button,Shift,X,Y );
  If Not ( csDesigning In ComponentState ) And ( Button = mbLeft ) Then
  Begin
    {
    FStyle := GetStyle;
    }
    If FStyle <> spUnknown Then
    Begin
      FSizing := True;
      SetCapture( Handle );
      StartInverseRect;
    End;
  End;
End;

Procedure TAdvancedSplitter.MouseMove( Shift : TShiftState; X,Y : Integer );
Begin
  Inherited MouseMove( Shift,X,Y );
  If ( GetCapture = Handle ) And FSizing Then MoveInverseRect( X,Y );
  GetCursor;
End;

Procedure TAdvancedSplitter.MouseUp( Button : TMouseButton; Shift : TShiftState; X,Y : Integer );
Begin
  If FSizing Then
  Begin
    ReleaseCapture;
    EndInverseRect( X,Y );
    FSizing := False;
  End;
  GetCursor;
  Inherited MouseUp( Button,Shift,X,Y );
End;

Procedure TAdvancedSplitter.Resize;
Begin
  Inherited Resize;
  GetMoveRect;
End;

Procedure TAdvancedSplitter.WMMove;
Begin
  Inherited;
  GetMoveRect;
End;

Procedure Register;
Begin
  RegisterComponents( 'Additional',[TAdvancedSplitter] );
End;

End.
