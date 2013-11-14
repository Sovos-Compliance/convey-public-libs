unit uMethodList;

interface

uses
  Classes, SysUtils;

type
  TMethodObject = class
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
  private
    FMethod : TMethod;
    FMustDelete: Boolean;
  public
    constructor Create (AMethod : TMethod);
    property Method : TMethod read FMethod Write FMethod;
    property MustDelete: Boolean read FMustDelete write FMustDelete;
  end;

  TCallMethodProc = procedure (AMethod : TMethod; APointer : pointer) of object;
  TMethodList = class (TList)
  private
    FListCopy : TMethodList;
    FIteratingCount : Integer;
    FListModified: Boolean;
    function GetMethod (Index : Integer) : TMethod;
    procedure SetMethod (Index : Integer; AMethod : TMethod);
    procedure BeginIterating;
    procedure EndIterating;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    function Add (AMethod : TMethod) : integer;
    function Remove (AMethod : TMethod) : integer;
    function IndexOfMethod (AMethod : TMethod) : Integer; overload;
    function IndexOfMethod (Obj : TObject) : Integer; overload;
    procedure Iterate(Proc : TCallMethodProc; APointer : pointer = nil);
    procedure Assign(AList : TMethodList);
    destructor Destroy; override;
    property Method [Index : Integer] : TMethod read GetMethod Write SetMethod; default;
  end;

implementation

{ TMethodObject }

constructor TMethodObject.Create;
begin
  inherited Create;
  FMethod := AMethod;
end;

class function TMethodObject.NewInstance: TObject;
begin
  Result := inherited NewInstance;
end;

procedure TMethodObject.FreeInstance;
begin
  inherited FreeInstance;
end;

{ TMethodList }

function TMethodList.GetMethod;
begin
  Result := TMethod (TMethodObject (Items [index]).Method);
end;

procedure TMethodList.SetMethod (Index : Integer; AMethod : TMethod);
var
  i : Integer;
begin
  if FListCopy <> nil
    then
    begin
      i := FListCopy.IndexOfMethod (Self [index]);
      if i >= 0
        then FListCopy [i] := AMethod;
    end;
  TMethodObject (Items [index]).Method := AMethod;
end;

function TMethodList.Add;
begin
  if FIteratingCount <= 0
    then Result := inherited Add (TMethodObject.Create (AMethod))
    else
    begin
      if FListCopy = nil
        then FListCopy := TMethodList.Create;
      FListCopy.Add (AMethod);
      Result := -1; // We don't know yet the real index were it will fall
      FListModified := True;
    end;
end;

function TMethodList.IndexOfMethod (AMethod : TMethod) : integer;
var
  i : Integer;
begin
  Result := -1;
  for i := 0 to Count - 1 do
    if (TMethodObject (Items [i]).Method.Code =
       TMethod (AMethod).Code) and
       (TMethodObject (Items [i]).Method.Data =
       TMethod (AMethod).Data)
      then
      begin
        Result := i;
        Exit;
      end;
end;

function TMethodList.IndexOfMethod (Obj : TObject) : Integer;
var
  i : Integer;
begin
  Result := -1;
  for i := 0 to Count - 1 do
    if TMethodObject (Items [i]).Method.Data = Obj
      then
      begin
        Result := i;
        Exit;
      end;
end;

function TMethodList.Remove;
begin
  Result := IndexOfMethod (AMethod);
  if Result >= 0
    then if FIteratingCount <= 0
      then Delete (Result)
      else
      begin
        TMethodObject (Items [Result]).MustDelete := True;
        FListModified := True;
      end;
  if FListCopy <> nil
    then FListCopy.Remove (AMethod);
end;

procedure TMethodList.Notify;
begin
  inherited;
  if Action = lnDeleted
    then TMethodObject (Ptr).Free;
end;

procedure TMethodList.Iterate(Proc : TCallMethodProc; APointer : pointer = nil);
var
  i : Integer;
begin
  BeginIterating;
  try
    for i := 0 to Count - 1 do
      if not TMethodObject (Items [i]).MustDelete
        then Proc (Method [i], APointer);
  finally
    EndIterating
  end;
end;

procedure TMethodList.Assign(AList : TMethodList);
var
  i : Integer;
begin
  Clear;
  for i := 0 to AList.Count - 1 do
    Add (AList [i]);
end;

destructor TMethodList.Destroy;
begin
  if FListCopy <> nil
    then FreeAndNil (FListCopy);
  inherited;
end;

procedure TMethodList.BeginIterating;
begin
  Inc (FIteratingCount);
end;

procedure TMethodList.EndIterating;
var
  i : Integer;
begin
  Dec (FIteratingCount);
  if (FIteratingCount <= 0) and FListModified
    then
    begin
      try
        i := 0;
        while i < Count do
          if TMethodObject (Items [i]).MustDelete
            then Delete (i)
            else Inc (i);
        if FListCopy <> nil
          then
          begin
            try
              for i := 0 to FListCopy.Count - 1 do
                Add (FListCopy [i]);
            finally
              FreeAndNil (FListCopy);
            end;
          end;
      finally
        FListModified := False;
      end;
    end;
end;

initialization
  
finalization
  
end.
