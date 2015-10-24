unit TestDeCAL;

interface

uses
  TestFramework, DeCAL, Classes;

type
  {$M+}
  TestDeCALUnit = class(TTestCase)
  private
    FAnsiString: DObject;
    {$IFDEF UNICODE}
    FUnicodeString: DObject;
    {$ENDIF}
    FStrings: TStringList;
    FDStrings: DTStrings;
    procedure CheckEqualsPtr(expected, actual: Pointer; msg: string = '');
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure asString;
    procedure getString;
    procedure Factory_CreateContainer;
    procedure hashCode;
    procedure HashLocation;
    procedure JenkinsHashBuffer;
    procedure JenkinsHashString;
    procedure JenkinsHashDObject;
    procedure PrintString;
    procedure DTStrings_add;
    procedure DTStrings_at;
    procedure DTStrings_popBack;
    procedure DTStrings_popFront;
    procedure DTStrings_pushBack;
    procedure DTStrings_pushFront;
    procedure DTStrings_putAt;
    procedure DTStrings_insertAtIter;
    procedure DTStrings_insertAt;
    procedure DTStrings_insertMultipleAtIter;
    procedure DTStrings_insertMultipleAt;
    procedure DTStrings_iterator_iget;
    procedure DTStrings_iterator_igetAt;
    procedure DTStrings_iterator_iput;
    procedure DTStrings_iterator_iputAt;
    procedure DTStrings_remove;
    procedure DTStrings_removeWithin;
    procedure _toString;
  end;

implementation

const
  TEST_STRING = 'DeCAL';
  TEST_STRING_HASH_BUFFER_ANSI = 203247719;
  TEST_STRING_HASH_BUFFER_UNICODE = 1348658116;
  TEST_STRING_HASH =
    {$IFDEF UNICODE}
    TEST_STRING_HASH_BUFFER_UNICODE
    {$ELSE}
    TEST_STRING_HASH_BUFFER_ANSI
    {$ENDIF};

{ TestLogObject }

procedure TestDeCALUnit.asString;
begin
  CheckEquals(TEST_STRING, DeCAL.AsString(FAnsiString), 'ANSI');
  {$IFDEF UNICODE}
  CheckEquals(TEST_STRING, DeCAL.AsString(FUnicodeString), 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.CheckEqualsPtr(expected, actual: Pointer; msg: string);
begin
  {$IFDEF WIN64}
  CheckEquals(NativeInt(expected), NativeInt(actual), msg);
  {$ELSE}
  CheckEquals(Integer(expected), Integer(actual), msg);
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_add;
begin
  FDStrings._add(FAnsiString);
  CheckEquals(FStrings[0], TEST_STRING, 'ANSI');
  {$IFDEF UNICODE}
  FDStrings._add(FUnicodeString);
  CheckEquals(FStrings[1], TEST_STRING, 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_at;
var
  actual: DObject;
begin
  FStrings.Add(TEST_STRING);
  actual := FDStrings.at(FStrings.Count - 1);
  CheckEquals(TEST_STRING, DeCAL.AsString(actual), 'ANSI');
end;

procedure TestDeCALUnit.DTStrings_insertAt;
begin
  FDStrings.insertAt(0, FAnsiString);
  CheckEquals(TEST_STRING, FStrings[0], 'ANSI');
  {$IFDEF UNICODE}
  FDStrings.insertAt(1, FUnicodeString);
  CheckEquals(TEST_STRING, FStrings[1], 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_insertAtIter;
begin
  FDStrings.insertAtIter(FDStrings.start, FAnsiString);
  CheckEquals(TEST_STRING, FStrings[0], 'ANSI');
  {$IFDEF UNICODE}
  FDStrings.insertAtIter(FDStrings.finish, FUnicodeString);
  CheckEquals(TEST_STRING, FStrings[1], 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_insertMultipleAt;
begin
  FDStrings.insertMultipleAt(0, 2, FAnsiString);
  CheckEquals(TEST_STRING, FStrings[0], 'ANSI');
  CheckEquals(TEST_STRING, FStrings[1], 'ANSI');
  {$IFDEF UNICODE}
  FDStrings.insertMultipleAt(2, 2, FUnicodeString);
  CheckEquals(TEST_STRING, FStrings[2], 'UNICODE');
  CheckEquals(TEST_STRING, FStrings[3], 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_insertMultipleAtIter;
begin
  FDStrings.insertMultipleAtIter(FDStrings.start, 2, FAnsiString);
  CheckEquals(TEST_STRING, FStrings[0], 'ANSI');
  CheckEquals(TEST_STRING, FStrings[1], 'ANSI');
  {$IFDEF UNICODE}
  FDStrings.insertMultipleAtIter(FDStrings.finish, 2, FUnicodeString);
  CheckEquals(TEST_STRING, FStrings[2], 'UNICODE');
  CheckEquals(TEST_STRING, FStrings[3], 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_iterator_iget;
var
  it: IIterHandler;
begin
  FStrings.Add(TEST_STRING);
  it := FDStrings as IIterHandler;
  CheckEquals(TEST_STRING, DeCAL.AsString(it.iget(FDStrings.start)^));
end;

procedure TestDeCALUnit.DTStrings_iterator_igetAt;
var
  it: IIterHandler;
begin
  FStrings.Add(TEST_STRING);
  it := FDStrings as IIterHandler;
  CheckEquals(TEST_STRING, DeCAL.AsString(it.igetAt(FDStrings.start, 0)^));
end;

procedure TestDeCALUnit.DTStrings_iterator_iput;
var
  it: IIterHandler;
begin
  it := FDStrings as IIterHandler;
  it.iput(FDStrings.start, FAnsiString);
  CheckEquals(TEST_STRING, DeCAL.AsString(it.iget(FDStrings.start)^));
end;

procedure TestDeCALUnit.DTStrings_iterator_iputAt;
var
  it: IIterHandler;
begin
  it := FDStrings as IIterHandler;
  it.iputAt(FDStrings.start, 0, FAnsiString);
  CheckEquals(TEST_STRING, DeCAL.AsString(it.iget(FDStrings.start)^));
end;

procedure TestDeCALUnit.DTStrings_popBack;
var
  actual: DObject;
begin
  FStrings.Add(TEST_STRING);
  actual := FDStrings.popBack;
  CheckEquals(0, FStrings.Count);
  CheckEquals(TEST_STRING, DeCAL.AsString(actual));
end;

procedure TestDeCALUnit.DTStrings_popFront;
var
  actual: DObject;
begin
  FStrings.Add(TEST_STRING);
  actual := FDStrings.popFront;
  CheckEquals(TEST_STRING, DeCAL.AsString(actual));
end;

procedure TestDeCALUnit.DTStrings_pushBack;
begin
  FDStrings._pushBack(FAnsiString);
  CheckEquals(TEST_STRING, FStrings[0], 'ANSI');
  {$IFDEF UNICODE}
  FDStrings._pushBack(FUnicodeString);
  CheckEquals(TEST_STRING, FStrings[1], 'ANSI');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_pushFront;
begin
  FDStrings._pushFront(FAnsiString);
  CheckEquals(TEST_STRING, FStrings[0], 'ANSI');
  {$IFDEF UNICODE}
  FDStrings._pushFront(FUnicodeString);
  CheckEquals(2, FStrings.Count, 'UNICODE');
  CheckEquals(TEST_STRING, FStrings[0], 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_putAt;
begin
  FStrings.Add('');
  FDStrings._putAt(0, FAnsiString);
  CheckEquals(TEST_STRING, FStrings[0], 'ANSI');
  {$IFDEF UNICODE}
  FStrings[0] := '';
  FDStrings._putAt(0, FUnicodeString);
  CheckEquals(TEST_STRING, FStrings[0], 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_remove;
begin
  FStrings.Add(TEST_STRING);
  FDStrings._remove(FAnsiString);
  CheckEquals(0, FStrings.Count, 'ANSI');
  {$IFDEF UNICODE}
  FStrings.Add(TEST_STRING);
  FDStrings._remove(FUnicodeString);
  CheckEquals(0, FStrings.Count, 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.DTStrings_removeWithin;
begin
  FStrings.Add(TEST_STRING);
  FDStrings.removeWithin(0, 1, FAnsiString);
  CheckEquals(0, FStrings.Count, 'ANSI');
  {$IFDEF UNICODE}
  FStrings.Add(TEST_STRING);
  FDStrings.removeWithin(0, 1, FUnicodeString);
  CheckEquals(0, FStrings.Count, 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.Factory_CreateContainer;
var
  Sequence: ISequence;
begin
  Sequence := Factory.CreateContainer(STR_LIST) as ISequence;
  CheckNotNull(Sequence);
end;

procedure TestDeCALUnit.getString;
begin
  FStrings.Add(TEST_STRING);
  CheckEquals(TEST_STRING, DeCAL.getString(FDStrings.start), 'ANSI');
  {$IFDEF UNICODE}
  CheckEquals(TEST_STRING, DeCAL.getString(FDStrings.start), 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.hashCode;
var
  actual: Integer;
begin
  actual := DeCAL.hashCode(FAnsiString);
  CheckEquals(TEST_STRING_HASH, actual, 'ANSI');
  {$IFDEF UNICODE}
  actual := DeCAL.hashCode(FUnicodeString);
  CheckEquals(TEST_STRING_HASH, actual, 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.HashLocation;
var
  loc: PChar;
  Len: Integer;
begin
  DeCAL.HashLocation(FAnsiString, loc, Len);
  CheckEqualsPtr(FAnsiString.VAnsiString, loc, 'loc');
  CheckEquals(Length(TEST_STRING), Len, 'Len');
  {$IFDEF UNICODE}
  DeCAL.HashLocation(FUnicodeString, loc, Len);
  CheckEqualsPtr(FUnicodeString.VUnicodeString, loc, 'UNICODE loc');
  CheckEquals(Length(TEST_STRING), Len, 'UNICODE Len');
  {$ENDIF}
end;

procedure TestDeCALUnit.JenkinsHashBuffer;
var
  actual: Integer;
begin
  actual := DeCAL.JenkinsHashBuffer(AnsiString(TEST_STRING), Length(TEST_STRING), 0);
  CheckEquals(TEST_STRING_HASH_BUFFER_ANSI, actual, 'ANSI');
  {$IFDEF UNICODE}
  actual := DeCAL.JenkinsHashBuffer(UnicodeString(TEST_STRING), Length(TEST_STRING) * SizeOf(Char), 0);
  CheckEquals(TEST_STRING_HASH_BUFFER_UNICODE, actual, 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.JenkinsHashDObject;
var
  actual: Integer;
begin
  actual := DeCAL.JenkinsHashDObject(FAnsiString);
  CheckEquals(TEST_STRING_HASH, actual, 'ANSI');
  {$IFDEF UNICODE}
  actual := DeCAL.JenkinsHashDObject(FUnicodeString);
  CheckEquals(TEST_STRING_HASH, actual, 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.JenkinsHashString;
var
  actual: Integer;
begin
  actual := DeCAL.JenkinsHashString(AnsiString(TEST_STRING));
  CheckEquals(TEST_STRING_HASH, actual, 'ANSI');
  {$IFDEF UNICODE}
  actual := DeCAL.JenkinsHashString(UnicodeString(TEST_STRING));
  CheckEquals(TEST_STRING_HASH, actual, 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.PrintString;
begin
  CheckEquals(TEST_STRING, DeCAL.PrintString(FAnsiString), 'ANSI');
  {$IFDEF UNICODE}
  CheckEquals(TEST_STRING, DeCAL.PrintString(FUnicodeString), 'UNICODE');
  {$ENDIF}
end;

procedure TestDeCALUnit.SetUp;
begin
  inherited;
  InitDObject(FAnsiString);
  SetDObject(FAnsiString, [AnsiString(TEST_STRING)]);
  {$IFDEF UNICODE}
  InitDObject(FUnicodeString);
  SetDObject(FUnicodeString, [UnicodeString(TEST_STRING)]);
  {$ENDIF}
  FStrings := TStringList.Create;
  FDStrings := DTStrings.Create(FStrings);
end;

procedure TestDeCALUnit.TearDown;
begin
  ClearDObject(FAnsiString);
  {$IFDEF UNICODE}
  ClearDObject(FUnicodeString);
  {$ENDIF}
  FStrings.Free;
  inherited;
end;

procedure TestDeCALUnit._toString;
begin
  CheckEquals(TEST_STRING, DeCAL.toString(FAnsiString), 'ANSI');
end;

initialization
  RegisterTest(TestDeCALUnit.Suite);

end.
