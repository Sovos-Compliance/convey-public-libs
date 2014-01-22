unit DbugIntf;

interface

uses
  Windows, Dialogs; // We need "Dialogs" for TMsgDlgType

procedure SendBoolean(const Identifier: string; const Value: Boolean);
procedure SendDateTime(const Identifier: string; const Value: TDateTime);
procedure SendDebugEx(const Msg: string; MType: TMsgDlgType);
procedure SendDebug(const Msg: string);
procedure SendInteger(const Identifier: string; const Value: Integer);
procedure SendMethodEnter(const MethodName: string);
procedure SendMethodExit(const MethodName: string);
procedure SendSeparator;
procedure SendDouble(const Identifier: string; const Value: Double);
procedure SendInt64(const Identifier: string; const Value: Int64);
function StartDebugWin: hWnd;

implementation

uses
  Messages,
  SysUtils,
  Registry,
  Forms; // We need "Forms" for the Application object

threadvar
  MsgPrefix: AnsiString;

function StartDebugWin: hWnd;
var
  DebugFilename: string;
  Buf: array[0..MAX_PATH + 1] of Char;
  si: TStartupInfo;
  pi: TProcessInformation;
begin
  MsgPrefix := '';

  Result := 0;
  with TRegIniFile.Create('\Software\GExperts') do
  try
    DebugFilename := ReadString('Debug', 'FilePath', '');
  finally
    Free;
  end;
  if Trim(DebugFileName) = '' then
  begin
    GetModuleFileName(HINSTANCE, Buf, SizeOf(Buf)-1);
    DebugFileName := ExtractFilePath(StrPas(Buf))+'GDebug.exe';
  end;
  if (Trim(DebugFilename) <> '') and FileExists(DebugFilename) then
  begin
    FillChar(si, SizeOf(si), #0);
    si.cb := SizeOf(si);
    si.dwFlags := STARTF_USESHOWWINDOW;
    si.wShowWindow := SW_SHOW;
    if not CreateProcess(PChar(DebugFilename), nil, nil, nil, False, 0, nil, nil,
                          si, pi) then
    begin
      Result := 0;
      Exit;
    end;
    try
      WaitForInputIdle(pi.hProcess, 3 * 1000); // wait for 3 seconds to get idle
    finally
      CloseHandle(pi.hThread);
      CloseHandle(pi.hProcess);
    end;
    Result := FindWindow('TfmDebug', nil);
  end;
end;

procedure SendDebugEx(const Msg: string; MType: TMsgDlgType);
var
  CDS: TCopyDataStruct;
  DebugWin: hWnd;
  MessageString: string;
begin
  DebugWin := FindWindow('TfmDebug', nil);
  if DebugWin = 0 then
    DebugWin := StartDebugWin;
  if DebugWin <> 0 then
  begin
    MessageString := MsgPrefix + Msg;
    CDS.cbData := Length(MessageString) + 4;
    CDS.dwData := 0;
    CDS.lpData := PChar(#1+Char(Ord(MType) + 1)+ MessageString +#0); //PMsg;
    SendMessage(DebugWin, WM_COPYDATA, WParam(Application.Handle), LParam(@CDS));
  end;
end;

procedure SendDebug(const Msg: string);
begin
  SendDebugEx(Msg, mtInformation);
end;

const
  Indentation = '    ';

procedure SendMethodEnter(const MethodName: string);
begin
  MsgPrefix := MsgPrefix + Indentation;
  SendDebugEx('Entering ' + MethodName, mtInformation);
end;

procedure SendMethodExit(const MethodName: string);
begin
  SendDebugEx('Exiting ' + MethodName, mtInformation);

  Delete(MsgPrefix, 1, Length(Indentation));
end;

procedure SendSeparator;
const
  SeparatorString = '------------------------------';
begin
  SendDebugEx(SeparatorString, mtInformation);
end;

procedure SendBoolean(const Identifier: string; const Value: Boolean);
begin
  // Note: We deliberately leave "True" and "False" as
  // hard-coded string constants, since these are
  // technical terminology which should not be localised.
  if Value then
    SendDebugEx(Identifier + '= True', mtInformation)
  else
    SendDebugEx(Identifier + '= False', mtInformation);
end;

procedure SendInteger(const Identifier: string; const Value: Integer);
begin
  SendDebugEx(Format('%s = %d', [Identifier, Value]), mtInformation);
end;

procedure SendDateTime(const Identifier: string; const Value: TDateTime);
begin
  SendDebugEx(Identifier + '=' + DateTimeToStr(Value), mtInformation);
end;

procedure SendDouble(const Identifier: string; const Value: Double);
begin
  SendDebugEx(Format('%s = %f', [Identifier, Value]), mtInformation);
end;

procedure SendInt64(const Identifier: string; const Value: Int64);
begin
  SendDebugEx(Format('%s = %d', [Identifier, Value]), mtInformation);
end;

end.

