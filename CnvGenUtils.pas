{ This unit MUST NOT include any other units that reference Classes unit
  in its uses clause because this unit is used in the array memory allocator
  wich MUST be reference before Classes unit in the global scope of the
  project }

unit CnvGenUtils;

{ When running PaxImporter use option -DPAXIMPORT }

{$i DelphiVersion_defines.inc}

{$IFNDEF PAXIMPORT}
{$i LibVer.inc}
{$ENDIF}

interface

uses
  Windows;

type
  DWORD = Cardinal;
  THandle = Longword;
  BOOL = LongBool;

const
  SZI = SizeOf (Integer);
  SZW = SizeOf (Word);
  SZT = SizeOf (TObject);
  SZP = SizeOf (Pointer);
  SZH = SizeOf (THandle);
  SZD = SizeOf (Double);
  SZL = SizeOf (LongWord);
  SZC = SizeOf (Currency);
  SZLI = SizeOf (Int64);

  iTlsBaseOffset = $0E10;

  VER_PLATFORM_WIN32s = 0;
  VER_PLATFORM_WIN32_WINDOWS = 1;
  VER_PLATFORM_WIN32_NT = 2;
 
type
  PInt = ^Integer;
  PByte = ^Byte;
  TStrVarRecArray = class;
  IStrVarRecArray = interface
    ['{0EEFBC72-98A5-4D3E-962B-82C7E191048B}']
    function Obj : TStrVarRecArray;
  end;

  TStrVarRecArray = class (TInterfacedObject, IStrVarRecArray)
  private
    Strings : array of string;
  protected
    function Obj: TStrVarRecArray;
  public
    Arr : array of TVarRec;
    constructor Create(const Values : array of Variant; FromIndex : integer = 0; 
        ToIndex : integer = -1);
    class function CreateIntf(const Values : array of Variant; FromIndex : integer
        = 0; ToIndex : integer = -1): IStrVarRecArray;
    procedure SetStr(Index : integer; const AStr : string);
    destructor Destroy; override;
  end;

function SetVmtEntry(AClass : TClass; VmtOffset : Integer; NewAddr : Pointer): Pointer;
procedure PatchMemory(p : Pointer; DataSize : Integer; Data : Pointer; OldData : pointer); overload;
procedure PatchMemory(p : Pointer; DataSize : Integer; Data : Pointer); overload;
function SetTlsOffset(P: PInt; AOffset: Integer; DirectReplacement : boolean =
    false): PInt;
{$IFNDEF WIN64}
function GetThreadVar(TlsSlot : integer): Pointer;
procedure SetThreadVar(TlsSlot : integer; Value : pointer);
{$ENDIF}
function KillProcess(const aProcess: string): Boolean;
function ProcessExists(const AProcess : string): Boolean;
function GetProcessHandle(const AProcess : string; dwDesiredAccess : DWORD): THandle;
function CnvGetComputerName: string;
function ParamCount: Integer;
function ParamStr(Index: Integer): string;

var
  Win32Platform : DWORD;
  
implementation
  
uses
  uWinProcHelper, {$IFDEF WIN64} SysUtils, {$ENDIF} TLHelp32 {$IFDef LEVEL7} , Variants {$EndIf}; // This three units are safe because they not reference Classes

const
  FakeData : Pointer = nil;

function SetVmtEntry(AClass : TClass; VmtOffset : Integer; NewAddr : Pointer):
    Pointer;
var
  VmtPtr : Pointer;
begin
  Result := nil;
  VmtPtr := Pointer (Integer (AClass) + VmtOffset);
  PatchMemory (VmtPtr, SizeOf (Pointer), @NewAddr, Result);
end;

procedure PatchMemory(p : Pointer; DataSize : Integer; Data : Pointer; OldData : pointer); {$IfDef LEVEL7} overload; {$ENDIF}
{$IFNDEF DELPHIXE2}
type
  SIZE_T = DWORD;
{$ENDIF}  
var
  OldProtect : DWORD;
  BytesWritten : SIZE_T;
begin
  VirtualProtect (p, DataSize, PAGE_EXECUTE_READWRITE, OldProtect);
  if OldData <> @FakeData
    then Move (p^, OldData^, DataSize);
  WriteProcessMemory(GetCurrentProcess, p, Data, DataSize, BytesWritten);
  VirtualProtect (p, DataSize, OldProtect, OldProtect);
end;

procedure PatchMemory (p : Pointer; DataSize : Integer; Data : Pointer); {$IfDef LEVEL7} overload; {$EndIf}
begin
  PatchMemory (p, DataSize, Data, @FakeData);
end;

function SetTlsOffset(P: PInt; AOffset: Integer; DirectReplacement : boolean =
    false): PInt;
var
  NewTlsOffset : Integer;
begin
  while P^ <> iTlsBaseOffset do
    Inc (PByte (P));
  if DirectReplacement
    then NewTlsOffset := AOffset
    else NewTlsOffset := iTlsBaseOffset + AOffset * SZI;
  PatchMemory (P, SizeOf (Integer), @NewTlsOffset);
  Inc (P);
  Result := P;
end;

procedure InitPlatformId;
var
  OSVersionInfo: TOSVersionInfo;
begin
  OSVersionInfo.dwOSVersionInfoSize := SizeOf(OSVersionInfo);
  if GetVersionEx(OSVersionInfo) then
    with OSVersionInfo do
      Win32Platform := dwPlatformId;
end;

{$IFNDEF WIN64}
function GetThreadVar(TlsSlot : integer): Pointer;
asm
    cmp         Win32Platform, VER_PLATFORM_WIN32_NT // Check if is WinNT or higher
    jge         @@GetDirectAccess
    push        TlsSlot
    call        TlsGetValue
    jmp         @@Exit
  @@GetDirectAccess:
    mov         Eax,fs:[TlsSlot]
  @@Exit:
end;

procedure SetThreadVar(TlsSlot : integer; Value : pointer);
asm
    cmp         Win32Platform, VER_PLATFORM_WIN32_NT // Check if is WinNT or higher
    jge         @@SetDirectAccess
    push        Value
    push        TlsSlot
    call        TlsSetValue
    jmp         @@Exit
  @@SetDirectAccess:
    mov         fs:[TlsSlot], Value
  @@Exit:
end;
{$ENDIF}

function KillProcess(const aProcess: string): Boolean;
begin
  Result := uWinProcHelper.KillProcess(AProcess);
end;

function ProcessExists(const AProcess : string): Boolean;
var
  h : THandle;
begin
  h := GetProcessHandle (AProcess, STANDARD_RIGHTS_REQUIRED);
  try
    Result := h <> 0;
  finally
    if h <> 0
      then CloseHandle (h);
  end;
end;

function GetProcessHandle(const AProcess : string; dwDesiredAccess : DWORD):
    THandle;
begin
  Result := uWinProcHelper.GetProcessHandle(AProcess, dwDesiredAccess);
end;

function CnvGetComputerName: string;
var
  Comp: array[0..255] of Char;
  I: DWord;
begin
  I := MAX_COMPUTERNAME_LENGTH + 1;
  GetComputerName(Comp, I);
  Result := string(Comp);
end;

function ParamStr(Index: Integer): string;
begin
  Result := system.ParamStr(Index);
end;

function ParamCount: Integer;
begin
  Result := system.ParamCount;
end;

{ TStrVarRecArray }

constructor TStrVarRecArray.Create(const Values : array of Variant; FromIndex : 
    integer = 0; ToIndex : integer = -1);
var
  i : Integer;
begin
  inherited Create;
  {$IFNDEF PAXIMPORT}
  if ToIndex = -1
    then ToIndex := Length (Values) - 1;
  SetLength (Arr, ToIndex - FromIndex + 1);
  SetLength (Strings, ToIndex - FromIndex + 1);
  for i := FromIndex to ToIndex do
    begin
      Arr [i - FromIndex].VType := vtAnsiString;
      SetStr (i - FromIndex, VarToStr (VarAsType (Values [i], varOleStr)));
    end;
  {$ENDIF}	
end;

procedure TStrVarRecArray.SetStr(Index : integer; const AStr : string);
begin
  {$IFNDEF PAXIMPORT}
  Strings [Index] := AStr;
  Arr [Index].VAnsiString := Pointer (Strings [Index]);
  {$ENDIF}
end;

function TStrVarRecArray.Obj: TStrVarRecArray;
begin
  Result := Self;
end;

class function TStrVarRecArray.CreateIntf(const Values : array of Variant; 
    FromIndex : integer = 0; ToIndex : integer = -1): IStrVarRecArray;
begin
  {$IFNDEF PAXIMPORT}
  Result := TStrVarRecArray.Create (Values, FromIndex, ToIndex);
  {$ENDIF}
end;

destructor TStrVarRecArray.Destroy;
begin
  SetLength (Arr, 0);
  SetLength (Strings, 0);
  inherited;
end;

initialization
  InitPlatformId;
end.
