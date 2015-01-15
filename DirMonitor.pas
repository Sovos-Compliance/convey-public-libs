unit DirMonitor;

interface

uses
  Windows, Messages, SysUtils, Classes, ProcessMonitor;

const
  FILE_LIST_DIRECTORY = $0001;

  (*
    Version 1.2
    Programmer: JUAN CARLOS MOLINOS MESA

    Directory Monitor, sends an event when it detects any change in a path or its subdirectories.

    ==============
    Specifies the filter criteria the function checks to determine if the wait operation has completed.
    This parameter can be one or more of the following values:

    FILE_NOTIFY_CHANGE_FILE_NAME	Any filename change in the watched directory or subtree causes a change notification wait operation to return. Changes include renaming, creating, or deleting a file.
    FILE_NOTIFY_CHANGE_DIR_NAME	Any directory-name change in the watched directory or subtree causes a change notification wait operation to return. Changes include creating or deleting a directory.
    FILE_NOTIFY_CHANGE_ATTRIBUTES	Any attribute change in the watched directory or subtree causes a change notification wait operation to return.
    FILE_NOTIFY_CHANGE_SIZE	Any file-size change in the watched directory or subtree causes a change notification wait operation to return. The operating system detects a change in file size only when the file is written to the disk. For operating systems that use extensive caching, detection occurs only when the cache is sufficiently flushed.
    FILE_NOTIFY_CHANGE_LAST_WRITE	Any change to the last write-time of files in the watched directory or subtree causes a change notification wait operation to return. The operating system detects a change to the last write-time only when the file is written to the disk. For operating systems that use extensive caching, detection occurs only when the cache is sufficiently flushed.
    FILE_NOTIFY_CHANGE_LAST_ACCESS	Any change to the last access time of files in the watched directory or subtree causes a change notification wait operation to return.
    FILE_NOTIFY_CHANGE_CREATION	Any change to the creation time of files in the watched directory or subtree causes a change notification wait operation to return.
    FILE_NOTIFY_CHANGE_SECURITY	Any security-descriptor change in the watched directory or subtree causes a change notification wait operation to return.

    Action sent to the event

    FILE_ACTION_ADDED	    The file was added to the directory.
    FILE_ACTION_REMOVED	  The file was removed from the directory.
    FILE_ACTION_MODIFIED	The file was modified. This can be a change in the time stamp or attributes.
    FILE_ACTION_RENAMED_OLD_NAME	The file was renamed and this is the old name.
    FILE_ACTION_RENAMED_NEW_NAME	The file was renamed and this is the new name.
  *)

type
  PFileNotifyInformation = ^TFileNotifyInformation;
  TFileNotifyInformation = record
    NextEntryOffset: DWORD;
    Action: DWORD;
    FileNameLength: DWORD;
    FileName: array [0..0] of WideChar;
  end;

  TFil = (nfFILE_NAME,
    nfDIR_NAME,
    nfATTRIBUTES,
    nfSIZE,
    nfLAST_WRITE,
    nfLAST_ACCESS,
    nfCREATION,
    nfSECURITY);
  TFilter = set of TFil;

  TAction = (faADDED, faREMOVED, faMODIFIED, faRENAMED_OLD_NAME,
    faRENAMED_NEW_NAME);

  TActionFilter = set of TAction;

  TEventChange = procedure (sender: TObject; Action: TAction; FileName: string)
    of object;

  TDirMonitor = class (TComponent)
  private
    { Private declarations }
  protected
    { Protected declarations }
    FDir: string;
    Mon: TProcessMonitor;
    FEventChange: TEventChange;
    FActive: Boolean;
    procedure W_FActive (Value: boolean);
    procedure Loaded; override;
    procedure MakeMask;
  public
    { Public declarations }
    FCompletionPort: Integer;
    FOverlapped: TOverlapped;
    FPOverlapped: POverlapped;
    FBytesWrite: DWORD;
    FNotificationBuffer: array [0..4096] of Byte;
    FHandle: integer;
    FWatchSubtree: boolean;
    FFilter: DWORD;
    FFilter_flag: TFilter;
    FActionFilter_flag: TActionFilter;

    constructor Create (Owner: TComponent); override;
    destructor Destroy; override;
    procedure DirectoryEvent;
  published
    { Published declarations }
    property Directory: string read FDir write Fdir;
    property WatchSubtree: boolean read FWatchSubtree write FWatchSubtree default
      false;
    property FilterNotification: TFilter read FFilter_flag write FFilter_flag;
    property FilterAction: TActionFilter read FActionFilter_flag write
      FActionFilter_flag;
    property OnChange: TEventChange read FEventChange write FEventChange;
    property Active: boolean read FActive write W_FActive default false;
  end;

procedure Register;

implementation

resourcestring
  STR_ErrorInCreateIoCompletionPort = 'Error in "CreateIoCompletionPort"';
  STR_ErrorInReadDirectoryChanges = 'Error in "ReadDirectoryChanges"';
  STR_FolderNotFound = 'Folder not found';

procedure Register;
begin
  RegisterComponents ('JC Components', [TDirMonitor]);
end;

{ TDirMonitor }

constructor TDirMonitor.Create (Owner: TComponent);
begin
  inherited;
  FPOverlapped := @FOverlapped;
  FCompletionPort := 0;
  FDir := 'c:\';
  FFilter_flag := [nfFILE_NAME];
  FActionFilter_flag := [faADDED, faREMOVED, faMODIFIED,
    faRENAMED_OLD_NAME, faRENAMED_NEW_NAME];
  Mon := TProcessMonitor.Create (self);
end;

destructor TDirMonitor.Destroy;
begin
  mon.Terminate;
  inherited;
end;

procedure TDirMonitor.MakeMask;
begin
  self.FFilter := 0;
  if nfFILE_NAME in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_FILE_NAME;
  if nfDIR_NAME in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_DIR_NAME;
  if nfATTRIBUTES in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_ATTRIBUTES;
  if nfSIZE in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_SIZE;
  if nfLAST_WRITE in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_LAST_WRITE;
  if nfLAST_ACCESS in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_LAST_ACCESS;
  if nfCREATION in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_CREATION;
  if nfSECURITY in FFilter_flag then
    FFilter := FFilter or FILE_NOTIFY_CHANGE_SECURITY;
end;

procedure TDirMonitor.Loaded;
begin
  inherited;
  if self.FActive then
    self.W_FActive (true);
end;

procedure TDirMonitor.DirectoryEvent;
var
  FileOpNotification: PFileNotifyInformation;
  Offset: Longint;
  TypeChange: integer;
  name: string;
  Action: TAction;
begin
  Pointer (FileOpNotification) := @FNotificationBuffer [0];
  repeat
    Offset := FileOpNotification^.NextEntryOffset;
    TypeChange := FileOpNotification^.Action;

    name := WideCharToString (@ (FileOpNotification^.FileName));

    PChar (FileOpNotification) := PChar (FileOpNotification) + Offset;

    Action := faADDED;
    case TypeChange of
      FILE_ACTION_ADDED: Action := faADDED;
      FILE_ACTION_REMOVED: Action := faREMOVED;
      FILE_ACTION_MODIFIED: Action := faMODIFIED;
      FILE_ACTION_RENAMED_OLD_NAME: Action := faRENAMED_OLD_NAME;
      FILE_ACTION_RENAMED_NEW_NAME: Action := faRENAMED_NEW_NAME;
    end;

    if Action in self.FActionFilter_flag then
      begin
        if (assigned (FEventChange)) and (Length (name) > 0) then
          FEventChange (self, Action, name);
      end;
  until Offset = 0;
end;

procedure TDirMonitor.W_FActive (Value: boolean);
var
  res: boolean;
begin
  if not (csDesigning in self.ComponentState) then
    begin
      //modo ejecución
      if (Value) and (not FActive) then
        begin
          self.MakeMask;
          FHandle := CreateFile (PChar (FDir),
            FILE_LIST_DIRECTORY, FILE_SHARE_READ or FILE_SHARE_WRITE or
              FILE_SHARE_DELETE,
            nil, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS or
              FILE_FLAG_OVERLAPPED, 0);

          if DWORD (FHandle) = INVALID_HANDLE_VALUE then
            begin
              raise EInvalidOperation.Create
                (STR_FolderNotFound);
              exit;
            end;

          self.Mon.FHandle := FHandle;

          FCompletionPort := CreateIoCompletionPort (FHandle, 0, Longint (pointer
            (self)), 0);

          if Pointer (FCompletionPort) = nil then
            begin
              raise Exception.Create (STR_ErrorInCreateIoCompletionPort);
              exit;
            end;

          ZeroMemory (@FNotificationBuffer, SizeOf (FNotificationBuffer));

          res := ReadDirectoryChanges (FHandle, @FNotificationBuffer,
            SizeOf (FNotificationBuffer), FWatchSubtree, FFilter, @FBytesWrite,
            @FOverlapped, nil);

          if not res then
            begin
              raise Exception.Create (STR_ErrorInReadDirectoryChanges);
              exit;
            end;

          self.FActive := true;
          Mon.Resume;
        end
      else
        begin
          if (not Value) and (FActive) then
            begin
              PostQueuedCompletionStatus (self.FCompletionPort, 0, 0, nil);
              CloseHandle (self.FHandle);
              CloseHandle (self.FCompletionPort);
              self.FActive := false;
              Mon.Suspend;
            end;
        end;
    end
  else
    self.FActive := Value; //modo diseño
end;

end.


