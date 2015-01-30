unit uThreadSafeXorShiftRandom;

interface

function Random : Int64;
procedure Randomize;

var
  RandSeed : array[0..1] of Int64;

implementation

function Random : Int64;
var
  x, y : Int64;
begin
  x := RandSeed[0];
  y := RandSeed[1];
  RandSeed[0] := y;
  x := x xor (x shl 23);
  x := x xor (x shr 17);
  x := x xor (y xor (y shr 26));
  RandSeed[1] := x;
  Result := x + y;
end;

procedure Randomize;
begin
  System.Randomize;
  RandSeed[0] := Int64(System.Random(MaxInt)) or (Int64(System.Random(MaxInt)) shl 32);
  RandSeed[1] := Int64(System.Random(MaxInt)) or (Int64(System.Random(MaxInt)) shl 32);
end;

initialization
  Randomize;
end.
