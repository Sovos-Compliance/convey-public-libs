unit uMemAllocatorOverrideAPI;

interface

type
  TGetMem = function(Size: NativeInt): Pointer; cdecl;
  TFreeMem = function(P: Pointer): Integer; cdecl;
  TReallocMem = function(P: Pointer; Size: NativeInt): Pointer; cdecl;

procedure OverrideMemAllocator(pGetMem : TGetMem; pReallocMem : TReallocMem; pFreeMem : TFreeMem); cdecl;
procedure ResetMemAllocator; cdecl;

implementation

var
  CustomAllocator : TMemoryManagerEx;
  OldAllocator : TMemoryManagerEx;
  pCustomGetMem : TGetMem;
  pCustomReallocMem : TReallocMem;
  pCustomFreeMem : TFreeMem;

procedure OverrideMemAllocator(pGetMem : TGetMem; pReallocMem : TReallocMem;
    pFreeMem : TFreeMem);
begin
  GetMemoryManager(OldAllocator);
  SetMemoryManager(CustomAllocator);
  pCustomGetMem := pGetMem;
  pCustomReallocMem := pReallocMem;
  pCustomFreeMem := pFreeMem;
end;

procedure ResetMemAllocator;
begin
  SetMemoryManager(OldAllocator);
end;

function CustomGetMem(Size: NativeInt): Pointer;
begin
  Result := pCustomGetMem(Size);
end;

function CustomFreeMem(P: Pointer): Integer;
begin
  Result := pCustomFreeMem(p);
end;

function CustomReallocMem(P: Pointer; Size: NativeInt): Pointer;
begin
  Result := pCustomReallocMem(P, Size);
end;

function CustomAllocMem(Size: NativeInt): Pointer;
begin
  Result := OldAllocator.AllocMem(Size);
end;

function CustomRegisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  Result := OldAllocator.RegisterExpectedMemoryLeak(p);
end;

function CustomUnregisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  Result := OldAllocator.UnregisterExpectedMemoryLeak(p);
end;

initialization
  CustomAllocator.GetMem := CustomGetMem;
  CustomAllocator.FreeMem := CustomFreeMem;
  CustomAllocator.ReallocMem := CustomReallocMem;
  CustomAllocator.AllocMem := CustomAllocMem;
  CustomAllocator.RegisterExpectedMemoryLeak := CustomRegisterExpectedMemoryLeak;
  CustomAllocator.UnregisterExpectedMemoryLeak := CustomUnregisterExpectedMemoryLeak;
end.
