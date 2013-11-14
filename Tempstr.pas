{ This class implements a temporary file stream }

unit TempStr;

interface

uses
  Classes;

type
  TTempFileStream = class (TFileStream)
  private
    FFileName : string;
    FPrefix: string;
    function CreateTempFile(const APrefix : string): string;
    procedure AddToList;
  public
    constructor Create (const Directory : string);
    constructor CreatePrefix(const APrefix: string; Dummy: Integer = 0); // Dummy added to avoid C++ warning
    destructor Destroy; override;
    property FileName : string read FFileName;
    property Prefix: string read FPrefix;
  end;

  TVolatileTempFileStream = class (TTempFileStream)
  public
    destructor Destroy; override;
  end;

var
  TmpFileList : TThreadList;

implementation

uses
  SysUtils, Windows;

function TTempFileStream.CreateTempFile(const APrefix : string): string;
var
  TempPath, TempName : PChar;
  n, i : integer;
begin
  FPrefix := APrefix;
  TempPath := StrAlloc (Max_Path);
  try
    GetTempPath (Max_Path, TempPath);
    TempName := StrAlloc (Max_Path);
    try
      i := 0;
      repeat
        n := GetTempFileName (TempPath, PChar (APrefix), 0, TempName);
        if n = 0
          then raise Exception.Create ('Error getting temp file name');
        Result := StrPas (TempName);
        sleep (i * 100);
        inc (i);
        if i > 10
          then raise Exception.Create ('Error getting temp file name. It couldn''t create the file on the temp folder');
      until FileExists (Result);
    finally
      StrDispose (TempName);
    end;
  finally
    StrDispose (TempPath);
  end;
end;

constructor TTempFileStream.Create;
var
  Dir : string;
  i : integer;
begin
  Dir := ExtractFilePath (Directory);
  i := 0;
  repeat
    FFileName := Format ('%s%.8d.tmp', [Dir, i]);
    inc (i);
  until not FileExists (FFileName);
  inherited Create (FFileName, fmCreate or fmOpenReadWrite);
  AddToList;
end;

constructor TTempFileStream.CreatePrefix(const APrefix: string; Dummy: Integer
    = 0);
begin
  FPrefix := APrefix;
  FFileName := CreateTempFile (APrefix);
  inherited Create (FFileName, fmOpenReadWrite);
  AddToList;
end;

procedure TTempFileStream.AddToList;
begin
  TmpFileList.Add (self);
end;

destructor TTempFileStream.Destroy;
begin
  TmpFileList.Remove (self);
  inherited;
end;

destructor TVolatileTempFileStream.Destroy;
begin
  inherited;
  DeleteFile (PChar (FileName));
end;

initialization
  TmpFileList := TThreadList.Create;
finalization
  FreeAndNil (TmpFileList);
end.
