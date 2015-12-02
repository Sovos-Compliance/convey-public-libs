/// Basic unit for managing exceptions raised by Delphi DLLs
/// Provides functions to captire and reset the exception class and text and also
/// exported functions for the DLL caller to reteieve the class/text

unit DllExceptions;

interface

uses
  System.SysUtils;

/// <summary>Store the details of the exception raised (ClassName and Message)</summary>
procedure DllException_CaptureDetails(E: Exception);
/// <summary>Reset the stored exception details</summary>
procedure DllException_ResetDetails;

implementation

threadvar
  LastErrorMessage: string;
  LastExceptionClass: string;

procedure DllException_CaptureDetails(E: Exception);
begin
  LastExceptionClass := E.ClassName;
  LastErrorMessage := E.Message;
end;

procedure DllException_ResetDetails;
begin
  LastExceptionClass := '';
  LastErrorMessage := '';
end;

function DllException_GetLastErrorMessage: PChar; stdcall;
begin
  if LastErrorMessage <> '' then
    Result := PChar(LastErrorMessage)
  else Result := nil;
end;

function DllException_GetLastClassName: PChar; stdcall;
begin
  if LastExceptionClass <> '' then
    Result := PChar(LastExceptionClass)
  else Result := nil;
end;

exports
  DllException_GetLastErrorMessage, DllException_GetLastClassName;

end.
