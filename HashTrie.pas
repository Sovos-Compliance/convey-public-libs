unit HashTrie;

interface

uses
  IntegerHashTrie, StringHashTrie;

type
  TStrHashTraverseProc = StringHashTrie.TStrHashTraverseProc;
  TStrHashTraverseMeth = StringHashTrie.TStrHashTraverseMeth;

  TStringHashTrie = class(StringHashTrie.TStringHashTrie)
  private
    function GetAutoFreeObjects: Boolean;
    function GetCaseSensitive: Boolean;
    function GetRootInitialized: Boolean;
    procedure SetAutoFreeObjects(const Value: Boolean);
    procedure SetCaseSensitive(const Value: Boolean);
  public
    constructor Create;
    function Add(const Key : String): Boolean; overload;
    function Add(const Key : String; Value : TObject): Boolean; overload;
    function Delete(const Key: String): Boolean;
    function Find(const Key : string): Boolean; overload;
    function Find(const Key : string; var Value : TObject): Boolean; overload;
    procedure Clear;
    property AutoFreeObjects: Boolean read GetAutoFreeObjects write SetAutoFreeObjects;
    property CaseSensitive: Boolean read GetCaseSensitive write SetCaseSensitive default False;
    property RootInitialized: Boolean read GetRootInitialized;
  end;

  TIntHashTraverseProc = IntegerHashTrie.TIntHashTraverseProc;
  TIntHashTraverseMeth = IntegerHashTrie.TIntHashTraverseMeth;

  TIntegerHashTrie = class(IntegerHashTrie.TIntegerHashTrie)
  private
    function GetAutoFreeObjects: Boolean;
    function GetRootInitialized: Boolean;
    procedure SetAutoFreeObjects(const Value: Boolean);
  public
    constructor Create;
    function Add(Key : Integer): Boolean; overload;
    function Add(Key : Integer; Value : TObject): Boolean; overload;
    procedure Clear;
    function Delete(Key: Integer): Boolean;
    function Find(Key: integer): Boolean; overload;
    function Find(Key: integer; var Value: TObject): Boolean; overload;
    property AutoFreeObjects: Boolean read GetAutoFreeObjects write SetAutoFreeObjects;
    property RootInitialized: Boolean read GetRootInitialized;
  end;

function SuperFastHash(data: PAnsiChar; Len: Cardinal; AUpper: Boolean): Cardinal;

implementation

uses
  Hash_Trie, uSuperFastHash;

function SuperFastHash(data: PAnsiChar; Len: Cardinal; AUpper: Boolean): Cardinal;
begin
  Result := uSuperFastHash.SuperFastHash(data, Len, AUpper);
end;

{ TStringHashTrie }
  
constructor TStringHashTrie.Create;
begin
  inherited Create;
  AutoFreeValueMode := afmFree;
  DuplicatesMode := dmAllowed;
  CaseSensitive := False;
end;

function TStringHashTrie.Add(const Key : String): Boolean;
begin
  Result := inherited Add(Key, nil);
end;

function TStringHashTrie.Add(const Key : String; Value : TObject): Boolean;
begin
  Result := inherited Add(Key, Value);
end;

procedure TStringHashTrie.Clear;
begin
  inherited Clear;
end;

function TStringHashTrie.Delete(const Key: String): Boolean;
begin
  Result := Remove(Key);
end;

function TStringHashTrie.Find(const Key : string): Boolean;
var
  Dummy : Pointer;
begin
  Result := inherited Find(Key, Dummy);
end;

function TStringHashTrie.Find(const Key : string; var Value : TObject): Boolean;
var
  TmpValue : Pointer;
begin
  Result := inherited Find(Key, TmpValue);
  if Result then
    Value := TmpValue;
end;

function TStringHashTrie.GetAutoFreeObjects: Boolean;
begin
  Result := AutoFreeValue;
end;

function TStringHashTrie.GetCaseSensitive: Boolean;
begin
  Result := not CaseInsensitive;
end;

function TStringHashTrie.GetRootInitialized: Boolean;
begin
  Result := Count > 0;
end;

procedure TStringHashTrie.SetAutoFreeObjects(const Value: Boolean);
begin
  AutoFreeValue := Value;
end;

procedure TStringHashTrie.SetCaseSensitive(const Value: Boolean);
begin
  CaseInsensitive := not Value;
end;

{ TIntegerHashTrie }
  
constructor TIntegerHashTrie.Create;
begin
  inherited Create;
  AutoFreeValueMode := afmFree;
  DuplicatesMode := dmAllowed;
end;

function TIntegerHashTrie.Add(Key : Integer): Boolean;
begin
  Result := inherited Add(Cardinal(Key), nil);
end;

function TIntegerHashTrie.Add(Key : Integer; Value : TObject): Boolean;
begin
  Result := inherited Add(Cardinal(Key), Value);
end;

procedure TIntegerHashTrie.Clear;
begin
  inherited Clear;
end;

function TIntegerHashTrie.Delete(Key: Integer): Boolean;
begin
  Result := Remove(Cardinal(Key));
end;

function TIntegerHashTrie.Find(Key: integer): Boolean;
var
  Dummy : Pointer;
begin
  Result := inherited Find(Cardinal(Key), Dummy);
end;

function TIntegerHashTrie.Find(Key: integer; var Value: TObject): Boolean;
var
  TmpValue : Pointer;
begin
  Result := inherited Find(Cardinal(Key), TmpValue);
  if Result then
    Value := TmpValue;
end;

function TIntegerHashTrie.GetAutoFreeObjects: Boolean;
begin
  Result := AutoFreeValue;
end;

function TIntegerHashTrie.GetRootInitialized: Boolean;
begin
  Result := Count > 0;
end;

procedure TIntegerHashTrie.SetAutoFreeObjects(const Value: Boolean);
begin
  AutoFreeValue := Value;
end;

end.

