unit uIniStream;

interface

uses
  Classes, inifiles;

type
  TIniStream = class(TCustomIniFile)
  private
    FSections: TStringList;
    FTargetStrings: TStrings;
    function AddSection(const Section: string): TStrings;
    procedure LoadValues(AStream: TStream);
  public
    constructor Create(AStream: TStream);
    destructor Destroy; override;
    procedure Clear;
    procedure DeleteKey(const Section, Ident: string); override;
    procedure EraseSection(const Section: string); override;
    procedure GetStrings(List: TStrings);
    procedure ReadSection(const Section: string; Strings: TStrings); override;
    procedure ReadSections(Strings: TStrings); override;
    procedure ReadSectionValues(const Section: string; Strings: TStrings); override;
    function ReadString(const Section, Ident, Default: string): string; override;
    procedure SetStrings(List: TStrings);
    procedure UpdateFile; override;
    procedure WriteString(const Section, Ident, Value: string); override;
    property TargetStrings: TStrings read FTargetStrings write FTargetStrings;
  end;

implementation

{ TIniStream }

function TIniStream.AddSection(const Section: string): TStrings;
var
  i: integer;
begin
  with FSections do begin
    i := IndexOf(Section);
    if i < 0 then begin
      Result := TStringList.Create;
      try
        AddObject(Section, Result);
      except
        Result.Free;
        result := nil;
      end;
    end else
      result := TStrings(Objects[i]);
  end;
end;

procedure TIniStream.Clear;
var
  I: Integer;
begin
  with FSections do begin
    for I := 0 to Count - 1 do
      TStrings(Objects[I]).Free;
    Clear;
  end;
end;

constructor TIniStream.Create(AStream: TStream);
begin
  inherited Create('');
  FSections := TStringList.Create;
  if not Assigned(AStream) then
    exit;
  AStream.Seek(0, soFromBeginning);
  LoadValues(AStream);
end;

procedure TIniStream.DeleteKey(const Section, Ident: string);
var
  I, J: Integer;
  Strings: TStrings;
begin
  I := FSections.IndexOf(Section);
  if I >= 0 then begin
    Strings := TStrings(FSections.Objects[I]);
    J := Strings.IndexOfName(Ident);
    if J >= 0 then Strings.Delete(J);
  end;
end;

destructor TIniStream.Destroy;
begin
  if FTargetStrings <> nil then
    GetStrings(FTargetStrings);
  if FSections <> nil then Clear;
  FSections.Free;
  inherited;
end;

procedure TIniStream.EraseSection(const Section: string);
var
  I: Integer;
begin
  I := FSections.IndexOf(Section);
  if I >= 0 then begin
    TStrings(FSections.Objects[I]).Free;
    FSections.Delete(I);
  end;
end;

procedure TIniStream.GetStrings(List: TStrings);
var
  I, J: Integer;
  Strings: TStrings;
begin
  List.BeginUpdate;
  try
    for I := 0 to FSections.Count - 1 do begin
      List.Add('[' + FSections[I] + ']');
      Strings := TStrings(FSections.Objects[I]);
      for J := 0 to Strings.Count - 1 do List.Add(Strings[J]);
      List.Add('');
    end;
  finally
    List.EndUpdate;
  end;
end;

procedure TIniStream.LoadValues(AStream: TStream);
var
  List: TStringList;
begin
  if Assigned(AStream) then begin
    List := TStringList.Create;
    try
      List.LoadFromStream(AStream);
      SetStrings(List);
    finally
      List.Free;
    end;
  end else
    Clear;
end;

procedure TIniStream.ReadSection(const Section: string; Strings: TStrings);
var
  I, J: Integer;
  SectionStrings: TStrings;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    I := FSections.IndexOf(Section);
    if I >= 0 then begin
      SectionStrings := TStrings(FSections.Objects[I]);
      for J := 0 to SectionStrings.Count - 1 do
        Strings.Add(SectionStrings.Names[J]);
    end;
  finally
    Strings.EndUpdate;
  end;
end;

procedure TIniStream.ReadSections(Strings: TStrings);
begin
  Strings.Assign(FSections);
end;

procedure TIniStream.ReadSectionValues(const Section: string; Strings: TStrings);
var
  I: Integer;
begin
  Strings.BeginUpdate;
  try
    Strings.Clear;
    I := FSections.IndexOf(Section);
    if I >= 0 then Strings.Assign(TStrings(FSections.Objects[I]));
  finally
    Strings.EndUpdate;
  end;
end;

function TIniStream.ReadString(const Section, Ident, Default: string): string;
var
  I: Integer;
  Strings: TStrings;
begin
  I := FSections.IndexOf(Section);
  if I >= 0 then begin
    Strings := TStrings(FSections.Objects[I]);
    I := Strings.IndexOfName(Ident);
    if I >= 0 then begin
      Result := Copy(Strings[I], Length(Ident) + 2, Maxint);
      Exit;
    end;
  end;
  Result := Default;
end;

procedure TIniStream.SetStrings(List: TStrings);
var
  I: Integer;
  S: string;
  Strings: TStrings;
begin
  Clear;
  Strings := nil;
  for I := 0 to List.Count - 1 do begin
    S := List[I];
    if (S <> '') and (S[1] <> ';') then
      if (S[1] = '[') and (S[Length(S)] = ']') then
        Strings := AddSection(Copy(S, 2, Length(S) - 2))
      else
        if Strings <> nil then Strings.Add(S);
  end;
end;

procedure TIniStream.UpdateFile;
begin
  if FTargetStrings <> nil then
    GetStrings(FTargetStrings);
end;

procedure TIniStream.WriteString(const Section, Ident, Value: string);
var
  I: Integer;
  S: string;
  Strings: TStrings;
begin
  I := FSections.IndexOf(Section);
  if I >= 0 then
    Strings := TStrings(FSections.Objects[I]) else
    Strings := AddSection(Section);
  S := Ident + '=' + Value;
  I := Strings.IndexOfName(Ident);
  if I >= 0 then Strings[I] := S else Strings.Add(S);
end;

end.
