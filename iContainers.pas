unit iContainers;

interface

uses
  SysUtils, SyncObjs, uSpinLock;

type
  EContainer = class (Exception);

  IIterableEventSubscriber = interface
    ['{2C526546-79F5-4E19-BCB7-405ACD87FD89}']
    procedure ItemInserted(AContext : Pointer);
    procedure ItemRemoved(AContext : Pointer);
    procedure BeforeAllocNode;
    procedure AfterAllocNode;
    procedure BeforeDeallocNode;
    procedure AfterDeallocNode;
  end;

  IDataHandler = interface
    ['{209E1887-3EF9-46D1-AD77-61136CE4DC67}']
    procedure CleanData(AContext: Pointer);
    function GetAsAnsiChar(AContext: Pointer): AnsiChar;
    function GetAsPointer(AContext: Pointer): Pointer;
    function GetAsObject(AContext: Pointer): TObject;
    function GetAsAnsiString(AContext: Pointer): AnsiString;
    function GetAsBoolean(AContext: Pointer): Boolean;
    function GetAsCurrency(AContext: Pointer): Currency;
    function GetAsExtended(AContext: Pointer): Extended;
    function GetAsInt64(AContext: Pointer): Int64;
    function GetAsInteger(AContext: Pointer): integer;
    function GetAsInterface(AContext: Pointer): IUnknown;
    function GetAsShortString(AContext: Pointer): ShortString;
    function GetAsWideChar(AContext: Pointer): WideChar;
    function GetAsWideString(AContext: Pointer): WideString;
    function GetType(AContext: Pointer): Byte;
    procedure SetAnsiChar(AContext: Pointer; Value : AnsiChar);
    procedure SetAnsiString(AContext: Pointer; const Value : AnsiString);
    procedure SetBoolean(AContext: Pointer; Value : Boolean);
    procedure SetCurrency(AContext: Pointer; const Value : Currency);
    procedure SetExtended(AContext: Pointer; const Value : Extended);
    procedure SetInt64(AContext: Pointer; const Value : Int64);
    procedure SetInteger(AContext: Pointer; Value : integer);
    procedure SetInterface(AContext: Pointer; Value : IUnknown);
    procedure SetObject(AContext: Pointer; Value : TObject);
    procedure SetPointer(AContext: Pointer; Value : Pointer);
    procedure SetShortString(AContext: Pointer; const Value : ShortString);
    procedure SetWideChar(AContext: Pointer; Value : WideChar);
    procedure SetWideString(AContext: Pointer; const Value : WideString);
    function Compare(AContext : Pointer; Value : integer) : integer; overload;
    function Compare(AContext : Pointer; Value : Pointer) : integer; overload;
    function Compare(AContext : Pointer; Value : TObject) : integer; overload;
    function Compare(AContext : Pointer; Value : AnsiChar) : integer; overload;
    function Compare(AContext : Pointer; Value : Boolean) : integer; overload;
    function Compare(AContext : Pointer; const Value : Currency) : integer; overload;
    function Compare(AContext : Pointer; const Value : Extended) : integer; overload;
    function Compare(AContext : Pointer; const Value : Int64) : integer; overload;
    function Compare(AContext : Pointer; Value : IUnknown) : integer; overload;
    function Compare(AContext : Pointer; Value : WideChar) : integer; overload;
    function CompareAnsiString(AContext : Pointer; const Value : AnsiString) : integer;
    function CompareShortString(AContext : Pointer; const Value : ShortString) : integer;
    function CompareWideString(AContext : Pointer; const Value : WideString) : integer;
    function GetAutoFreeObjects: Boolean;
    procedure SetAutoFreeObjects(Value: Boolean);
    property AutoFreeObjects: Boolean read GetAutoFreeObjects write SetAutoFreeObjects; // Default False
  end;

  IIterator = interface
    ['{BE2A2C47-2BB7-4BD9-B2DA-4F3F728B7A89}']
    function IterateForward : boolean;
    function IterateBackwards : boolean;
    function Context : Pointer;
    function GetAsInteger : integer;
    function GetAsPointer : Pointer;
    function GetAsObject : TObject;
    function GetAsAnsiString : AnsiString;
    function GetAsShortString : ShortString;
    function GetAsExtended : Extended;
    function GetAsCurrency : Currency;
    function GetAsInt64 : Int64;
    function GetAsWideString : WideString;
    function GetAsInterface : IUnknown;
    function GetAsBoolean : Boolean;
    function GetAsAnsiChar : AnsiChar;
    function GetAsWideChar : WideChar;
    function GetType: Byte;
    procedure RemoveCurrentNode;
  end;

  IListExhaustedEventSubscriber = interface
    ['{847789BE-3B13-4E33-8516-29313076C620}']
    procedure ListExhausted;
  end;

const
  TAILABLEITERATOR_INFINITENODECOUNT = 0;

type
  TTailableIteratorStatus = (tisNotInitialized, tisReturnedData, tisTimedout, tisExhausted, tisLostContext);
  ITailableIterator = interface(IIterator)
    ['{FC068A4B-C3CD-429A-BA3F-CF35BCF21ABA}']
    function IterateForward(Timeout : Cardinal) : boolean; overload;
    function Status : TTailableIteratorStatus;
    function GetAutoRemoveNodes: Boolean;
    function GetMaxNodesWindowCount: Cardinal;
    function GetNodeWindowCount: Cardinal;
    procedure SetAutoRemoveNodes(Value: Boolean);
    procedure SetMaxNodesWindowCount(Value: Cardinal);
    procedure ReleaseMaxNodesLimiter; // IMPORTANT to call this when using MaxNodesWindowCount. A secondary thread filling the linked
                                      // list will remain stopped while waiting for items to be read if the operation is aborted
                                      // before the elements producer is done inserting into the list
    property AutoRemoveNodes: Boolean read GetAutoRemoveNodes write SetAutoRemoveNodes; // Default False
    property MaxNodesWindowCount: Cardinal read GetMaxNodesWindowCount write SetMaxNodesWindowCount; // Default TAILABLEITERATOR_INFINITENODECOUNT;
    property NodeWindowCount: Cardinal read GetNodeWindowCount;
  end;

  IIterable = interface
    ['{00FCCA03-49F0-4BFA-B0D7-C2C607162B8B}']
    function InitIterable(AtEnd: Boolean): Pointer;
    function Next(AContext: Pointer): Pointer;
    function Prev(AContext : Pointer) : Pointer;
    function TailableIteratorSupported : Boolean;
    procedure SetIterableEventSubscriber(ASubscriber : IIterableEventSubscriber);
  end;

  INodeRemover = interface
    ['{2F4B0ECF-9CAF-42B4-8B8C-820A602A3DB3}']
    procedure RemoveNode(AContext : Pointer);
  end;

  TIterator = class (TInterfacedObject, IIterator)
  private
    FIteratingForward: Boolean;
    procedure CheckContext;
  protected
    FIterable : IIterable;
    FDataHandler : IDataHandler;
    FContext : Pointer;
    constructor Create(AIterable: IIterable); virtual;
    function Context: Pointer; virtual;
    function GetAsAnsiChar: AnsiChar; virtual;
    function GetAsPointer: Pointer; virtual;
    function GetAsAnsiString: AnsiString; virtual;
    function GetAsBoolean: Boolean; virtual;
    function GetAsCurrency: Currency; virtual;
    function GetAsExtended: Extended; virtual;
    function GetAsInt64: Int64; virtual;
    function GetAsInteger: integer; virtual;
    function GetAsInterface: IUnknown; virtual;
    function GetAsObject: TObject; virtual;
    function GetAsShortString: ShortString; virtual;
    function GetAsWideChar: WideChar; virtual;
    function GetAsWideString: WideString; virtual;
    function GetType: Byte; virtual;
    function IterateForward: boolean; virtual;
    function IterateBackwards: boolean; virtual;
    procedure RemoveCurrentNode; virtual;
  public
    class function CreateIterator(AIterable: IIterable): IIterator;
  end;

  TTailableIterator = class(TIterator,
                            IUnknown, // We need this to detect when refcount = 1 to unlink from list
                            ITailableIterator,
                            IIterableEventSubscriber,
                            IListExhaustedEventSubscriber)
  private
    FListActionEvent: TEvent;
    FStatus: TTailableIteratorStatus;
    FLock, FNodeAllocatorLock : TSpinLock;
    FAutoRemoveNodes : Boolean;
    FBackupContext : Pointer;
    FIterationThreadID: Cardinal;
    FMaxNodesWindowCount: Cardinal;
    FNodeRemover : INodeRemover;
    FNodeWindowCount : Cardinal;
    FOpenInsertGateEvent: TEvent;
    FReadAfterExhausted: Boolean;
    procedure Lock;
    procedure Unlock;
    procedure BackupContext;
    procedure CheckForLostContext;
    procedure FailedIterationPostActions;
    procedure CheckPreviousNodeAutoRemove;
    procedure CheckStatusNotInitialized;
    function InheritedIterateForward: Boolean;
    procedure InitOpenInsertGateEvent;
    procedure CheckOpenInsertGate(AForceReleasingWait: Boolean = False);
    procedure SetStatus(AStatus: TTailableIteratorStatus);
    procedure SuccesfulIterationPostActions;
    procedure UnlinkFromIterable;
  protected
    procedure AfterAllocNode;
    procedure AfterDeallocNode;
    procedure BeforeAllocNode;
    procedure BeforeDeallocNode;
    function GetAutoRemoveNodes: Boolean;
    procedure SetAutoRemoveNodes(Value: Boolean);
    function GetMaxNodesWindowCount: Cardinal;
    function GetNodeWindowCount: Cardinal;
    procedure SetMaxNodesWindowCount(Value: Cardinal);
    procedure ListExhausted; virtual;
    procedure ItemInserted(AContext : Pointer); virtual;
    procedure ItemRemoved(AContext : Pointer); virtual;
    function IterateBackwards: boolean; override;
    function IterateForward(ATimeout : Cardinal): boolean; reintroduce; overload; virtual;
    function IterateForward: boolean; overload; override;
    procedure ReleaseMaxNodesLimiter;
    function Status: TTailableIteratorStatus;
    function _Release: Integer; stdcall;
  public
    constructor Create(AIterable: IIterable); override;
    destructor Destroy; override;
  end;

function NewIterator(AIterable: IIterable): IIterator;
function NewTailableIterator(AIterable: IIterable): ITailableIterator;

implementation
uses
  Windows;

{$IFNDEF DELPHIXE2}
const
  S_OK = 0;
  INFINITE = Cardinal($FFFFFFFF);
{$ENDIF}

// START resource string wizard section
resourcestring
  SINodeRemovedNotSupportedByIterable = 'INodeRemoved not supported by iterable';
  SCanTCreateAnIteratorPointingToNilList = 'Can''t create an Iterator pointing to nil list';
  STailableIteratorsNotSupportedByContainer = 'Tailable iterators not supported by container';
  SIterateBackwardsNotSupportedByTailableIterator = 'IterateBackwards not supported by Tailable Iterator';
  SErrorSettingAutoRemoveNodes = 'Can''t set AutoRemoveNodes to False if MaxNodesWindowCount > 1';
  SMaxNodesWindowCountRequiresAutoRemoveNodes = 'AutoRemoveNodes must be true when attempting to set MaxNodesWindowCount > 1';
  SMaxNodesWindowCountSetError = 'MaxNodesWindowCount must be 0 or higher than 1';
  SInternalErrorWaitingForListActionEvent = 'Internal error waiting for list action event';
  SAIterableMustImplementIDataHandl = 'AIterable must implement IDataHandler interface';
  SFContextNilCallingTIteratorGetAs = 'FContext = nil calling TIterator.GetAsPointer';
  SLostIterationContextDueToRemoveOfTail = 'Lost iteration context due to remove of tail';
// END resource string wizard section

const
  kernel32  = 'kernel32.dll';

{$IFNDEF WIN64}
function InterlockedIncrement(var Addend: Integer): Integer; stdcall; external kernel32 name 'InterlockedIncrement';
function InterlockedDecrement(var Addend: Integer): Integer; stdcall; external kernel32 name 'InterlockedDecrement';
{$ELSE}
{ This include to work requires the following entry on the path of the project: $(BDS)\source\ }
{$I \rtl\sys\InterlockedAPIs.inc}
{$ENDIF}
type
  DWORD = LongWord;

function GetCurrentThreadId: DWORD; stdcall; external kernel32 name 'GetCurrentThreadId';

function NewIterator(AIterable: IIterable): IIterator;
begin
  Result := TIterator.Create (AIterable);
end;

function NewTailableIterator(AIterable: IIterable): ITailableIterator;
begin
  Result := TTailableIterator.Create(AIterable);
end;

{ TIterator }

constructor TIterator.Create(AIterable: IIterable);
begin
  inherited Create;
  if AIterable = nil then
    raise EContainer.Create(SCanTCreateAnIteratorPointingToNilList);
  FIterable := AIterable;
  if FIterable.QueryInterface (IDataHandler, FDataHandler) <> S_OK
    then raise EContainer.Create (SAIterableMustImplementIDataHandl);
end;

procedure TIterator.CheckContext;
begin
  if FContext = nil then
    raise EContainer.Create (SFContextNilCallingTIteratorGetAs);
end;

function TIterator.Context: Pointer;
begin
  Result := FContext;
end;

class function TIterator.CreateIterator(AIterable: IIterable): IIterator;
begin
  Result := Self.Create (AIterable);
end;

function TIterator.GetAsAnsiChar: AnsiChar;
begin
  CheckContext;
  Result := FDataHandler.GetAsAnsiChar(FContext);
end;

function TIterator.GetAsAnsiString: AnsiString;
begin
  CheckContext;
  Result := FDataHandler.GetAsAnsiString(FContext);
end;

function TIterator.GetAsBoolean: Boolean;
begin
  CheckContext;
  Result := FDataHandler.GetAsBoolean(FContext);
end;

function TIterator.GetAsCurrency: Currency;
begin
  CheckContext;
  Result := FDataHandler.GetAsCurrency(FContext);
end;

function TIterator.GetAsExtended: Extended;
begin
  CheckContext;
  Result := FDataHandler.GetAsExtended(FContext);
end;

function TIterator.GetAsInt64: Int64;
begin
  CheckContext;
  Result := FDataHandler.GetAsInt64(FContext);
end;

function TIterator.GetAsInteger: integer;
begin
  CheckContext;
  Result := FDataHandler.GetAsInteger(FContext);
end;

function TIterator.GetAsInterface: IUnknown;
begin
  CheckContext;
  Result := FDataHandler.GetAsInterface(FContext);
end;

function TIterator.GetAsPointer: Pointer;
begin
  CheckContext;
  Result := FDataHandler.GetAsPointer(FContext);
end;

function TIterator.GetAsObject: TObject;
begin
  CheckContext;
  Result := FDataHandler.GetAsObject(FContext);
end;

function TIterator.GetAsShortString: ShortString;
begin
  CheckContext;
  Result := FDataHandler.GetAsShortString(FContext);
end;

function TIterator.GetAsWideChar: WideChar;
begin
  CheckContext;
  Result := FDataHandler.GetAsWideChar(FContext);
end;

function TIterator.GetAsWideString: WideString;
begin
  CheckContext;
  Result := FDataHandler.GetAsWideString(FContext);
end;

function TIterator.GetType: Byte;
begin
  CheckContext;
  Result := FDataHandler.GetType (FContext);
end;

function TIterator.IterateForward: boolean;
begin
  if FContext = nil
    then FContext := FIterable.InitIterable (False)
    else FContext := FIterable.Next(FContext);
  Result := FContext <> nil;
  FIteratingForward := True;
end;

function TIterator.IterateBackwards: boolean;
begin
  if FContext = nil
    then FContext := FIterable.InitIterable (True)
    else FContext := FIterable.Prev(FContext);
  Result := FContext <> nil;
  FIteratingForward := False;
end;

procedure TIterator.RemoveCurrentNode;
var
  ANextContext : Pointer;
  NodeRemover : INodeRemover;
begin
  CheckContext;
  if FIterable.QueryInterface(INodeRemover, NodeRemover) <> S_OK then
    raise Exception.Create(SINodeRemovedNotSupportedByIterable);
  if FIteratingForward then
      ANextContext := FIterable.Prev(FContext)
    else ANextContext := FIterable.Next(FContext);
  NodeRemover.RemoveNode(FContext);
  FContext := ANextContext;
end;

{ TTailableIterator }

constructor TTailableIterator.Create(AIterable: IIterable);
begin
  inherited;
  if not AIterable.TailableIteratorSupported then
    raise EContainer.Create(STailableIteratorsNotSupportedByContainer);
  FListActionEvent := TEvent.Create({ EventAttributes} nil,
                                    { ManualReset } True,
                                    { InitialState } False,
                                    { Name } '');
  FLock := TSpinLock.Create;
  FNodeAllocatorLock := TSpinLock.Create;
  FLock.SupportReentrantLocks := False; // This will improve performance of spinlocks by avoiding calls to GetCurrentThreadId but
                                        // we have to be careful not to have reentrant Lock calls in our code or we will cause a spinning deadlock
  FNodeAllocatorLock.SupportReentrantLocks := False;                                      
  AIterable.SetIterableEventSubscriber(Self);
  FIterable.QueryInterface(INodeRemover, FNodeRemover);
  FStatus := tisNotInitialized;
end;

destructor TTailableIterator.Destroy;
begin
  UnlinkFromIterable;  
  ReleaseMaxNodesLimiter;
  FreeAndNil(FListActionEvent);
  FreeAndNil(FLock);
  FreeAndNil(FNodeAllocatorLock);
  inherited;
end;

procedure TTailableIterator.AfterAllocNode;
begin
  FNodeAllocatorLock.Unlock;
end;

procedure TTailableIterator.AfterDeallocNode;
begin
  FNodeAllocatorLock.Unlock;
end;

procedure TTailableIterator.BeforeAllocNode;
begin
  FNodeAllocatorLock.Lock;
end;

procedure TTailableIterator.BeforeDeallocNode;
begin
  FNodeAllocatorLock.Lock;
end;

procedure TTailableIterator.Lock;
begin
  FLock.Enter;
end;

procedure TTailableIterator.Unlock;
begin
  FLock.Leave;
end;

procedure TTailableIterator.SetAutoRemoveNodes(Value: Boolean);
begin
  if FAutoRemoveNodes = Value then
    exit;
  if (not Value) and (FMaxNodesWindowCount <> TAILABLEITERATOR_INFINITENODECOUNT) then
    raise EContainer.Create(SErrorSettingAutoRemoveNodes);
  FAutoRemoveNodes := Value;
end;

function TTailableIterator.GetAutoRemoveNodes: Boolean;
begin
  Result := FAutoRemoveNodes;
end;

procedure TTailableIterator.BackupContext;
begin
  FBackupContext := FContext;
end;

procedure TTailableIterator.FailedIterationPostActions;
begin
  FContext := FBackupContext;
  FListActionEvent.ResetEvent;
  CheckOpenInsertGate(True);
end;

procedure TTailableIterator.CheckPreviousNodeAutoRemove;
begin
  if FAutoRemoveNodes and
     (FBackupContext <> nil) and
     (FNodeRemover <> nil) and
     (FBackupContext <> FContext) then
    begin
      FNodeRemover.RemoveNode(FBackupContext);
      FBackupContext := nil;
    end;
end;

function TTailableIterator.InheritedIterateForward: Boolean;
begin
  // We will enclose the following code on try..finally because CheckForLostContext can raise an exception
  // and we have to ensure we call Unlock
  Lock;
  try
    CheckForLostContext;
    if FStatus = tisExhausted then
      begin
        if (FContext = nil) and FReadAfterExhausted then
          begin
            Result := False;
            exit;
          end;
        FReadAfterExhausted := True;
      end;
    BackupContext;
    Result := inherited IterateForward;
    if Result then
      SuccesfulIterationPostActions
    else if FStatus in [tisReturnedData] then
      FailedIterationPostActions
  finally
    Unlock;
  end;
end;

procedure TTailableIterator.SuccesfulIterationPostActions;
begin  
  CheckPreviousNodeAutoRemove;
  CheckOpenInsertGate;
end;

function TTailableIterator.Status: TTailableIteratorStatus;
begin
  Result := FStatus;
end;

procedure TTailableIterator.ListExhausted;
begin
  if FStatus <> tisTimedout then
    begin
      Lock;
      SetStatus(tisExhausted);      
      Unlock;
    end;  
  FListActionEvent.SetEvent;    
end;

procedure TTailableIterator.CheckForLostContext;
begin
  if FStatus = tisLostContext then
    raise EContainer.Create(SLostIterationContextDueToRemoveOfTail);
end;

procedure TTailableIterator.CheckStatusNotInitialized;
begin
  if FStatus = tisNotInitialized then
    begin
      Lock;
      SetStatus(tisReturnedData);
      Unlock;
    end;
end;

function TTailableIterator.GetMaxNodesWindowCount: Cardinal;
begin
  Result := FMaxNodesWindowCount;
end;

function TTailableIterator.GetNodeWindowCount: Cardinal;
begin
  Result := FNodeWindowCount;
end;

procedure TTailableIterator.InitOpenInsertGateEvent;
begin
  if FOpenInsertGateEvent <> nil then
    exit;
  FOpenInsertGateEvent := TEvent.Create({ EventAttributes } nil,
                                        { ManualReset } False,
                                        { InitialState } True,
                                        { Name } '');
end;

procedure TTailableIterator.ItemInserted(AContext : Pointer);
var
  ANodeCount : Cardinal;
begin
  ANodeCount := Cardinal(InterlockedIncrement(integer(FNodeWindowCount)));
  FListActionEvent.SetEvent;
  if (FOpenInsertGateEvent <> nil) and (ANodeCount + 1 >= FMaxNodesWindowCount) and 
     (not (FStatus in [tisExhausted, tisTimedout])) then
    FOpenInsertGateEvent.WaitFor(INFINITE);
end;

procedure TTailableIterator.ItemRemoved(AContext : Pointer);
begin
  InterlockedDecrement(integer(FNodeWindowCount));
  if FIterationThreadID = GetCurrentThreadId then
    exit;
  Lock;
  try
    if AContext <> FContext then
      exit;
    FContext := nil; 
    SetStatus(tisLostContext);
  finally
    Unlock;
  end;
  FListActionEvent.SetEvent;
end;

function TTailableIterator.IterateBackwards: boolean;
begin
  raise EContainer.Create(SIterateBackwardsNotSupportedByTailableIterator);
end;

function TTailableIterator.IterateForward(ATimeout : Cardinal): boolean; 
const
  MaxLoopsNeeded = 3; // <- Read comment bellow on the reason why the value of this constant
var
  LoopCount : integer;
  MaxLoopsReached : Boolean;
begin
  if ATimeout <> INFINITE then
    ATimeout := ATimeout div MaxLoopsNeeded;
  FIterationThreadID := GetCurrentThreadId;
  CheckStatusNotInitialized; 
  LoopCount := 0;
  (* the following code can be argued it's "goofy". Why three loops???
     Two loops are the minimum needed, because there will be scenarios where on the first
     loop there will be no more available data, and the iterator is going to put to sleep
     using FListActionEvent event.
     The third loop is the tricky one, it's needed because there's situation where
     TTailableIterator.ItemInserted is called to notify the iterator about a fresh insertion when
     in between the actual insertion (that happend as part of the linkedlist code) and the time
     FListActionEvent.SetEvent is called, the contents of the list can be exhausted by the reading thread
     the thread put to sleep entering its second loop and be awaken then again failing to read any data.
     In this case we let the iterator loop thru one more time and wait for another "awake" event *)
  repeat    
    Result := False;
    inc(LoopCount);
    MaxLoopsReached := LoopCount >= MaxLoopsNeeded; 
    CheckOpenInsertGate;
    case FListActionEvent.WaitFor(ATimeout) of
      wrTimeout : if MaxLoopsReached then                  
        begin
          Lock;
          SetStatus(tisTimedout);
          Unlock;
          break;
        end
        else continue;
      wrSignaled : Result := InheritedIterateForward;
      else raise EContainer.Create(SInternalErrorWaitingForListActionEvent);
    end;
  until Result or MaxLoopsReached;
end;

function TTailableIterator.IterateForward: boolean;
begin
  Result := IterateForward(INFINITE);
end;

procedure TTailableIterator.CheckOpenInsertGate(AForceReleasingWait: Boolean =
    False);
begin
  if FOpenInsertGateEvent = nil then
    exit;
  // The wait here to get to half a way the limit of FMaxNodesWindowCount makes the list
  // inserter more efficient because reduces the context changing between threads
  // With a synthetic test that inserts 1 million integers and reads them from another thread
  // The performance gain was in average 5% of total time consumed to run the job if this logic didn't exist
  if AForceReleasingWait or (FNodeWindowCount < FMaxNodesWindowCount div 2 + 1) then    
    FOpenInsertGateEvent.SetEvent;
end;

procedure TTailableIterator.ReleaseMaxNodesLimiter;
begin
  if FOpenInsertGateEvent = nil then
    exit;
  ListExhausted;  
  FOpenInsertGateEvent.SetEvent;
  FreeAndNil(FOpenInsertGateEvent);
end;

procedure TTailableIterator.SetMaxNodesWindowCount(Value: Cardinal);
begin
  if Value = 1 then
    raise EContainer.Create(SMaxNodesWindowCountSetError);
  if Value = FMaxNodesWindowCount then
    exit;
  if (Value <> TAILABLEITERATOR_INFINITENODECOUNT) and (not FAutoRemoveNodes) then
    raise EContainer.Create(SMaxNodesWindowCountRequiresAutoRemoveNodes);
  FMaxNodesWindowCount := Value;
  if (Value <> TAILABLEITERATOR_INFINITENODECOUNT) and (FOpenInsertGateEvent = nil) then
    InitOpenInsertGateEvent
  else if (Value = TAILABLEITERATOR_INFINITENODECOUNT) and (FOpenInsertGateEvent <> nil) then
    ReleaseMaxNodesLimiter;
end;

procedure TTailableIterator.SetStatus(AStatus: TTailableIteratorStatus);
begin
  FStatus := AStatus;
end;

procedure TTailableIterator.UnlinkFromIterable;
begin
  if FIterable <> nil then
    FIterable.SetIterableEventSubscriber(nil);
end;

function TTailableIterator._Release: Integer;
begin
  Result := inherited _Release;
  if Result = 1 then
    UnlinkFromIterable; // Only reference remaining is Iterable pointer, let's unlink from it
end;

end.

