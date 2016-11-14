{
#####################################################################
##SOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOS##
 #O                                                               O#
 #V Author: Sovos Compliance, LLC                                 V#
 #O Address: 200 Ballardvale St., Building 1, 4th Floor           O#
 #S Wilmington, MA 01887, USA                                     S#
 #S www.sovos.com <http://www.sovos.com/>                         S#
 #O Contact: Tel 978-527-0000 Fax                                 O#
 #V                                                               V#
 #O THIS PROGRAM IS A PROPRIETARY PRODUCT AND MAY NOT BE USED     O#
 #S WITHOUT WRITTEN PERMISSION FROM Sovos Compliance              S#
 #S                                                               S#
 #O (c)2016 Sovos Compliance, LLC, All rights reserved.           O#
 #V THE INFORMATION CONTAINED HEREIN IS CONFIDENTIAL              V#
 #O ALL RIGHTS RESERVED                                           O#
##SOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOSSOVOS##
#####################################################################
#####################################################################
# Source File :- convey-public-libs\Tempstr.pas
#####################################################################
}

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
  SysUtils, Windows, Types;

function TTempFileStream.CreateTempFile(const APrefix : string): string;
var
  TempPath : PChar;
  TempFileName, Prefix : string;
  h : THandle;
  i : integer;
begin
  if APrefix = '' then
    Prefix := 'TmpFile'
  else Prefix := APrefix;
  FPrefix := Prefix;
  TempPath := StrAlloc (Max_Path);
  try
    GetTempPath (Max_Path, TempPath);
    i := 0;
    while True do
      begin
        TempFileName := Format('%s%s_%.8d.tmp', [TempPath, APrefix, i]);
        h := CreateFile(PAnsiChar(TempFileName), GENERIC_WRITE, 0, nil, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, 0);
        if h <> INVALID_HANDLE_VALUE then
          begin
            CloseHandle(h);
            Result := TempFileName;
            break;
          end;
        inc(i);
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
