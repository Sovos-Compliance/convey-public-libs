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
    class function GenerateTempFileName(const ATempPath: string; const APrefix: String = ''): string;
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
  i : integer;
begin
  FPrefix := APrefix;
  TempPath := StrAlloc (Max_Path);
  try
    GetTempPath (Max_Path, TempPath);
    i := 0;
    repeat
      Result := GenerateTempFileName (TempPath, APrefix);
      sleep (i * 100);
      inc (i);
      if i > 10
        then raise Exception.Create ('Error getting temp file name. It couldn''t create the file on the temp folder');
    until FileExists (Result);
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

class function TTempFileStream.GenerateTempFileName(const ATempPath: string; const APrefix: String = ''): string;
var
  i : integer;
  TempPath, Prefix : string;
  F : Text;
begin
  if ATempPath[Length(ATempPath)] = '\' then
    TempPath := ATempPath
  else TempPath := ATempPath + '\';
  if APrefix = '' then
    Prefix := 'TmpFile'
  else Prefix := APrefix;

  for i := 0 to 10000000 do
    begin
      Result := Format('%s%s_%.8d.tmp', [TempPath, APrefix, i]);
      if not FileExists(Result) then
        break;
    end;
  Assign(f, Result);
  try
    ReWrite(f);
  finally
    CloseFile(f);
  end;
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
