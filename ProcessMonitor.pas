unit ProcessMonitor;

interface

uses
  Classes,Windows,SysUtils;

type
  TProcessMonitor = class(TThread)
  private
    { Private declarations }
  protected
    FProRef: TComponent;
    procedure Execute; override;
    procedure SendEvent;
  public
    FHandle: integer;
    constructor Create(ProRef: TComponent); overload;
  end;

implementation

{ TMonitor }

uses DirMonitor;

constructor TProcessMonitor.Create(ProRef: TComponent);
begin
  self.Create(true);
  self.FProRef:=ProRef;
  FreeOnTerminate:=true;
  self.Priority:=tpTimeCritical;
end;

procedure TProcessMonitor.SendEvent;
var DirMon: TDirMonitor;
begin
  DirMon := self.FProRef as TDirMonitor;
  DirMon.DirectoryEvent;
end;

procedure TProcessMonitor.Execute;
var state:cardinal;
  quit:boolean;
  parent:TDirMonitor;
  numBytes: DWORD;

begin
  { Place thread code here }
  quit := false;
  parent := TDirMonitor(self.FProRef);
  while (not quit) do
  begin
    GetQueuedCompletionStatus( parent.FCompletionPort, numBytes, state, parent.FPOverlapped, INFINITE);
    if (parent.FPOverlapped<>nil)	then
    begin
      if self.Terminated then
        quit:=true
      else
      begin
        self.Synchronize(self.SendEvent);

        parent.FBytesWrite := 0;
        ZeroMemory(@parent.FNotificationBuffer, SizeOf(parent.FNotificationBuffer));
        ReadDirectoryChanges(parent.FHandle, @parent.FNotificationBuffer,
          SizeOf(parent.FNotificationBuffer), parent.FWatchSubtree, parent.FFilter,
          @parent.FBytesWrite, @parent.FOverlapped, nil);
      end;
    end;
  end;
end;

end.
