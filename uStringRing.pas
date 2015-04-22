unit uStringRing;

interface

type
  TStringRing = class
  private
    FStrings : array of String;
    FCurIndex : Integer;
  public
    constructor Create(AElementCount : Cardinal);
    function NextString(const s: String): String;
  end;

implementation

uses
  Windows;

constructor TStringRing.Create(AElementCount : Cardinal);
begin
  inherited Create;
  SetLength(FStrings, AElementCount);
  FCurIndex := -1;
end;

function TStringRing.NextString(const s: String): String;
var
  ACurIndex : Integer;
begin
  repeat
    ACurIndex := InterlockedIncrement(FCurIndex);
    if ACurIndex > high(FStrings) then
      begin
        InterlockedCompareExchange(FCurIndex, -1, ACurIndex);
        continue;
      end;
  until ACurIndex <= high(FStrings);
  FStrings[ACurIndex] := s;
  Result := FStrings[ACurIndex];
end;

end.
