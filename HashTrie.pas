unit HashTrie;

interface

uses
  Hash_Trie, IntegerHashTrie, StringHashTrie;

type
  TStrHashTraverseProc = StringHashTrie.TStrHashTraverseProc;
  TStrHashTraverseMeth = StringHashTrie.TStrHashTraverseMeth;

  THashTrie = class
  private
    function GetAutoFreeObjects: Boolean;
    function GetRootInitialized: Boolean;
    procedure SetAutoFreeObjects(const Value: Boolean);
  protected
    FHashTrie : Hash_Trie.THashTrie;
  public
    destructor Destroy; override;
    procedure Clear;
    property AutoFreeObjects: Boolean read GetAutoFreeObjects write SetAutoFreeObjects;
    property RootInitialized: Boolean read GetRootInitialized;
  end;

  TStringHashTrie = class(THashTrie)
  private
    function GetCaseSensitive: Boolean;
    procedure Init(AHashSize: Byte; AUseHashTable: Boolean);
    procedure SetCaseSensitive(const Value: Boolean);
  public
    constructor Create; overload;
    constructor Create(AUseHashTable : Boolean); overload;
    function Add(const Key : String; Value : TObject): Boolean; overload;
    function Add(const Key: String): Boolean; overload;
    function Delete(const Key: String): Boolean;
    function Find(const Key : string; var Value : TObject): Boolean; overload;
    function Find(const Key : string): Boolean; overload;
    procedure Traverse(UserData: Pointer; UserProc: TStrHashTraverseProc); overload;
    procedure Traverse(UserData: Pointer; UserProc: TStrHashTraverseMeth); overload;
    property CaseSensitive: Boolean read GetCaseSensitive write SetCaseSensitive default False;
  end;

  TIntHashTraverseProc = IntegerHashTrie.TIntHashTraverseProc;
  TIntHashTraverseMeth = IntegerHashTrie.TIntHashTraverseMeth;

  TIntegerHashTrie = class(THashTrie)
  public
    constructor Create;
    function Add(Key : Integer; Value : TObject): Boolean; overload;
    function Add(Key : Integer): Boolean; overload;
    function Delete(Key: Integer): Boolean;
    function Find(Key: integer; var Value: TObject): Boolean; overload;
    function Find(Key: integer): Boolean; overload;
    procedure Traverse(UserData: Pointer; UserProc: TIntHashTraverseMeth); overload;
    procedure Traverse(UserData: Pointer; UserProc: TIntHashTraverseProc); overload;
  end;

function SuperFastHash(data: PAnsiChar; Len: Cardinal; AUpper: Boolean): Cardinal;

implementation

uses
  uSuperFastHash;

function SuperFastHash(data: PAnsiChar; Len: Cardinal; AUpper: Boolean): Cardinal;
begin
  Result := uSuperFastHash.SuperFastHash(data, Len, AUpper);
end;

destructor THashTrie.Destroy;
begin
  FHashTrie.Free;
  inherited;
end;

procedure THashTrie.Clear;
begin
  FHashTrie.Clear;
end;

{ THashTrie }

function THashTrie.GetAutoFreeObjects: Boolean;
begin
  Result := FHashTrie.AutoFreeValue;
end;

function THashTrie.GetRootInitialized: Boolean;
begin
  Result := FHashTrie.Count > 0;
end;

procedure THashTrie.SetAutoFreeObjects(const Value: Boolean);
begin
  FHashTrie.AutoFreeValue := Value;
end;

{ TStringHashTrie }
  
constructor TStringHashTrie.Create;
begin
  inherited Create;
  Init(16, False);
end;

constructor TStringHashTrie.Create(AUseHashTable : Boolean);
begin
  inherited Create;
  Init(20, True);
end;

function TStringHashTrie.Add(const Key : String; Value : TObject): Boolean;
begin
  Result := StringHashTrie.TStringHashTrie(FHashTrie).Add(Key, Value);
end;

function TStringHashTrie.Add(const Key: String): Boolean;
begin
  Result := StringHashTrie.TStringHashTrie(FHashTrie).Add(Key);
end;

function TStringHashTrie.Delete(const Key: String): Boolean;
begin
  Result := StringHashTrie.TStringHashTrie(FHashTrie).Remove(Key);
end;

function TStringHashTrie.Find(const Key : string; var Value : TObject): Boolean;
var
  TmpValue : Pointer;
begin
  Result := StringHashTrie.TStringHashTrie(FHashTrie).Find(Key, TmpValue);
  if Result then
    Value := TmpValue;
end;

function TStringHashTrie.Find(const Key : string): Boolean;
begin
  Result := StringHashTrie.TStringHashTrie(FHashTrie).Find(Key);
end;

function TStringHashTrie.GetCaseSensitive: Boolean;
begin
  Result := not StringHashTrie.TStringHashTrie(FHashTrie).CaseInsensitive;
end;

procedure TStringHashTrie.Init(AHashSize: Byte; AUseHashTable: Boolean);
begin
  FHashTrie := StringHashTrie.TStringHashTrie.Create(AHashSize, AUseHashTable);
  FHashTrie.AutoFreeValueMode := afmFree;
  CaseSensitive := False;
end;

procedure TStringHashTrie.SetCaseSensitive(const Value: Boolean);
begin
  StringHashTrie.TStringHashTrie(FHashTrie).CaseInsensitive := not Value;
end;

procedure TStringHashTrie.Traverse(UserData: Pointer; UserProc: TStrHashTraverseMeth);
begin
  StringHashTrie.TStringHashTrie(FHashTrie).Traverse(UserData, UserProc);
end;

procedure TStringHashTrie.Traverse(UserData: Pointer; UserProc: TStrHashTraverseProc);
begin
  StringHashTrie.TStringHashTrie(FHashTrie).Traverse(UserData, UserProc);
end;

{ TIntegerHashTrie }
  
constructor TIntegerHashTrie.Create;
begin
  inherited Create;
  FHashTrie := IntegerHashTrie.TIntegerHashTrie.Create;
  FHashTrie.AutoFreeValueMode := afmFree;
end;

function TIntegerHashTrie.Add(Key : Integer; Value : TObject): Boolean;
begin
  Result := IntegerHashTrie.TIntegerHashTrie(FHashTrie).Add(Cardinal(Key), Value);
end;

function TIntegerHashTrie.Add(Key : Integer): Boolean;
begin
  Result := IntegerHashTrie.TIntegerHashTrie(FHashTrie).Add(Cardinal(Key));
end;

function TIntegerHashTrie.Delete(Key: Integer): Boolean;
begin
  Result := IntegerHashTrie.TIntegerHashTrie(FHashTrie).Remove(Cardinal(Key));
end;

function TIntegerHashTrie.Find(Key: integer; var Value: TObject): Boolean;
var
  TmpValue : Pointer;
begin
  Result := IntegerHashTrie.TIntegerHashTrie(FHashTrie).Find(Cardinal(Key), TmpValue);
  if Result then
    Value := TmpValue;
end;

function TIntegerHashTrie.Find(Key: integer): Boolean;
begin
  Result := IntegerHashTrie.TIntegerHashTrie(FHashTrie).Find(Cardinal(Key));
end;

procedure TIntegerHashTrie.Traverse(UserData: Pointer; UserProc: TIntHashTraverseMeth);
begin
  IntegerHashTrie.TIntegerHashTrie(FHashTrie).Traverse(UserData, UserProc);
end;

procedure TIntegerHashTrie.Traverse(UserData: Pointer; UserProc: TIntHashTraverseProc);
begin
  IntegerHashTrie.TIntegerHashTrie(FHashTrie).Traverse(UserData, UserProc);
end;

end.

