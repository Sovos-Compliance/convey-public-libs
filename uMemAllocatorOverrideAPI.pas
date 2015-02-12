(*
The MIT License (MIT)

Copyright (c) 2015 Convey Compliance Systems, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*)

unit uMemAllocatorOverrideAPI;

interface

type
  TGetMem = function(Size: NativeInt): Pointer; cdecl;
  TFreeMem = function(P: Pointer): Integer; cdecl;
  TReallocMem = function(P: Pointer; Size: NativeInt): Pointer; cdecl;

procedure OverrideMemAllocator(pGetMem : TGetMem; pReallocMem : TReallocMem; pFreeMem : TFreeMem); cdecl;
procedure ResetMemAllocator; cdecl;

implementation

uses
  Math;

const
  OVERALLOCSIZE = sizeof(Pointer) + sizeof(NativeUInt);

var
  CustomAllocator : TMemoryManagerEx;
  OldAllocator : TMemoryManagerEx;
  OverridenAllocator : TMemoryManagerEx;
  pCustomGetMem : TGetMem;
  pCustomReallocMem : TReallocMem;
  pCustomFreeMem : TFreeMem;

function CustomGetMem(Size: NativeInt): Pointer; forward;

{ Wrappers to call overriden memory allocator }

function OverridenFreeMem(P: Pointer): Integer;
begin
  if Assigned(pCustomFreeMem) then  
    Result := pCustomFreeMem(P)
  else
    Result := 0; // If we got here it's a mem leak of overriden allocator already reset. We can't free the memory
end;

function OverridenReallocMem(P: Pointer; Size: NativeInt): Pointer;
begin
  if Assigned(pCustomReallocMem) then
    Result := pCustomReallocMem(P, Size)
  else
  begin
    // If we got here means the block was originally allocated using overriden allocator, now
    // we must allocate using OldAllocator. So we will do GetMem and move memory
    // Import to note that the pointer here is already adjusted to REAL pointer start
    // So to obtain size we need to increase one NativeUInt
    Result := CustomGetMem(Size - OVERALLOCSIZE); // Size already inflated, that's why we substract OVERALLOCSIZE
    move(Pointer(NativeUInt(P) + OVERALLOCSIZE)^, Result^, Min(PNativeUInt(NativeUInt(P) + sizeof(Pointer))^, NativeUInt(Size - OVERALLOCSIZE)));
    dec(NativeUInt(Result), OVERALLOCSIZE); // We need to return pointer adjusted as normal allocator would do
  end;
end;

function OverridenRegisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  Result := False;
end;

function OverridenUnregisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  Result := False;
end;

{ Wrappers to direct call to appropiate allocator }

function CustomGetMem(Size: NativeInt): Pointer;
begin
  if Assigned(pCustomGetMem) then
    begin
      Result := pCustomGetMem(Size + OVERALLOCSIZE);
      PPointer(Result)^ := @OverridenAllocator;
    end
  else
    begin
      Result := OldAllocator.GetMem(Size + OVERALLOCSIZE);
      PPointer(Result)^ := @OldAllocator;
    end;
  inc(NativeUInt(Result), sizeof(Pointer));
  PNativeUInt(Result)^ := Size;
  inc(NativeUInt(Result), sizeof(NativeUInt));
end;

function CustomFreeMem(P: Pointer): Integer;
begin
  dec(NativeUInt(p), OVERALLOCSIZE);
  Result := PMemoryManagerEx(PPointer(p)^)^.FreeMem(p);
end;

function CustomReallocMem(P: Pointer; Size: NativeInt): Pointer;
begin
  if p <> nil then
    begin
      dec(NativeUInt(p), OVERALLOCSIZE);
      Result := PMemoryManagerEx(PPointer(p)^)^.ReallocMem(P, Size + OVERALLOCSIZE);
      inc(NativeUInt(Result), sizeof(Pointer));
      PNativeUInt(Result)^ := Size;
      inc(NativeUInt(Result), sizeof(NativeUInt));
    end
    else Result := CustomGetMem(Size);
end;

function CustomAllocMem(Size: NativeInt): Pointer;
begin
  Result := CustomGetMem(Size);
  FillChar(Result^, Size, 0);
end;

function CustomRegisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  dec(NativeUInt(p), OVERALLOCSIZE);
  Result := PMemoryManagerEx(PPointer(p)^)^.RegisterExpectedMemoryLeak(p);
end;

function CustomUnregisterExpectedMemoryLeak(P: Pointer): Boolean;
begin
  dec(NativeUInt(p), OVERALLOCSIZE);
  Result := PMemoryManagerEx(PPointer(p)^)^.UnregisterExpectedMemoryLeak(p);
end;

{ APIs to override the memory allocator }

procedure OverrideMemAllocator(pGetMem : TGetMem; pReallocMem : TReallocMem;
    pFreeMem : TFreeMem);
begin
  pCustomGetMem := pGetMem;
  pCustomReallocMem := pReallocMem;
  pCustomFreeMem := pFreeMem;
end;

procedure ResetMemAllocator;
begin
  pCustomGetMem := nil;
  pCustomReallocMem := nil;
  pCustomFreeMem := nil;
end;

initialization
  CustomAllocator.GetMem := CustomGetMem;
  CustomAllocator.FreeMem := CustomFreeMem;
  CustomAllocator.ReallocMem := CustomReallocMem;
  CustomAllocator.AllocMem := CustomAllocMem;
  CustomAllocator.RegisterExpectedMemoryLeak := CustomRegisterExpectedMemoryLeak;
  CustomAllocator.UnregisterExpectedMemoryLeak := CustomUnregisterExpectedMemoryLeak;
  OverridenAllocator.GetMem := nil;
  OverridenAllocator.FreeMem := OverridenFreeMem;
  OverridenAllocator.ReallocMem := OverridenReallocMem;
  OverridenAllocator.AllocMem := nil;
  OverridenAllocator.RegisterExpectedMemoryLeak := OverridenRegisterExpectedMemoryLeak;
  OverridenAllocator.UnregisterExpectedMemoryLeak := OverridenUnregisterExpectedMemoryLeak;
  GetMemoryManager(OldAllocator);
  SetMemoryManager(CustomAllocator);
finalization
  SetMemoryManager(OldAllocator);
end.
