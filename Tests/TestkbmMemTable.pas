unit TestkbmMemTable;

interface

uses
  TestFramework, kbmMemTable;

type
  {$M+}
  TestkbmMemTableUnit = class(TTestCase)
  private
    FTable: TkbmMemTable;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure AppendRecord;
    procedure InsertRecord;
    procedure BookmarkValid;
    procedure CompareBookmarks;
    procedure GetBookmark;
    procedure Locate;
    procedure CSVStreamFormat;
    procedure BinaryStreamFormat;
  end;


implementation

uses Db, Variants, Classes, kbmMemCSVStreamFormat, kbmMemBinaryStreamFormat;

const
  STRING_FIELD_NAME = 'ftString';

{ TestkbmMemTableUnit }

procedure TestkbmMemTableUnit.AppendRecord;
const
  expected: string = 'string';
begin
  FTable.AppendRecord([expected]);
  CheckEquals(expected, FTable.FieldByName(STRING_FIELD_NAME).AsString);
end;

procedure TestkbmMemTableUnit.BinaryStreamFormat;
const
  expected: string = 'string';
var
  ms: TMemoryStream;
  fmt: TkbmCustomStreamFormat;
begin
  FTable.InsertRecord([expected]);
  ms := TMemoryStream.Create;
  try
    fmt := TkbmCustomBinaryStreamFormat.Create(nil);
    try
      FTable.DefaultFormat := fmt;
      FTable.SaveToStream(ms);
      FTable.Close;
      FTable.Open;
      ms.Position := 0;
      FTable.LoadFromStream(ms);
      FTable.First;
      CheckEquals(expected, FTable.FieldByName(STRING_FIELD_NAME).AsString);
    finally
      fmt.Free;
    end;
  finally
    ms.Free;
  end;
end;

procedure TestkbmMemTableUnit.BookmarkValid;
var
  bookmark: TBookmark;
begin
  FTable.InsertRecord(['']);
  bookmark := FTable.GetBookmark;
  CheckTrue(FTable.BookmarkValid(bookmark));
end;

procedure TestkbmMemTableUnit.CompareBookmarks;
var
  bm1, bm2: TBookmark;
begin
  FTable.InsertRecord(['1']);
  bm1 := FTable.GetBookmark;
  FTable.InsertRecord(['2']);
  bm2 := FTable.GetBookmark;
  CheckEquals(-1, FTable.CompareBookmarks(bm1, bm2));
end;

procedure TestkbmMemTableUnit.GetBookmark;
const
  expected: string = 'string';
var
  bookmark: TBookmark;
begin
  FTable.InsertRecord(['']);
  FTable.InsertRecord([expected]);
  bookmark := FTable.GetBookmark;
  CheckEquals(1, FTable.RecNo);
  CheckEquals(2, FTable.RecordCount);
  FTable.Last;
  FTable.GotoBookmark(bookmark);
  CheckEquals(expected, FTable.FieldByName(STRING_FIELD_NAME).AsString);
end;

procedure TestkbmMemTableUnit.InsertRecord;
const
  expected: string = 'string';
begin
  FTable.AppendRecord(['']);
  FTable.InsertRecord([expected]);
  CheckEquals(1, FTable.RecNo);
  CheckEquals(2, FTable.RecordCount);
  CheckEquals(expected, FTable.FieldByName(STRING_FIELD_NAME).AsString);
end;

procedure TestkbmMemTableUnit.Locate;
const
  expected: string = 'string';
begin
  FTable.InsertRecord(['']);
  FTable.InsertRecord([expected]);
  CheckEquals(1, FTable.RecNo);
  CheckEquals(2, FTable.RecordCount);
  CheckTrue(FTable.Locate(STRING_FIELD_NAME, VarArrayOf([expected]), []));
  CheckEquals(expected, FTable.FieldByName(STRING_FIELD_NAME).AsString);
end;

procedure TestkbmMemTableUnit.CSVStreamFormat;
const
  expected: string = 'string';
var
  ms: TMemoryStream;
  fmt: TkbmCustomStreamFormat;
begin
  FTable.InsertRecord([expected]);
  ms := TMemoryStream.Create;
  try
    fmt := TkbmCustomCSVStreamFormat.Create(nil);
    try
      FTable.DefaultFormat := fmt;
      FTable.SaveToStream(ms);
      FTable.Close;
      FTable.Open;
      ms.Position := 0;
      FTable.LoadFromStream(ms);
      FTable.First;
      CheckEquals(expected, FTable.FieldByName(STRING_FIELD_NAME).AsString);
    finally
      fmt.Free;
    end;
  finally
    ms.Free;
  end;
end;

procedure TestkbmMemTableUnit.SetUp;
begin
  inherited;
  FTable := TkbmMemTable.Create(nil);
  FTable.FieldDefs.Add(STRING_FIELD_NAME, ftString, 10);
  FTable.Active := True;
end;

procedure TestkbmMemTableUnit.TearDown;
begin
  FTable.Free;
  inherited;
end;

initialization
  RegisterTest(TestkbmMemTableUnit.Suite);

end.
