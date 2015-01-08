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
