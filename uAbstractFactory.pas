unit uAbstractFactory;
{.$Define UseCriticalSection}

interface

uses
  Classes, SysUtils, uECodedError, uSpinLock, SyncObjs;

const
  AF_ERROR_NOIMPLEMENTORS = 0001;
  AF_ERROR_MUSTOVERRIDECREATEOBJECT = 0002;

type
  { Prototype of Method pointer passed to PushImplementorMethodFactory should be:
    TMethodFactory = function (AOwner : TObject) : IUnknown; }
  IFactory = interface
    ['{A27E1134-7833-422B-A66E-CC3D3660B29B}']
    function CreateObject(AOwner: TObject): IUnknown;
    procedure PushImplementorClass(AClass: TClass);
    procedure PushImplementorMethodFactory(AMethod: Pointer);
    procedure RemoveImplementor(AFactoryPointer: Pointer);
  end;

  TMethodFactory = function (AOwner : TObject) : IUnknown;

  TAbstractFactory = class;
  TFactoryItem = class
  public
    function CreateObject(AFactory: TAbstractFactory; AOwner: TObject): IUnknown; virtual; abstract;
    function Match(APointer: Pointer): Boolean; virtual; abstract;
  end;

  TFactoryItemMethod = class (TFactoryItem)
  private
    FFactoryMethod : Pointer;
  public
    constructor Create(AMethod: Pointer);
    function CreateObject(AFactory: TAbstractFactory; AOwner: TObject): IUnknown; override;
    function Match(APointer: Pointer): Boolean; override;
  end;

  TFactoryByClass = class (TFactoryItem)
  private
    FImplementorClass : TClass;
  public
    constructor Create(AClass: TClass);
    function CreateObject(AFactory: TAbstractFactory; AOwner: TObject): IUnknown; override;
    function Match(APointer: Pointer): Boolean; override;
    property ImplementorClass: TClass read FImplementorClass;
  end;

  TAbstractFactory = class (TInterfacedObject, IFactory)
  private
    FFactoryItems: TList;
    {$IfDef UseCriticalSection}
    FLock : TCriticalSection;
    {$Else}
    FLock : TReadWriteSpinLock;
    {$EndIf}
    procedure DestroyFactoryItems;
    procedure LockFactoryItems;
    procedure ReadLockFactoryItems;
    procedure ReadUnlockFactoryItems;
    procedure RemoveFactoryItem(APointer: Pointer);
    procedure UnlockFactoryItems;
  protected
    function CreateObjectFromClass(AClass: TClass): IUnknown; virtual;
    procedure PushImplementorClass(AClass: TClass); virtual;
    procedure PushImplementorMethodFactory(AMethod: Pointer); virtual;
    procedure RemoveImplementor(AFactoryPointer: Pointer); virtual;
    class procedure ThrowError(AErrorCode: Integer; const AErrorMessage: String); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateObject(AOwner: TObject): IUnknown;
  end;

  EFactory = class(ECodedError)
  protected
    class function ErrorCodePrefix: String; override;
  end;

implementation

resourcestring
  SConcreteFactoryMustOverrideThisM = 'Concrete factory must override this method if planning to create objects by class';
  SNoImplementorRegisteredInThisFac = 'No implementor registered in this factory. ClassName: %s';

{ TAbstractFactory }

constructor TAbstractFactory.Create;
begin
  inherited;
  {$IfDef UseCriticalSection}
  FLock := TCriticalSection.Create;
  {$Else}
  FLock := TReadWriteSpinLock.Create;
  {$EndIf}
  FFactoryItems := TList.Create;
end;

destructor TAbstractFactory.Destroy;
begin
  LockFactoryItems;
  try
    DestroyFactoryItems;
    FFactoryItems.Free;
  finally
    UnlockFactoryItems;
  end;
  FLock.Free;
  inherited;
end;

function TAbstractFactory.CreateObject(AOwner: TObject): IUnknown;
begin
  ReadLockFactoryItems;
  try
    if FFactoryItems.Count <= 0 then
      ThrowError (AF_ERROR_NOIMPLEMENTORS, Format(SNoImplementorRegisteredInThisFac,[classname]));
    Result := TFactoryItem (FFactoryItems.Last).CreateObject (Self, AOwner);
  finally
    ReadUnlockFactoryItems;
  end;
end;

function TAbstractFactory.CreateObjectFromClass(AClass: TClass): IUnknown;
begin
  ThrowError (AF_ERROR_MUSTOVERRIDECREATEOBJECT, SConcreteFactoryMustOverrideThisM);
end;

procedure TAbstractFactory.PushImplementorClass(AClass: TClass);
begin
  LockFactoryItems;
  try
    FFactoryItems.Add(TFactoryByClass.Create (AClass))
  finally
    UnlockFactoryItems;
  end;
end;

procedure TAbstractFactory.PushImplementorMethodFactory(AMethod: Pointer);
begin
  LockFactoryItems;
  try
    FFactoryItems.Add(TFactoryItemMethod.Create (AMethod))
  finally
    UnlockFactoryItems;
  end;
end;

procedure TAbstractFactory.RemoveImplementor(AFactoryPointer: Pointer);
begin
  RemoveFactoryItem(AFactoryPointer);
end;

procedure TAbstractFactory.DestroyFactoryItems;
var
  i : integer;
begin
  for i := 0 to FFactoryItems.Count - 1 do
    TFactoryItem (FFactoryItems[i]).Free;
end;

procedure TAbstractFactory.RemoveFactoryItem(APointer: Pointer);
var
  i : integer;
begin
  LockFactoryItems;
  try
    for I := 0 to FFactoryItems.Count - 1 do
      if TFactoryItem (FFactoryItems[i]).Match (APointer) then
        begin
          TFactoryItem (FFactoryItems[i]).Free;
          FFactoryItems.Delete (i);
          exit;
        end;
  finally
    UnlockFactoryItems;
  end;
end;

procedure TAbstractFactory.ReadLockFactoryItems;
begin
  {$IfDef UseCriticalSection}
  FLock.Enter;
  {$Else}
  FLock.ReadLock;
  {$EndIf}
end;

procedure TAbstractFactory.ReadUnlockFactoryItems;
begin
  {$IfDef UseCriticalSection}
  FLock.Leave;
  {$Else}
  FLock.ReadUnlock;
  {$EndIf}
end;

procedure TAbstractFactory.LockFactoryItems;
begin
  {$IfDef UseCriticalSection}
  FLock.Enter;
  {$Else}
  FLock.Lock;
  {$EndIf}
end;

procedure TAbstractFactory.UnlockFactoryItems;
begin
  {$IfDef UseCriticalSection}
  FLock.Leave;
  {$Else}
  FLock.Unlock;
  {$EndIf}
end;

class procedure TAbstractFactory.ThrowError(AErrorCode: Integer; const
    AErrorMessage: String);
begin
  raise EFactory.Create (AErrorCode, AErrorMessage);
end;

{ TFactoryItemMethod }

constructor TFactoryItemMethod.Create(AMethod: Pointer);
begin
  inherited Create;
  FFactoryMethod := AMethod;
end;

function TFactoryItemMethod.CreateObject(AFactory: TAbstractFactory; AOwner:
    TObject): IUnknown;
begin
  Result := TMethodFactory (FFactoryMethod)(AOwner);
end;

function TFactoryItemMethod.Match(APointer: Pointer): Boolean;
begin
  Result := FFactoryMethod = APointer;
end;

{ TFactoryByClass }

constructor TFactoryByClass.Create(AClass: TClass);
begin
  inherited Create;
  FImplementorClass := AClass;
end;

function TFactoryByClass.CreateObject(AFactory: TAbstractFactory; AOwner:
    TObject): IUnknown;
begin
  Result := AFactory.CreateObjectFromClass (FImplementorClass);
end;

function TFactoryByClass.Match(APointer: Pointer): Boolean;
begin
  Result := FImplementorClass = APointer; 
end;

{ EFactory }

class function EFactory.ErrorCodePrefix: String;
begin
  Result := 'AF';
end;

end.


