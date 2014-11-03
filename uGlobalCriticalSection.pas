unit uGlobalCriticalSection;

interface

procedure Enter;
procedure Leave;

implementation

uses
  SyncObjs;

var
  Lock : TCriticalSection;

procedure Enter;
begin
  Lock.Enter;
end;

procedure Leave;
begin
  Lock.Leave;
end;


initialization
  Lock := TCriticalSection.Create;
finalization
  Lock.Free;
end.
