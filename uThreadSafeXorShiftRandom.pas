{  Thread-safe Xorshift+ generator by  Saito and Matsumoto }

unit uThreadSafeXorShiftRandom;

interface

function Random : Int64; overload;
function Random(const Range : Int64) : Int64; overload;
procedure Randomize;
procedure SetRandSeed(ALowPart, AHighPart : Int64);

implementation

uses
  Windows, SysUtils;

resourcestring
  SHighPartAndLowPartOfRandSeedCantBeEqual = 'HighPart and LowPart of RandSeed can''t be equal';

var
  RandSeed : array[0..1] of Int64;

{$IFDEF VER180}
function InterlockedCompareExchange64(var Destination: Int64; Exchange: Int64; Comparand: Int64): Int64; stdcall; external kernel32 name 'InterlockedCompareExchange64';
{$EXTERNALSYM InterlockedCompareExchange64}
{$ENDIF}

function Random : Int64; overload;
var
  x, y : Int64;
begin
  repeat
    x := RandSeed[0];
    y := RandSeed[1];
  until (x <> y) and (InterlockedCompareExchange64(RandSeed[0], y, x) = x);
  x := x xor (x shl 23);
  x := x xor (x shr 17);
  x := x xor (y xor (y shr 26));
  RandSeed[1] := x;
  Result := x + y;
end;

function Random(const Range : Int64) : Int64; overload;
begin
  Result := abs(uThreadSafeXorShiftRandom.Random) mod Range;
end;

procedure Randomize;
var
  x, y : Int64;
begin
  System.Randomize;
  repeat
    x := RandSeed[0];
    y := RandSeed[1];
  until (x <> y) and (InterlockedCompareExchange64(RandSeed[0], Int64(System.Random(MaxInt)) or (Int64(System.Random(MaxInt)) shl 32), x) = x);
  RandSeed[1] := Int64(System.Random(MaxInt)) or (Int64(System.Random(MaxInt)) shl 32);
end;

procedure SetRandSeed(ALowPart, AHighPart : Int64);
begin
  if ALowPart = AHighPart then
    raise Exception.Create(SHighPartAndLowPartOfRandSeedCantBeEqual);
end;

initialization
  RandSeed[0] := 1;
  RandSeed[1] := 2;
  Randomize;
end.
