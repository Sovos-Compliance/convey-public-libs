unit uScope;

interface

{$i DelphiVersion_defines.inc}

uses
  {$IFNDEF DELPHIXE}
  CnvStrUtils,
  {$ENDIF}
  SyncObjs;

{$IFNDEF DELPHIXE}
type
  // We must define NativeInt for platforms lesser than DelphiXE
  // to make things even worse, in Delphi 2007 NativeInt is a 64 bits integer when on later
  // versions this type mutates depending on the target platform x86 or x64
  NativeInt = Integer;
  NativeUInt = Cardinal;
{$ENDIF}

type
  TEndThreadSubscriber = procedure (ExitCode: Integer);
  PPointer = ^Pointer;
  PCardinal = ^Cardinal;
  TFinalizeScopeMethod = procedure of object;
  TFinalizeScopeProcedure = procedure;

  PObject = ^TObject;
  IScope = interface
    ['{B3906162-927C-4BA7-BEC6-1F4920EC9833}']
    function Add(AObject : TObject): Pointer; overload;
    function Add(APointer : Pointer): Pointer; overload;
    function Add(AHandle : Cardinal; AFreeProc : Pointer = nil): Cardinal; overload;
    // The following methods don't work for local variables at a procedure level
    // at the moment the Scope object is destroyed local variables are no longer valid, therefore references
    // tracked by IScope will be invalid and will cause an access violation
    procedure AddObjectReference(AObjectReference : PObject);
    procedure AddPointerReference(APointerReference : PPointer);
    procedure AddHandleReference(AHandleReference: PCardinal; AFreeProc: Pointer = nil);
    procedure AssignObject(var Target; AObject : TObject);
    procedure AssignPointer(var Target; APointer: Pointer);
    procedure AssignHandle(var Target; Handle : Cardinal; AFreeProc : Pointer = nil); // The prototype for FreeProc is: procedure (AHandle : Cardinal)
    function AllocMem(ASize : Cardinal) : pointer;
    {$IFNDEF DELPHIXE}
    function StrList(const AStringArray : array of string) : TAdvStringList; overload;
    function StrList : TAdvStringList; overload;
    {$ENDIF}
    // Keep the following methods always at the bottom because otherwise will break generation of import file because
    // These methods are excluded, they make PAX registrations blow up
    procedure Assign(var Target; AObject : TObject); overload;
    procedure Assign(var Target; APointer: Pointer); overload;
    procedure Assign(var Target; Handle : Cardinal; AFreeProc : Pointer = nil); overload; // The prototype for FreeProc is: procedure (AHandle : Cardinal)
    procedure AddFinalizeScopeMethod(AProc : TFinalizeScopeMethod);
    procedure AutoFinalize(AInitProc, AFinalizeProc : TFinalizeScopeMethod);
    procedure AddFinalizeScopeMethods(const AMethodReferences : array of TFinalizeScopeMethod);
    procedure AddFinalizeScopeProc(AProc : TFinalizeScopeProcedure);
    procedure AddFinalizeScopeProcs(const AProcReferences : array of TFinalizeScopeProcedure);
    procedure AddObjectReferences(const AObjectReferences : array of PObject);
    procedure AddPointerReferences(const APointerReferences : array of PPointer);
    procedure AddHandleReferences(const AHandleReferences: array of PCardinal; AFreeProc: Pointer = nil);
  end;

  IAutoLocker = interface
    ['{E81B482E-5719-4C30-B37D-6F5D652E88CF}']
  end;

function NewScope: IScope;
{ !!!! Important: ONLY use the following function to protect calls using synchronization objects
  for calls that are in one procedure. AutoLocker objects allocate memory in a very light way
  fashion on a piece of memory that works like a stack.
  DON'T use it as a member of a class or bad things will happen }
function NewAutoLocker(ALockObject : TSynchroObject) : IAutoLocker;

procedure RegisterEndThreadSubscriber(ASubscriber: Pointer);
procedure UnRegisterEndThreadSubscriber(ASubscriber: Pointer);

procedure WaitForDLL_Attached_Event;

var
  InitializingDll : Boolean; // Use this flag to know when a DLL is being attached, only used when ModuleIsPackage is True
  ShuttingDownDll : Boolean; // Use this flag to know when a DLL is in DETACH mode, only used when ModuleIsPackage is True

implementation

uses
  uLinkedList, iContainers, SysUtils, Windows, CnvGenUtils, Classes;

resourcestring
  SEndOfAutolockerAllocationStackRe = 'End of autolocker allocation stack reached';
  SOnlyLastAutoLockerCanBeDestroyed = 'Only last AutoLocker can be destroyed';

const
  kernel32 = 'kernel32.dll';
  AUTOLOCKER_STACKSIZE = 32;

type
  TTrackedResource = class;

  TScope = class(TInterfacedObject, IScope)
    procedure FreeInstance; override;
  private
    FObjects : ILinkedList;
    LastExceptionMsg : string;
    LastExceptionClass : string;
    procedure DestroyTrackedObjects;
  protected
    constructor Create; virtual;
    procedure FinalizeTrackedResource(ATrackedResource: TTrackedResource);
    function Add(AObject : TObject): Pointer; overload;
    function Add(APointer : Pointer): Pointer; overload;
    function Add(AHandle: Cardinal; AFreeProc: Pointer = nil): Cardinal; overload;
    procedure AutoFinalize(AInitProc, AFinalizeProc : TFinalizeScopeMethod);
    procedure AddFinalizeScopeMethod(AProc : TFinalizeScopeMethod);
    procedure AddFinalizeScopeProc(AProc : TFinalizeScopeProcedure);
    procedure Assign(var Target; AObject : TObject); overload;
    procedure Assign(var Target; APointer: Pointer); overload;
    procedure Assign(var Target; AHandle: Cardinal; AFreeProc: Pointer = nil); overload;
    procedure AddObjectReferences(const AObjectReferences: array of PObject);
    procedure AddPointerReferences(const APointerReferences: array of PPointer);
    procedure AddHandleReferences(const AObjectReferences: array of PCardinal; AFreeProc: Pointer = nil);
    procedure AddFinalizeScopeMethods(const AMethodReferences : array of TFinalizeScopeMethod);
    procedure AddFinalizeScopeProcs(const AProcReferences: array of TFinalizeScopeProcedure);
    procedure AddObjectReference(AObjectReference : PObject);
    procedure AddPointerReference(APointerReference : PPointer);
    procedure AddHandleReference(AHandleReference: PCardinal; AFreeProc: Pointer = nil);
    procedure AssignObject(var Target; AObject : TObject);
    procedure AssignPointer(var Target; APointer: Pointer);
    procedure AssignHandle(var Target; Handle : Cardinal; AFreeProc : Pointer = nil);
    function AllocMem(ASize : Cardinal): pointer;
    {$IFNDEF DELPHIXE}
    function StrList(const AStringArray : array of string): TAdvStringList; overload;
    function StrList: TAdvStringList; overload;
    {$ENDIF}
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
  end;

  TFreeHandleProcedure = procedure (AHandle : Cardinal);

  TTrackedResource = class
  public
    procedure FreeTrackedResource; virtual; abstract;
  end;

  TTrackedHandle = class(TTrackedResource)
  private
    FHandle : Cardinal;
    FFreeProc : TFreeHandleProcedure;
    FVarAddress: Pointer;
  public
    constructor Create(AHandle: Cardinal; AFreeProc: TFreeHandleProcedure;
        AVarAddress: Pointer = nil);
    procedure FreeTrackedResource; override;
  end;

  TTrackedHandleRefrence = class (TTrackedHandle)
  public
    procedure FreeTrackedResource; override;
  end;

  TTrackedObject = class(TTrackedResource)
  private
    FObject : TObject;
    FVarAddress : Pointer;
  public
    constructor Create(AObject : TObject; AVarAddress : Pointer = nil);
    procedure FreeTrackedResource; override;
  end;

  TTrackedObjectReference = class(TTrackedObject)
  public
    procedure FreeTrackedResource; override;
  end;

  TTrackedPointer = class(TTrackedResource)
  private
    FPointer : Pointer;
    FVarAddress: Pointer;
  public
    constructor Create(APointer : Pointer; AVarAddress : Pointer = nil);
    procedure FreeTrackedResource; override;
  end;

  TTrackedPointerReference = class(TTrackedPointer)
  public
    procedure FreeTrackedResource; override;
  end;

  TTrackedFinalizeScopeMethod = class(TTrackedResource)
  private
    FMethod : TFinalizeScopeMethod;
  public
    constructor Create(AMethod: TFinalizeScopeMethod);
    procedure FreeTrackedResource; override;
  end;

  TTrackedFinalizeScopeProc = class(TTrackedResource)
  private
    FProc : TFinalizeScopeProcedure;
  public
    constructor Create(AProc: TFinalizeScopeProcedure);
    procedure FreeTrackedResource; override;
  end;

  TAutoLocker = class(TInterfacedObject, IAutoLocker)
  private
    FLock : TSynchroObject;
  public
    constructor Create(ALock: TSynchroObject);
    destructor Destroy; override;
    procedure FreeInstance; override;
    class function NewInstance: TObject; override;
  end;

function CloseHandle(hObject: Cardinal): LongBool; stdcall; forward;

threadvar
  AutoLockerStack : Pointer;
  AutoLockerStackPtr : Pointer;
  AutoLockerStackEnd : Pointer;

var
  EndThreadSubscribers : ILinkedList;

function NewScope: IScope;
begin
  Result := TScope.Create;
end;

constructor TScope.Create;
begin
  inherited;
  FObjects := LinkedListFactory.CreateObject (Self) as ILinkedList;
end;

destructor TScope.Destroy;
begin
  DestroyTrackedObjects;
  inherited;
end;

procedure TScope.DestroyTrackedObjects;
begin
  if FObjects = nil then
    exit;
  with TIterator.CreateIterator(FObjects) do
    while IterateBackwards do
      try
        FinalizeTrackedResource (GetAsObject as TTrackedResource);
      except
        on E : Exception do
          begin
            LastExceptionMsg := E.Message;
            LastExceptionClass := E.ClassName;
          end;
      end;
end;

function TScope.Add(AObject : TObject): Pointer;
begin
  Result := AObject;
  FObjects.Insert(TTrackedObject.Create (AObject));
end;

function TScope.Add(APointer : Pointer): Pointer;
begin
  Result := APointer;
  FObjects.Insert(TTrackedPointer.Create (APointer));
end;

function TScope.Add(AHandle: Cardinal; AFreeProc: Pointer = nil): Cardinal;
begin
  Result := AHandle;
  FObjects.Insert(TTrackedHandle.Create (integer (AHandle), AFreeProc));
end;

procedure TScope.AddFinalizeScopeMethod(AProc : TFinalizeScopeMethod);
begin
  FObjects.Insert(TTrackedFinalizeScopeMethod.Create(AProc));
end;

procedure TScope.AddFinalizeScopeMethods(const AMethodReferences : array of TFinalizeScopeMethod);
var
  i : integer;
begin
  for i := high (AMethodReferences) downto low (AMethodReferences) do
    FObjects.Insert (TTrackedFinalizeScopeMethod.Create (AMethodReferences[i]));
end;

procedure TScope.AddFinalizeScopeProc(AProc : TFinalizeScopeProcedure);
begin
  FObjects.Insert(TTrackedFinalizeScopeProc.Create(AProc));
end;

procedure TScope.AddFinalizeScopeProcs(const AProcReferences: array of TFinalizeScopeProcedure);
var
  i : integer;
begin
  for i := high (AProcReferences) downto low (AProcReferences) do
    FObjects.Insert (TTrackedFinalizeScopeProc.Create (AProcReferences[i]));
end;

procedure TScope.AddHandleReference(AHandleReference: PCardinal; AFreeProc:
    Pointer = nil);
begin
  AddHandleReferences([AHandleReference], AFreeProc);
end;

procedure TScope.AddObjectReferences(const AObjectReferences: array of PObject);
var
  i : integer;
begin
  for i := low (AObjectReferences) to high (AObjectReferences) do
    FObjects.Insert (TTrackedObjectReference.Create (AObjectReferences[i]^, AObjectReferences[i]));
end;

procedure TScope.AddHandleReferences(const AObjectReferences: array of PCardinal;
    AFreeProc: Pointer = nil);
var
  i : integer;
begin
  for i := low (AObjectReferences) to high (AObjectReferences) do
    FObjects.Insert (TTrackedHandleRefrence.Create (AObjectReferences[i]^, AFreeProc, AObjectReferences[i]));
end;

procedure TScope.AddObjectReference(AObjectReference : PObject);
begin
  AddObjectReferences([AObjectReference]);
end;

procedure TScope.AddPointerReference(APointerReference : PPointer);
begin
  AddPointerReferences([APointerReference]);
end;

procedure TScope.AddPointerReferences(const APointerReferences: array of
    PPointer);
var
  i : integer;
begin
  for i := low (APointerReferences) to high (APointerReferences) do
    FObjects.Insert (TTrackedPointerReference.Create (APointerReferences[i]^, APointerReferences[i]));
end;

procedure TScope.AfterConstruction;
begin
  inherited;
  if FObjects = nil
    then raise Exception.Create ('Call NewScope to initialize a new Scope object')
end;

function TScope.AllocMem(ASize : Cardinal): pointer;
begin
  GetMem(Result, ASize);
  Add(Result);
end;

procedure TScope.Assign(var Target; AObject : TObject);
begin
  TObject (Target) := AObject;
  FObjects.Insert(TTrackedObject.Create (AObject, @Target));
end;

procedure TScope.Assign(var Target; AHandle: Cardinal; AFreeProc: Pointer =
    nil);
begin
  Cardinal (Target) := AHandle;
  FObjects.Insert(TTrackedHandle.Create (integer (AHandle), AFreeProc, @Target));
end;

procedure TScope.Assign(var Target; APointer: Pointer);
begin
  Pointer (Target) := APointer;
  FObjects.Insert(TTrackedPointer.Create (APointer, @Target));
end;

procedure TScope.AssignHandle(var Target; Handle : Cardinal; AFreeProc :
    Pointer = nil);
begin
  Assign(Target, Handle, AFreeProc);
end;

procedure TScope.AssignObject(var Target; AObject : TObject);
begin
  Assign(Target, AObject);
end;

procedure TScope.AssignPointer(var Target; APointer: Pointer);
begin
  Assign(Target, APointer);
end;

procedure TScope.AutoFinalize(AInitProc, AFinalizeProc : TFinalizeScopeMethod);
begin
  AInitProc;
  AddFinalizeScopeMethod(AFinalizeProc);
end;

procedure TScope.FinalizeTrackedResource(ATrackedResource: TTrackedResource);
begin
  with ATrackedResource do
    begin
      try
        FreeTrackedResource;
      finally
        Free;
      end;
    end;
end;

procedure TScope.FreeInstance;
var
  ALastExceptionMsg : String;
  ALastExceptionClass : String;
begin
  ALastExceptionMsg := LastExceptionMsg;
  ALastExceptionClass := LastExceptionClass;
  inherited;
  if ALastExceptionMsg <> '' then
    raise Exception.CreateFmt ('%s (%s class)', [ALastExceptionMsg, ALastExceptionClass]);
end;

{$IFNDEF DELPHIXE}
function TScope.StrList: TAdvStringList;
begin
  Result := Add(TAdvStringList.Create);
end;

function TScope.StrList(const AStringArray : array of string): TAdvStringList;
var
  i : integer;
begin
  Result := StrList;
  for i := low(AStringArray) to high(AStringArray) do
    Result.Add(AStringArray[i]);
end;
{$ENDIF}

function CloseHandle; external kernel32 name 'CloseHandle';

constructor TTrackedHandle.Create(AHandle: Cardinal; AFreeProc:
    TFreeHandleProcedure; AVarAddress: Pointer = nil);
begin
  inherited Create;
  FHandle := AHandle;
  FFreeProc := AFreeProc;
  FVarAddress := AVarAddress;
end;

procedure TTrackedHandle.FreeTrackedResource;
begin
  try
    if assigned (FFreeProc)
      then FFreeProc (FHandle)
      else CloseHandle (FHandle);
  finally
    if FVarAddress <> nil then
      PCardinal (FVarAddress)^ := 0;
  end;
end;

constructor TTrackedObject.Create(AObject : TObject; AVarAddress : Pointer =
    nil);
begin
  inherited Create;
  FObject := AObject;
  FVarAddress := AVarAddress;
end;

procedure TTrackedObject.FreeTrackedResource;
begin
  try
    FObject.Free;
  finally
    if FVarAddress <> nil then
      PPointer(FVarAddress)^ := nil;
  end;
end;

constructor TTrackedPointer.Create(APointer : Pointer; AVarAddress : Pointer =
    nil);
begin
  inherited Create;
  FPointer := APointer;
  FVarAddress := AVarAddress;
end;

procedure TTrackedPointer.FreeTrackedResource;
begin
  try
    FreeMem (FPointer);
  finally
    if FVarAddress <> nil then
      PPointer(FVarAddress)^ := nil;
  end;
end;

procedure TTrackedObjectReference.FreeTrackedResource;
begin
  FObject := PPointer (FVarAddress)^;
  if FObject <> nil
    then inherited;
end;

procedure TTrackedHandleRefrence.FreeTrackedResource;
begin
  FHandle := PCardinal (FVarAddress)^;
  if FHandle <> 0
    then inherited;
end;

procedure TTrackedPointerReference.FreeTrackedResource;
begin
  FPointer := PPointer (FVarAddress)^;
  if FPointer <> nil
    then inherited;
end;

constructor TTrackedFinalizeScopeMethod.Create(AMethod: TFinalizeScopeMethod);
begin
  inherited Create;
  FMethod := AMethod;
end;

procedure TTrackedFinalizeScopeMethod.FreeTrackedResource;
begin
  if assigned(FMethod) then
    FMethod;
end;

constructor TTrackedFinalizeScopeProc.Create(AProc: TFinalizeScopeProcedure);
begin
  inherited Create;
  FProc := AProc;
end;

procedure TTrackedFinalizeScopeProc.FreeTrackedResource;
begin
  if assigned(FProc) then
    FProc;
end;

type
  PJump = ^TJump;
  TJump = packed record
    OpCode:byte;
    Distance:integer;
  end;

{$IFNDEF DELPHI2007}
type
  THookedDllProc = procedure (Reason: DWORD);
{$ENDIF}

var
  DllAttachedEvent : TEvent;
  OldCode : TJump;
  NewCode : TJump;
  {$IFDEF DELPHI2007}
  OldDllProc : TDLLProc;
  {$ELSE}
  OldDllProc : Pointer;
  {$ENDIF}

procedure WaitForDLL_Attached_Event;
begin
  if DllAttachedEvent <> nil then
    DllAttachedEvent.WaitFor(INFINITE);
end;

// Hooked DllProc used to flag when DLL is being detached
procedure HookedDllProc(Reason: DWORD);
begin
  if not ShuttingDownDll then
    ShuttingDownDll := Reason = DLL_PROCESS_DETACH;
  if assigned(OldDllProc) then
    {$IFNDEF DELPHI2007}THookedDllProc({$ENDIF}OldDllProc{$IFNDEF DELPHI2007}){$ENDIF}(Reason);
end;

procedure HookedEndThread(ExitCode: Integer);
var
  i : IIterator;
begin
  {$IFDEF DELPHI2007}
  if Assigned(SystemThreadEndProc) then
    SystemThreadEndProc(ExitCode);
  {$ENDIF}
  i := NewIterator(EndThreadSubscribers);
  while i.IterateBackwards do
    TEndThreadSubscriber(i.GetAsPointer)(ExitCode);
  i := nil;
  (* JSB: Special code to prevent deadlock when unloading a DLL and trying to finalize a thread
     on the finalization section of units.
     Read post http://www.verious.com/qa/exit-thread-upon-deleting-static-object-during-unload-dll-causes-deadlock/
     it briefly touches on the subject that there seems to be a limitation (bug?) on trying to finalize a thread when already
     entering on the dllMain call to perform a DLL_DETACH ( DLL_PROCESS_DETACH )
     We need to know that module is going into detach mode before changing from ExitThread to TerminateThread.
     This problem also seems to happen only with "normal" dlls, not with Borland Packages (BPLs)
  *)
  if (not IsLibrary) or (not ShuttingDownDll) then
    ExitThread(ExitCode)
  else TerminateThread(GetCurrentThread, ExitCode); // Forceful termination of thread if library mode and DLL_PROCESS_DETACH mode
end;

{ TAutoLocker }

procedure FreeLockerStackEndThreadSubscriber(ExitCode : integer);
begin
  if AutoLockerStack <> nil then
    FreeMem(AutoLockerStack);
end;

procedure InitAutoLockerStack;
begin
  GetMem(AutoLockerStack, AUTOLOCKER_STACKSIZE * TAutoLocker.InstanceSize);
  AutoLockerStackPtr := AutoLockerStack;
  AutoLockerStackEnd := Pointer(Integer(AutoLockerStack) + AUTOLOCKER_STACKSIZE * TAutoLocker.InstanceSize);
end;

constructor TAutoLocker.Create(ALock: TSynchroObject);
begin
  inherited Create;
  FLock := ALock;
  FLock.Acquire;
end;

destructor TAutoLocker.Destroy;
begin
  FLock.Release;
  inherited;
end;

procedure TAutoLocker.FreeInstance;
begin
  if Self <> Pointer(Integer(AutoLockerStackPtr) - TAutoLocker.InstanceSize) then
    raise Exception.Create(SOnlyLastAutoLockerCanBeDestroyed);
  CleanupInstance;
  dec(NativeUInt(AutoLockerStackPtr), TAutoLocker.InstanceSize);
end;

class function TAutoLocker.NewInstance: TObject;
begin
  if AutoLockerStack = nil then
    InitAutoLockerStack;
  if Integer(AutoLockerStackPtr) >= Integer(AutoLockerStackEnd) then
    raise Exception.Create(SEndOfAutolockerAllocationStackRe);
  Result := pointer(AutoLockerStackPtr);
  inc(NativeUInt(AutoLockerStackPtr), TAutoLocker.InstanceSize);
  InitInstance(Result);
  TAutoLocker(Result).FRefCount := 1;
end;

function NewAutoLocker(ALockObject : TSynchroObject) : IAutoLocker;
begin
  Result := TAutoLocker.Create(ALockObject);
end;

procedure PatchEndThread;
begin
  NewCode.Distance := NativeUInt(@HookedEndThread) - (NativeUInt(@EndThread) + 5);
  PatchMemory (@EndThread, 5, @NewCode, @OldCode);
  FlushInstructionCache (GetCurrentProcess, @EndThread, 5);
end;

procedure UnPatchEndThread;
begin
  PatchMemory (@EndThread, 5, @OldCode);
  FlushInstructionCache (GetCurrentProcess, @EndThread, 5);
end;

procedure RegisterEndThreadSubscriber(ASubscriber: Pointer);
begin
  EndThreadSubscribers.Insert(ASubscriber);
end;

procedure UnRegisterEndThreadSubscriber(ASubscriber: Pointer);
begin
  EndThreadSubscribers.Remove(ASubscriber);
end;

type
  TSignalInitializedThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TSignalInitializedThread.Execute;
begin
  InitializingDll := False;
  DllAttachedEvent.SetEvent;
end;

initialization
  if IsLibrary and (not ModuleIsPackage) then
    begin
      InitializingDll := True;
      DllAttachedEvent := TEvent.Create(nil, True, False, '');
      with TSignalInitializedThread.Create(False) do
        FreeOnTerminate := True;
    end;
  OldDllProc := DllProc;
  DllProc := @HookedDllProc;
  NewCode.OpCode := $E9;
  NewCode.Distance := 0;
  PatchEndThread;
  EndThreadSubscribers := LinkedListFactory.CreateObject (nil) as ILinkedList;
  RegisterEndThreadSubscriber(@FreeLockerStackEndThreadSubscriber);
finalization
  UnRegisterEndThreadSubscriber(@FreeLockerStackEndThreadSubscriber);
  UnPatchEndThread;
  DllProc := OldDllProc;
  if DllAttachedEvent <> nil then
    FreeAndNil(DllAttachedEvent);
end.