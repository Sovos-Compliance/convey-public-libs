unit CnvSysUtils;

interface

uses
  Classes, Windows;

type
  TSystemState = class
  private
    KeyState: TKeyboardState;
    FDisableGetState: Boolean;
    function GetControlPressed: Boolean;
    function GetAltPressed: Boolean;
    function GetShiftPressed: Boolean;
    function GetLButtonPressed: Boolean;
    function GetMButtonPressed: Boolean;
    function GetRButtonPressed: Boolean;
    function GetShiftState(State : TShiftState): Boolean;
    function GetInsert: Boolean;
    function GetCapsLock: Boolean;
    function GetNumLock: Boolean;
    function GetScrollLock: Boolean;
    function GetFullState: Word;
  public
    property ControlPressed: Boolean read GetControlPressed;
    property AltPressed: Boolean read GetAltPressed;
    property ShiftPressed: Boolean read GetShiftPressed;
    property LButtonPressed: Boolean read GetLButtonPressed;
    property MButtonPressed: Boolean read GetMButtonPressed;
    property RButtonPressed: Boolean read GetRButtonPressed;
    property Insert: Boolean read GetInsert;
    property CapsLock: Boolean read GetCapsLock;
    property NumLock: Boolean read GetNumLock;
    property ScrollLock: Boolean read GetScrollLock;
    property FullState: Word read GetFullState;
  end;

procedure GetAllIPs(IPs: TStrings);
function GetFullyQualifiedDomainName : AnsiString;
function GetComputerName: string;
function GetUserName(const ANameFormat: integer = -1): string;
function GetWindowsDomain: string;
function IsForegroundTask: Boolean;
function GetProcessIDOfHInstance(AHInstance : Cardinal): Cardinal; // This FN doesn't seam to work on NT based systems. Don't use

var
  SystemState : TSystemState;

implementation

uses
  SysUtils, Forms, Winsock;

type
  PCheckTaskInfo = ^TCheckTaskInfo;
  TCheckTaskInfo = record
    FocusWnd: HWnd;
    Found: Boolean;
  end;

function GetUserNameEx(NameFormat: Integer; lpNameBuffer: PChar; var lpnSize: Cardinal): BOOL; stdcall;
  external 'Secur32.dll' name {$IFDEF UNICODE}'GetUserNameExW'{$ELSE}'GetUserNameExA'{$ENDIF};

procedure GetAllIPs(IPs: TStrings);
type
  TaPInAddr = array [0..20] of PInAddr;
  PaPInAddr = ^TaPInAddr;
var
  phe  : PHostEnt;
  pptr : PaPInAddr;
  Buffer : array [0..MAX_PATH] of AnsiChar;
  I    : Integer;
  GInitData : TWSADATA;
begin
  WSAStartup($101, GInitData);
  try
    GetHostName(Buffer, SizeOf(Buffer));
    phe := GetHostByName(buffer);
    if phe = nil
      then Exit;
    pptr := PaPInAddr(Phe^.h_addr_list);
    I := 0;
    while pptr^[I] <> nil do
      begin
        IPs.add(StrPas(inet_ntoa(pptr^[I]^)));
        Inc(I);
      end;
  finally
    WSACleanup;
  end;
end;

function GetFullyQualifiedDomainName: AnsiString;
var
  HostEnt: PHostEnt;
  szHostname: array[0..MAX_PATH] of AnsiChar;
begin
  Result:= '';
  if GetHostName (szHostname, MAX_PATH) = 0
    then
    begin
      HostEnt:= GetHostByName (szHostname);
      if Assigned (HostEnt)
        then Result := StrPas (HostEnt^.h_name);
    end;
end;

// Delphi declares MAX_COMPUTERNAME_LENGTH as 15, but really it should be 16
function GetComputerName: string;
var lpBuffer: array[0..MAX_COMPUTERNAME_LENGTH + 1] of char;
    dwSize: DWORD;
begin
  dwSize:= MAX_COMPUTERNAME_LENGTH + 1;

  if not Windows.GetComputerName(@lpBuffer, dwSize) then
    raise Exception.Create(SysErrorMessage(GetLastError));

  Result:= StrPas(lpBuffer);
end;

function GetUserName(const ANameFormat: integer = -1): string;
var lpBuffer: array[0..MAX_PATH] of char;
    dwSize: DWORD;
begin
  dwSize:= MAX_PATH;

  if ANameFormat > -1 then
    if not GetUserNameEx(ANameFormat, lpBuffer, dwSize) then
      raise Exception.Create(SysErrorMessage(GetLastError()))
    else
  else
    if not windows.GetUserName(lpBuffer, dwSize) then
      raise Exception.Create(SysErrorMessage(GetLastError()));

  Result:= StrPas(lpBuffer);
end;

function GetWindowsDomain: string;
var
  psnuType:DWord;
  lpszDomain:Array[0..MAX_PATH] Of Char;
  UserSID:Array[0..1024] Of Char;
  dwDomainLength:DWORD;
  dwSIDBuffSize:DWORD;
  lpszUserName:Array[0..MAX_PATH] Of Char;
begin
  dwDomainLength:=MAX_PATH;
  dwSIDBuffSize:=1024;
  StrPCopy(lpszUserName, GetUserName);
  If Not LookupAccountName (nil,lpszUserName,@UserSID,dwSIDBuffSize,lpszDomain,dwDomainLength,psnuType)
    then Result := ''
    else
    begin
      Result := StrPas (lpszDomain);
    end;
end;

function CheckTaskWindow(Window: HWnd; Data: Longint): WordBool;
  {$IFDEF MSWINDOWS} stdcall {$ELSE} export {$ENDIF};
begin
  Result := True;
  if PCheckTaskInfo(Data)^.FocusWnd = Window then begin
    Result := False;
    PCheckTaskInfo(Data)^.Found := True;
  end;
end;

function IsForegroundTask: Boolean;
var
  Info: TCheckTaskInfo;
{$IFNDEF MSWINDOWS}
  Proc: TFarProc;
{$ENDIF}
begin
  Info.FocusWnd := GetActiveWindow;
  Info.Found := False;
{$IFDEF MSWINDOWS}
  EnumThreadWindows(GetCurrentThreadID, @CheckTaskWindow, Longint(@Info));
{$ELSE}
  Proc := MakeProcInstance(@CheckTaskWindow, HInstance);
  try
    EnumTaskWindows(GetCurrentTask, Proc, Longint(@Info));
  finally
    FreeProcInstance(Proc);
  end;
{$ENDIF}
  Result := Info.Found;
end;

type
  PHANDLE_TABLE_ENTRY = ^HANDLE_TABLE_ENTRY;
  HANDLE_TABLE_ENTRY = record
     flags : Cardinal;
     pObject : Cardinal;
  end;

  PHANDLE_TABLE = ^HANDLE_TABLE;
  HANDLE_TABLE = record
    cEntries : Cardinal;
    handles : array [0..0] of HANDLE_TABLE_ENTRY;
  end;

threadvar
  Magic : Cardinal;

function InitMagic : Cardinal; forward;

function GetProcessIDOfHInstance(AHInstance : Cardinal): Cardinal;
type
  PCardinal = ^cardinal;
var
  ProcessID : Cardinal;
  dw : Cardinal;
  pdw : PCardinal;
  phTable : PHANDLE_TABLE;
  hEntry : PHANDLE_TABLE_ENTRY;
begin
  if Magic = 0
    then Magic := InitMagic;
  ProcessID := GetCurrentProcessId; // Process Id of the calling process
  dw := ProcessID xor Magic;
  pdw := PCardinal (dw + $44); // Offset to the handle table that belongs to the calling process
  phTable := PHANDLE_TABLE (pdw^);
  hEntry := @phTable^.handles;
  hEntry := PHANDLE_TABLE_ENTRY (cardinal (hEntry) + AHInstance); // Index into the handle table
  ProcessID := hEntry^.pObject xor Magic;
  Result := ProcessId;
end;

function TSystemState.GetControlPressed: Boolean;
begin
  Result := GetShiftState ([ssCtrl]);
end;

function TSystemState.GetAltPressed: Boolean;
begin
  Result := GetShiftState ([ssAlt]);
end;

function TSystemState.GetShiftPressed: Boolean;
begin
  Result := GetShiftState ([ssShift]);
end;

function TSystemState.GetLButtonPressed: Boolean;
begin
  Result := GetShiftState ([ssLeft]);
end;

function TSystemState.GetMButtonPressed: Boolean;
begin
  Result := GetShiftState ([ssMiddle]);
end;

function TSystemState.GetRButtonPressed: Boolean;
begin
  Result := GetShiftState ([ssRight]);
end;

function TSystemState.GetShiftState(State : TShiftState): Boolean;
var
  ShiftState : TShiftState;
begin
  if not FDisableGetState
    then GetKeyboardState(KeyState);
  ShiftState := KeyboardStateToShiftState (KeyState);
  Result := State * ShiftState = State;
end;

function TSystemState.GetInsert: Boolean;
begin
  if not FDisableGetState
    then GetKeyboardState(KeyState);
  Result := KeyState [VK_INSERT] = 1;
end;

function TSystemState.GetCapsLock: Boolean;
begin
  if not FDisableGetState
    then GetKeyboardState(KeyState);
  Result := KeyState [VK_CAPITAL] = 1;
end;

function TSystemState.GetNumLock: Boolean;
begin
  if not FDisableGetState
    then GetKeyboardState(KeyState);
  Result := KeyState [VK_NUMLOCK] = 1;
end;

function TSystemState.GetScrollLock: Boolean;
begin
  if not FDisableGetState
    then GetKeyboardState(KeyState);
  Result := KeyState [VK_SCROLL] = 1;
end;

function TSystemState.GetFullState: Word;
begin
  Result := 0;
  if ControlPressed
    then Inc (Result, 1);
  FDisableGetState := True;
  try
    if AltPressed
      then Inc (Result, 2);
    if ShiftPressed
      then Inc (Result, 4);
    if LButtonPressed
      then Inc (Result, 8);
    if MButtonPressed
      then Inc (Result, 16);
    if RButtonPressed
      then Inc (Result, 32);
    if Insert
      then Inc (Result, 64);
    if CapsLock
      then Inc (Result, 128);
    if NumLock
      then Inc (Result, 256);
    if ScrollLock
      then Inc (Result, 512);
  finally
    FDisableGetState := False;
  end;
end;

{$IFDEF MSWINDOWS}
{$IFDEF WIN32}
function InitMagic : Cardinal;
var
  tid : cardinal;
  AMagic : Cardinal;
begin
  tid := GetCurrentThreadId;
  asm
    push ax
    push es
    push fs
    mov  ax, fs
    mov  es, ax
    mov  eax, 18h
    mov  eax, es:[eax]
    sub  eax, 10h
    xor  eax, [tid]
    mov  [AMagic], eax
    pop  fs
    pop  es
    pop  ax
  end;
  Result := AMagic;
end;
{$ENDIF}
{$IFDEF WIN64}
function InitMagic : Cardinal;
var
  tid : cardinal;
  AMagic : Cardinal;
asm
    call GetCurrentThreadId
    mov tid,eax
    push gs
    mov  eax, 18h
    mov  eax, gs:[eax]
    sub  eax, 10h
    xor  eax, [tid]
    mov  [AMagic], eax
    pop  gs
    mov eax, [AMagic]
end;
{$ENDIF}
{$ENDIF}

initialization
  SystemState := TSystemState.Create;
finalization
  FreeAndNil (SystemState);
end.
