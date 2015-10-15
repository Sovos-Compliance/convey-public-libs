unit CnvFileUtils;

interface

uses
  Classes, SysUtils, Graphics;

const
  SFindFirst = 'FindFirst';
  SFindNext = 'FindNext';
  SFindClose = 'FindClose';
  SCNV = 'CNV';
  SVarFileInfoTranslation = '\VarFileInfo\Translation';
  SStringFileInfo = '\StringFileInfo\';
  SCONVEYZLIBSTREAM = 'CONVEY_ZLIB_STREAM';

resourcestring
  STR_ThisClassCanTBeCreatedDirectlyBy = 'This class can''t be created directly by the user';

type
  TCharSet = set of Char;
  TCompressionNotification = procedure (var ContinueCompression : Boolean) of object;

  TFindCloseMethod = procedure (var F: TSearchRec) of object;
  TFindFirstMethod = function (const Path: string; Attr: Integer; var F: TSearchRec):Integer of object;
  TFindNextMethod =  function (var F: TSearchRec): Integer of object;

  TBasicFileSystem = class
  private
    FOwner: TObject;
    constructor InternalCreate(AOwner : TObject);
  public
    constructor Create;
  published
    procedure FindClose(var F: TSearchRec);
    function FindFirst(const Path: string; Attr: Integer; var F: TSearchRec):
        Integer;
    function FindNext(var F: TSearchRec): Integer;
  end;

  PSearchRec = ^TSearchRec;
  TFilesStringList = class (TStringList)
  private
    FFileSystem: TObject;
    FindFirstMethod : TFindFirstMethod;
    FindNextMethod : TFindNextMethod;
    FindCloseMethod : TFindCloseMethod;
    procedure FillList(const FileMask : string; Attr : integer; RecurseFolders :
        boolean = False);
    function GetSearchRecs(Index: Integer): TSearchRec;
    function GetPSearchRecs(Index: Integer): PSearchRec;
    procedure InitMethods;
  public
    constructor Create(const FileMask : string; RecurseFolders : boolean = False);
        overload;
    constructor Create(const FileMask : string; Attr : integer; RecurseFolders :
        boolean = False); overload;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    destructor Destroy; override;
    constructor Create(const AFileSystem : TObject; FileMask : string; 
        RecurseFolders : boolean = False); overload;
    constructor Create(const AFileSystem : TObject; FileMask : string; Attr : 
        integer; RecurseFolders : boolean = False); overload;
    property SearchRecs[Index: Integer]: TSearchRec read GetSearchRecs;
    property PSearchRecs[Index: Integer]: PSearchRec read GetPSearchRecs;
  end;

  TCnvMemoryStream = class (TMemoryStream)
  public
    property Capacity;
  end;

function GenerateTempFileName(Prefix : string = 'CNV'): string;
function ExtractOnlyFileName(const FileName : string): string;
function ConsolidatePath(const Path : string): string;
function TempPath: string;
function StripFileName(const FileName: string; Canvas : TCanvas; Width : 
    Integer): string;
function MakePathShorterByOneDir(Var Pad: String; PadChars : TCharSet): Boolean;
function KortPadIn(Pad: String; maxL: Integer; PadChars : TCharSet): string;
procedure DeleteFiles(const FileMask : string);
function FileMaskToSQLMask(const Mask : String): string;
function MatchesCommaSeparatedMasks(const FileName, Masks : string): Boolean;
procedure RegisterFileToDelete(const FileName : string);
procedure DeleteRegisteredFiles;
function StripDrive(const FName : string): string;
procedure ReadLn(s : TStream; var AStr : string);
procedure DumpToDisk(const AFileName, AContents : string);
function CnvGetFileDate(const AName : string): TDateTime;
function MakePathRelative(RelativeTo, SourcePath: string): string;
function StringIsMask(const s : string): Boolean;

// Compression and decompression utilities

{$IFNDEF CNVFILEUTILS_LIGHT}
function CreateCompressedStream(Stream : TStream; WriteSignature : boolean;
    CallBack : TCompressionNotification = nil): TStream;
procedure DecompressStream (Source, Target : TStream);
{$ENDIF}

function GetFileInfo(const AFileName: String): TSearchRec;

function CalculateFileCRC(const AFileName: string): cardinal;

function FileContains(const AFileName, AStrToSearchFor: string; const
    CaseSensitive: boolean = False): boolean;

var
  ZLIB_SIGNATURE : string;

implementation

uses
  Windows, FastStrings, Masks,
  {$IFNDEF CNVFILEUTILS_LIGHT}
  CnvZlib,
  {$ENDIF}
  CnvStrUtils, Math, uScope, uCRC32;

var
  FilesToDelete : TStringList;

function AllocBuffer (var ABufSize : integer) : Pointer;
begin
  Result := nil;
  repeat
    try
      GetMem (Result, ABufSize);
      if Result = nil
        then ABufSize := ABufSize div 2;
    except
      on E : EOutOfMemory do
        begin
          Result := nil;
          ABufSize := ABufSize div 2;
        end;
    end;
  until Result <> nil;
end;

constructor TFilesStringList.Create(const FileMask : string; Attr : integer;
    RecurseFolders : boolean = False);
begin
  inherited Create;
  FFileSystem := TBasicFileSystem.InternalCreate (self);
  InitMethods;
  FillList (FileMask, Attr, RecurseFolders);
end;

constructor TFilesStringList.Create(const FileMask : string; RecurseFolders :
    boolean = False);
begin
  inherited Create;
  FFileSystem := TBasicFileSystem.InternalCreate (self);
  InitMethods;
  FillList (FileMask, 0, RecurseFolders);
end;

procedure TFilesStringList.FillList(const FileMask : string; Attr : integer;
    RecurseFolders : boolean = False);
const
  PathDelimiters : set of char = ['\', '/'];
var
  R : TSearchRec;
  PR : PSearchRec;
  FindResult : integer;
  Path : string;
  List : TFilesStringList;
  k, i : integer;
  Masks : TAdvStringList;
begin
  Masks := TAdvStringList.Create;
  try
    Masks.TokenSeparator := '|';
    Masks.TokenizedText := FileMask;
    for k := 0 to Masks.Count - 1 do
      begin
        Path := ExtractFilePath (Masks [k]);
        while (length (Path) > 1) and (Path [length (Path)] in PathDelimiters) and
              (Path [length (Path) - 1] in PathDelimiters) do
          SetLength (Path, length (Path) - 1);
        FindResult := FindFirstMethod (Masks [k], Attr, R);
        try
          if FindResult = 0
            then repeat
              New (PR);
              try
                PR^ := R;
                AddObject (Path + R.Name, TObject (PR));
              except
                Dispose (PR);
                raise;
              end;
            until FindNextMethod (R) <> 0;
        finally
          FindCloseMethod (R);
        end;
        if RecurseFolders
          then
          begin
            List := TFilesStringList.Create (FFileSystem, ExtractFilePath (Masks [k]) + '*', faDirectory or Attr);
            try
              for i := 0 to List.Count - 1 do
                if (List.SearchRecs [i].Attr and faDirectory <> 0) and
                   (List [i][length (List [i])] <> '.')
                  then FillList (List [i] + '\' + ExtractFileName (Masks [k]), Attr, True);
            finally
              List.Free;
            end;
          end;
      end;
  finally
    Masks.Free;
  end;
end;

function TFilesStringList.GetSearchRecs(Index: Integer): TSearchRec;
begin
  Result := PSearchRec (Objects [Index])^;
end;

procedure TFilesStringList.Clear;
var
  i : integer;
begin
  for i := 0 to Count - 1 do
    if Objects [i] <> nil
      then
      begin
        Dispose (PSearchRec (Objects [i]));
        Objects [i] := nil;
      end;
  inherited;
end;

procedure TFilesStringList.Delete(Index: Integer);
begin
  Dispose (PSearchRec (Objects [Index]));
  Objects [Index] := nil;
  inherited Delete (Index);
end;

destructor TFilesStringList.Destroy;
begin
  Clear;
  if (FFileSystem is TBasicFileSystem) and ((FFileSystem as TBasicFileSystem).FOwner = Self)
    then FFileSystem.Free;
  inherited;
end;

procedure TFilesStringList.InitMethods;
begin
  TMethod (FindFirstMethod).Data := FFileSystem;
  TMethod (FindFirstMethod).Code := FFileSystem.MethodAddress (SFindFirst);
  TMethod (FindNextMethod).Data := FFileSystem;
  TMethod (FindNextMethod).Code := FFileSystem.MethodAddress (SFindNext);
  TMethod (FindCloseMethod).Data := FFileSystem;
  TMethod (FindCloseMethod).Code := FFileSystem.MethodAddress (SFindClose);
end;

constructor TFilesStringList.Create(const AFileSystem : TObject; FileMask :
    string; RecurseFolders : boolean = False);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  InitMethods;
  FillList (FileMask, 0, RecurseFolders);
end;

constructor TFilesStringList.Create(const AFileSystem : TObject; FileMask : 
    string; Attr : integer; RecurseFolders : boolean = False);
begin
  inherited Create;
  FFileSystem := AFileSystem;
  InitMethods;
  FillList (FileMask, Attr, RecurseFolders);
end;

function TFilesStringList.GetPSearchRecs(Index: Integer): PSearchRec;
begin
  Result := PSearchRec (Objects [Index]);
end;

{ Procedures and functions }

function GenerateTempFileName(Prefix : string = SCNV): string;
var
  TmpPath : PChar;
  TmpResult : PChar;
begin
  Result := '';
  GetMem (TmpPath, MAX_PATH + 1);
  try
    if GetTempPath (MAX_PATH + 1, TmpPath) <= MAX_PATH
      then
      begin
        GetMem (TmpResult, MAX_PATH + 1);
        try
          if GetTempFileName (TmpPath, PChar (Prefix), 0, TmpResult) <> 0
            then Result := StrPas (TmpResult);
        finally
          FreeMem (TmpResult, MAX_PATH + 1);
        end;
      end;
  finally
    FreeMem (TmpPath, MAX_PATH + 1);
  end;
end;

function ExtractOnlyFileName(const FileName : string): string;
begin
  Result := system.Copy (FileName, 1, Length (FileName) - Length (ExtractFileExt (FileName)));
end;

function ConsolidatePath(const Path : string): string;
begin
  if Path <> ''
    then if Path [Length (Path)] <> '\'
      then Result := Path + '\'
      else Result := Path;
end;

function TempPath: string;
var
  TmpPath : PChar;
begin
  Result := '';
  GetMem (TmpPath, MAX_PATH + 1);
  try
    if GetTempPath (MAX_PATH + 1, TmpPath) <= MAX_PATH
      then Result := ConsolidatePath (StrPas (TmpPath));
  finally
    FreeMem (TmpPath, MAX_PATH + 1);
  end;
end;

function MakePathShorterByOneDir(Var Pad: String; PadChars : TCharSet): Boolean;
{Try to remove the most left directory in the 'Pad'.}
var
  LengthPadIn: Integer;
  i: Integer;
  NewPad: String;
begin
  LengthPadIn := length(Pad);
  NewPad := Pad;
  i:= LengthPadIn;
  while (length(NewPad) = LengthPadIn) and (i > 18) do
  begin
    NewPad := KortPadIn(NewPad, i, PadChars);
    dec(i);
  end;
  Pad := NewPad;
  if (length(NewPad) = LengthPadIn) then
    Result := False
  else
    Result := True;
end;

function KortPadIn(Pad: String; maxL: Integer; PadChars : TCharSet): string;
{ Tested for:
  E:\dcode\remainde\rem.db 19 -> E:\..rem.db
  E:\dcode\remainde\rem.db 20 -> E:\..\remainde\rem.db
  E:\dcode\remainde\test\a 19 -> E:\..\test\a
  E:\dcode\remainde\test\a 20 -> E:\..\remainde\test\a
  1995, Turbo Pascal }
const
  start = 6;      {for e.g. 'c:\...' }
  MinFileL = 12;  {8 characters for the name bevore the point
                   3 characters for the extention and 1 for the point.}
var
  TempPad: String;
  Lfile: Integer;  {lengte filenaam}
  i: Integer;
begin
  If (length(Pad) > maxL) and (maxL > (start+MinFileL) ) then
  {stop if: -path is short enaugh or
            -The new to make path lenght is shorter then (start+MinFileL) characters (6 + 12). }
  begin
    Lfile := Length(Pad);
    for i := Length(Pad) downto 0 do     {Determen length filename}
    begin
      If Pad[i] in ['\', '.'] then
      begin
        Lfile := Length(Pad)-i;
        Break;
      end;
    end;
    if (Lfile + start) >= maxL then
      TempPad := copy(Pad, length(Pad)-Lfile, 255)
    else
      TempPad := copy(Pad, length(Pad)-maxL+start, 255);

    if (length(TempPad)-Lfile) > 1 then
    begin
    {find the first '\' or '.' from the left}
    for i := 1 to (length(TempPad)-Lfile) do
    begin
      If TempPad[i] in ['\', '.'] then
      begin
        {copy everything after the first '\' or '.' from the left}
        TempPad := copy(TempPad, i, 255);
        Break;
      end;
    end;
    end;
    TempPad := copy(Pad, 1, 3) + '...' + TempPad;
    KortPadIn := TempPad;
  end
  else
    KortPadIn := Pad;
end;

function StripFileName(const FileName: string; Canvas : TCanvas; Width : 
    Integer): string;
var
  w : Integer;
  PadChars : TCharSet;
begin
  Result := FileName;
  if FastCharPos (Result, '\', 1) > 0
    then PadChars := ['\']
    else PadChars := ['.'];
  repeat
    w := Canvas.TextWidth (Result);
  until (w <= Width) or (not MakePathShorterByOneDir (Result, PadChars));
end;

procedure DeleteFiles(const FileMask : string);
var
  Files : TFilesStringList;
  i : Integer;
begin
  Files := TFilesStringList.Create (FileMask);
  try
    for i := 0 to Files.Count - 1 do
      begin
        SetFileAttributes (PChar (Files [i]), FILE_ATTRIBUTE_NORMAL);
        SysUtils.DeleteFile (Files [i]);
      end;
  finally
    Files.Free;
  end;
end;

function FileMaskToSQLMask(const Mask : String): string;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length (Mask) do
    case Mask [i] of
      '*' : Result := Result + '%';
      '?' : Result := Result + '_';
      '%' : Result := Result + '>%';
      '_' : Result := Result + '>_';
      '>' : Result := Result + '>>';
      else Result := Result + Mask [i];
    end;
end;

procedure RegisterFileToDelete(const FileName : string);
begin
  FilesToDelete.Add (FileName);
end;

procedure DeleteRegisteredFiles;
begin
  while FilesToDelete.Count > 0 do
    begin
      SetFileAttributes (PChar (FilesToDelete [0]), FILE_ATTRIBUTE_NORMAL);
      SysUtils.DeleteFile (FilesToDelete [0]);
      FilesToDelete.Delete (0);
    end;
end;

function MatchesCommaSeparatedMasks(const FileName, Masks : string): Boolean;
var
  MaskList : TStringList;
  i : Integer;
begin
  Result := False;
  MaskList := TStringList.Create;
  try
    MaskList.CommaText := Masks;
    for i := 0 to MaskList.Count - 1 do
      if MatchesMask (FileName, MaskList [i])
        then
        begin
          Result := True;
          Break;
        end;
  finally
    MaskList.Free;
  end;
end;


{$IFNDEF CNVFILEUTILS_LIGHT}
function CreateCompressedStream(Stream : TStream; WriteSignature : boolean;
    CallBack : TCompressionNotification = nil): TStream;
var
  CompStream : TCompressionStream;
  Buf : Pointer;
  Readed : Integer;
  ContinueCompressing : Boolean;
  ABufSize : integer;
begin
  ABufSize := Stream.Size;
  Result := TMemoryStream.Create;
  try
    if WriteSignature
      then Result.Write (ZLIB_SIGNATURE [1], Length (ZLIB_SIGNATURE));
    Buf := AllocBuffer (ABufSize);
    try
      CompStream := TCompressionStream.Create (clMax, Result);
      try
        ContinueCompressing := True;
        repeat
          Readed := Stream.read (Buf^, ABufSize);
          if Readed > 0
            then
            begin
              CompStream.Write (Buf^, Readed);
              if Assigned (CallBack)
                then CallBack (ContinueCompressing);
            end;
        until (Readed <= 0) or (not ContinueCompressing);
      finally
        CompStream.Free;
      end;
      Result.Seek (0, soFromBeginning);
    finally
      FreeMem (Buf);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure DecompressStream (Source, Target : TStream);
var
  DecompStream : TDecompressionStream;
  Buffer : Pointer;
  Readed : Integer;
  ABufSize : integer;
begin
  ABufSize := Source.Size * 20; // Typical compression ratio of text files or highly compressible binary files
  DecompStream := TDecompressionStream.Create (Source);
  try
    Buffer := AllocBuffer (ABufSize);
    try
      repeat
        Readed := DecompStream.read (Buffer^, ABufSize);
        if Readed > 0
          then Target.Write (Buffer^, Readed);
      until Readed <= 0;
    finally
      FreeMem (Buffer);
    end;
  finally
    DecompStream.Free;
  end;
end;
{$ENDIF}

function StripDrive(const FName : string): string;
var
  j : integer;
begin
  j := pos (':\', FName);
  if j > 0
    then Result := copy (FName, j + 2, length (FName) - j - 1)
    else Result := FName;
end;

procedure ReadLn(s : TStream; var AStr : string);
type
  TRLState = (rlWaiting10, rlWaiting13or10);
var
  ASize, Read, OrigPos : Int64;
  i, n : integer;
  State : TRLState;
  Buf : array [0..127] of char;
  Dest : PChar;
begin
  ASize := s.Size;
  State := rlWaiting13or10;
  n := 0;
  OrigPos := s.Position;
  while OrigPos + n < ASize do
    begin
      Read := s.Read (Buf, sizeof (Buf));
      SetLength (AStr, n + Read);
      Dest := PChar (AStr);
      inc (Dest, n);
      inc (n, Read);
      for i := 0 to Read - 1 do
        case State of
          rlWaiting10 :
            begin
              SetLength (AStr, n - Read + i - 1);
              if Buf [i] = #10
                then s.Seek (i + 1 - Read, soFromCurrent)
                else s.Seek (i - Read, soFromCurrent);
              exit;
            end;
          rlWaiting13or10 : case Buf [i] of
            #13 : State := rlWaiting10;
            #10 :
              begin
                SetLength (AStr, n - Read + i - 1);
                s.Seek (i + 1 - Read, soFromCurrent);
                exit;
              end;
            else
            begin
              Dest^ := Buf [i];
              inc (Dest);
            end;
          end;
        end;
    end;
  if State = rlWaiting10
    then SetLength (AStr, n - 1);
end;

function CnvGetFileDate(const AName : string): TDateTime;
var
  s : TFileStream;
begin
  s := TFileStream.Create (AName, fmOpenRead or fmShareDenyNone);
  try
    Result := FileDateToDateTime (FileGetDate (s.Handle));
  finally
    s.Free;
  end;
end;

function GetFileInfo(const AFileName: String): TSearchRec;
var
  LocalScope : IScope;
  Files : TFilesStringList;
begin
  LocalScope := NewScope;
  Files := LocalScope.Add (TFilesStringList.Create (AFileName));
  if Files.Count > 0 then
    Result := Files.SearchRecs [0]
  else FillChar (Result, sizeOf(Result), 0);
end;

procedure DumpToDisk(const AFileName, AContents : string);
var
  AFile : TextFile;
begin
  AssignFile(AFile, AFileName);
  ReWrite(AFile);
  try
    write (AFile, AContents);
  finally
    CloseFile(AFile);
  end;
end;

function CalculateFileCRC(const AFileName: string): cardinal;
var
  MemStream : TMemoryStream;
begin
  Result := 0;
  if not FileExists(AFileName) then
    exit;
  MemStream := TMemoryStream.Create;
  try
    MemStream.LoadFromFile(AFileName);
    result := uCRC32.crc32(1, @PChar(MemStream.Memory)[1], MemStream.Size);
  finally
    MemStream.Free;
  end;

end;

function FileContains(const AFileName, AStrToSearchFor: string; const
    CaseSensitive: boolean = False): boolean;
const
  DEFAULT_BUFFER_SIZE = 512;
var
  Stream : TFileStream;
  s : PChar;
  BytesToRead : integer;
begin
  result := False;
  Stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    GetMem(s, DEFAULT_BUFFER_SIZE);
    try
      while (Stream.Position < Stream.Size) and not result do
        begin
          if (Stream.Size - Stream.Position) > DEFAULT_BUFFER_SIZE then
            BytesToRead := DEFAULT_BUFFER_SIZE
          else BytesToRead := Stream.Size - Stream.Position;
          Stream.ReadBuffer(s^, BytesToRead);
          result := SmartPos(AStrToSearchFor, s, CaseSensitive) > 0;
        end;
    finally
      FreeMem(s);
    end;
  finally
    Stream.Free;
  end;
end;

function MakePathRelative(RelativeTo, SourcePath: string): string;
var
  i, n, LastPathSeparatorIdx : integer;
begin
  LastPathSeparatorIdx := 0;
  Result := SourcePath;
  // Let's find the first difference
  for i := 1 to length(RelativeTo) do
    if i < length(SourcePath) then
      if UpCase(RelativeTo[i]) <> UpCase(SourcePath[i]) then
        if LastPathSeparatorIdx > 1 then
          begin
            // Get rid of starting common part of path for both paths
            RelativeTo := copy(RelativeTo, LastPathSeparatorIdx + 1, length(RelativeTo));
            SourcePath := copy(SourcePath, LastPathSeparatorIdx + 1, length(SourcePath));
            break;
          end
        else exit // Didn't find a single \ sign? Can't calculate relative path...
      else
      begin
        if RelativeTo[i] = '\' then
          LastPathSeparatorIdx := i;
        continue;
      end
    else exit; // SourcePath length lesser than current position i AND we didn't find first difference?
  // Let's count how many folders until RelativeTo actual file
  n := 0;
  for i := 1 to length(RelativeTo) do
    if RelativeTo[i] = '\' then
      inc(n);
  // Build relative path
  Result := '';
  for i := 1 to n do
    Result := Result + '..\';
  Result := Result + SourcePath;
end;

function StringIsMask(const s : string): Boolean;
var
  i : integer;
begin
  Result := False;
  for i := 1 to length(s) do
    if s[i] in ['*', '?'] then
      begin
        Result := True;
        break;
      end;
end;

{ TBasicFileSystem }

procedure TBasicFileSystem.FindClose(var F: TSearchRec);
begin
  SysUtils.FindClose (F);
end;

function TBasicFileSystem.FindFirst(const Path: string; Attr: Integer; var F: 
    TSearchRec): Integer;
begin
  result := SysUtils.FindFirst (Path, Attr, f);
end;

function TBasicFileSystem.FindNext(var F: TSearchRec): Integer;
begin
  result := SysUtils.FindNext(F);
end;

constructor TBasicFileSystem.Create;
begin
  raise Exception.Create (STR_ThisClassCanTBeCreatedDirectlyBy);
end;

constructor TBasicFileSystem.InternalCreate(AOwner : TObject);
begin
  inherited Create;
  FOwner := AOwner;
end;

initialization
  ZLIB_SIGNATURE := SCONVEYZLIBSTREAM;
  FilesToDelete := TStringList.Create;
  FilesToDelete.Sorted := True;
  FilesToDelete.Duplicates := dupIgnore;
finalization
  DeleteRegisteredFiles;
  FilesToDelete.Free;
end.

