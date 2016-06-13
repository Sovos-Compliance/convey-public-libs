unit uCnvDictionary;

interface

{$i DelphiVersion_defines.inc}

{$IFDEF DELPHIXE}
  {$DEFINE HAS_GENERICS}
{$ENDIF}

uses
  {$IFDEF HAS_GENERICS}System.Generics.Collections{$ELSE}HashTrie{$ENDIF},
  Windows;

type
  (* AValue can be primitive wrapper(use if (AValue is TPrimitiveWrapper) then to check)
     then you can access value:
       TStringWrapper(AValue).Value
       TIntegerWrapper(AValue).Value
     etc. 
  *)
  TCnvStringDictionaryEnumerateCallback = procedure(const AKey: string; const AValue: TObject; AUserData: Pointer) of object;
  TCnvIntegerDictionaryEnumerateCallback = procedure(const AKey: Integer; const AValue: TObject; AUserData: Pointer) of object;

  (* Associative array with string key implementation *)
  TCnvStringDictionary = class
  private
    FDic: {$IFDEF HAS_GENERICS}TDictionary<string, TObject>{$ELSE}TStringHashTrie{$ENDIF};
    FUserEnumerateCallback: TCnvStringDictionaryEnumerateCallback;
    {$IFNDEF HAS_GENERICS}
    procedure EnumerateCallback(UserData: Pointer; Value: PChar; Data: TObject; var Done: Boolean);
    {$ENDIF}
  public
    constructor Create(AAutoFreeObjects: Boolean = false; ACaseSensitive: Boolean = False);
    destructor Destroy; override;
    procedure AddOrSetValue(const AKey: string; const AValue: TObject); overload;
    procedure AddOrSetValue(const AKey: string; const AValue: string); overload;
    procedure AddOrSetValue(const AKey: string; const AValue: Integer); overload;
    procedure AddOrSetValue(const AKey: string; const AValue: Int64); overload;
    procedure AddOrSetValue(const AKey: string; const AValue: Double); overload;
    procedure AddOrSetValue(const AKey: string; const AValue: Boolean); overload;
    procedure AddOrSetValueDate(const AKey: string; const AValue: TDateTime);
    procedure Remove(const AKey: string);
    function TryGetValue(const AKey: string; out AValue: TObject): Boolean;
        overload;
    function TryGetValue(const AKey: string; out AValue: string): Boolean; overload;
    function TryGetValue(const AKey: string; out AValue: Integer): Boolean; overload;
    function TryGetValue(const AKey: string; out AValue: Int64): Boolean; overload;
    function TryGetValue(const AKey: string; out AValue: Double): Boolean; overload;
    function TryGetValue(const AKey: string; out AValue: Boolean): Boolean; overload;
    function TryGetValueDate(const AKey: string; out AValue: TDateTime): Boolean;
    function ContainsKey(const AKey: string): Boolean;
    procedure Clear;
    procedure Foreach(ACallback: TCnvStringDictionaryEnumerateCallback; AUserData: Pointer = nil);
  end;

  TStrHashTraverseProc = procedure(UserData: Pointer; Value: PChar;
    Data: TObject; var Done: Boolean);
  TStrHashTraverseMeth = procedure(UserData: Pointer; Value: PChar;
    Data: TObject; var Done: Boolean) of object;

  _TStringHashTrie = class(TCnvStringDictionary)
  private
    FStrHashTraverseProc : TStrHashTraverseProc;
    FStrHashTraverseMeth : TStrHashTraverseMeth;
    procedure ForEachCallback(const AKey: string; const AValue: TObject; AUserData: Pointer);
  public
    procedure Add(const S: string; Data: TObject); overload;
    procedure Add(const s : string); overload;
    procedure Delete(const S: string);
    function Find(const S: string; var Data: TObject): Boolean; overload;
    function Find(const s : string): Boolean; overload;
    procedure Traverse(UserData: Pointer; UserProc: TStrHashTraverseProc); overload;
    procedure Traverse(UserData: Pointer; UserProc: TStrHashTraverseMeth); overload;
  end;

  (* Associative array with integer key implementation *)

  TCnvIntegerDictionary = class
  private
    FDic: {$IFDEF HAS_GENERICS}TDictionary<Integer, TObject>{$ELSE}TIntegerHashTrie{$ENDIF};
    FUserEnumerateCallback: TCnvIntegerDictionaryEnumerateCallback;
    {$IFNDEF HAS_GENERICS}
    procedure EnumerateCallback(UserData: Pointer; Value: Integer; Data: TObject; var Done: Boolean);
    {$ENDIF}
  public
    constructor Create(AAutoFreeObjects: Boolean = false);
    destructor Destroy; override;
    procedure AddOrSetValue(const AKey: Integer; const AValue: TObject); overload;
    procedure AddOrSetValue(const AKey: Integer; const AValue: string); overload;
    procedure AddOrSetValue(const AKey: Integer; const AValue: Integer); overload;
    procedure AddOrSetValue(const AKey: Integer; const AValue: Int64); overload;
    procedure AddOrSetValue(const AKey: Integer; const AValue: Double); overload;
    procedure AddOrSetValue(const AKey: Integer; const AValue: Boolean); overload;
    procedure AddOrSetValueDate(const AKey: Integer; const AValue: TDateTime);
    procedure Remove(const AKey: Integer);
    function TryGetValue(const AKey: Integer; out AValue: TObject): Boolean; overload;
    function TryGetValue(const AKey: Integer; out AValue: string): Boolean; overload;
    function TryGetValue(const AKey: Integer; out AValue: Integer): Boolean; overload;
    function TryGetValue(const AKey: Integer; out AValue: Int64): Boolean; overload;
    function TryGetValue(const AKey: Integer; out AValue: Double): Boolean; overload;
    function TryGetValue(const AKey: Integer; out AValue: Boolean): Boolean; overload;
    function TryGetValueDate(const AKey: Integer; out AValue: TDateTime): Boolean;
    function ContainsKey(const AKey: Integer): Boolean;
    procedure Clear;
    procedure Foreach(ACallback: TCnvIntegerDictionaryEnumerateCallback; AUserData: Pointer = nil);
  end;

  TIntHashTraverseProc = procedure(UserData: Pointer; Value: integer;
    Data: TObject; var Done: Boolean);
  TIntHashTraverseMeth = procedure(UserData: Pointer; Value: integer;
    Data: TObject; var Done: Boolean) of object;

  _TIntegerHashTrie = class(TCnvIntegerDictionary)
  private
    FIntHashTraverseProc : TIntHashTraverseProc;
    FIntHashTraverseMeth : TIntHashTraverseMeth;
    procedure ForEachCallback(const AKey: Integer; const AValue: TObject;
        AUserData: Pointer);
  public
    procedure Add(const n: integer; Data: TObject); overload;
    procedure Delete(n: integer);
    function Find(n: integer; var Data: TObject): Boolean; overload;
    procedure Traverse(UserData: Pointer; UserProc: TIntHashTraverseProc); overload;
    procedure Traverse(UserData: Pointer; UserProc: TIntHashTraverseMeth); overload;
    function Find(n : integer): Boolean; overload;
    procedure Add(n : integer); overload;
  end;

  (* wrapper classes to support primitives(assigned to TObject) *)
  TPrimitiveWrapper = class
  end;

  TStringWrapper = class(TPrimitiveWrapper)
  private
    FValue: string;
  public
    constructor Create(AValue: string);
    property Value: string read FValue write FValue;
  end;

  TIntegerWrapper = class(TPrimitiveWrapper)
  private
    FValue: Integer;
  public
    constructor Create(AValue: Integer);
    property Value: Integer read FValue write FValue;
  end;

  TInt64Wrapper = class(TPrimitiveWrapper)
  private
    FValue: Int64;
  public
    constructor Create(AValue: Int64);
    property Value: Int64 read FValue write FValue;
  end;

  TDoubleWrapper = class(TPrimitiveWrapper)
  private
    FValue: Extended;
  public
    constructor Create(AValue: Extended);
    property Value: Extended read FValue write FValue;
  end;

  TBooleanWrapper = class(TPrimitiveWrapper)
  private
    FValue: Boolean;
  public
    constructor Create(AValue: Boolean);
    property Value: Boolean read FValue write FValue;
  end;

  TDateTimeWrapper = class(TPrimitiveWrapper)
  private
    FValue: TDateTime;
  public
    constructor Create(AValue: TDateTime);
    property Value: TDateTime read FValue write FValue;
  end;

implementation

uses
{$IFDEF HAS_GENERICS}
  System.Generics.Defaults,
{$ENDIF}
  SysUtils;

{ TCnvStringDictionary }

constructor TCnvStringDictionary.Create(AAutoFreeObjects: Boolean; ACaseSensitive: Boolean);
{$IFDEF HAS_GENERICS}
var
  ownerships: TDictionaryOwnerships;
  comparer: IEqualityComparer<string>;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  if AAutoFreeObjects then
    ownerships := [doOwnsValues]
  else
    ownerships := [];
  if ACaseSensitive then
    comparer := nil
  else
    comparer := TIStringComparer.Ordinal;
  FDic := TObjectDictionary<string, TObject>.Create(ownerships, comparer);
{$ELSE}
  FDic := TStringHashTrie.Create;
  FDic.AutoFreeObjects := AAutoFreeObjects;
  FDic.CaseSensitive := ACaseSensitive;
{$ENDIF}
end;

destructor TCnvStringDictionary.Destroy;
begin
  FDic.Free;
  inherited;
end;

{$IFNDEF HAS_GENERICS}
procedure TCnvStringDictionary.EnumerateCallback(UserData: Pointer;
  Value: PChar; Data: TObject; var Done: Boolean);
begin
  FUserEnumerateCallback(Value, Data, UserData);
end;
{$ENDIF}

procedure TCnvStringDictionary.Foreach(ACallback: TCnvStringDictionaryEnumerateCallback;
  AUserData: Pointer);
{$IFDEF HAS_GENERICS}
var
  key: string;
{$ENDIF}
begin
  FUserEnumerateCallback := ACallback;
{$IFDEF HAS_GENERICS}
  for key in FDic.Keys do
    FUserEnumerateCallback(key, FDic.Items[key], AUserData);
{$ELSE}
  FDic.Traverse(AUserData, EnumerateCallback);
{$ENDIF}
end;

procedure TCnvStringDictionary.AddOrSetValue(const AKey: string;
  const AValue: TObject);
begin
{$IFDEF HAS_GENERICS}
  FDic.AddOrSetValue(AKey, AValue);
{$ELSE}
  FDic.Add(AKey, AValue);
{$ENDIF}
end;

procedure TCnvStringDictionary.AddOrSetValue(const AKey: string;
  const AValue: Integer);
begin
  AddOrSetValue(AKey, TIntegerWrapper.Create(AValue));
end;

procedure TCnvStringDictionary.AddOrSetValue(const AKey, AValue: string);
begin
  AddOrSetValue(AKey, TStringWrapper.Create(AValue));
end;

procedure TCnvStringDictionary.AddOrSetValue(const AKey: string;
  const AValue: Boolean);
begin
  AddOrSetValue(AKey, TBooleanWrapper.Create(AValue));
end;

procedure TCnvStringDictionary.AddOrSetValueDate(const AKey: string;
  const AValue: TDateTime);
begin
  AddOrSetValue(AKey, TDateTimeWrapper.Create(AValue));
end;

procedure TCnvStringDictionary.AddOrSetValue(const AKey: string;
  const AValue: Int64);
begin
  AddOrSetValue(AKey, TInt64Wrapper.Create(AValue));
end;

procedure TCnvStringDictionary.AddOrSetValue(const AKey: string;
  const AValue: Double);
begin
  AddOrSetValue(AKey, TDoubleWrapper.Create(AValue));
end;

procedure TCnvStringDictionary.Clear;
begin
  FDic.Clear;
end;

function TCnvStringDictionary.ContainsKey(const AKey: string): Boolean;
{$IFNDEF HAS_GENERICS}
var
  stub: TObject;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.ContainsKey(AKey);
{$ELSE}
  Result := FDic.Find(AKey, stub);
{$ENDIF}
end;

procedure TCnvStringDictionary.Remove(const AKey: string);
begin
{$IFDEF HAS_GENERICS}
  FDic.Remove(AKey);
{$ELSE}
  FDic.Delete(AKey);
{$ENDIF}
end;

function TCnvStringDictionary.TryGetValue(const AKey: string; out AValue:
    TObject): Boolean;
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.TryGetValue(AKey, AValue);
{$ELSE}
  Result := FDic.Find(AKey, AValue);
{$ENDIF}
end;

function TCnvStringDictionary.TryGetValue(const AKey: string;
  out AValue: Integer): Boolean;
var
  wrap: TIntegerWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvStringDictionary.TryGetValue(const AKey: string;
  out AValue: string): Boolean;
var
  wrap: TStringWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvStringDictionary.TryGetValue(const AKey: string;
  out AValue: Int64): Boolean;
var
  wrap: TInt64Wrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvStringDictionary.TryGetValue(const AKey: string;
  out AValue: Double): Boolean;
var
  wrap: TDoubleWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvStringDictionary.TryGetValue(const AKey: string;
  out AValue: Boolean): Boolean;
var
  wrap: TBooleanWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvStringDictionary.TryGetValueDate(const AKey: string;
  out AValue: TDateTime): Boolean;
var
  wrap: TDateTimeWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

{ TCnvIntegerDictionary }

procedure TCnvIntegerDictionary.AddOrSetValue(const AKey: Integer;
  const AValue: TObject);
begin
{$IFDEF HAS_GENERICS}
  FDic.AddOrSetValue(AKey, AValue);
{$ELSE}
  FDic.Add(AKey, AValue);
{$ENDIF}
end;

procedure TCnvIntegerDictionary.AddOrSetValue(const AKey, AValue: Integer);
begin
  AddOrSetValue(AKey, TIntegerWrapper.Create(AValue));
end;

procedure TCnvIntegerDictionary.AddOrSetValue(const AKey: Integer;
  const AValue: string);
begin
  AddOrSetValue(AKey, TStringWrapper.Create(AValue));
end;

procedure TCnvIntegerDictionary.AddOrSetValue(const AKey: Integer;
  const AValue: Boolean);
begin
  AddOrSetValue(AKey, TBooleanWrapper.Create(AValue));
end;

procedure TCnvIntegerDictionary.AddOrSetValueDate(const AKey: Integer;
  const AValue: TDateTime);
begin
  AddOrSetValue(AKey, TDateTimeWrapper.Create(AValue));
end;

procedure TCnvIntegerDictionary.AddOrSetValue(const AKey: Integer;
  const AValue: Int64);
begin
  AddOrSetValue(AKey, TInt64Wrapper.Create(AValue));
end;

procedure TCnvIntegerDictionary.AddOrSetValue(const AKey: Integer;
  const AValue: Double);
begin
  AddOrSetValue(AKey, TDoubleWrapper.Create(AValue));
end;

procedure TCnvIntegerDictionary.Clear;
begin
  FDic.Clear;
end;

function TCnvIntegerDictionary.ContainsKey(const AKey: Integer): Boolean;
{$IFNDEF HAS_GENERICS}
var
  stub: TObject;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.ContainsKey(AKey);
{$ELSE}
  Result := FDic.Find(AKey, stub);
{$ENDIF}
end;

constructor TCnvIntegerDictionary.Create(AAutoFreeObjects: Boolean);
{$IFDEF HAS_GENERICS}
var
  ownerships: TDictionaryOwnerships;
{$ENDIF}
begin
{$IFDEF HAS_GENERICS}
  if AAutoFreeObjects then
    ownerships := [doOwnsValues]
  else
    ownerships := [];
  FDic := TObjectDictionary<Integer, TObject>.Create(ownerships);
{$ELSE}
  FDic := TIntegerHashTrie.Create;
  FDic.AutoFreeObjects := AAutoFreeObjects;
{$ENDIF}
end;

destructor TCnvIntegerDictionary.Destroy;
begin
  FDic.Free;
  inherited;
end;

{$IFNDEF HAS_GENERICS}
procedure TCnvIntegerDictionary.EnumerateCallback(UserData: Pointer;
  Value: Integer; Data: TObject; var Done: Boolean);
begin
  FUserEnumerateCallback(Value, Data, UserData);
end;
{$ENDIF}

procedure TCnvIntegerDictionary.Foreach(
  ACallback: TCnvIntegerDictionaryEnumerateCallback; AUserData: Pointer);
{$IFDEF HAS_GENERICS}
var
  key: Integer;
{$ENDIF}
begin
  FUserEnumerateCallback := ACallback;
{$IFDEF HAS_GENERICS}
  for key in FDic.Keys do
    FUserEnumerateCallback(key, FDic.Items[key], AUserData);
{$ELSE}
  FDic.Traverse(AUserData, EnumerateCallback);
{$ENDIF}
end;

procedure TCnvIntegerDictionary.Remove(const AKey: Integer);
begin
{$IFDEF HAS_GENERICS}
  FDic.Remove(AKey);
{$ELSE}
  FDic.Delete(AKey);
{$ENDIF}
end;

function TCnvIntegerDictionary.TryGetValue(const AKey: Integer;
  out AValue: TObject): Boolean;
begin
{$IFDEF HAS_GENERICS}
  Result := FDic.TryGetValue(AKey, AValue);
{$ELSE}
  Result := FDic.Find(AKey, AValue);
{$ENDIF}
end;

function TCnvIntegerDictionary.TryGetValue(const AKey: Integer;
  out AValue: Integer): Boolean;
var
  wrap: TIntegerWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvIntegerDictionary.TryGetValue(const AKey: Integer;
  out AValue: string): Boolean;
var
  wrap: TStringWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvIntegerDictionary.TryGetValue(const AKey: Integer;
  out AValue: Int64): Boolean;
var
  wrap: TInt64Wrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvIntegerDictionary.TryGetValue(const AKey: Integer;
  out AValue: Double): Boolean;
var
  wrap: TDoubleWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvIntegerDictionary.TryGetValue(const AKey: Integer;
  out AValue: Boolean): Boolean;
var
  wrap: TBooleanWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

function TCnvIntegerDictionary.TryGetValueDate(const AKey: Integer;
  out AValue: TDateTime): Boolean;
var
  wrap: TDateTimeWrapper;
begin
  Result := TryGetValue(AKey, TObject(wrap)) and (wrap <> nil);
  if Result then
    AValue := wrap.Value;
end;

{ TStringWrapper }

constructor TStringWrapper.Create(AValue: string);
begin
  FValue := AValue;
end;

{ TIntegerWrapper }

constructor TIntegerWrapper.Create(AValue: Integer);
begin
  FValue := AValue;
end;

{ TInt64Wrapper }

constructor TInt64Wrapper.Create(AValue: Int64);
begin
  FValue := AValue;
end;

{ TDoubleWrapper }

constructor TDoubleWrapper.Create(AValue: Extended);
begin
  FValue := AValue;
end;

{ TBooleanWrapper }

constructor TBooleanWrapper.Create(AValue: Boolean);
begin
  FValue := AValue;
end;

{ TDateTimeWrapper }

constructor TDateTimeWrapper.Create(AValue: TDateTime);
begin
  FValue := AValue;
end;

{ _TStringHashTrie }

procedure _TStringHashTrie.Add(const S: string; Data: TObject);
begin
  AddOrSetValue(S, Data);
end;

procedure _TStringHashTrie.Add(const s : string);
begin
  AddOrSetValue(S, nil);
end;

procedure _TStringHashTrie.Delete(const S: string);
begin
  Remove(S);
end;

function _TStringHashTrie.Find(const S: string; var Data: TObject):
    Boolean;
begin
  Result := TryGetValue(S, Data);
end;

function _TStringHashTrie.Find(const s : string): Boolean;
var
  Dummy : TObject;
begin
  Result := TryGetValue(S, Dummy);
end;

procedure _TStringHashTrie.ForEachCallback(const AKey: string; const
    AValue: TObject; AUserData: Pointer);
var
  ADone : Boolean;
begin
  ADone := False;
  if assigned(FStrHashTraverseMeth) then
    FStrHashTraverseMeth(AUserData, PChar(AKey), AValue, ADone)
  else FStrHashTraverseProc(AUserData, PChar(AKey), AValue, ADone);
  if ADone then
    Abort;
end;

procedure _TStringHashTrie.Traverse(UserData: Pointer; UserProc:
    TStrHashTraverseProc);
begin
  FStrHashTraverseProc := UserProc;
  FStrHashTraverseMeth := nil;
  try
    ForEach(ForEachCallback, UserData);
  except
    on EAbort do { Ignore }
  end;
end;

procedure _TStringHashTrie.Traverse(UserData: Pointer; UserProc:
    TStrHashTraverseMeth);
begin
  FStrHashTraverseMeth := UserProc;
  FStrHashTraverseProc := nil;
  try
    ForEach(ForEachCallback, UserData);
  except
    on EAbort do { Ignore }
  end;
end;

{ _TIntegerHashTrie }

procedure _TIntegerHashTrie.Add(const n: integer; Data: TObject);
begin
  AddOrSetValue(n, Data);
end;

procedure _TIntegerHashTrie.Add(n : integer);
begin
  AddOrSetValue(n, nil);
end;

procedure _TIntegerHashTrie.Delete(n: integer);
begin
  Remove(n);
end;

function _TIntegerHashTrie.Find(n: integer; var Data: TObject): Boolean;
begin
  Result := TryGetValue(n, Data);
end;

function _TIntegerHashTrie.Find(n : integer): Boolean;
var
  Data : TObject;
begin
  Result := TryGetValue(n, Data);
end;

procedure _TIntegerHashTrie.ForEachCallback(const AKey: Integer; const AValue:
    TObject; AUserData: Pointer);
var
  ADone : Boolean;
begin
  ADone := False;
  if assigned(FIntHashTraverseMeth) then
    FIntHashTraverseMeth(AUserData, AKey, AValue, ADone)
  else FIntHashTraverseProc(AUserData, AKey, AValue, ADone);
  if ADone then
    Abort;
end;

procedure _TIntegerHashTrie.Traverse(UserData: Pointer; UserProc:
    TIntHashTraverseProc);
begin
  FIntHashTraverseProc := UserProc;
  FIntHashTraverseMeth := nil;
  try
    Foreach(ForEachCallback, UserData);
  except
    on EAbort do { ignore }
  end;
end;

procedure _TIntegerHashTrie.Traverse(UserData: Pointer; UserProc:
    TIntHashTraverseMeth);
begin
  FIntHashTraverseProc := nil;
  FIntHashTraverseMeth := UserProc;
  try
    Foreach(ForEachCallback, UserData);
  except
    on EAbort do { ignore }
  end;
end;

end.

