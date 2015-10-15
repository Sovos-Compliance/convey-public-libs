unit uLinkedList;

interface

uses
  iContainers, uAbstractFactory, uContainerDataHandler;

type
  PLinkedNode = ^TLinkedNode;
  TLinkedNode = record
    Data : TContainerData;
    Prev : PLinkedNode;
    Next : PLinkedNode;
  end;

  TAbstractLinkedListClass = class of TAbstractLinkedList;
  TAbstractLinkedList = class (TInterfacedObject)
  public
    constructor Create; virtual;
  end;

  ILinkedList = interface (IIterable)
    ['{AB4DE40A-B6D1-4E95-A45D-4465FB018AA2}']
    procedure Clear;
    function GetEmpty: Boolean;
    function Insert(APointer: Pointer): PLinkedNode; overload;
    function Insert(AObject: TObject): PLinkedNode; overload;
    function Insert(AInteger: Integer): PLinkedNode; overload;
    function InsertAnsiString(const AAnsiString: AnsiString): PLinkedNode; overload;
    function InsertShortString(const AShortString: ShortString): PLinkedNode; overload;
    function Insert(const AInt64: Int64): PLinkedNode; overload;
    function Insert(const AExtended : Extended): PLinkedNode; overload;
    function Insert(const ACurrency : Currency): PLinkedNode; overload;
    function Insert(ABoolean: Boolean): PLinkedNode; overload;
    function Insert(AAnsiChar: AnsiChar): PLinkedNode; overload;
    function Insert(AWideChar: WideChar): PLinkedNode; overload;
    function InsertWideString(const AWideString: WideString): PLinkedNode; overload;
    function Insert(AInterface: IUnknown): PLinkedNode; overload;

    function Remove(APointer: Pointer): Boolean; overload;
    function Remove(AObject: TObject): Boolean; overload;
    function Remove(AInteger: Integer): Boolean; overload;
    function RemoveAnsiString(const AAnsiString: AnsiString): Boolean; overload;
    function RemoveShortString(const AShortString: ShortString): Boolean; overload;
    function Remove(const AInt64: Int64): Boolean; overload;
    function Remove(const AExtended : Extended): Boolean; overload;
    function Remove(const ACurrency : Currency): Boolean; overload;
    function Remove(ABoolean: Boolean): Boolean; overload;
    function Remove(AAnsiChar: AnsiChar): Boolean; overload;
    function Remove(AWideChar: WideChar): Boolean; overload;
    function RemoveWideString(const AWideString: WideString): Boolean; overload;
    function Remove(AInterface: IUnknown): Boolean; overload;
    procedure RemoveNode(ANode : PLinkedNode);

    procedure MoveToStartOfList (ANode : PLinkedNode);
    procedure MoveToEndOfList (ANode : PLinkedNode);
    function FirstNode : PLinkedNode;
    function GetDataHandler: IDataHandler;
    function LastNode : PLinkedNode;
    function GetAutoFreeObjects: Boolean;
    procedure SetAutoFreeObjects(Value: Boolean);
    property AutoFreeObjects: Boolean read GetAutoFreeObjects write SetAutoFreeObjects; // Default False
    property DataHandler: IDataHandler read GetDataHandler;
    property Empty: Boolean read GetEmpty;
  end;

function LinkedListFactory: IFactory;

implementation

uses
  SysUtils;

var
  gvLinkedListFactory : IFactory;

type
  TLinkedListFactory = class(TAbstractFactory)
  protected
    function CreateObjectFromClass(AClass: TClass): IUnknown; override;
  end;

function LinkedListFactory: IFactory;
begin
  Result := gvLinkedListFactory;
end;

function TLinkedListFactory.CreateObjectFromClass(AClass: TClass): IUnknown;
begin
  Result := TAbstractLinkedListClass (AClass).Create;
end;

constructor TAbstractLinkedList.Create;
begin
  inherited;
end;

initialization
  gvLinkedListFactory := TLinkedListFactory.Create;
end.

