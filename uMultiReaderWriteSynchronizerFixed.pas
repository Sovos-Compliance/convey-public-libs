unit uMultiReaderWriteSynchronizerFixed;

interface

{$IFNDEF VER180}
{$IF CompilerVersion < 11.0} // Delphi 2007

uses
  SysUtils, Windows;

{ Thread synchronization }

{ IReadWriteSync is an abstract interface for general read/write synchronization.
  Some implementations may allow simultaneous readers, but writers always have
  exclusive locks.

  Worst case is that this class behaves identical to a TRTLCriticalSection -
  that is, read and write locks block all other threads. }

type
  TThreadLocalCounter2 = class;
  IReadWriteSync = interface
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: Boolean;
    procedure EndWrite;
  end;

{  TSimpleRWSync = class(TInterfacedObject, IReadWriteSync)
  private
    FLock: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: Boolean;
    procedure EndWrite;
  end;}

{ Type conversion records }

  WordRec = packed record
    case Integer of
      0: (Lo, Hi: Byte);
      1: (Bytes: array [0..1] of Byte);
  end;

{ TThreadLocalCounter

  This class implements a lightweight non-blocking thread local storage
  mechanism specifically built for tracking per-thread recursion counts
  in TMultiReadExclusiveWriteSynchronizer.  This class is intended for
  Delphi RTL internal use only.  In the future it may be generalized
  and "hardened" for general application use, but until then leave it alone.

  Rules of Use:
  The tls object must be opened to gain access to the thread-specific data
  structure.  If a threadinfo block does not exist for the current thread,
  Open will allocate one.  Every call to Open must be matched with a call
  to Close.  The pointer returned by Open is invalid after the matching call
  to Close.

  The thread info structure is unique to each thread.  Once you have it, it's
  yours.  You don't need to guard against concurrent access to the thread
  data by multiple threads - your thread is the only thread that will ever
  have access to the structure that Open returns.  The thread info structure
  is allocated and owned by the tls object.  If you put allocated pointers
  in the thread info make sure you free them before you delete the threadinfo
  node.

  When thread data is no longer needed, call the Delete method on the pointer.
  This must be done between calls to Open and Close.  Delete schedules the
  pointer for destruction, but the pointer (and its data) will still be
  valid until Close is called.

  Important:  Do not keep the tls object open for long periods of time.  The
  tls object performs internal cleanup only when no threads have the
  tls object in the open state.  In particular, be careful not to wait on
  a thread synchronization event or critical section while you
  have the tls object open.  It's much better to open and close the tls
  object before and after the blocking event than to leave the tls object
  open while waiting.

  Implementation Notes:
  The main purpose of this storage class is to provide thread-local storage
  without using limited / problematic OS tls slots and without requiring
  expensive blocking thread synchronization.  This class performs no
  blocking waits or spin loops!  (except for memory allocation)

  Thread info is kept in linked lists to facilitate non-blocking threading
  techniques.  A hash table indexed by a hash of the current thread ID
  reduces linear search times.

  When a node is deleted, it is moved out of the hash table lists into
  the purgatory list.  The hash table no longer points to the deleted node,
  but the deleted node's next pointer still points into the hash table.  This
  is so that deleting a node will not interrupt other threads that are
  traversing the list concurrent with the deletion.  If another thread is
  visiting a node while it is being deleted, the thread will follow the
  node's next pointer and get back into the live list without interruption.

  The purgatory list is linked through the nodes' NextDead field.  Again, this
  is to preserve the exit path of other threads still visiting the deleted
  node.

  When the last concurrent use of the tls object is closed (when FOpenCount
  drops to zero), all nodes in the purgatory list are reviewed for destruction
  or recycling. It's safe to do this without a thread synchronization lock
  because we know there are no threads visiting any of the nodes.  Newly
  deleted nodes are cleared of their thread identity and assigned a clock tick
  expiration value.  If a deleted node has been in the purgatory for longer
  than the holding period, Close will free the node.  When Open needs to
  allocate a new node for a new thread, it first tries to recycle an old node
  from the purgatory.  If nothing is available for recycling, Open allocates
  new memory.  The default holding period is one minute.

  Note that nodes enter the holding pattern when the tls object is closed.
  They won't be reviewed for destruction until the *next* time the tls
  object transitions into the closed state.  This is intentional, to
  reduce memory allocation thrashing when multiple threads open, delete,
  and close tls frequently, as will be the case with non-recursive read
  locks in TMREWSync.

  Close grabs the purgatory list before checking the FOpenCount to avoid
  race conditions with other threads reopening the tls while Close is
  executing.  If FOpenCount is not yet zero, Close has to put the purgatory
  list back together (Reattach), including any items added to the
  purgatory list after Close swiped it.  Since the number of thread
  participants should be small (less than 32) and the frequency of deletions
  relative to thread data access should be low, the purgatory list should
  never grow large enough to make this non-blocking Close implementation a
  performance problem.

  The linked list management relies heavily on InterlockedExchange to perform
  atomic node pointer replacements.  There are brief windows of time where
  the linked list may be circular while a two-step insertion takes place.
  During that brief window, other threads traversing the lists may see
  the same node more than once more than once. (pun!) This is fine for what this
  implementation needs.  Don't do anything silly like try to count the
  nodes during a traversal.
}

  PThreadInfo = ^TThreadInfo;
  TThreadInfo = record
    Next: PThreadInfo;
    NextDead: PThreadInfo;
    ThreadID: Cardinal;
    RecursionCount: Cardinal;
  end;

{  TThreadLocalCounter = class
  private
    FHashTable: array [0..15] of PThreadInfo;
    FPurgatory: PThreadInfo;
    FOpenCount: Integer;
    function HashIndex: Byte;
    function Recycle: PThreadInfo;
    procedure Reattach(List: PThreadInfo);
  protected
    FHoldTime: Cardinal;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open(var Thread: PThreadInfo);
    procedure Delete(var Thread: PThreadInfo);
    procedure Close(var Thread: PThreadInfo);
  end;         }


  TMultiReadExclusiveWriteSynchronizer = class(TInterfacedObject, IReadWriteSync)
  private
    FSentinel: Integer;
    FReadSignal: THandle;
    FWriteSignal: THandle;
    FWaitRecycle: Cardinal;
    FWriteRecursionCount: Cardinal;
    tls: TThreadLocalCounter2;         // !! ThreadLocalCounter2 patch
    FWriterID: Cardinal;
    FRevisionLevel: Cardinal;
    procedure BlockReaders;
    procedure UnblockReaders;
    procedure UnblockOneWriter;
    procedure WaitForReadSignal;
    procedure WaitForWriteSignal;
{$IFDEF DEBUG_MREWS}
    procedure Debug(const Msg: string);
{$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: Boolean;
    procedure EndWrite;
    property RevisionLevel: Cardinal read FRevisionLevel;
  end;

  PThreadInfo2 = ^TThreadInfo2;
  TThreadInfo2 = record
    Next: PThreadInfo2;
    ThreadID: Cardinal;
    Active: Integer;
    RecursionCount: Cardinal;
  end;

  TThreadLocalCounter2 = class(TObject)
  private
    FHashTable: array [0..15] of PThreadInfo2;
    function HashIndex: Byte;
    function Recycle: PThreadInfo2;
  public
    destructor Destroy; override;
    procedure Open(var Thread: PThreadInfo2);
    procedure Delete(var Thread: PThreadInfo2);
    procedure Close(var Thread: PThreadInfo2);
  end;

{$IFEND}
{$ENDIF}

implementation

{$IFNDEF VER180}
{$IF CompilerVersion < 11.0} { Delphi 2007 }

{ TThreadLocalCounter2
  This implementation will replace TThreadLocalCounter in the next major release,
  when we can break DCU interface compatibility. }

const
  Alive = High(Integer);

function InterlockedExchangeAdd (Addend: PLongint; Value: Longint): Longint;
asm
  mov ecx, eax
  mov eax, edx
  lock xadd [ecx], eax
end;

destructor TThreadLocalCounter2.Destroy;
var
  P, Q: PThreadInfo2;
  I: Integer;
begin
  for I := 0 to High(FHashTable) do
  begin
    P := FHashTable[I];
    FHashTable[I] := nil;
    while P <> nil do
    begin
      Q := P;
      P := P^.Next;
      FreeMem(Q);
    end;
  end;
  inherited Destroy;
end;

function TThreadLocalCounter2.HashIndex: Byte;
var
  H: Word;
begin
  H := Word(GetCurrentThreadID);
  Result := (WordRec(H).Lo xor WordRec(H).Hi) and 15;
end;

procedure TThreadLocalCounter2.Open(var Thread: PThreadInfo2);
var
  P: PThreadInfo2;
  CurThread: Cardinal;
  H: Byte;
begin
  H := HashIndex;
  CurThread := GetCurrentThreadID;

  P := FHashTable[H];
  while (P <> nil) and (P.ThreadID <> CurThread) do
    P := P.Next;

  if P = nil then
  begin
    P := Recycle;

    if P = nil then
    begin
      P := PThreadInfo2(AllocMem(sizeof(TThreadInfo2)));
      P.ThreadID := CurThread;
      P.Active := Alive;

      // Another thread could start traversing the list between when we set the
      // head to P and when we assign to P.Next.  Initializing P.Next to point
      // to itself will make others spin until we assign the tail to P.Next.
      P.Next := P;
      P.Next := PThreadInfo2(InterlockedExchange(Integer(FHashTable[H]), Integer(P)));
    end;
  end;
  Thread := P;
end;

procedure TThreadLocalCounter2.Close(var Thread: PThreadInfo2);
begin
  Thread := nil;
end;

procedure TThreadLocalCounter2.Delete(var Thread: PThreadInfo2);
begin
  Thread.ThreadID := 0;
  Thread.Active := 0;
end;

function TThreadLocalCounter2.Recycle: PThreadInfo2;
var
  Gen: Integer;
begin
  Result := FHashTable[HashIndex];
  while (Result <> nil) do
  begin
    Gen := InterlockedExchange(Result.Active, Alive);
    if Gen <> Alive then
    begin
      Result.ThreadID := GetCurrentThreadID;
      Exit;
    end
    else
      Result := Result.Next;
  end;
end;

const
  mrWriteRequest = $FFFF; // 65535 concurrent read requests (threads)
                          // 32768 concurrent write requests (threads)
                          // only one write lock at a time
                          // 2^32 lock recursions per thread (read and write com

constructor TMultiReadExclusiveWriteSynchronizer.Create;
begin
  inherited Create;
  FSentinel := mrWriteRequest;
  FReadSignal := CreateEvent(nil, True, True, nil);  // manual reset, start signaled
  FWriteSignal := CreateEvent(nil, False, False, nil); // auto reset, start blocked
  FWaitRecycle := INFINITE;
  tls := TThreadLocalCounter2.Create;
end;

destructor TMultiReadExclusiveWriteSynchronizer.Destroy;
begin
  BeginWrite;
  inherited Destroy;
  CloseHandle(FReadSignal);
  CloseHandle(FWriteSignal);
  tls.Free;
end;

procedure TMultiReadExclusiveWriteSynchronizer.BeginRead;
var
  Thread: PThreadInfo2;
  WasRecursive: Boolean;
  SentValue: Integer;
begin
{$IFDEF DEBUG_MREWS}
  Debug('Read enter');
{$ENDIF}

  TThreadLocalCounter2(tls).Open(Thread);
  Inc(Thread.RecursionCount);
  WasRecursive := Thread.RecursionCount > 1;

  if FWriterID <> GetCurrentThreadID then
  begin
{$IFDEF DEBUG_MREWS}
    Debug('Trying to get the ReadLock (we did not have a write lock)');
{$ENDIF}
    // In order to prevent recursive Reads from causing deadlock,
    // we need to always WaitForReadSignal if not recursive.
    // This prevents unnecessarily decrementing the FSentinel, and
    // then immediately incrementing it again.
    if not WasRecursive then
    begin
      // Make sure we don't starve writers. A writer will
      // always set the read signal when it is done, and it is initially on.
      WaitForReadSignal;
      while (InterlockedDecrement(FSentinel) <= 0) do
      begin
  {$IFDEF DEBUG_MREWS}
        Debug('Read loop');
  {$ENDIF}
        // Because the InterlockedDecrement happened, it is possible that
        // other threads "think" we have the read lock,
        // even though we really don't. If we are the last reader to do this,
        // then SentValue will become mrWriteRequest
        SentValue := InterlockedIncrement(FSentinel);
        // So, if we did inc it to mrWriteRequest at this point,
        // we need to signal the writer.
        if SentValue = mrWriteRequest then
          UnblockOneWriter;

        // This sleep below prevents starvation of writers
        Sleep(0);

  {$IFDEF DEBUG_MREWS}
        Debug('Read loop2 - waiting to be signaled');
  {$ENDIF}
        WaitForReadSignal;
  {$IFDEF DEBUG_MREWS}
        Debug('Read signaled');
  {$ENDIF}
      end;
    end;
  end;
{$IFDEF DEBUG_MREWS}
  Debug('Read lock');
{$ENDIF}
end;

function TMultiReadExclusiveWriteSynchronizer.BeginWrite: Boolean;
var
  Thread: PThreadInfo2;
  HasReadLock: Boolean;
  ThreadID: Cardinal;
  Test: Integer;
  OldRevisionLevel: Cardinal;
begin
  {
    States of FSentinel (roughly - during inc/dec's, the states may not be exactly what is said here):
    mrWriteRequest:         A reader or a writer can get the lock
    1 - (mrWriteRequest-1): A reader (possibly more than one) has the lock
    0:                      A writer (possibly) just got the lock, if returned from the main write While loop
    < 0, but not a multiple of mrWriteRequest: Writer(s) want the lock, but reader(s) have it.
          New readers should be blocked, but current readers should be able to call BeginRead
    < 0, but a multiple of mrWriteRequest: Writer(s) waiting for a writer to finish
  }


{$IFDEF DEBUG_MREWS}
  Debug('Write enter------------------------------------');
{$ENDIF}
  Result := True;
  ThreadID := GetCurrentThreadID;
  if FWriterID <> ThreadID then  // somebody or nobody has a write lock
  begin
    // Prevent new readers from entering while we wait for the existing readers
    // to exit.
    BlockReaders;

    OldRevisionLevel := FRevisionLevel;

    TThreadLocalCounter2(tls).Open(Thread);
    // We have another lock already. It must be a read lock, because if it
    // were a write lock, FWriterID would be our threadid.
    HasReadLock := Thread.RecursionCount > 0;

    if HasReadLock then    // acquiring a write lock requires releasing read locks
      InterlockedIncrement(FSentinel);

{$IFDEF DEBUG_MREWS}
    Debug('Write before loop');
{$ENDIF}
    // InterlockedExchangeAdd returns prev value
    while InterlockedExchangeAdd(@FSentinel, -mrWriteRequest) <> mrWriteRequest do
    begin
{$IFDEF DEBUG_MREWS}
      Debug('Write loop');
      Sleep(1000); // sleep to force / debug race condition
      Debug('Write loop2a');
{$ENDIF}

      // Undo what we did, since we didn't get the lock
      Test := InterlockedExchangeAdd(@FSentinel, mrWriteRequest);
      // If the old value (in Test) was 0, then we may be able to
      // get the lock (because it will now be mrWriteRequest). So,
      // we continue the loop to find out. Otherwise, we go to sleep,
      // waiting for a reader or writer to signal us.

      if Test <> 0 then
      begin
        {$IFDEF DEBUG_MREWS}
        Debug('Write starting to wait');
        {$ENDIF}
        WaitForWriteSignal;
      end
      {$IFDEF DEBUG_MREWS}
      else
        Debug('Write continue')
      {$ENDIF}
    end;

    // At the EndWrite, first Writers are awoken, and then Readers are awoken.
    // If a Writer got the lock, we don't want the readers to do busy
    // waiting. This Block resets the event in case the situation happened.
    BlockReaders;

    // Put our read lock marker back before we lose track of it
    if HasReadLock then
      InterlockedDecrement(FSentinel);

    FWriterID := ThreadID;

    Result := Integer(OldRevisionLevel) = (InterlockedIncrement(Integer(FRevisionLevel)) - 1);
  end;

  Inc(FWriteRecursionCount);
{$IFDEF DEBUG_MREWS}
  Debug('Write lock-----------------------------------');
{$ENDIF}
end;

procedure TMultiReadExclusiveWriteSynchronizer.BlockReaders;
begin
  {$IFDEF DEBUG_MREWS}
  Debug('------------------------------- BlockReaders --------------------------');
  {$ENDIF}
  ResetEvent(FReadSignal);
end;

{procedure TMultiReadExclusiveWriteSynchronizer.Debug(const Msg: string);
begin
  OutputDebugString(PChar(Format('%d %s Thread=%x Sentinel=%d, FWriterID=%x',
    [InterlockedIncrement(x), Msg, GetCurrentThreadID, FSentinel, FWriterID])));
end;}

procedure TMultiReadExclusiveWriteSynchronizer.EndRead;
var
  Thread: PThreadInfo2;
  Test: Integer;
begin
{$IFDEF DEBUG_MREWS}
  Debug('Read end');
{$ENDIF}
  TThreadLocalCounter2(tls).Open(Thread);
  Dec(Thread.RecursionCount);
  if (Thread.RecursionCount = 0) then
  begin
     TThreadLocalCounter2(tls).Delete(Thread);

    // original code below commented out
    if (FWriterID <> GetCurrentThreadID) then
    begin
      Test := InterlockedIncrement(FSentinel);
      // It is possible for Test to be mrWriteRequest
      // or, it can be = 0, if the write loops:
      // Test := InterlockedExchangeAdd(FSentinel, mrWriteRequest) + mrWriteRequest;
      // Did not get executed before this has called (the sleep debug makes it happen faster)
      {$IFDEF DEBUG_MREWS}
      Debug(Format('Read UnblockOneWriter may be called. Test=%d', [Test]));
      {$ENDIF}
      if Test = mrWriteRequest then
        UnblockOneWriter
      else if Test <= 0 then // We may have some writers waiting
      begin
        if (Test mod mrWriteRequest) = 0 then
          UnblockOneWriter; // No more readers left (only writers) so signal one of them
      end;
    end;
  end;
{$IFDEF DEBUG_MREWS}
  Debug('Read unlock');
{$ENDIF}
end;

procedure TMultiReadExclusiveWriteSynchronizer.EndWrite;
var
  Thread: PThreadInfo2;
begin
{$IFDEF DEBUG_MREWS}
  Debug('&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&  Write end');
{$ENDIF}
  assert(FWriterID = GetCurrentThreadID);
  TThreadLocalCounter2(tls).Open(Thread);
  Dec(FWriteRecursionCount);
  if FWriteRecursionCount = 0 then
  begin
    FWriterID := 0;
    InterlockedExchangeAdd(@FSentinel, mrWriteRequest);
    {$IFDEF DEBUG_MREWS}
    Debug('Write about to UnblockOneWriter');
    {$ENDIF}
    UnblockOneWriter;
    {$IFDEF DEBUG_MREWS}
    Debug('Write about to UnblockReaders');
    {$ENDIF}
    UnblockReaders;
  end;
  if Thread.RecursionCount = 0 then
    TThreadLocalCounter2(tls).Delete(Thread);
{$IFDEF DEBUG_MREWS}
  Debug('Write unlock');
{$ENDIF}
end;

procedure TMultiReadExclusiveWriteSynchronizer.UnblockOneWriter;
begin
  {$IFDEF DEBUG_MREWS}
  Debug('UnblockOneWriter');
  {$ENDIF}
  SetEvent(FWriteSignal);
end;

procedure TMultiReadExclusiveWriteSynchronizer.UnblockReaders;
begin
  {$IFDEF DEBUG_MREWS}
  Debug('UnblockReaders +++++++++++++++++++++++++++');
  {$ENDIF}
  SetEvent(FReadSignal);
end;

procedure TMultiReadExclusiveWriteSynchronizer.WaitForReadSignal;
begin
  WaitForSingleObject(FReadSignal, FWaitRecycle);
end;

procedure TMultiReadExclusiveWriteSynchronizer.WaitForWriteSignal;
begin
  {$IFDEF DEBUG_MREWS}
  Debug('WaitForWriteSignal');
  {$ENDIF}
  WaitForSingleObject(FWriteSignal, FWaitRecycle);
end;


{$IFEND}
{$ENDIF}

end.
