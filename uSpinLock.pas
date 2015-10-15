unit uSpinLock;

interface

{$i DelphiVersion_defines.inc}

uses
  SyncObjs, uECodedError;

const
  SL_ERROR_TIMEOUT = 0001;
  SL_ERROR_PROMOTIONDISABLED = 0002;

type
  {$IFNDEF DELPHIXE}
  // We must define NativeInt for platforms lesser than DelphiXE
  // to make things even worse, in Delphi 2007 NativeInt is a 64 bits integer when on later
  // versions this type mutates depending on the target platform x86 or x64
  NativeInt = Integer;
  NativeUInt = Cardinal;
  {$ENDIF}
  TSpinLockMode = (slmNone, slmRead, slmFull);
  TLockResult = Integer;

const
  lrLocked = 0;
  lrNeedsSpinning = 1;

type
  TSpinLockClass = class of TSpinLock;
  TSpinLock = class (TSynchroObject)
  private
    FLock: Integer;
    FMaxLoops: Integer;
    FWaitWhenSwitchToThread: Cardinal;
    FLockerThread : Cardinal;
    FSupportReentrantLocks: LongBool;
    procedure CheckSwitchToThread(Cycles: integer);
    function GetLockCount: Integer;
    function GetLockMode: TSpinLockMode;
    function InternalLock: TLockResult;
    function SwapNewValue(NewValue: Integer): LongBool;
  protected
    procedure Spin(NewValue: Integer);
  public
    constructor Create(AMaxLoops: Integer = 0; AWaitTimeWhenSwitchToThread: Cardinal = 0); virtual;
    class procedure BurnCycles;
    procedure Acquire; override;
    function TryAcquire: Boolean; virtual;
    procedure Release; override;
    procedure Lock; virtual;
    function TryLock: Boolean; virtual;
    procedure Unlock; virtual;
    procedure Enter;
    function TryEnter: Boolean;
    procedure Leave;
    procedure Exit;
    class procedure ThrowError(AErrorCode: Integer; const AErrorMessage: String);
    property LockCount: Integer read GetLockCount;
    property LockerThread: Cardinal read FLockerThread;
    property LockMode: TSpinLockMode read GetLockMode;
    property SupportReentrantLocks: LongBool read FSupportReentrantLocks write FSupportReentrantLocks default True;
  end;

  TReadWriteSpinLock = class(TSpinLock)
  private
    FReadLockCounterTLS: NativeUInt;
    procedure ApplyReadLockingProcedure(AProc: Pointer; ReadLockRecursionCount: Integer);
    procedure CheckApplyReadLockingProcedure(AProc: Pointer);
    function InternalReadLock: TLockResult;
    procedure UpdateReadLockTLS(Addend: Integer);
  public
    constructor Create(AMaxLoops: Integer = 0; AWaitTimeWhenSwitchToThread: Cardinal = 0); override;
    destructor Destroy; override;
    procedure Lock; override;
    procedure Unlock; override;
    procedure ReadLock;
    procedure BeginRead;
    procedure ReadUnlock;
    procedure EndRead;
    procedure BeginWrite;
    procedure EndWrite;
  end;

  ESpinLock = class (ECodedError)
  protected
    class function ErrorCodePrefix: String; override;
  end;

implementation

uses
  SysUtils;

resourcestring
  SPotentialDeadlockExecutingTSpinLock = 'Reached max number of loops trying to acquire lock in TSpinLock.Lock';
  StrPromotionDemotionM = 'Promotion/Demotion mechanism disabled when using Loops limitation';

const
  LOCK_UNLOCKED = $00;

  LOCK_PUT_FIRST_LOCK = $01;
  LOCK_PUT_FIRST_READLOCK = -$01;
  LOCK_ONLY_LOCKER = $01;

  READLOCK_DECREMENT_TLSCOUNTER = -$01;
  READLOCK_INCREMENT_TLSCOUNTER = $01;

  kernel32 = 'kernel32.dll';

type
  DWORD = LongWord;
  BOOL = LongBool;

{$IFNDEF DELPHI2007}
procedure Sleep(dwMilliseconds: DWORD); stdcall; external kernel32 name 'Sleep';
{$ENDIF}
function GetCurrentThreadId: DWORD; stdcall; external kernel32 name 'GetCurrentThreadId';
function SwitchToThread: BOOL; stdcall; external kernel32 name 'SwitchToThread';
function TlsAlloc: DWORD; stdcall; external kernel32 name 'TlsAlloc';
function TlsGetValue(dwTlsIndex: DWORD): Pointer; stdcall; external kernel32 name 'TlsGetValue';
function TlsSetValue(dwTlsIndex: DWORD; lpTlsValue: Pointer): BOOL; stdcall; external kernel32 name 'TlsSetValue';
function TlsFree(dwTlsIndex: DWORD): BOOL; stdcall; external kernel32 name 'TlsFree';

{ TSpinLock }

constructor TSpinLock.Create(AMaxLoops: Integer = 0; AWaitTimeWhenSwitchToThread: Cardinal = 0);
begin
  inherited Create;
  FLock := 0;
  FMaxLoops := AMaxLoops;
  FWaitWhenSwitchToThread := AWaitTimeWhenSwitchToThread;
  FSupportReentrantLocks := True;
end;

procedure TSpinLock.Acquire;
begin
  Lock;
end;

class procedure TSpinLock.BurnCycles;
asm
  db $0F,$31 { RDTSC } // Cycle burner
  db $0F,$31 { RDTSC } // Cycle burner
  db $0F,$31 { RDTSC } // Cycle burner
  db $0F,$31 { RDTSC } // Cycle burner
end;

procedure TSpinLock.Release;
begin
  Unlock;
end;

procedure TSpinLock.Enter;
begin
  Lock;
end;

procedure TSpinLock.Leave;
begin
  Unlock;
end;

procedure TSpinLock.Exit;
begin
  Unlock;
end;

function TSpinLock.InternalLock: TLockResult;
asm
  {$IFNDEF WIN64}
  mov ecx, eax
  xor eax, eax
  mov edx, LOCK_PUT_FIRST_LOCK
  lock cmpxchg dword ptr [ecx + offset FLock], edx  // exchange in an interlocked fashion FLock and EDX
  je @@ReturnLocked
  jg @@ReturnNeedSpinning         // If rax is > than FLock there's a read lock set. We need to spin
  db $83,$79,$14,$00  // cmp dword ptr [ecx + offset FSupportReentrantLocks], 0
  je @@ReturnNeedSpinning
  call GetCurrentThreadId         // Resource locked, let's acquire our current thread ID
  cmp dword ptr [ecx + offset FLockerThread], eax  // Check if the current thread is the locker
  jne @@ReturnNeedSpinning  // If we are not the lockers, we will have to spin
  db $F0,$FF,$41,$04 { lock inc dword ptr [ecx + offset FLock] }
@@ReturnLocked:
  mov eax, lrLocked
  ret
@@ReturnNeedSpinning:
  mov eax, lrNeedsSpinning
  {$ELSE} // Win64
  // The code bellow doesn't follow the standard epilog..code..prolog structure expected for asm functions calling
  // other functions on Win64. This is in order to improve performance. Most time GetCurrentThreadId is not going to be called
  // so with the way this is coded we will avoid all of the prolog..epilog logic
  xor eax, eax
  mov edx, LOCK_PUT_FIRST_LOCK
  lock cmpxchg dword ptr [rcx + offset FLock], edx  // exchange in an interlocked fashion FLock and EDX
  je @@ReturnLocked
  jg @@ReturnNeedSpinning         // If rax is > than FLock there's a read lock set. We need to spin
  cmp dword ptr [rcx + offset FSupportReentrantLocks], 0h
  je @@ReturnNeedSpinning
  push rbp  // Let's start stack preparation here for the call to GetCurrentThreadId
  push rcx
  sub rsp, 20h
  mov rbp, rsp
  call GetCurrentThreadId         // Resource locked, let's acquire our current thread ID
  lea rsp, [rbp + 20h]
  pop rcx
  pop rbp
  cmp dword ptr [rcx + offset FLockerThread], eax  // Check if the current thread is the locker
  jne @@ReturnNeedSpinning
  lock inc dword ptr [rcx + offset FLock]
@@ReturnLocked:
  mov eax, lrLocked
  ret
@@ReturnNeedSpinning:
  mov eax, lrNeedsSpinning
  {$ENDIF}
end;

procedure TSpinLock.Unlock;
asm
  {$IFNDEF WIN64}
  db $83,$78,$04,LOCK_ONLY_LOCKER { cmp dword ptr [eax+$04],LOCK_ONLY_LOCKER }
  jne @@DecLock
  db $C7,$40,$10,$00,$00,$00,$00 { mov dword ptr [eax + offset FLockerThread], 0 } // Zero out FLockerThread
@@DecLock:
  db $F0,$FF,$48,$04  { lock dec dword ptr [eax + offset Flock] }  // Atomically decrement by one FLock
  {$ELSE}
  .NOFRAME
  cmp dword ptr [rcx + offset FLock], LOCK_ONLY_LOCKER
  jne @@DecLock
  mov dword ptr [rcx + offset FLockerThread], 0h  // Zero out FLockerThread
@@DecLock:
  lock dec dword ptr [rcx + offset Flock]   // Atomically decrement by one FLock
  {$ENDIF}
end;

function TSpinLock.GetLockCount: Integer;
begin
  Result := abs(FLock);
end;

function TSpinLock.GetLockMode: TSpinLockMode;
begin
  if FLock > 0 then
    Result := slmFull
    else if FLock < 0 then
      Result := slmRead
    else Result := slmNone;
end;

procedure TSpinLock.Spin(NewValue: Integer);
var
  Cycles : integer;
begin
  Cycles := 0;
  repeat
    if SwapNewValue(NewValue) then
      system.exit;
    CheckSwitchToThread(Cycles);
    BurnCycles;
    inc (Cycles);
  until (FMaxLoops > 0) and (Cycles > FMaxLoops);
  ThrowError (SL_ERROR_TIMEOUT, SPotentialDeadlockExecutingTSpinLock);
end;

procedure TSpinLock.CheckSwitchToThread(Cycles: integer);
begin
  if Cycles div 7 = 0 then
    begin
      SwitchToThread;
      if FWaitWhenSwitchToThread > 0 then
        Sleep(FWaitWhenSwitchToThread);
    end;
end;

procedure TSpinLock.Lock;
begin
  if InternalLock = lrNeedsSpinning then
    Spin(LOCK_PUT_FIRST_LOCK);
  if FSupportReentrantLocks and (FLockerThread = 0) then
    FLockerThread := GetCurrentThreadId;
end;

function TSpinLock.SwapNewValue(NewValue: Integer): LongBool;
asm
  {$IFNDEF WIN64}
  // edx <- NewValue
  mov ecx, Self
  xor eax, eax
  lock cmpxchg dword ptr [ecx + offset FLock], edx
  jz @@ReturnTrue
  xor eax, eax
  ret
@@ReturnTrue:
  mov eax, True
  {$ELSE}
  .NOFRAME
  xor eax, eax
  lock cmpxchg dword ptr [rcx + offset FLock], edx
  jz @@ReturnTrue
  xor eax, eax
  ret
@@ReturnTrue:
  mov eax, True
  {$ENDIF}
end;

class procedure TSpinLock.ThrowError(AErrorCode: Integer; const AErrorMessage:
    String);
begin
  raise ESpinLock.Create (AErrorCode, AErrorMessage);
end;

function TSpinLock.TryAcquire: Boolean;
begin
  Result := TryLock;
end;

function TSpinLock.TryEnter: Boolean;
begin
  Result := TryLock;
end;

function TSpinLock.TryLock: Boolean;
begin
  Result := InternalLock = lrLocked;
  if Result and FSupportReentrantLocks and (FLockerThread = 0) then
    FLockerThread := GetCurrentThreadId;
end;

{ TReadWriteSpinLock }

constructor TReadWriteSpinLock.Create(AMaxLoops: Integer = 0; AWaitTimeWhenSwitchToThread: Cardinal = 0);
begin
  inherited Create (AMaxLoops, AWaitTimeWhenSwitchToThread);
  FReadLockCounterTLS := TlsAlloc;
end;

destructor TReadWriteSpinLock.Destroy;
begin
  TlsFree (FReadLockCounterTLS);
  inherited;
end;

procedure TReadWriteSpinLock.Lock;
begin
  CheckApplyReadLockingProcedure(@TReadWriteSpinLock.ReadUnlock);
  inherited;
end;

procedure TReadWriteSpinLock.Unlock;
begin
  inherited;
  CheckApplyReadLockingProcedure (@TReadWriteSpinLock.ReadLock);
end;

procedure TReadWriteSpinLock.CheckApplyReadLockingProcedure(AProc: Pointer);
var
  ReadLockRecursionCount : integer;
begin
  ReadLockRecursionCount := integer (TlsGetValue (FReadLockCounterTLS));
  if ReadLockRecursionCount > 0 then
    begin
      if FMaxLoops > 0 then
        ThrowError (SL_ERROR_PROMOTIONDISABLED, StrPromotionDemotionM);
      ApplyReadLockingProcedure (AProc, ReadLockRecursionCount);
    end;
end;

procedure TReadWriteSpinLock.ApplyReadLockingProcedure(AProc: Pointer; ReadLockRecursionCount: Integer);
type
  TReadLockingProcedure = procedure of object;
var
  AMethod : TMethod;
  i : integer;
begin
  AMethod.Data := Self;
  AMethod.Code := AProc;
  for i := 1 to ReadLockRecursionCount do
    TReadLockingProcedure(AMethod)();
  TlsSetValue (FReadLockCounterTLS, Pointer (ReadLockRecursionCount));
end;

procedure TReadWriteSpinLock.BeginRead;
begin
  ReadLock;
end;

procedure TReadWriteSpinLock.BeginWrite;
begin
  Lock;
end;

procedure TReadWriteSpinLock.EndRead;
begin
  ReadUnlock;
end;

procedure TReadWriteSpinLock.EndWrite;
begin
  Unlock;
end;

function TReadWriteSpinLock.InternalReadLock: TLockResult;
asm
  {$IFNDEF WIN64}
  mov ecx, eax
  xor eax, eax
  mov edx, LOCK_PUT_FIRST_READLOCK
@@TryToGetReadLock:
  lock cmpxchg dword ptr [ecx + offset FLock], edx  // exchange in an interlocked fashion FLock and EDX
  je @@ReturnLocked
  cmp eax, LOCK_UNLOCKED
  jg @@NeedSpinning
  mov edx, eax
  dec edx
  jmp @@TryToGetReadLock
@@NeedSpinning:
  mov eax, lrNeedsSpinning
  ret
@@ReturnLocked:
  mov eax, lrLocked
  {$ELSE}
  .NOFRAME
  xor eax, eax
  mov edx, LOCK_PUT_FIRST_READLOCK
@@TryToGetReadLock:
  lock cmpxchg dword ptr [rcx + offset FLock], edx  // exchange in an interlocked fashion FLock and EDX
  je @@ReturnLocked
  cmp eax, LOCK_UNLOCKED
  jg @@NeedSpinning
  mov edx, eax
  dec edx
  jmp @@TryToGetReadLock
@@NeedSpinning:
  mov eax, lrNeedsSpinning
  ret
@@ReturnLocked:
  mov eax, lrLocked
  {$ENDIF}
end;

procedure TReadWriteSpinLock.ReadLock;
begin
  if InternalReadLock = lrNeedsSpinning then
    Spin(LOCK_PUT_FIRST_READLOCK);
  UpdateReadLockTLS(READLOCK_INCREMENT_TLSCOUNTER);
end;

procedure TReadWriteSpinLock.ReadUnlock;
asm
  {$IFNDEF WIN64}
  db $F0,$FF,$40,$04  { lock inc [eax + offset FLock] }
  mov edx, READLOCK_DECREMENT_TLSCOUNTER
  call UpdateReadLockTLS
  {$ELSE}
  .PARAMS 2
  .PUSHNV rbp
  lock inc dword ptr [rcx + offset FLock]
  mov rdx, READLOCK_DECREMENT_TLSCOUNTER
  call UpdateReadLockTLS
  {$ENDIF}
end;

procedure TReadWriteSpinLock.UpdateReadLockTLS(Addend: Integer);
  {$IFDEF PUREPASCAL}
begin
  TlsSetValue(FReadLockCounterTLS, Pointer(NativeUInt(TlsGetValue(FReadLockCounterTLS)) + Addend));
  {$ELSE}
asm
  {$IFNDEF WIN64}
  push ebx
  push edi
  mov ebx, edx
  mov edi, dword ptr [eax + offset FReadLockCounterTLS]
  push edi
  call TlsGetValue
  add eax, ebx
  push eax
  push edi
  call TlsSetValue
  pop edi
  pop ebx
  {$ELSE}
  .PARAMS 2
  .PUSHNV rbp
  .PUSHNV r12
  .PUSHNV r13
  mov r12, rdx
  mov r13, qword ptr [rcx + offset FReadLockCounterTLS]
  mov rcx, r13
  call TlsGetValue
  add rax, r12
  mov rcx, r13
  mov rdx, rax
  call TlsSetValue
  {$ENDIF}
  {$ENDIF}
end;

{ ESpinLock }

class function ESpinLock.ErrorCodePrefix: String;
begin
  Result := 'SL';
end;

end.
