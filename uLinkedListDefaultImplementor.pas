unit uLinkedListDefaultImplementor;

interface

uses
  iContainers, uAllocators, uLinkedList;

type
  TLinkedList = class (TAbstractLinkedList, ILinkedList, IIterable, IDataHandler, INodeRemover)
  private
    FAllocator : TFixedBlockHeap;
    FDataHandler: IDataHandler;
    FEventSubscriber: IIterableEventSubscriber;
    FFirstNode: PLinkedNode;
    FLastNode: PLinkedNode;
    function AllocNode: PLinkedNode;
    procedure CleanNode(ANode: PLinkedNode);
    procedure DeallocNode(ANode: PLinkedNode);
    function GetDataHandler: IDataHandler;
    procedure InternalRemoveNode(ANode: PLinkedNode);
    function NewNode(APointer: Pointer): PLinkedNode; overload;
    function NewAnsiStringNode(const AAnsiString: AnsiString): PLinkedNode;
    function NewNode(AInteger: Integer): PLinkedNode; overload;
    function NewShortStringNode(const AShortString: ShortString): PLinkedNode;
    function NewNode(AInt64: Int64): PLinkedNode; overload;
    function NewNode(AExtended: Extended): PLinkedNode; overload;
    function NewNode(const ACurrency: Currency): PLinkedNode; overload;
    function NewNode(ABoolean: Boolean): PLinkedNode; overload;
    function NewNode(AAnsiChar: AnsiChar): PLinkedNode; overload;
    function NewNode(AWideChar: WideChar): PLinkedNode; overload;
    function NewWideStringNode(const AWideString: WideString): PLinkedNode;
    function NewNode(AInterface: IUnknown): PLinkedNode; overload;
    function NewNode(AObject: TObject): PLinkedNode; overload;
  protected
    function InitIterable(AtEnd: Boolean): Pointer; virtual;
    function Next(AContext: Pointer): Pointer; virtual; // IIterable
    function Prev(AContext : Pointer): Pointer; virtual;
    function GetEmpty: Boolean; virtual; // ILinkedList
    function InsertNodeInList(ANode: PLinkedNode): PLinkedNode;
    procedure INodeRemover_RemoveNode(AContext : Pointer);
    procedure INodeRemover.RemoveNode = INodeRemover_RemoveNode;
    procedure Clear; virtual; // ILinkedList
    function Insert(AInteger: Integer): PLinkedNode; overload; virtual;
    function Insert(AObject: TObject): PLinkedNode; overload; virtual;
    function InsertAnsiString(const AAnsiString: AnsiString): PLinkedNode; overload; virtual;
    function Insert(APointer: Pointer): PLinkedNode; overload; virtual;
    function InsertShortString(const AShortString: ShortString): PLinkedNode; overload; virtual;
    function Insert(const AInt64: Int64): PLinkedNode; overload; virtual;
    function Insert(const AExtended: Extended): PLinkedNode; overload; virtual;
    function Insert(const ACurrency: Currency): PLinkedNode; overload; virtual;
    function Insert(ABoolean: Boolean): PLinkedNode; overload; virtual;
    function Insert(AAnsiChar: AnsiChar): PLinkedNode; overload; virtual;
    function Insert(AWideChar: WideChar): PLinkedNode; overload; virtual;
    function InsertWideString(const AWideString: WideString): PLinkedNode; overload; virtual;
    function Insert(AInterface: IUnknown): PLinkedNode; overload; virtual;
    function Remove(APointer: Pointer): Boolean; overload; virtual;
    function Remove(AObject: TObject): Boolean; overload; virtual;
    function Remove(AInteger: Integer): Boolean; overload; virtual;
    function RemoveAnsiString(const AAnsiString: AnsiString): Boolean; overload; virtual;
    function RemoveShortString(const AShortString: ShortString): Boolean; overload; virtual;
    function Remove(const AInt64: Int64): Boolean; overload; virtual;
    function Remove(const AExtended : Extended): Boolean; overload; virtual;
    function Remove(const ACurrency : Currency): Boolean; overload; virtual;
    function Remove(ABoolean: Boolean): Boolean; overload; virtual;
    function Remove(AAnsiChar: AnsiChar): Boolean; overload; virtual;
    function Remove(AWideChar: WideChar): Boolean; overload; virtual;
    function RemoveWideString(const AWideString: WideString): Boolean; overload; virtual;
    function Remove(AInterface: IUnknown): Boolean; overload; virtual;
    procedure MoveToStartOfList(ANode : PLinkedNode); virtual;
    procedure MoveToEndOfList(ANode : PLinkedNode); virtual;
    function FirstNode: PLinkedNode; virtual;
    function GetAutoFreeObjects: Boolean;
    function LastNode: PLinkedNode; virtual;
    procedure SetAutoFreeObjects(Value: Boolean);
    procedure SetIterableEventSubscriber(ASubscriber : IIterableEventSubscriber);
    function TailableIteratorSupported: Boolean;
    property Empty: Boolean read GetEmpty; // ILinkedList
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure RemoveNode(ANode: PLinkedNode); virtual;
    property DataHandler: IDataHandler read GetDataHandler implements IDataHandler;
  end;

implementation

uses
  uContainerDataHandler, SysUtils;

resourcestring
  SCallNewLinkedListToCreateANewLin = 'Call NewLinkedList to create a new LinkedList';
  SAContextNilCallingTLinkedListNex = 'AContext = nil calling TLinkedList.Next';
  SAContextNilCallingTLinkedListPre = 'AContext = nil calling TLinkedList.Prev';

const
  NODEBLOCKS = 8;

constructor TLinkedList.Create;
begin
  inherited;
  FAllocator := TFixedBlockHeap.Create(sizeof (TLinkedNode), NODEBLOCKS);
  FDataHandler := TContainerDataHandler.Create;
end;

destructor TLinkedList.Destroy;
begin
  Clear;
  FAllocator.Free;
  inherited;
end;

procedure TLinkedList.AfterConstruction;
begin
  inherited;
  if FAllocator = nil
    then raise Exception.Create (SCallNewLinkedListToCreateANewLin);
end;

function TLinkedList.AllocNode: PLinkedNode;
begin
  if FEventSubscriber <> nil then
    FEventSubscriber.BeforeAllocNode;
  Result := FAllocator.Alloc;
  if FEventSubscriber <> nil then
    FEventSubscriber.AfterAllocNode;
  Result^.Next := nil;
  Result^.Prev := nil;
  Result^.Data.AsPointer := nil;
end;

function TLinkedList.InitIterable(AtEnd: Boolean): Pointer;
begin
  if not AtEnd
    then Result := FFirstNode
    else Result := FLastNode;
end;

procedure TLinkedList.Clear;
var
  FNextNode : PLinkedNode;
begin
  FNextNode := FFirstNode;
  while FNextNode <> nil do
    begin
      FNextNode := FNextNode^.Next;
      DeallocNode (FFirstNode);
      FFirstNode := FNextNode;
    end;
  FLastNode := nil;
end;

function TLinkedList.GetEmpty: Boolean;
begin
  Result := FFirstNode = nil;
end;

function TLinkedList.Insert(AInteger: Integer): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(AInteger));
end;

function TLinkedList.InsertAnsiString(const AAnsiString: AnsiString):
    PLinkedNode;
begin
  Result := InsertNodeInList(NewAnsiStringNode(AAnsiString));
end;

function TLinkedList.InsertNodeInList(ANode: PLinkedNode): PLinkedNode;
begin
  ANode.Prev := FLastNode;
  if FLastNode <> nil then
    FLastNode.Next := ANode;
  FLastNode := ANode;
  if FFirstNode = nil then
    FFirstNode := ANode;
  if FEventSubscriber <> nil then
    FEventSubscriber.ItemInserted(ANode);
  Result := ANode;
end;

function TLinkedList.Next(AContext: Pointer): Pointer;
begin
  if AContext = nil then
    raise EContainer.Create (SAContextNilCallingTLinkedListNex);
  Result := PLinkedNode (AContext).Next;
end;

function TLinkedList.NewNode(APointer: Pointer): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetPointer(Result, APointer);
end;

function TLinkedList.NewAnsiStringNode(const AAnsiString: AnsiString):
    PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetAnsiString(Result, AAnsiString);
end;

procedure TLinkedList.CleanNode(ANode: PLinkedNode);
begin
  FDataHandler.CleanData (ANode);
end;

procedure TLinkedList.DeallocNode(ANode: PLinkedNode);
begin
  CleanNode(ANode);
  if FEventSubscriber <> nil then
    FEventSubscriber.BeforeDeallocNode;
  Dealloc(ANode);
  if FEventSubscriber <> nil then
    FEventSubscriber.AfterDeallocNode;
end;

function TLinkedList.FirstNode: PLinkedNode;
begin
  Result := FFirstNode;
end;

function TLinkedList.GetAutoFreeObjects: Boolean;
begin
  Result := FDataHandler.AutoFreeObjects;
end;

function TLinkedList.GetDataHandler: IDataHandler;
begin
  Result := FDataHandler;
end;

procedure TLinkedList.INodeRemover_RemoveNode(AContext : Pointer);
begin
  RemoveNode(AContext);
end;

function TLinkedList.Insert(APointer: Pointer): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(APointer));
end;

function TLinkedList.InsertShortString(const AShortString: ShortString):
    PLinkedNode;
begin
  Result := InsertNodeInList(NewShortStringNode(AShortString));
end;

function TLinkedList.Insert(const AInt64: Int64): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(AInt64));
end;

function TLinkedList.Insert(const AExtended: Extended): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(AExtended));
end;

function TLinkedList.Insert(const ACurrency: Currency): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(ACurrency));
end;

function TLinkedList.Insert(ABoolean: Boolean): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(ABoolean));
end;

function TLinkedList.Insert(AAnsiChar: AnsiChar): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(AAnsiChar));
end;

function TLinkedList.Insert(AWideChar: WideChar): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(AWideChar));
end;

function TLinkedList.InsertWideString(const AWideString: WideString):
    PLinkedNode;
begin
  Result := InsertNodeInList(NewWideStringNode(AWideString));
end;

function TLinkedList.Insert(AInterface: IUnknown): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(AInterface));
end;

function TLinkedList.Insert(AObject: TObject): PLinkedNode;
begin
  Result := InsertNodeInList(NewNode(AObject));
end;

procedure TLinkedList.InternalRemoveNode(ANode: PLinkedNode);
begin
  if FEventSubscriber <> nil then
    FEventSubscriber.ItemRemoved(ANode);
  if FFirstNode = ANode then
    FFirstNode := ANode.Next;
  if FLastNode = ANode then
    FLastNode := ANode.Prev;
  if ANode.Prev <> nil then
    ANode.Prev.Next := ANode.Next;
  if ANode.Next <> nil then
    ANode.Next.Prev := ANode.Prev;
end;

function TLinkedList.LastNode: PLinkedNode;
begin
  Result := FLastNode;
end;

procedure TLinkedList.MoveToEndOfList(ANode : PLinkedNode);
begin
  if FLastNode = nil then
    raise Exception.Create ('Last node can''t be nil');
  if ANode <> FLastNode then
    begin
      InternalRemoveNode (ANode);
      ANode.Prev := FLastNode;
      FLastNode.Next := ANode;
      ANode.Next := nil;
      FLastNode := ANode;
    end;
end;

procedure TLinkedList.MoveToStartOfList(ANode : PLinkedNode);
begin
  if FFirstNode = nil then
    raise Exception.Create ('First node can''t be nil');
  if ANode <> FFirstNode then
    begin
      InternalRemoveNode (ANode);
      ANode.Next := FFirstNode;
      ANode.Prev := nil;
      FFirstNode.Prev := ANode;
      FFirstNode := ANode;
    end;
end;

function TLinkedList.NewNode(AInteger: Integer): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetInteger(Result, AInteger);
end;

function TLinkedList.NewShortStringNode(const AShortString: ShortString):
    PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetShortString(Result, AShortString);
end;

function TLinkedList.NewNode(AInt64: Int64): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetInt64(Result, AInt64);
end;

function TLinkedList.NewNode(AExtended: Extended): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetExtended(Result, AExtended);
end;

function TLinkedList.NewNode(const ACurrency: Currency): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetCurrency(Result, ACurrency);
end;

function TLinkedList.NewNode(ABoolean: Boolean): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetBoolean(Result, ABoolean);
end;

function TLinkedList.NewNode(AAnsiChar: AnsiChar): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetAnsiChar(Result, AAnsiChar);
end;

function TLinkedList.NewNode(AWideChar: WideChar): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetWideChar(Result, AWideChar);
end;

function TLinkedList.NewWideStringNode(const AWideString: WideString):
    PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetWideString(Result, AWideString);
end;

function TLinkedList.NewNode(AInterface: IUnknown): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetInterface(Result, AInterface);
end;

function TLinkedList.NewNode(AObject: TObject): PLinkedNode;
begin
  Result := AllocNode;
  FDataHandler.SetObject(Result, AObject);
end;

function TLinkedList.Prev(AContext : Pointer): Pointer;
begin
  if AContext = nil then
    raise EContainer.Create (SAContextNilCallingTLinkedListPre);
  Result := PLinkedNode (AContext).Prev;
end;

function TLinkedList.Remove(AAnsiChar: AnsiChar): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, AAnsiChar) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.RemoveAnsiString(const AAnsiString: AnsiString): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.CompareAnsiString (Context, AAnsiString) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(ABoolean: Boolean): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, ABoolean) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(const ACurrency : Currency): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, ACurrency) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(const AExtended : Extended): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, AExtended) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(AInteger: Integer): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, AInteger) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(const AInt64: Int64): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, AInt64) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(APointer: Pointer): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, APointer) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.RemoveShortString(const AShortString: ShortString): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.CompareShortString (Context, AShortString) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(AInterface: IUnknown): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, AInterface) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(AObject: TObject): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, AObject) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.RemoveWideString(const AWideString: WideString): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.CompareWideString (Context, AWideString) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

function TLinkedList.Remove(AWideChar: WideChar): Boolean;
begin
  Result := False;
  with TIterator.CreateIterator(Self) do
    while IterateForward do
      if FDataHandler.Compare (Context, AWideChar) = 0
        then
        begin
          RemoveNode (Context);
          Result := True;
          exit;
        end;
end;

procedure TLinkedList.RemoveNode(ANode: PLinkedNode);
begin
  InternalRemoveNode (ANode);
  DeallocNode (ANode);
end;

procedure TLinkedList.SetAutoFreeObjects(Value: Boolean);
begin
  FDataHandler.AutoFreeObjects := Value;
end;

procedure TLinkedList.SetIterableEventSubscriber(ASubscriber :
    IIterableEventSubscriber);
begin
  FEventSubscriber := ASubscriber;
end;

function TLinkedList.TailableIteratorSupported: Boolean;
begin
  Result := True;
end;

initialization
  LinkedListFactory.PushImplementorClass(TLinkedList);
finalization
  LinkedListFactory.RemoveImplementor(TLinkedList);
end.
