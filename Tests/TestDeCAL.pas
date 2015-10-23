unit TestDeCAL;

interface

uses
  TestFramework, DeCAL;

type
  {$M+}
  TestDeCALUnit = class(TTestCase)
  private
    FAnsiString: DObject;
    {$IFDEF UNICODE}
    FUnicodeString: DObject;
    {$ENDIF}
    procedure CheckEqualsPtr(expected, actual: Pointer; msg: string = '');
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Factory_CreateContainer;
    procedure hashCode;
    procedure HashLocation;
    procedure JenkinsHashBuffer;
    procedure JenkinsHashString;
    procedure JenkinsHashDObject;
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

procedure TestDeCALUnit.CheckEqualsPtr(expected, actual: Pointer; msg: string);
begin
  {$IFDEF WIN64}
  CheckEquals(NativeInt(expected), NativeInt(actual), msg);
  {$ELSE}
  CheckEquals(Integer(expected), Integer(actual), msg);
  {$ENDIF}
end;

procedure TestDeCALUnit.Factory_CreateContainer;
var
  Sequence: ISequence;
begin
  Sequence := Factory.CreateContainer(STR_LIST) as ISequence;
  CheckNotNull(Sequence);
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

procedure TestDeCALUnit.SetUp;
begin
  inherited;
  InitDObject(FAnsiString);
  SetDObject(FAnsiString, [AnsiString(TEST_STRING)]);
  {$IFDEF UNICODE}
  InitDObject(FUnicodeString);
  SetDObject(FUnicodeString, [UnicodeString(TEST_STRING)]);
  {$ENDIF}
end;

procedure TestDeCALUnit.TearDown;
begin
  ClearDObject(FAnsiString);
  {$IFDEF UNICODE}
  ClearDObject(FUnicodeString);
  {$ENDIF}
  inherited;
end;

initialization
  RegisterTest(TestDeCALUnit.Suite);

end.
