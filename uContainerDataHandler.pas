unit uContainerDataHandler;

interface

uses
  iContainers;

const
  vtSmallAnsiString = 255;

type
  {$IFNDEF DELPHIXE}
  // We must define NativeInt for platforms lesser than DelphiXE
  // to make things even worse, in Delphi 2007 NativeInt is a 64 bits integer when on later
  // versions this type mutates depending on the target platform x86 or x64
  NativeInt = Integer;
  NativeUInt = Cardinal;
  {$ENDIF}
  TSmallAnsiStringBuffer = array [0..sizeof(Extended) - 1] of byte;
  PContainerData = ^TContainerData;
  TContainerData = record
    case VType : byte of
      vtPointer, vtObject, vtInterface : (AsPointer : Pointer);
      vtInteger : (AsInteger : integer);
      vtString : (AsShortString : PShortString);
      vtAnsiString : (AsAnsiString : PAnsiString);
      vtInt64 : (AsInt64 : Int64);
      vtExtended : (AsExtended : Extended);
      vtCurrency : (AsCurrency : Currency);
      vtBoolean : (AsBoolean : Boolean);
      vtChar : (AsAnsiChar : AnsiChar);
      vtWideChar : (AsWideChar : WideChar);
      vtWideString : (AsWideString : PWideString);
      vtSmallAnsiString : (AsBuffer : TSmallAnsiStringBuffer);
  end;

  TContainerDataHandler = class (TInterfacedObject, IDataHandler)
  private
    FAutoFreeObjects: Boolean;
    procedure CheckContext(AContext: Pointer);
  protected
    procedure CleanData(AContext: Pointer); virtual;
    function CheckType(AContext: Pointer; AType: Byte): Byte; virtual;
    function GetAsAnsiChar(AContext: Pointer): AnsiChar; virtual;
    function GetAsAnsiString(AContext: Pointer): AnsiString; virtual;
    function GetAsBoolean(AContext: Pointer): Boolean; virtual;
    function GetAsCurrency(AContext: Pointer): Currency; virtual;
    function GetAsExtended(AContext: Pointer): Extended; virtual;
    function GetAsInt64(AContext: Pointer): Int64; virtual;
    function GetAsInteger(AContext: Pointer): integer; virtual;
    function GetAsInterface(AContext: Pointer): IUnknown; virtual;
    function GetAsObject(AContext: Pointer): TObject; virtual;
    function GetAsPointer(AContext: Pointer): Pointer; virtual;
    function GetAsShortString(AContext: Pointer): ShortString; virtual;
    function GetAsWideChar(AContext: Pointer): WideChar; virtual;
    function GetAsWideString(AContext: Pointer): WideString; virtual;

    procedure SetAnsiChar(AContext: Pointer; Value : AnsiChar); virtual;
    procedure SetAnsiString(AContext: Pointer; const Value : AnsiString); virtual;
    procedure SetBoolean(AContext: Pointer; Value : Boolean); virtual;
    procedure SetCurrency(AContext: Pointer; const Value : Currency); virtual;
    procedure SetExtended(AContext: Pointer; const Value : Extended); virtual;
    procedure SetInt64(AContext: Pointer; const Value : Int64); virtual;
    procedure SetInteger(AContext: Pointer; Value : integer); virtual;
    procedure SetInterface(AContext: Pointer; Value : IUnknown); virtual;
    procedure SetObject(AContext: Pointer; Value : TObject); virtual;
    procedure SetPointer(AContext: Pointer; Value : Pointer); virtual;
    procedure SetShortString(AContext: Pointer; const Value : ShortString); virtual;
    procedure SetWideChar(AContext: Pointer; Value : WideChar); virtual;
    procedure SetWideString(AContext: Pointer; const Value : WideString); virtual;

    function Compare(AContext : Pointer; Value : integer): integer; overload; virtual;
    function Compare(AContext : Pointer; Value : Pointer): integer; overload; virtual;
    function Compare(AContext : Pointer; Value : TObject): integer; overload; virtual;
    function Compare(AContext : Pointer; Value : AnsiChar): integer; overload; virtual;
    function Compare(AContext : Pointer; Value : Boolean): integer; overload; virtual;
    function Compare(AContext : Pointer; const Value : Currency): integer; overload; virtual;
    function Compare(AContext : Pointer; const Value : Extended): integer; overload; virtual;
    function Compare(AContext : Pointer; const Value : Int64): integer; overload; virtual;
    function Compare(AContext : Pointer; Value : IUnknown): integer; overload; virtual;
    function Compare(AContext : Pointer; Value : WideChar): integer; overload; virtual;
    function CompareAnsiString(AContext : Pointer; const Value : AnsiString): integer; virtual;
    function CompareShortString(AContext: Pointer; const Value: ShortString): integer; virtual;
    function CompareWideString(AContext : Pointer; const Value : WideString): integer; virtual;
    function GetAutoFreeObjects: Boolean;

    function GetType(AContext: Pointer): Byte; virtual;
    procedure SetAutoFreeObjects(Value: Boolean);
  end;

implementation

uses
  SysUtils
  {$IFDEF UNICODE},AnsiStrings{$ENDIF};

// START resource string wizard section
resourcestring
  SAContextShouldBeNil = 'AContext should be <> nil';
  STryingToAccessObjectPointedByCon = 'Trying to access object pointed by context using wrong access method';

// END resource string wizard section


procedure TContainerDataHandler.CheckContext(AContext: Pointer);
begin
  if AContext = nil then
    raise EContainer.Create (SAContextShouldBeNil);
end;

function TContainerDataHandler.CheckType(AContext: Pointer; AType: Byte): Byte;
begin
  CheckContext (AContext);
  if (PContainerData (AContext).VType <> AType) and
     ((PContainerData (AContext).VType <> vtSmallAnsiString) or (AType <> vtAnsiString)) and
     ((PContainerData (AContext).VType <> vtSmallAnsiString) or (AType <> vtString)) then
    raise EContainer.Create (STryingToAccessObjectPointedByCon);
  Result := PContainerData (AContext).VType;
end;

procedure TContainerDataHandler.CleanData(AContext: Pointer);
begin
  with PContainerData (AContext)^ do
    case VType of
      vtAnsiString: AnsiString(AsAnsiString) := '';
      vtWideString: WideString(AsWideString) := '';
      vtString : Dispose (AsShortString);
      vtInterface :
        begin
          if AsPointer <> nil then
            IUnknown(AsPointer)._Release;
          AsPointer := nil;
        end;
      vtObject : if FAutoFreeObjects then
        TObject(AsPointer).Free;
    end;
end;

function TContainerDataHandler.Compare(AContext : Pointer; Value : integer):
    integer;
begin
  if GetAsInteger (AContext) > Value
    then Result := 1
    else if GetAsInteger (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; Value : Pointer):
    integer;
begin
  if integer (GetAsPointer (AContext)) > integer (Value)
    then Result := 1
    else if GetAsPointer (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; Value : TObject):
    integer;
begin
  if integer (GetAsObject (AContext)) > integer (Value)
    then Result := 1
    else if GetAsObject (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; Value : AnsiChar):
    integer;
begin
  if GetAsAnsiChar (AContext) > Value
    then Result := 1
    else if GetAsAnsiChar (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; Value : Boolean):
    integer;
begin
  if GetAsBoolean (AContext) > Value
    then Result := 1
    else if GetAsBoolean (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; const Value :
    Currency): integer;
begin
  if GetAsCurrency (AContext) > Value
    then Result := 1
    else if GetAsCurrency (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; const Value :
    Extended): integer;
begin
  if GetAsExtended (AContext) > Value
    then Result := 1
    else if GetAsExtended (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; const Value :
    Int64): integer;
begin
  if GetAsInt64(AContext) > Value
    then Result := 1
    else if GetAsInt64 (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; Value : IUnknown):
    integer;
begin
  if NativeUInt(Pointer(GetAsInterface(AContext))) > NativeUInt(Pointer(Value))
    then Result := 1
    else if GetAsInterface (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.Compare(AContext : Pointer; Value : WideChar):
    integer;
begin
  if GetAsWideChar (AContext) > Value
    then Result := 1
    else if GetAsWideChar (AContext) = Value
      then Result := 0
      else Result := -1;
end;

function TContainerDataHandler.CompareAnsiString(AContext : Pointer; const
    Value : AnsiString): integer;
begin
  Result := {$IFDEF UNICODE}AnsiStrings.{$ENDIF}CompareStr (GetAsAnsiString (AContext), Value);
end;

function TContainerDataHandler.CompareShortString(AContext: Pointer; const
    Value: ShortString): integer;
begin
  Result := {$IFDEF UNICODE}AnsiStrings.{$ENDIF}CompareStr (GetAsShortString (AContext), Value);
end;

function TContainerDataHandler.CompareWideString(AContext : Pointer; const
    Value : WideString): integer;
begin
  Result := {$IFDEF UNICODE}SysUtils.{$ENDIF}CompareStr (GetAsWideString (AContext), Value);
end;

function TContainerDataHandler.GetAsAnsiChar(AContext: Pointer): AnsiChar;
begin
  CheckType (AContext, vtChar);
  Result := PContainerData (AContext).AsAnsiChar;
end;

function TContainerDataHandler.GetAsAnsiString(AContext: Pointer): AnsiString;
begin
  case CheckType (AContext, vtAnsiString) of
    vtAnsiString : Result := AnsiString (PContainerData (AContext).AsAnsiString);
    vtSmallAnsiString :
      begin
        SetLength (Result, PContainerData (AContext).AsBuffer[0]);
        move (PContainerData (AContext).AsBuffer[1], PAnsiChar(Result)^, PContainerData (AContext).AsBuffer[0]);
      end;
  end;
end;

function TContainerDataHandler.GetAsBoolean(AContext: Pointer): Boolean;
begin
  CheckType (AContext, vtBoolean);
  Result := PContainerData (AContext).AsBoolean;
end;

function TContainerDataHandler.GetAsCurrency(AContext: Pointer): Currency;
begin
  CheckType (AContext, vtCurrency);
  Result := PContainerData (AContext).AsCurrency;
end;

function TContainerDataHandler.GetAsExtended(AContext: Pointer): Extended;
begin
  CheckType (AContext, vtExtended);
  Result := PContainerData (AContext).AsExtended;
end;

function TContainerDataHandler.GetAsInt64(AContext: Pointer): Int64;
begin
  CheckType (AContext, vtInt64);
  Result := PContainerData (AContext).AsInt64;
end;

function TContainerDataHandler.GetAsInteger(AContext: Pointer): integer;
begin
  CheckType (AContext, vtInteger);
  Result := PContainerData (AContext).AsInteger;
end;

function TContainerDataHandler.GetAsInterface(AContext: Pointer): IUnknown;
begin
  CheckType (AContext, vtInterface);
  Result := IUnknown (PContainerData (AContext).AsPointer);
end;

function TContainerDataHandler.GetAsObject(AContext: Pointer): TObject;
begin
  CheckType (AContext, vtObject);
  Result := PContainerData (AContext).AsPointer;
end;

function TContainerDataHandler.GetAsPointer(AContext: Pointer): Pointer;
begin
  CheckType (AContext, vtPointer);
  Result := PContainerData (AContext).AsPointer;
end;

function TContainerDataHandler.GetAsShortString(AContext: Pointer): ShortString;
begin
  case CheckType (AContext, vtString) of
    vtString : Result := PContainerData (AContext).AsShortString^;
    vtSmallAnsiString :
      begin
        SetLength (Result, PContainerData (AContext).AsBuffer[0]);
        move (PContainerData (AContext).AsBuffer[1], Result[1], PContainerData (AContext).AsBuffer[0]);
      end;
  end;
end;

function TContainerDataHandler.GetAsWideChar(AContext: Pointer): WideChar;
begin
  CheckType (AContext, vtWideChar);
  Result := PContainerData (AContext).AsWideChar;
end;

function TContainerDataHandler.GetAsWideString(AContext: Pointer): WideString;
begin
  CheckType (AContext, vtWideString);
  Result := WideString (PContainerData (AContext).AsWideString);
end;

function TContainerDataHandler.GetAutoFreeObjects: Boolean;
begin
  Result := FAutoFreeObjects;
end;

function TContainerDataHandler.GetType(AContext: Pointer): Byte;
begin
  CheckContext (AContext);
  Result := PContainerData (AContext).VType;
end;

procedure TContainerDataHandler.SetAnsiChar(AContext: Pointer; Value :
    AnsiChar);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtChar;
      AsAnsiChar := Value;
    end;
end;

procedure TContainerDataHandler.SetAnsiString(AContext: Pointer; const Value :
    AnsiString);
var
  Len : integer;
begin
  Len := length (Value);
  with PContainerData (AContext)^ do
    if Len < sizeof (TSmallAnsiStringBuffer)
      then
      begin
        VType := vtSmallAnsiString;
        move (PAnsiChar (Value)^, AsBuffer[1], Len);
        AsBuffer[0] := Len;
      end
      else
      begin
        VType := vtAnsiString;
        AsAnsiString := nil;
        AnsiString(AsAnsiString) := Value;
        UniqueString(AnsiString(AsAnsiString));
      end;
end;

procedure TContainerDataHandler.SetAutoFreeObjects(Value: Boolean);
begin
  FAutoFreeObjects := Value;
end;

procedure TContainerDataHandler.SetBoolean(AContext: Pointer; Value : Boolean);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtBoolean;
      AsBoolean := Value;
    end;
end;

procedure TContainerDataHandler.SetCurrency(AContext: Pointer; const Value :
    Currency);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtCurrency;
      AsCurrency := Value;
    end;
end;

procedure TContainerDataHandler.SetExtended(AContext: Pointer; const Value :
    Extended);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtExtended;
      AsExtended := Value;
    end;
end;

procedure TContainerDataHandler.SetInt64(AContext: Pointer; const Value :
    Int64);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtInt64;
      AsInt64 := Value;
    end;
end;

procedure TContainerDataHandler.SetInteger(AContext: Pointer; Value : integer);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtInteger;
      AsInteger := Value;
    end;
end;

procedure TContainerDataHandler.SetInterface(AContext: Pointer; Value :
    IUnknown);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtInterface;
      if AsPointer <> nil then
        IUnknown(AsPointer)._Release;
      AsPointer := Pointer(Value);
      if AsPointer <> nil then
        IUnknown(AsPointer)._AddRef;
    end;
end;

procedure TContainerDataHandler.SetObject(AContext: Pointer; Value : TObject);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtObject;
      AsPointer := Value;
    end;
end;

procedure TContainerDataHandler.SetPointer(AContext: Pointer; Value : Pointer);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtPointer;
      AsPointer := Value;
    end;
end;

procedure TContainerDataHandler.SetShortString(AContext: Pointer; const Value :
    ShortString);
var
  Len : integer;
begin
  Len := length (Value);
  with PContainerData (AContext)^ do
    if Len < sizeof (TSmallAnsiStringBuffer)
      then
      begin
        VType := vtSmallAnsiString;
        move (Value[1], AsBuffer[1], Len);
        AsBuffer[0] := Len;
      end
      else
      begin
        VType := vtString;
        New (AsShortString);
        PShortString (AsShortString)^ := Value;
      end;
end;

procedure TContainerDataHandler.SetWideChar(AContext: Pointer; Value :
    WideChar);
begin
  with PContainerData (AContext)^ do
    begin
      VType := vtWideChar;
      AsWideChar := Value;
    end;
end;

procedure TContainerDataHandler.SetWideString(AContext: Pointer; const Value :
    WideString);
begin
  {$IFDEF VER130}
  raise Exception.Create ('WideString not yet supported on TContainerDataHandler');
  {$ELSE}
  with PContainerData (AContext)^ do
    begin
      VType := vtWideString;
      AsWideString := nil;
      WideString (AsWideString) := Value;
      UniqueString (WideString (AsWideString));
    end;
  {$ENDIF}
end;

end.

