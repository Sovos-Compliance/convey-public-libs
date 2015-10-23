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
    procedure Test;
    procedure HashLocation;
    procedure JenkinsHashString;
  end;

implementation

const
  TEST_STRING = 'DeCAL';

{ TestLogObject }

procedure TestDeCALUnit.CheckEqualsPtr(expected, actual: Pointer; msg: string);
begin
  {$IFDEF WIN64}
  CheckEquals(NativeInt(expected), NativeInt(actual), msg);
  {$ELSE}
  CheckEquals(Integer(expected), Integer(actual), msg);
  {$ENDIF}
end;

procedure TestDeCALUnit.HashLocation;
var
  loc: PChar;
  Len: Integer;
begin
  DeCAL.HashLocation(FAnsiString, loc, Len);
  CheckEqualsPtr(FAnsiString.vAnsistring, loc, 'loc');
  CheckEquals(Length(TEST_STRING), Len, 'Len');
  {$IFDEF UNICODE}
  DeCAL.HashLocation(FUnicodeString, loc, Len);
  CheckEqualsPtr(FUnicodeString.VUnicodeString, loc, 'UNICODE loc');
  CheckEquals(Length(TEST_STRING), Len, 'UNICODE Len');
  {$ENDIF}
end;

procedure TestDeCALUnit.JenkinsHashString;
const
  expected = 1348658116;
var
  actual: Integer;
begin
  actual := DeCAL.JenkinsHashString(AnsiString(TEST_STRING));
  CheckEquals(expected, actual);
  {$IFDEF UNICODE}
  actual := DeCAL.JenkinsHashString(UnicodeString(TEST_STRING));
  CheckEquals(expected, actual, 'UNICODE');
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

procedure TestDeCALUnit.Test;
var
  Sequence: ISequence;
begin
  Sequence := Factory.CreateContainer(STR_LIST) as ISequence;
  CheckNotNull(Sequence);
end;

initialization
  RegisterTest(TestDeCALUnit.Suite);

end.
