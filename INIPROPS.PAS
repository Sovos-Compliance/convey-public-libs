{ If you have problems compiling this package when trying to install it in Delphi 4
  because the compiler says that ComServ cannot be included in the Package
  try activating the next directive adding the $ sign after the { sign.
  Don't forget to delete the $ sign after installing the package, it's only
  required when compiling for DesignTime }

{Define DESIGNTIME}
{$IFDEF VER180}
  {$Define D4and5}
  {$Define D10}
  {$Define Ver130}
{$Else}
  {$IfDef Ver130}
    {$Define D4and5}
  {$Else}
    {$IFDef Ver120}
      {$Define D4and5}
    {$EndIf}
  {$EndIf}
{$ENDIF}  

unit Iniprops;

interface

{
  TINIPropSav - version 2.21
  Copyright 1997-1998 - José Sebastián Battig - Maiten Desarrollos Informaticos
  E-Mail: sbattig@bigfoot.com

  Please read the notes.txt file
}

{$IfDef Win32}
{Define DemoVersion} { If you have the registered version please delete this directive }
{$EndIf}

uses
  SysUtils, WinTypes, WinProcs, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, INIFiles, TypInfo,
  {$IFDef VER180} DesignIntf, DesignEditors, VCLEditors {$Else} DsgnIntf {$EndIf}, Menus {$IfDef Win32} , ExtIni, Registry {$EndIf};

type
  {$IFDef D10}
  IFormDesigner = IDesigner;
  {$EndIf}
  TAutoLoad = (aldNone, aldBeforeOnCreateForm, aldBeforeOnShowForm, aldAfterOnCreateForm, aldAfterOnShowForm);
  TAutoSave = (asvNone, asvBeforeOnDestroyForm, asvBeforeOnHideForm, asvAfterOnDestroyForm, asvAfterOnHideForm);
  TSpecialProperties = (npInteger, npEnumeration, npFloat); { Added in version 1.3 }
  TSpecialPropertiesSet = set of TSpecialProperties; { Added in version 1.3 }
  TPropertyWork = procedure (Sender : TObject; Component : TComponent; const PropName : string) of object;
  TPropertyError = procedure (Sender : TObject; Component : TComponent;
                              const PropName, Value : string; E : Exception) of object;

  TINIPropSav = class(TComponent)
  private
    {$IfDef Win32}
    FINIFile : TExtINIFile;
    {$Else}
    FINIFile : TINIFile;
    {$EndIf}
    FUseAppDir : boolean;
    FFileName : PString;
    FSavedProperties : TStrings;
    FSections : TStrings;
    FLoadProperty : TPropertyWork;
    FSaveProperty : TPropertyWork;
    FLoadError : TPropertyError;
    FSaveError : TPropertyError;
    MustLoad : boolean;
    FAutoLoad : TAutoLoad;
    FAutoSave : TAutoSave;
    OnLoad : TNotifyEvent;
    OnSave : TNotifyEvent;
    AutoOpened : boolean;
    {$IFDef D10}
    FCachedComponent: TComponent;
    {$Endif}
    ToBind : TStringList;
    ToBindMethods : TStringList;
    SubPropsStack : TList;
    FStoreAsRaw : TSpecialPropertiesSet; { Added in version 1.3 }
    FStartLoadingProperties : TNotifyEvent; { Added in version 2.2 }
    FEndLoadingProperties : TNotifyEvent; { Added in version 2.2 }
    FStartSavingProperties : TNotifyEvent; { Added in version 2.2 }
    FEndSavingProperties : TNotifyEvent; { Added in version 2.2 }
    {$IfDef Win32}
    FEncrypted : boolean; { Added in version 2.1}
    FUseRegistry : boolean; { New in version 1.1 }
    FCompanyName : string; { New in version 1.1 }
    FProductName : string; { New in version 1.1 }
    FRootKey : HKEY; { Added in version 1.21 }
    FUseSoftwareKey : boolean; { Added in version 1.21 }
    FLazyWrite : boolean; { Added in version 1.22 }
    {$EndIf}
    procedure ReOpen;
    procedure SetSavedProperties (AProp : TStrings);
    procedure SetSections (ASecc : TStrings);
    procedure SetFileName (const AName : string);
    function GetFileName : string;
    procedure SetUseAppDir (Value : boolean);
    procedure ReadProperties (Reader : TReader);
    procedure WriteProperties (Writer : TWriter);
    procedure ReadSections (Reader : TReader);
    procedure WriteSections (Writer : TWriter);
    procedure UpdateObjects;
    procedure PropertyWork ({$IFDef D10}const {$EndIf}Prop : {$IFDef D10}IProperty{$Else}TPropertyEditor{$Endif});
    procedure PropertiesWork;
    function GetIsOpen : boolean;
    function GetSavedComponentsCount : integer;
    function GetSavedComponents (Index : integer) : TComponent;
    function GetSavedProperties (Index : integer) : string;
    function GetSections (Component : TComponent; const Prop : string) : string;
    procedure SetSections2 (Component : TComponent; const Prop, Secc : string);
    function GetIdentifiers (Component : TComponent; const Prop : string) : string;
    procedure SetIdentifiers (Component : TComponent; const Prop, Ident : string);
    function GetMustLoad (Component : TComponent; const Prop : string) : boolean;
    procedure SetMustLoad (Component : TComponent; const Prop : string; Value : boolean);
    function GetMustSave (Component : TComponent; const Prop : string) : boolean;
    procedure SetMustSave (Component : TComponent; const Prop : string; Value : boolean);
    procedure GetSubProperties ({$IFDef D10}const {$Endif}Prop : {$IFDef D10} IProperty {$Else} TPropertyEditor {$EndIf});
    procedure AutoLoadEvent (Sender : TObject);
    procedure AutoSaveEvent (Sender : TObject);
    procedure WriteAutoSave (Value : TAutoSave);
    procedure WriteAutoLoad (Value : TAutoLoad);
    procedure AssignSave (Form : TForm);
    procedure AssignLoad (Form : TForm);
    function AssignPath (const AFileName : string) : string;
    function PrepareCompRef (CompRef : TComponent; var Value : string) : TComponent;
    procedure BindReferences (List : TStringList; Tipo : TTypeKind);
    procedure SetStoreAsRaw (value : TSpecialPropertiesSet); { Added in version 1.3 }
    {$IfDef Win32}
    procedure SetUseRegistry (value : boolean); { Added in version 1.1 }
    procedure SetRootKey (value : HKEY); { Added in version 1.21 }
    procedure SetLazyWrite (value : boolean); { Added in version 1.22 }
    function GetRegINIFile : TRegINIFile; { Added in version 1.22 }
    procedure SetEncrypted (AEncrypted : boolean);
    {$EndIf}
    function GetINIFile : TINIFile; { Added in version 1.22 }
  protected
    procedure Notification (AComponent : TComponent;
                            AOperation : TOperation); override;
    procedure DefineProperties (Filer : TFiler); override;
    procedure Loaded; override;
    procedure UpdateNames (Remove : TComponent);
    property Properties : TStrings read FSavedProperties write SetSavedProperties;
    property Sections : TStrings read FSections write SetSections;
    { This function could be declared as a unit function, but i like to put it here because
      i guess that only i'm interested in this function, and someone that want's to derive
      this component, that's why is protected }
    class function IsClass (Prop : {$IfDef D10}IProperty{$Else}TPropertyEditor{$EndIf}; Clase : TClass) : boolean;
  public
    constructor Create (AOwner : TComponent); override;
    destructor Destroy; override;
    procedure EraseSection (const Section : string);
    procedure ReadSection (const Section : string; Values : TStrings);
    function ReadBool (const Section, Ident : string; Default : boolean) : boolean;
    procedure WriteBool (const Section, Ident : string; Value : boolean);
    function ReadInteger (const Section, Ident : string; Default : integer) : integer;
    procedure WriteInteger (const Section, Ident : string; Value : integer);
    function ReadString (const Section, Ident, Default : string) : string;
    procedure WriteString (const Section, Ident, Value : string);
    procedure ReadSectionValues (const Section : string; Values : TStrings);
    procedure OpenFile;
    procedure CloseFile;
    procedure LoadProperties;
    procedure SaveProperties;
    function IndexOf (Component : TComponent; const Prop : string) : integer;
    property IsOpen : boolean read GetIsOpen;
    property SavedComponentsCount : integer read GetSavedComponentsCount;
    property SavedComponents [Index : integer] : TComponent read GetSavedComponents;
    property SavedProperties [Index : integer] : string read GetSavedProperties;
    property INISections [Component : TComponent; const Prop : string] : string read GetSections write SetSections2;
    property INIIdentifiers [Component : TComponent; const Prop : string] : string read GetIdentifiers write SetIdentifiers;
    property MustLoadProperty [Component : TComponent; const Prop : string] : boolean read GetMustLoad write SetMustLoad;
    property MustSaveProperty [Component : TComponent; const Prop : string] : boolean read GetMustSave write SetMustSave;
    {$IfDef Win32}
    property RegINIFile : TRegINIfile read GetRegINIFile; { Added in version 1.22 }
    {$EndIf}
    property INIFile : TINIFile read GetINIFile; { Added in version 1.22 }
  published
    property FileName : string read GetFileName write SetFileName; { In version 1.1 this property is updated when the
                                                                   registry file is opened, so you have not to make assumptions
                                                                   about it's value. Check the OpenFile Method to see how and
                                                                   when is changed. }
    property UseAppDir : boolean read FUseAppDir write SetUseAppDir default true;
    property AutoLoadProperties : TAutoLoad read FAutoLoad write WriteAutoLoad default aldAfterOnCreateForm;
    property AutoSaveProperties : TAutoSave read FAutoSave write WriteAutoSave default asvBeforeOnDestroyForm;
    property StoreAsRawData : TSpecialPropertiesSet read FStoreAsRaw write SetStoreAsRaw; { Added in version 1.3 }
    property OnLoadProperty : TPropertyWork read FLoadProperty write FLoadProperty;
    property OnSaveProperty : TPropertyWork read FSaveProperty write FSaveProperty;
    property OnLoadPropertyError : TPropertyError read FLoadError write FLoadError;
    property OnSavePropertyError : TPropertyError read FSAveError write FSaveError;
    property OnStartLoadingProperties : TNotifyEvent read FStartLoadingProperties write FStartLoadingProperties; { ver 2.2 }
    property OnEndLoadingProperties : TNotifyEvent read FEndLoadingProperties write FEndLoadingProperties; { ver 2.2 }
    property OnStartSavingProperties : TNotifyEvent read FStartSavingProperties write FStartSavingProperties; { ver 2.2 }
    property OnEndSavingProperties : TNotifyEvent read FEndSavingProperties write FEndSavingProperties; { ver 2.2 }
    {$IfDef Win32}
    property Encrypted : boolean read FEncrypted write SetEncrypted default false; { Added in version 2.1 }
    property UseRegistry : boolean read FUseRegistry write SetUseRegistry default false; { Added in version 1.1 }
    property CompanyName : string read FCompanyName write FCompanyName; { Added in version 1.1 }
    property ProductName : string read FProductName write FProductName; { Added in version 1.1 }
    property RootKey : HKEY read FRootKey write SetRootKey default HKEY_CURRENT_USER; { Added in version 1.21 }
    property UseSoftwareKey : boolean read FUseSoftwareKey write FUseSoftwareKey default true; { Added in version 1.21 }
    property LazyWrite : boolean read FLazyWrite write SetLazyWrite default true; { Added in version 1.22 }
    {$EndIf}
  end;

{ Error messages used in conjunction with EINIPropSav... if you want to change it.... }
const
  INIProblems : string = 'There are problems with the INI/Registry file';
  PropNotFind : string = 'Property don''t found';
  NoComponentError : string = 'Cannot solve component reference of a non-component class';

type
  EINIPropSav = class (Exception)
    { Nothing special }
  end;

{ These are utility functions for parse the info stored in the component, if you derive the
  component and you want to do some special management of the stored information you can use
  this functions }

function INIpQuote (const s : string) : string;
function INIpUnQuote (const s : string) : string;
function StringForList (const Comp, Prop : string) : string;
function SeccionForList (const Comp, Prop : string;
                         Seccion, Item, Value : string;
                         Guardar, Cargar : boolean) : string; { To much parameters no??...
  do you remember structured programming ??? :) }
function ExtractSeccion (const Cad : string) : string;
function ExtractItem (const Cad : string) : string;
function ExtractValue (const Cad : string) : string;
function ExtractComponent (const Cad : string) : string;
function ExtractProperty (const Cad : string) : string;
function ExtractGuardar (const Cad : string) : boolean; { Sorry by the name, Guardar = "to Save" in english }
function ExtractCargar (const Cad : string) : boolean; { Cargar = "to Load" in english }

{ Encryption utility functions... are not big deal, but it serve to our purpose to hide
  information in the Registry or ini files }

{$IfDef Win32}

procedure Encrypt (var Data; Size : cardinal; Basic : boolean);
procedure Decrypt (var Data; Size : cardinal; Basic : boolean);

type
  HKEYArray = array [HKEY_CLASSES_ROOT..HKEY_DYN_DATA] of string;

const
  HKEYS : HKEYArray = ('HKEY_CLASSES_ROOT', 'HKEY_CURRENT_USER',
    'HKEY_LOCAL_MACHINE', 'HKEY_USERS', 'HKEY_PERFORMANCE_DATA',
    'HKEY_CURRENT_CONFIG', 'HKEY_DYN_DATA');

{ These two functions are used to map strings to HKEY numeric constants
  to strings, both functions are registered in the initialization part of this unit }

function HKEYToIdent (aint : longint; var Ident : string) : boolean;
function IdentToHKEY (const Ident : string; var Int : longint) : boolean;
{$EndIf}

implementation

{$IFDef DemoVersion}
{$IfDef D4and5}
uses
  TempStr, CryptSt, TlHelp32, ComObj, {$IfNDef DESIGNTIME}, ComServ {$EndIf};
{$Else}
uses
  TempStr, CryptSt, TlHelp32;
{$EndIf}
{$Else}
{$IfDef Ver80}
uses
  TrimFunc;
{$Else}
{$IfDef D4and5}
uses
  TempStr, CryptSt, ComObj {$IFNDef DESIGNTIME}, ComServ {$EndIf};
{$Else}
uses
  TempStr, CryptSt;
{$EndIf}
{$EndIf}
{$EndIf}

const
  PropsToCheck : set of TTypeKind = [tkInteger, tkEnumeration, tkFloat];
  {$IfDef Ver100}
  Registered : boolean = false;
  {$EndIf}
  {$IfDef D4and5}
  Registered : boolean = false;
  {$EndIf}

function ToSpecialProperties (value : TTypeKind) : TSpecialProperties;
begin
  case value of
    tkInteger : Result := npInteger;
    tkEnumeration : Result := npEnumeration;
    tkFloat : Result := npFloat;
    else raise Exception.Create ('No se puede convertir de TTypeKind a TSpecialProperties');
  end;
end;

type
  { Here the expose trick again... i hope that in D3 GetOrdValue continue being not virtual }
  TExposePropertyEditor = class (TPropertyEditor)
  public
    {
    procedure Activate; override;    
    function GetOrdValue : longint;
    procedure SetOrdValue (value : longint);
    function GetFloatValue : double;
    procedure SetFloatValue (value : double);}
  end;

{function TExposePropertyEditor.GetOrdValue;
begin
  Result := inherited GetOrdValue;
end;

procedure TExposePropertyEditor.SetOrdValue;
begin
  inherited SetOrdValue (Value);
end;

function TExposePropertyEditor.GetFloatValue;
begin
  Result := inherited GetFloatValue;
end;

procedure TExposePropertyEditor.SetFloatValue;
begin
  inherited SetFloatValue (Value);
end;}

{ You will ask why I commented out all the code in TExposePropertyEditor... well, simply
  because I accidentaly discovered that when you create a new class in a unit and cast
  the object you want to access protected stuff to this newly created class, then you have
  access to all protected stuff without re-writing this stuff in your new class. Nice trick
  to fool encapsulation. This works fine in Delphi 2 as well as Delphi 3, I had no chance to
  try it in Delphi 4. So, I decided to delete all this useless code to avoid more overhead,
  but I let it there just to show the diference. }

{$IfDef DemoVersion}
const
  MsgShowed : boolean = false;
{$EndIf}

type
  { This class is used in cojuntion with the GetPropertiesProcedure for set the
    properties values when reading from the Ini file or the registry }
  {$IfDef D4and5}
  TMyDesigner = class (TComObject, IFormDesigner)
  {$Else}
  TMyDesigner = class (TFormDesigner)
  {$EndIf}
    {$IfDef D4and5}
    procedure Modified;
    procedure Notification(AnObject: TPersistent; Operation: TOperation);

    function GetCustomForm: TCustomForm;
    procedure SetCustomForm(Value: TCustomForm);
    function GetIsControl: Boolean;
    procedure SetIsControl(Value: Boolean);
    function IsDesignMsg(Sender: TControl; var Message: TMessage): Boolean;
    procedure PaintGrid;
    procedure ValidateRename(AComponent: TComponent;
      const CurName, NewName: string);

    function CreateMethod(const Name: string; TypeData: PTypeData): TMethod;
    {$IfDef D10}
    overload;
    function CreateMethod(const Name: string; const AEventInfo: IEventInfo): TMethod; overload;
    {$EndIf}
    function GetMethodName(const Method: TMethod): string;
    procedure GetMethods(TypeData: PTypeData; Proc: TGetStrProc);
    {$IfDef D10}
    overload;
    procedure GetMethods(const AEventInfo: IEventInfo; Proc: TGetStrProc); overload;
    {$EndIf}
    function GetPrivateDirectory: string;
    procedure GetSelections(const List: IDesignerSelections);
    function MethodExists(const Name: string): Boolean;
    procedure RenameMethod(const CurName, NewName: string);
    procedure SelectComponent(Instance: TPersistent);
    {$IFDef D10}
    overload;
    procedure SelectComponent(const ADesignObject: IDesignObject); overload;
    {$EndIf}
    procedure SetSelections(const List: IDesignerSelections);
    procedure ShowMethod(const Name: string);
    function UniqueName(const BaseName: string): string;
    procedure GetComponentNames(TypeData: PTypeData; Proc: TGetStrProc);
    function GetComponent(const Name: string): TComponent;
    function GetComponentName(Component: TComponent): string;
    function GetObject(const Name: string): TPersistent;
    function GetObjectName(Instance: TPersistent): string;
    procedure GetObjectNames(TypeData: PTypeData; Proc: TGetStrProc);
    function MethodFromAncestor(const Method: TMethod): Boolean;
    function CreateComponent(ComponentClass: TComponentClass; Parent: TComponent;
      Left, Top, Width, Height: Integer): TComponent;
    function IsComponentLinkable(Component: TComponent): Boolean;
    procedure MakeComponentLinkable(Component: TComponent);
    function GetRoot: TComponent;
    procedure Revert(Instance: TPersistent; PropInfo: PPropInfo);
    function GetIsDormant: Boolean;
    function HasInterface: Boolean;
    function HasInterfaceMember(const Name: string): Boolean;
    procedure AddToInterface(InvKind: Integer; const Name: string; VT: Word;
      const TypeInfo: string);
    procedure GetProjectModules(Proc: TGetModuleProc);
    function GetAncestorDesigner: IFormDesigner;
    function IsSourceReadOnly: Boolean;
    {$Else}
    procedure Modified; override;
    {$EndIf}
    {$IfDef Ver130}
    function GetContainerWindow: TWinControl;
    procedure SetContainerWindow(const NewContainer: TWinControl);
    function GetScrollRanges(const ScrollPosition: TPoint): TPoint;
    procedure Edit(const Component: {$IFDEF D10} TComponent {$Else}IComponent{$Endif});
    {$IfNDef D10}
    function BuildLocalMenu(Base: TPopupMenu; Filter: TLocalMenuFilters): TPopupMenu;
    {$EndIf}
    procedure ChainCall(const MethodName, InstanceName, InstanceMethod: string;
      TypeData: PTypeData);
    {$IfDef D10} overload;
    procedure ChainCall(const MethodName, InstanceName, InstanceMethod: string;
        const AEventInfo: IEventInfo); overload;
    {$EndIf}
    procedure CopySelection;
    procedure CutSelection;
    function CanPaste: Boolean;
    procedure PasteSelection;
    procedure DeleteSelection {$IFDef D10} (ADoAll: Boolean = False) {$Endif};
    procedure ClearSelection;
    procedure NoSelection;
    procedure ModuleFileNames(var ImplFileName, IntfFileName, FormFileName: string);
    function GetRootClassName: string;
    {$EndIf}
    {$IFDEF D10}
    function IsComponentHidden(Component: TComponent): Boolean;
    function GetBaseRegKey: string;
    function GetIDEOptions: TCustomIniFile;
    function GetPathAndBaseExeName: string;
    procedure Activate;
    function CreateCurrentComponent(Parent: TComponent; const Rect: TRect): TComponent;
    function GetShiftState: TShiftState;
    procedure ModalEdit(EditKey: Char; const ReturnWindow: IActivatable);
    procedure SelectItemName(const PropertyName: string);
    procedure Resurrect;
    function GetActiveClassGroup: TPersistentClass;
    function FindRootAncestor(const AClassName: string): TComponent;
    procedure PaintMenu;
    function GetDesignerExtension: string;
    {$EndIf}
  end;

{$IfDef D4and5}
{$IfNDef DESIGNTIME}
const
  Class_TMyDesigner : TGUID = '{B9DD0AD2-84A0-11D2-8E06-00104BECB272}';
{$EndIf}

{$i EmptyDesigner.inc}
{$EndIf}

var
  SubProps : string; { This global variable is here because i had problems
                       when it was declared inside the class because it was used
                       in a CallBack function...a rare problem... }

{$IfDef DemoVersion}

{ This is the code segment that preforms the shareware control... the idea is very
  simple. Check for a process called delphi32.exe, and then in that process check
  for a module with the extension .DCL, if that's true then delphi is loaded into
  memory...., if only delphi32.exe is in memory could be because the DCL load operation
  failed... or because someone is trying to fool this component }

function GetProcessId (const Nombre : string) : DWORD;
var
  Module : TProcessEntry32;
  h : THandle;
  proc : string;
  Found : boolean;
begin
  Found := false;
  Result := 1;
  h := CreateToolhelp32SnapShot (TH32CS_SNAPALL, 0);
  try
    Module.dwSize := sizeof (Module);
    if Process32First (h, Module)
      then repeat
        Proc := StrPas (Module.szExeFile);
        if UpperCase (Nombre) = UpperCase (copy (Proc, length (Proc) - length (Nombre) + 1, length (Nombre)))
          then
          begin
            Result := Module.th32ProcessId;
            Found := true;
            break;
          end;
      until not Process32Next (h, Module);
  finally
    CloseHandle (h);
  end;
  if not Found
    then raise Exception.Create ('Process not found');
end;

function CheckShare : boolean;
var
  Module : TModuleEntry32;
  h : THandle;
  id : DWORD;
  Modulo : string;
begin
  Result := false;
  try
    id := GetProcessId ('DELPHI32.EXE')
  except
    exit;
  end;
  h := CreateToolhelp32SnapShot (TH32CS_SNAPALL, id);
  try
    Fillchar (Module, sizeof (Module), 0);
    Module.dwSize := sizeof (Module);
    if Module32First (h, Module)
      then repeat
        Modulo :=  StrPas (Module.szExePath);
        {$IfDef Ver90}
        if UpperCase (ExtractFileExt (Modulo)) = '.DCL'
        {$Endif}
        {$IfDef Ver100}
        if UpperCase (ExtractFileName (Modulo)) = 'INIPROPS.DPL'
        {$EndIf}
        {$IfDef D4and5}
        if UpperCase (ExtractFileName (Modulo)) = 'INIPROPS.DPL'
        {$EndIf}
          then
          begin
            Result := true;
            break;
          end;
      until not Module32Next (h, Module);
  finally
    CloseHandle (h);
  end;
end;
{$EndIf} { DemoVersion }

{ TINIPropSav }

constructor TINIPropSav.Create;
begin
  inherited Create (AOwner);
  FIniFile := nil;
  FFileName := nil;
  FSavedProperties := TStringList.Create;
  FSections := TStringList.Create;
  FUseAppDir := true;
  FAutoLoad := aldAfterOnCreateForm;
  FAutoSave := asvBeforeOnDestroyForm;
  FStoreAsRaw := [];
  {$IfDef Win32}
  FRootKey := HKEY_CURRENT_USER;
  FUseSoftwareKey := true;
  FLazyWrite := true;
  {$EndIf}
  { I have to do the folowing to avoid an access violation error in Delphi 3, Delphi 3
    changes the way to manage the property editors. In runtime, there's a nil pointer
    that when is referenced to access a list of property editors an exception is raised.
    When you register a property editor the list is created avoiding that problem }
  {$IFDef Ver100}
  if (not Registered) and (not (csDesigning in ComponentState))
    then
    begin
      { I reegister a non existent property... but I don't care that, i just care to
        avoid the error }
      RegisterPropertyEditor (TypeInfo (TFont), TINIPropSav, 'Font', TFontProperty);
      Registered := true;
    end;
  {$EndIf}
  {$IfDef D4and5}
  if (not Registered) and (not (csDesigning in ComponentState))
    then
    begin
      { I register a non existent property... but I don't care that, i just care to
        avoid the error }
      RegisterPropertyEditor (TypeInfo (TFont), TINIPropSav, 'Font', TFontProperty);
      Registered := true;
    end;
  {$EndIf}
end;

destructor TINIPropSav.Destroy;
begin
  FSavedProperties.Clear;
  FSavedProperties.Free;
  FSections.Free;
  CloseFile;
  DisposeStr (FFileName); { PString used for FFileName for compatibility with D1,
                            this uses the exact needed memory in D1 that just "string" }
  inherited Destroy;
end;

{ Method added in version 1.1 }
{$IfDef Win32}

procedure TINIPropSav.SetEncrypted;
begin
  if AEncrypted <> FEncrypted
    then
    begin
      if AEncrypted
        then if FUseRegistry
          then FEncrypted := AEncrypted
          else if csDesigning in ComponentState
            then if not (csLoading in ComponentState)
              then raise Exception.Create ('Cannot set the Encrypted property to true if UseRegistry is false')
              else FEncrypted := AEncrypted
            else if csLoading in ComponentState
              then FEncrypted := AEncrypted
              else {}
        else FEncrypted := AEncrypted;
    end;
end;

procedure TINIPropSav.SetUseRegistry;
begin
  if value <> FUseRegistry
    then
    begin
      FUseRegistry := value;
      if not FUseRegistry
        then FEncrypted := false;
      if FIniFile <> nil
        then CloseFile;
    end;
end;

{ Method added in version 1.21 }
procedure TINIPropSav.SetRootKey;
begin
  FRootKey := Value;
  if FIniFile <> nil
    then FINIFile.RootKey := FRootKey;
end;

{ Methods added in version 1.22 }

function TINIPropSav.GetRegINIFile;
begin
  if FIniFile <> nil
    then Result := FINIFile.RegINIFile
    else Result := nil;
end;

procedure TINIPropSav.SetLazyWrite;
begin
  FLazyWrite := value;
  if FINIFile <> nil
    then FINIFile.LazyWrite := FLazyWrite;
end;

{$EndIf}

function TINIPropSav.GetINIFile;
begin
  {$IFDef Win32}
  if FINIFile <> nil
    then Result := FINIFile.INIFile
    else Result := nil;
  {$Else}
  Result := FINIFile;
  {$EndIf}
end;

procedure TINIPropSav.SetStoreAsRaw;
begin
  if Value <> FStoreAsRaw
    then
    begin
      FStoreAsRaw := Value;
      {$IfDef Win32}
      if FINIFile <> nil
        then
        begin
          FINIFile.StoreIntegerAsRaw := npInteger in FStoreAsRaw;
          FINIFile.StoreFloatAsRaw := npFloat in FStoreAsRaw;
        end;
      {$EndIf}
    end;
end;

procedure TINIPropSav.AutoLoadEvent;
begin
  if FAutoLoad <> aldNone
    then if FAutoLoad in [aldBeforeOnCreateForm, aldBeforeOnShowForm]
      then
      begin
        try
          LoadProperties;
        finally
          if assigned (OnLoad)
            then OnLoad (Sender);
        end;
      end
      else
      begin
        if assigned (OnLoad)
          then OnLoad (Sender);
        LoadProperties;
      end
    else if assigned (OnLoad)
      then OnLoad (Sender);
end;

procedure TINIPropSav.AutoSaveEvent;
begin
  if FAutoSave <> asvNone
    then if FAutoSave in [asvAfterOnDestroyForm, asvAfterOnHideForm]
      then
      begin
        if assigned (OnSave)
          then OnSave (Sender);
        SaveProperties;
      end
      else
      begin
        try
          SaveProperties;
        finally
          if assigned (OnSave)
            then OnSave (Sender);
        end;
      end
    else if assigned (OnSave)
      then OnSave (Sender);
end;

{ This method binds the references stored in the ini file, it lookups the owners until it finds the
  final reference for a given component }
procedure TINIPropSav.BindReferences;
var
  i, j : integer;
  ObjName, PropName, Value : string;
  Comp, Ref : TComponent;
  Method : TMethod;
begin
  for i := 0 to List.Count - 1 do
    begin
      Comp := TComponent (List.Objects [i]);
      j := pos ('=', List [i]);
      if j > 0
        then
        begin
          PropName := copy (List [i], 1, j - 1);
          Value := copy (List [i], j + 1, length (List [i]) - j);
        end
        else continue; { The error is ignored to continue fixing references }
      if Value <> ''
      {$IfNDef Ver80}
        then Ref := Application { Starts the lookup by the Application object, the form reference MUST be present }
      {$Else}
        then Ref := Owner { In delphi 1 starts the lookup in the Form... that's the owner }
      {$EndIf}
        else
        begin
          Ref := nil;
          SetOrdProp (Comp, GetPropInfo (Comp.ClassInfo, PropName), longint (Ref));
          continue;
        end;
      while (Value <> '') and (Ref <> nil) do
        begin
          j := pos ('.', Value);
          if j <= 0
            then if Tipo <> tkMethod
              then j := length (Value) + 1
              else break;
          ObjName := copy (Value, 1, j - 1);
          Value := copy (Value, j + 1, length (Value) - j);
          Ref := Ref.FindComponent (ObjName);
        end;
      if Ref <> nil
        then if Tipo = tkClass
          then SetOrdProp (Comp, GetPropInfo (Comp.ClassInfo, PropName), longint (Ref))
          else
          begin
            if Value <> ''
              then
              begin
                Method.Code := Ref.MethodAddress (Value);
                Method.Data := Ref;
              end
              else
              begin
                Method.Code := nil;
                Method.Data := nil;
              end;
            SetMethodProp (Comp, GetPropInfo (Comp.ClassInfo, PropName), Method);
          end;
    end;
end;

function TINIPropSav.PrepareCompRef;
begin
  if CompRef <> nil
    then
    begin
      if not (CompRef is TComponent)
        then raise EINIPropSav.Create (NoComponentError);
      while CompRef <> nil do
        begin
          Value := CompRef.Name + Value;
          CompRef := CompRef.Owner;
          if (CompRef <> nil) and {$IfNDef Ver80 }(CompRef <> Application) {$Else} (CompRef <> Owner) {$EndIf}
            then Value := '.' + Value;
        end;
    end
    else Value := '';
  Result := CompRef;
end;

{ This is a callback method for properties that have subproperties,
  like the font property }
procedure TINIPropSav.GetSubProperties;
var
  p : integer;
  Value : string;
  CompRef : TComponent;
begin
  try
    if paSubProperties in Prop.GetAttributes
      then
      begin
        SubPropsStack.Add (pointer (TExposePropertyEditor (Prop).GetOrdValue));
        Prop.GetProperties (GetSubProperties);
        SubPropsStack.Delete (SubPropsStack.Count - 1);
      end
      else if not MustLoad
        then
        begin
          case Prop.GetPropType^.Kind of
            tkClass : PrepareCompRef (TComponent (TExposePropertyEditor (Prop).GetOrdValue), Value);
            tkMethod :
              begin
                CompRef := TComponent (TExposePropertyEditor (Prop).GetMethodValue.Data);
                if CompRef <> nil
                  then
                  begin
                    PrepareCompRef (CompRef, Value);
                    if Value <> ''
                      then Value := Value + '.';
                    Value := Value + CompRef.MethodName (TExposePropertyEditor (Prop).GetMethodValue.Code);
                    if Value [length (Value)] = '.'
                      then Value := '';
                  end
                  else Value := '';
              end;
            else value := Prop.{$IFDef D10}GetValue{$else}Value{$Endif}
          end;
          if SubProps <> ''
            then SubProps := SubProps + ', '+ Value
            else SubProps := Value;
        end
        else
        begin
          p := pos (',', SubProps);
          if p <> 0
            then
            begin
              Value := Trim (copy (SubProps, 1, p - 1));
              SubProps := copy (SubProps, p + 1, length (SubProps) - p);
            end
            else Value := SubProps;
          case Prop.GetPropType^.Kind of
            tkClass : ToBind.AddObject (Prop.GetName + '=' + Value, SubPropsStack [SubPropsStack.Count - 1]);
            tkMethod : ToBindMethods.AddObject (Prop.GetName + '=' + Value, SubPropsStack [SubPropsStack.Count - 1]);
            else Prop.{$IFDef D10}SetValue (Value){$else}Value := Value{$Endif};
          end;
        end;
  finally
    { Added in version 1.12 You must free the property editors returned by
      GetComponentProperties, they are owned by the Designer and in this case
      the Designer is MY Designer, so the property editors belongs to me }
    {$IFNDef D10}
    Prop.Free;
    {$EndIf}
  end;
end;

{ This function is declared as class function because it's use in the unit iniprop.pas with
  a actual object and for use this function we use the expose trick again. This function really
  could be declared as a sole function... but dont has utility in the context of the class for
  the end user of the class }

class function TINIPropSav.IsClass (Prop : {$IfDef D10}IProperty{$Else}TPropertyEditor{$Endif}; Clase : TClass) : boolean;
var
  Obj : TObject;
begin
  Result := false;
  if Prop.GetPropType^.Kind = tkClass
    then
    begin
      Obj := TObject (TExposePropertyEditor (Prop).GetOrdValue);
      if Obj <> nil
        then Result := Obj is Clase
    end;
end;

{ This is the callback method of the function GetComponentProperties, this method is
  used for the Load and the Save actions... this method is really big... }
procedure TINIPropSav.PropertyWork;
var
  CompRef, CompTemp : TComponent;
  Comp : TPersistent;
  Secc : string;
  Ident : string;
  Index : integer;
  CompName : string;
  Cad, Value : string;
  Strings: TStrings;
  Cargar, Guardar : boolean;
  AsLink : boolean;
  Picture : TPicture;
  Graphic : TGraphic;
  IntegerValue : longint;
  FloatValue : double;
  {$IfNDef Ver80}
  CryptStream : TEncryptedStream;
  TempFile : TTempFileStream;
  TempFileName, OldName : string;
  {$EndIf}
{ These nested procedures where added in version 1.2}
procedure CalculateAsLink;
var
  Cad2 : string;
begin
  try
    Cad2 := ExtractValue (Cad);
    if Cad2 <> ''
      then AsLink := boolean (StrToInt (Cad2))
      else AsLink := false;
  except
    AsLink := false;
  end;
end;
procedure LoadProperty;
var
  LastRawInteger : boolean;
  procedure ReadValue;
  begin
    {$IfDef Win32}
    if FEncrypted and (length (Value) > 0)
      then Encrypt (Value [1], length (Value), true);
    {$EndIf}
    Value := FINIFile.ReadString (Secc, Ident, Value);
    {$IfDef Win32}
    if FEncrypted and (length (Value) > 0)
      then Decrypt (Value [1], length (Value), true);
    {$EndIf}
  end;
  procedure ReadProperty;
  begin
    Value := Prop.{$IFDef D10}GetValue{$Else}Value{$EndIf};
    ReadValue;
    Prop.{$IFDef D10}SetValue (Value){$Else}Value := Value{$EndIf};
  end;
begin
  try
    if Cargar
      then if (not IsClass (Prop, TStrings)) and (not IsClass (Prop, TPicture)) and
              (not IsClass (Prop, TGraphic))
        then if not (Prop.GetPropType^.Kind in [tkClass, tkMethod])
          then
          begin
            { Code for read simple properties modified in version 1.3 to support Raw Data}
            if Prop.GetPropType^.Kind in PropsToCheck
              then if ToSpecialProperties (Prop.GetPropType^.Kind) in FStoreAsRaw
                then case Prop.GetPropType^.Kind of
                    tkInteger :
                      begin
                        IntegerValue := TExposePropertyEditor (Prop).GetOrdValue;
                        {$IFDef Win32}
                        if FEncrypted
                          then Encrypt (IntegerValue, sizeof (IntegerValue), not (npInteger in FStoreAsRaw));
                        {$EndIf}
                        IntegerValue := FINIFile.ReadInteger (Secc, Ident, IntegerValue);
                        {$IfDef Win32}
                        if FEncrypted
                          then Decrypt (IntegerValue, sizeof (IntegerValue), not (npInteger in FStoreAsRaw));
                        {$EndIf}
                        Prop.{$IFDef D10}SetValue (IntToStr (IntegerValue)){$Else}Value := IntToStr (IntegerValue){$EndIf};
                      end;
                    tkEnumeration :
                      begin
                        {$IfDef Win32}
                        LastRawInteger := FINIFile.StoreIntegerAsRaw;
                        FINIFile.StoreIntegerAsRaw := npEnumeration in FStoreAsRaw;
                        try
                        {$EndIf}
                          IntegerValue := TExposePropertyEditor (Prop).GetOrdValue;
                          {$IfDef Win32}
                          if FEncrypted
                            then Encrypt (IntegerValue, sizeof (IntegerValue), not FINIFile.StoreIntegerAsRaw);
                          {$EndIf}
                          IntegerValue := FINIFile.ReadInteger (Secc, Ident, IntegerValue);
                          {$IfDef Win32}
                          if FEncrypted
                            then Decrypt (IntegerValue, sizeof (IntegerValue), not FINIFile.StoreIntegerAsRaw);
                          {$EndIf}
                          TExposePropertyEditor (Prop).SetOrdValue (IntegerValue);
                        {$IfDef Win32}
                        finally
                          FINIFile.StoreIntegerAsRaw := LastRawInteger;
                        end;
                        {$EndIf}
                      end;
                    {$IfDef Win32}
                    tkFloat :
                      begin
                        FloatValue := TExposePropertyEditor (Prop).GetFloatValue;
                        if FEncrypted
                          then Encrypt (FloatValue, sizeof (FloatValue), not (npFloat in FStoreAsRaw));
                        FloatValue := FINIFile.ReadFloat (Secc, Ident, FloatValue);
                        if FEncrypted
                          then Decrypt (FloatValue, sizeof (FloatValue), not (npFloat in FStoreAsRaw));
                        Prop.{$IFDef D10}SetValue (FloatToStr (FloatValue)){$Else}Value := FloatToStr (FloatValue){$Endif};
                      end;
                    {$Else}
                    tkFloat : ReadProperty;
                    {$EndIf}
                  end
                else ReadProperty
              else ReadProperty;
            if assigned (FLoadProperty)
              then FLoadProperty (self, TComponent (Comp), Prop.GetName);
          end
          else
          begin
            if Prop.GetPropType^.Kind = tkClass
              then
              begin
                CalculateAsLink;
                if (paSubProperties in Prop.GetAttributes) and (not AsLink)
                  then
                  begin
                    { Code for read class properties with subproperties }
                    SubProps := '';
                    MustLoad := false;
                    SubPropsStack.Add (pointer (TExposePropertyEditor (Prop).GetOrdValue));
                    Prop.GetProperties (GetSubProperties);
                    SubPropsStack.Clear;
                    MustLoad := true;
                    Value := SubProps;
                    ReadValue;
                    SubProps := Value;
                    if SubProps <> ''
                      then Prop.GetProperties (GetSubProperties);
                  end
                  else
                  begin
                    { Code for read class pointer properties }
                    CompRef := TComponent (TExposePropertyEditor (Prop).GetOrdValue);
                    CompRef := PrepareCompRef (CompRef, Value);
                    ReadValue;
                    ToBind.AddObject (Prop.GetName + '=' + Value, Comp);
                  end
              end
              else
              begin
                { Code for read method properties }
                CompTemp := TComponent (TExposePropertyEditor (Prop).GetMethodValue.Data);
                CompRef := CompTemp;
                CompRef := PrepareCompRef (CompRef, Value);
                if CompTemp <> nil
                  then Value := Value + '.' + CompTemp.MethodName (TExposePropertyEditor (Prop).GetMethodValue.Code);
                ReadValue;
                if Value = ''
                  then Value := 'nil';
                ToBindMethods.AddObject (Prop.GetName + '=' + Value, Comp);
              end;
            if assigned (FLoadProperty)
              then FLoadProperty (self, TComponent (Comp), Prop.GetName);
          end
        else
        begin
          try
            Value := ExtractValue (Cad);
            ReadValue;
            FSections [index] := SeccionForList (CompName, Prop.GetName, Secc, Ident, Value, Guardar, Cargar);
            if IsClass (Prop, TStrings)
              then
              begin
                Strings := TStrings (TExposePropertyEditor (Prop).GetOrdValue);
                {$IfDef Win32}
                if FEncrypted
                  then
                  begin
                    CryptStream := TEncryptedStream.Create (AssignPath (Value), fmOpenRead);
                    try
                      Strings.LoadFromStream (CryptStream);
                    finally
                      CryptStream.Free;
                    end;
                  end
                  else {$EndIf} Strings.LoadFromFile (AssignPath (Value));
              end
              else if IsClass (Prop, TPicture)
                then
                begin
                  Picture := TPicture (TExposePropertyEditor (Prop).GetOrdValue);
                  if UpperCase (Value) <> 'EMPTY'
                    then {$IfDef Win32} if FEncrypted
                      then
                      begin
                        CryptStream := TEncryptedStream.Create (AssignPath (Value), fmOpenRead);
                        try
                          TempFileName := '';
                          TempFile := TTempFileStream.Create (AssignPath (Value));
                          try
                            try
                              TempFileName := TempFile.FileName;
                              TempFile.CopyFrom (CryptStream, CryptStream.Size);
                            finally
                              TempFile.Free;
                            end;
                            OldName := TempFileName;
                            TempFileName := ChangeFileExt (TempFileName, ExtractFileExt (AssignPath (Value)));
                            RenameFile (OldName, TempFileName);
                            Picture.LoadFromFile (TempFileName);
                          finally
                            if TempFileName <> ''
                              then SysUtils.DeleteFile (TempFileName);
                          end;
                        finally
                          CryptStream.Free;
                        end;
                      end
                      else {$EndIf} Picture.LoadFromFile (AssignPath (Value))
                    else Picture.Assign (nil);
                end
                else if IsClass (Prop, TGraphic)
                  then
                  begin
                    Graphic := TGraphic (TExposePropertyEditor (Prop).GetOrdValue);
                    if UpperCase (Value) <> 'EMPTY'
                      then {$IfDef Win32} if FEncrypted
                        then
                        begin
                          CryptStream := TEncryptedStream.Create (AssignPath (Value), fmOpenRead);
                          try
                            Graphic.LoadFromStream (CryptStream);
                          finally
                            CryptStream.Free;
                          end;
                        end
                        else {$EndIf} Graphic.LoadFromFile (AssignPath (Value))
                      else Graphic.Assign (nil);
                  end;
          except
            on EFOpenError do { The error is ignored. It's like use the default value of the property};
            else raise;
          end;
        end
      else { Cargar is false... so nothing to do }
  except
    on E : Exception do if assigned (FLoadError)
      then FLoadError (self, TComponent (Comp), Prop.GetName, Value, E);
  end
end;
procedure SaveProperty;
var
  LastRawInteger : boolean;
  procedure WriteValue;
  begin
    {$IfDef Win32}
    if (FEncrypted) and (length (Value) > 0)
      then Encrypt (Value [1], length (Value), true);
    {$EndIf}
    FINIFile.WriteString (Secc, Ident, Value);
  end;
  procedure WriteProperty;
  begin
    Value := Prop.{$IFDef D10}GetValue{$Else}Value{$Endif};
    WriteValue;
  end;
begin
  try
    if Guardar
      then if (not IsClass (Prop, TStrings)) and (not IsClass (Prop, TPicture)) and
              (not IsClass (Prop, TGraphic))
        then if not (Prop.GetPropType^.Kind in [tkClass, tkMethod])
          then
          begin
            { Code to save simple properties modified in version 1.3 to support Raw Data }
            if assigned (FSaveProperty)
              then FSaveProperty (self, TComponent (Comp), Prop.GetName);
            if Prop.GetPropType^.Kind in PropsToCheck
              then if ToSpecialProperties (Prop.GetPropType^.Kind) in FStoreAsRaw
                then case Prop.GetPropType^.Kind of
                    tkInteger :
                      begin
                        IntegerValue := TExposePropertyEditor (Prop).GetOrdValue;
                        {$IfDef Win32}
                        if FEncrypted
                          then Encrypt (IntegerValue, sizeof (IntegerValue), not (npInteger in FStoreAsRaw));
                        {$EndIf}
                        FINIFile.WriteInteger (Secc, Ident, IntegerValue);
                      end;
                    tkEnumeration :
                      begin
                        {$IfDef Win32}
                        LastRawInteger := FINIFile.StoreIntegerAsRaw;
                        FINIFile.StoreIntegerAsRaw := npEnumeration in FStoreAsRaw;
                        try
                        {$EndIf}
                          IntegerValue := TExposePropertyEditor (Prop).GetOrdValue;
                          {$IfDef Win32}
                          if FEncrypted
                            then Encrypt (IntegerValue, sizeof (IntegerValue), not FINIFile.StoreIntegerAsRaw);
                          {$EndIf}
                          FINIFile.WriteInteger (Secc, Ident, IntegerValue);
                        {$IfDef Win32}
                        finally
                          FINIFile.StoreIntegerAsRaw := LastRawInteger;
                        end;
                        {$EndIf}
                      end;
                    {$IfDef Win32}
                    tkFloat :
                      begin
                        FloatValue := TExposePropertyEditor (Prop).GetFloatValue;
                        if FEncrypted
                          then Encrypt (FloatValue, sizeof (FloatValue), not (npFloat in FStoreAsRaw));
                        FINIFile.WriteFloat (Secc, Ident, FloatValue);
                      end;
                    {$Else}
                    tkFloat : WriteProperty;
                    {$EndIf}
                  end
                else WriteProperty
              else WriteProperty;
          end
          else
          begin
            if Prop.GetPropType^.Kind = tkClass
              then
              begin
                CalculateAsLink;
                if (paSubProperties in Prop.GetAttributes) and (not AsLink)
                  then
                  begin
                    { Code for write class properties with subproperties }
                    SubProps := '';
                    try
                      SubPropsStack.Add (pointer (TExposePropertyEditor (Prop).GetOrdValue));
                      Prop.GetProperties (GetSubProperties);
                      SubPropsStack.Clear;
                    finally
                      Value := SubProps;
                    end;
                    if SubProps <> ''
                      then WriteValue;
                  end
                  else
                  begin
                    { Code for write class pointer properties }
                    CompRef := TComponent (TExposePropertyEditor (Prop).GetOrdValue);
                    CompRef := PrepareCompRef (CompRef, Value);
                    WriteValue;
                  end;
              end
              else
              begin
                if assigned (FSaveProperty)
                  then FSaveProperty (self, TComponent (Comp), Prop.GetName);
                { Code for write method properties }
                CompTemp := TComponent (TExposePropertyEditor (Prop).GetMethodValue.Data);
                CompRef := CompTemp;
                if CompRef <> nil
                  then
                  begin
                    CompRef := PrepareCompRef (CompRef, Value);
                    if Value <> ''
                      then Value := Value + '.';
                    Value := Value + CompTemp.MethodName (TExposePropertyEditor (Prop).GetMethodValue.Code);
                    if Value [length (Value)] = '.'
                      then Value := '';
                    WriteValue;
                  end
                  else FINIFile.WriteString (Secc, Ident, '');
              end;
          end
        else
        begin
          { Code for write TStrings properties }
          Value := ExtractValue (Cad);
          WriteValue;
          Value := ExtractValue (Cad);
          if IsClass (Prop, TStrings)
            then
            begin
              Strings := TStrings (TExposePropertyEditor (Prop).GetOrdValue);
              {$IfDef Win32}
              if FEncrypted
                then
                begin
                  CryptStream := TEncryptedStream.Create (AssignPath (Value), fmOpenWrite or fmCreate);
                  try
                    Strings.SaveToStream (CryptStream);
                  finally
                    CryptStream.Free;
                  end;
                end
                else {$EndIf} Strings.SaveToFile (AssignPath (Value));
            end
            else if IsClass (Prop, TPicture)
              then
              begin
                Picture := TPicture (TExposePropertyEditor (Prop).GetOrdValue);
                if (Picture.Graphic <> nil) and (not Picture.Graphic.Empty)
                  then {$IfDef Win32} if FEncrypted
                    then
                    begin
                      CryptStream := TEncryptedStream.Create (AssignPath (Value), fmOpenWrite or fmCreate);
                      try
                        Picture.Graphic.SaveToStream (CryptStream);
                      finally
                        CryptStream.Free;
                      end;
                    end
                    else {$EndIf} Picture.SaveToFile (AssignPath (Value))
                  else
                  begin
                    Value := 'EMPTY';
                    WriteValue;
                  end;
              end
              else if IsClass (Prop, TGraphic)
                then
                begin
                  Graphic := TGraphic (TExposePropertyEditor (Prop).GetOrdValue);
                  if (Graphic <> nil) and (not Graphic.Empty)
                    then {$IfDef Win32} if FEncrypted
                      then
                      begin
                        CryptStream := TEncryptedStream.Create (AssignPath (Value), fmOpenWrite or fmCreate);
                        try
                          Graphic.SaveToStream (CryptStream);
                        finally
                          CryptStream.Free;
                        end;
                      end
                      else {$EndIf} Graphic.SaveToFile (AssignPath (Value))
                    else
                    begin
                      Value := 'EMPTY';
                      WriteValue;
                    end;
                end;
        end
  except
    on E : Exception do if assigned (FSaveError)
      then FSaveError (self, TComponent (Comp), Prop.GetName, Value, E);
  end;
end;

begin
  try
    // JSB: For now this is not implemented !!!!
    {$IFDef D10}
    Comp := FCachedComponent;
    {$Else}
    Comp := Prop.GetComponent (0);
    {$Endif}
    if Comp <> Owner
      then CompName := TComponent (Comp).Name
      else CompName := 'Form';
    Cad := StringForList (CompName, Prop.GetName);
    Index := FSavedProperties.IndexOf (Cad);
    Value := '';
    if Index <> -1
      then
      begin
        Cad := FSections [Index];
        Secc := ExtractSeccion (Cad);
        Ident := ExtractItem (Cad);
        Cargar := ExtractCargar (Cad);
        Guardar := ExtractGuardar (Cad);
        if MustLoad
          then LoadProperty
          else SaveProperty;
      end;
  finally
    {$IFNDef D10}
    Prop.Free;
    {$EndIF}
  end;
end;

{ This method is called by the LoadProperties and the SaveProperties methods }

procedure TINIPropSav.PropertiesWork;
const
  PropTypes : TTypeKinds = [tkInteger, tkChar, tkEnumeration, tkFloat, tkString, tkSet, tkClass, tkMethod
                            {$IfNDef Ver80} ,tkLString, tkWChar {$EndIf}]; { TkLString included in Delphi 2.0 }
var
  i : integer;
  List : {$IfDef D10} IDesignerSelections {$Else} TDesignerSelectionList {$EndIf};
  Last : TObject;
  Designer : TMyDesigner;
  LastCursor : TCursor;
  Procesed : TList;
begin
  LastCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    if FINIFile = nil
      then
      begin
        OpenFile;
        AutoOpened := true;
      end;
    if FINIFile <> nil
      then
      begin
        UpdateNames (nil);
        {$IfDef Win32}
        {$Hints Off}
        {$EndIf}
        Last := nil;
        Designer := nil;
        Procesed := nil;
        {$IfDef Win32}
        {$Hints On}
        {$EndIf}
        { It's important to make you note that this is a special construction. The allocations
          are inside the try finally block, that's why I initialize the variables to nil outside
          the block, if a contruction fails then in the finally block the call to free will not cause
          problems because the value of the pointer is nil }
        try
          {$IfDef Win32}
          {$Warnings Off}
          {$EndIf}
          {$IfDef D4and5}
          Designer := TMyDesigner.Create;
          { The following line is to avoid a premature destruction of the
            object based in the reference count for COM objects. In fact,
            without this line it will be destroyed inside the GetComponentProperties
            procedure and it will cause a access violation later }
          Designer._AddRef;
          {$Else}
          Designer := TMyDesigner.Create;
          {$EndIf}
          {$IfDef Win32}
          {$Warnings On}
          {$EndIf}
          {$IfNDef D4and5}
          Designer.Form := Owner as TForm;
          {$EndIf}
          Procesed := TList.Create;
          ToBind := TStringList.Create;
          ToBindMethods := TStringList.Create;
          SubPropsStack := TList.Create;
          for i := 0 to FSavedProperties.Count - 1 do
            begin
              if Last <> FSavedProperties.Objects [i]
                then
                begin
                  Last := FSavedProperties.Objects [i];
                  if Procesed.IndexOf (Last) = -1 { This is not the best performance... for compatibilty
                                                    with older versions of the component i can't use the
                                                    sorted option of the FSavedProperties object. The use
                                                    of sorted have been avoided this not so good algoritm }
                    then
                    begin
                      Procesed.Add (Last);
                      List := {$IfDef D10} CreateSelectionList {$Else}TDesignerSelectionList.Create{$EndIf};
                      try
                        List.Add (Last as TComponent);
                        {$IFDef D10}
                        FCachedComponent := Last as TComponent;
                        {$Endif}
                        GetComponentProperties (List, PropTypes, Designer, PropertyWork);
                      finally
                        {$IFNDef D10}
                        List.Free;
                        {$EndIf}
                      end;
                    end
               end;
            end;
          if MustLoad
            then
            begin
              BindReferences (ToBind, tkClass);
              BindReferences (ToBindMethods, tkMethod);
            end;
        finally
          SubPropsStack.Free;
          SubPropsStack := nil;
          ToBindMethods.Free;
          ToBindMethods := nil;
          ToBind.Free;
          ToBind := nil;
          {$IfNDef D4and5}
          Designer.Free;
          {$Else}
          { This is the way to destroy a COM object }
          Designer._Release;
          {$EndIf}
          Procesed.Free;
        end;
      end
      else raise EINIPropSav.Create (INIProblems);
  finally
    Screen.Cursor := LastCursor;
    if AutoOpened
      then
      begin
        CloseFile;
        AutoOpened := false;
      end;
  end;
end;

procedure TINIPropSav.LoadProperties;
begin
  MustLoad := true;
  if assigned (FStartLoadingProperties)
    then FStartLoadingProperties (self);
  try
    {$IfDef DemoVersion}
    { Here is the shareware control }
    if not MsgShowed
      then if not CheckShare
        then MessageDlg ('This application uses the TINIPropSav demo version ' +
                       'programmed by José Sebastián Battig. E-Mail: sbattig@bigfoot.com '#13#10+
                       'Please Register...support the Shareware concept.', mtInformation, [mbOk], 0);
    MsgShowed := true;
    {$EndIf}
    PropertiesWork;
  finally
    if assigned (FEndLoadingProperties)
      then FEndLoadingProperties (self);
  end;
end;

procedure TINIPropSav.SaveProperties;
begin
  MustLoad := false;
  if assigned (FStartSavingProperties)
    then FStartSavingProperties (self);
  try
    PropertiesWork;
  finally
    if assigned (FEndSavingProperties)
      then FEndSavingProperties (self);
  end;
end;

procedure TINIPropSav.SetSections;
begin
  if ASecc <> FSections
    then FSections.Assign (ASecc);
end;

procedure TINIPropSav.ReOpen;
begin
  CloseFile;
  OpenFile;
end;

procedure TINIPropSav.SetFileName;
begin
  if AName <> GetFileName
    then
    begin
      DisposeStr (FFileName);
      FFileName := NewStr (AName);
      if FINIFile <> nil
        then ReOpen;
    end;
end;

function TINIPropSav.GetFileName;
begin
  if FFileName <> nil
    then Result := FFileName^
    else Result := '';
end;

procedure TINIPropSav.SetUseAppDir;
begin
  if Value <> FUseAppDir
    then
    begin
      FUseAppDir := Value;
      if FINIFile <> nil
        then ReOpen;
    end;
end;

function TINIPropSav.GetIsOpen;
begin
  Result := FINIFile <> nil;
end;

function TINIPropSav.GetSavedComponentsCount;
begin
  Result := FSavedProperties.Count;
end;

function TINIPropSav.GetSavedComponents (Index : integer) : TComponent;
begin
  Result := FSavedProperties.Objects [Index] as TComponent;
end;

function TINIPropSav.GetSavedProperties (Index : integer) : string;
begin
  Result := ExtractProperty (FSavedProperties [Index]);
end;

function TINIPropSav.IndexOf;
var
  CompName : string;
begin
  if Component <> Owner
    then CompName := Component.Name
    else CompName := 'Form';
  Result := FSavedProperties.IndexOf (StringForList (CompName, Prop));
end;

function TINIPropSav.GetSections (Component : TComponent; const Prop : string) : string;
var
  Index : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then Result := ExtractSeccion (FSections [Index])
    else raise EINIPropSav.Create (PropNotFind);
end;

procedure TINIPropSav.SetSections2 (Component : TComponent; const Prop, Secc : string);
{ I Know, i Know... you dont like the name of this function... well me neither...but i
  dont wanna change it now :) }
var
  Index : integer;
  Cad : string;
  p : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then
    begin
      Cad := FSections [Index];
      p := pos ('+', Cad);
      if p <> 0
        then FSections [Index] := Secc + '+' + copy (Cad, p + 1, length (Cad) - p);
    end
    else raise EINIPropSav.Create (PropNotFind);
end;

function TINIPropSav.GetIdentifiers (Component : TComponent; const Prop : string) : string;
var
  Index : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then Result := ExtractItem (FSections [Index])
    else raise EINIPropSav.Create (PropNotFind);
end;

procedure TINIPropSav.SetIdentifiers (Component : TComponent; const Prop, Ident : string);
var
  Index : integer;
  Cad : string;
  p, p2 : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then
    begin
      Cad := FSections [Index];
      p := pos ('+', Cad);
      p2 := pos ('.', Cad);
      if (p <> 0) and (p2 <> 0)
        then FSections [Index] := copy (Cad, 1, p) + Ident + copy (Cad, p2, length (Cad) - p2 + 1);
    end
    else raise EINIPropSav.Create (PropNotFind);
end;

function TINIPropSav.GetMustLoad (Component : TComponent; const Prop : string) : boolean;
var
  Index : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then Result := ExtractCargar (FSections [Index])
    else raise EINIPropSav.Create (PropNotFind);
end;

procedure TINIPropSav.SetMustLoad (Component : TComponent; const Prop : string; Value : boolean);
var
  Index : integer;
  Cad : string;
  p, p2 : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then
    begin
      Cad := FSections [Index];
      p := pos ('.', Cad);
      p2 := pos ('#', Cad);
      if (p <> 0) and (p2 <> 0)
        then FSections [Index] := copy (Cad, 1, p) + IntToStr (integer (Value)) + copy (Cad, p2, length (Cad) - p2 + 1);
    end
    else raise EINIPropSav.Create (PropNotFind);
end;

function TINIPropSav.GetMustSave (Component : TComponent; const Prop : string) : boolean;
var
  Index : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then Result := ExtractGuardar (FSections [Index])
    else raise EINIPropSav.Create (PropNotFind);
end;

procedure TINIPropSav.SetMustSave (Component : TComponent; const Prop : string; Value : boolean);
var
  Index : integer;
  Cad : string;
  p : integer;
begin
  Index := IndexOf (Component, Prop);
  if Index <> -1
    then
    begin
      Cad := FSections [Index];
      p := pos ('#', Cad);
      if p <> 0
        then FSections [Index] := copy (Cad, 1, p) + IntToStr (integer (Value));
    end
    else raise EINIPropSav.Create (PropNotFind);
end;

procedure TINIPropSav.UpdateObjects;
var
  i : integer;
  Comp : TComponent;
  cad : string;
begin
  for i := 0 to FSavedProperties.Count - 1 do
    begin
      Cad := ExtractComponent (FSavedProperties [i]);
      if Cad <> 'Form'
        then Comp := Owner.FindComponent (Cad)
        else Comp := Owner;
      FSavedProperties.Objects [i] := Comp;
    end;
end;

procedure TINIPropSav.SetSavedProperties;
begin
  if AProp <> FSavedProperties
    then
    begin
      FSavedProperties.Assign (AProp);
      UpdateObjects;
    end;
end;

{ This method updates the info stored in the component about the component's
  properties to be saved, the info is stored as strings }
procedure TINIPropSav.UpdateNames;
var
  i : integer;
  p : TComponent;
  Cad : string;
  LastCursor : TCursor;
begin
  LastCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    i := 0;
    while i < FSavedProperties.Count do
      begin
        try
          p := FSavedProperties.Objects [i] as TComponent;
          if p <> nil
            then
            begin
              Cad := FSavedProperties [i];
              if (p <> Owner) and (p.Name <> ExtractComponent (Cad))
                then FSavedProperties [i] := StringForList (p.Name, ExtractProperty (Cad));
              if p = Remove
                then
                begin
                  FSavedProperties.Delete (i);
                  FSections.Delete (i);
                end
                else inc (i);
            end
            else inc (i);
        except
          inc (i);
        end;
      end;
  finally
    Screen.Cursor := LastCursor;
  end;
end;

procedure TINIPropSav.Notification;
begin
  inherited Notification (AComponent, AOperation);
  if not (csDestroying in ComponentState)
    then if AComponent <> self
      then if AOperation = opRemove
        then UpdateNames (AComponent);
end;

procedure TINIPropSav.ReadProperties;
begin
  (FSavedProperties as TStringList).Sorted := false;
  Reader.ReadListBegin;
  while not Reader.EndOfList do
    FSavedProperties.Add (Reader.ReadString);
  Reader.ReadListEnd;
end;

procedure TINIPropSav.ReadSections;
begin
  Reader.ReadListBegin;
  while not Reader.EndOfList do
    FSections.Add (Reader.ReadString);
  Reader.ReadListEnd;
end;

procedure TINIPropSav.WriteProperties;
var
 i : integer;
begin
  UpdateNames (nil);
  Writer.WriteListBegin;
  for i := 0 to FSavedProperties.Count - 1 do
    Writer.WriteString (FSavedProperties [i]);
  Writer.WriteListEnd;
end;

procedure TINIPropSav.WriteSections;
var
 i : integer;
begin
  Writer.WriteListBegin;
  for i := 0 to FSections.Count - 1 do
    Writer.WriteString (FSections [i]);
  Writer.WriteListEnd;
end;

procedure TINIPropSav.DefineProperties;
begin
  inherited DefineProperties (Filer);
  UpdateNames (nil);
  Filer.DefineProperty ('Properties', ReadProperties, WriteProperties, FSavedProperties.Count > 0);
  Filer.DefineProperty ('Sections', ReadSections, WriteSections, FSections.Count > 0);
end;

procedure TINIPropSav.AssignLoad;
begin
  if FAutoLoad in [aldBeforeOnCreateForm, aldAfterOnCreateForm]
    then
    begin
      OnLoad := Form.OnCreate;
      Form.OnCreate := AutoLoadEvent;
    end
    else if FAutoLoad in [aldBeforeOnShowForm, aldAfterOnShowForm]
      then
      begin
        OnLoad := Form.OnShow;
        Form.OnShow := AutoLoadEvent;
      end;
end;

procedure TINIPropSav.AssignSave;
begin
  if FAutoSave in [asvBeforeOnDestroyForm, asvAfterOnDestroyForm]
    then
    begin
      OnSave := Form.OnDestroy;
      Form.OnDestroy := AutoSaveEvent;
    end
    else if FAutoSave in [asvBeforeOnHideForm, asvAfterOnHideForm]
      then
      begin
        OnSave := Form.OnHide;
        Form.OnHide := AutoSaveEvent;
      end;
end;

procedure TINIPropSav.WriteAutoLoad;
var
  Form : TForm;
begin
  if FAutoLoad <> Value
    then
    begin
      FAutoLoad := Value;
      if [csDesigning, csReading] * ComponentState = []
        then try
          Form := Owner as TForm;
          AssignLoad (Form);
        except
          on EInvalidCast do {};
          else raise;
        end;
    end;
end;

procedure TINIPropSav.WriteAutoSave;
var
  Form : TForm;
begin
  if FAutoSave <> Value
    then
    begin
      FAutoSave := Value;
      if [csDesigning, csReading] * ComponentState = []
        then try
          Form := Owner as TForm;
          AssignSave (Form);
        except
          on EInvalidCast do {};
          else raise;
        end;
    end;
end;

procedure TINIPropSav.Loaded;
var
  Form : TForm;
begin
  inherited Loaded;
  UpdateObjects;
  if (not (csDesigning in ComponentState)) and
    (Owner is TForm) then
    begin
      Form := Owner as TForm;
      AssignLoad (Form);
      AssignSave (Form);
    end;
end;

function TINIPropSav.AssignPath;
begin
  if UseAppDir
    then Result := ExtractFilePath (Application.ExeName) + AFileName
    else Result := AFileName;
end;

procedure TINIPropSav.OpenFile;
var
  FName : string;
begin
  if FINIFile = nil
    then
    begin
      if Trim (GetFileName) = ''
        then FileName := ChangeFileExt (ExtractFileName (Application.ExeName), '.INI');
      { Changed in version 1.1 }
      {$IFDef Win32} if not FUseRegistry
        then
        begin {$EndIf}
          FName := AssignPath (GetFileName);
          {$IfDef Win32}
          FINIFile := TExtINIFile.Create (FName);
          FIniFile.UseRegistry := false;
          {$Else}
          FINIFile := TINIFile.Create (FName);
          {$EndIf}
        {$IFDef Win32}
        end
        else
        begin
          if FUseSoftwareKey
            then
            begin
              FName := ChangeFileExt (ExtractFileName (FileName), '');
              FileName := FName;
            end;
          if FCompanyName = ''
            then CompanyName := FName;
          if FProductName = ''
            then FProductName := FName;
          if FUseSoftwareKey
            then FINIFile := TExtINIFile.Create (Format ('\Software\%s\%s', [FCompanyName, FProductName]))
            else FINIfile := TExtINIFile.Create (FileName);
          FINIFile.UseRegistry := true;
          FINIFile.StoreIntegerAsRaw := npInteger in FStoreAsRaw;
          FINIFile.StoreFloatAsRaw := npFloat in FStoreAsRaw;
          FINIFile.RootKey := FRootKey;
          FINIFile.LazyWrite := FLazyWrite;
        end;
        {$EndIf}
    end;
end;

procedure TINIPropSav.CloseFile;
begin
  if FINIFile <> nil
    then
    begin
      FINIFile.Free;
      FINIFile := nil;
    end;
end;

procedure TINIPropSav.EraseSection;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then FINIFile.EraseSection (Section)
    else raise EINIPropSav.Create (INIProblems);
end;

function TINIPropSav.ReadBool;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then Result := FINIFile.ReadBool (Section, Ident, Default)
    else raise EINIPropSav.Create (INIProblems);
end;

procedure TINIPropSav.WriteBool;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then FINIFile.WriteBool (Section, Ident, Value)
    else raise EINIPropSav.Create (INIProblems);
end;

function TINIPropSav.ReadInteger;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then Result := FINIFile.ReadInteger (Section, Ident, Default)
    else raise EINIPropSav.Create (INIProblems);
end;

procedure TINIPropSav.WriteInteger;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then FINIFile.WriteInteger (Section, Ident, Value)
    else raise EINIPropSav.Create (INIProblems);
end;

function TINIPropSav.ReadString;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then Result := FINIFile.ReadString (Section, Ident, Default)
    else raise EINIPropSav.Create (INIProblems);
end;

procedure TINIPropSav.WriteString;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then FINIFile.WriteString (Section, Ident, Value)
    else raise EINIPropSav.Create (INIProblems);
end;

procedure TINIPropSav.ReadSection;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then FINIFile.ReadSection (Section, Values)
    else raise EINIPropSav.Create (INIProblems);
end;

procedure TINIPropSav.ReadSectionValues;
begin
  if FINIFile = nil
    then OpenFile;
  if FINIFile <> nil
    then FINIFile.ReadSectionValues (Section, Values)
    else raise EINIPropSav.Create (INIProblems);
end;

{$IfNDef D4and5}
procedure TMyDesigner.Modified;
begin
  { Nothing to do here... this is only to avoid a GP Fault generated when you use
    a nil designer when setting a property, in delphi 1 i have to do this, i dont
    tried in Delphi 2 what happens if i dont use this class, but... with this class
    works, so i will left the class here until someone probes me the opposite... :)
    i had not very much time to test all the posible new features of delphi 2 that
    can be removed from this component, i tested all the things that i had to add in order
    to keep the component working with D2.... ok? The logic says that in D2 a error
    210 where raised because the Modified procedure is a asbtract procedure of the
    TDesigner class }
end;
{$EndIf}

{ Functions }

{ This function works as the Pos function but in inverse way, so this function starts from the last
  character and ends in the char 1 }
function InvertPos (PosCad, Cad : string) : byte;
var
  i, Posit : byte;
begin
  Posit := 0;
  i := length (Cad);
  while (i >= 1) and (Posit = 0) do
    begin
      Posit := pos (PosCad, copy (Cad, i, length (Cad) - i + 1));
      dec (i);
    end;
  if Posit <> 0
    then InvertPos := i + 1
    else InvertPos := 0;
end;

function StringForList;

begin
  Result := Format ('%s+%s', [Comp, Prop]);
end;

function SeccionForList;
begin
  if Seccion = ''
    then Seccion := Comp;
  if Item = ''
    then Item := Prop;
  { In the next expression you can see the format of the strings that store the sections
    information of every saved item. In the case of the properties, they are stored in
    the form: Format ('%s+%s', [ComponentName, PropertyName])
    In the version 1.2 was added the "Value" token in the expression, but there's no problem
    with older version. It's still compatible }
  Result := Format ('%s+%s=%s.%d#%d', [Seccion, Item, Value, integer (Guardar), integer (Cargar)]);
end;

function INIpQuote;
var
  i : integer;
begin
  Result := '';
  for i := 1 to length (s) do
    case s [i] of
      '+' : Result := Result + '/1';
      '=' : Result := Result + '/2';
      '.' : Result := Result + '/3';
      '#' : Result := Result + '/4';
      '/' : Result := Result + '//';
      else Result := Result + s [i];
    end;
end;

function INIpUnQuote;
var
  i : integer;
begin
  Result := '';
  i := 1;
  while i <= length (s) do
    if s [i] = '/'
      then
      begin
        case s [i + 1] of
          '1' : Result := Result + '+';
          '2' : Result := Result + '=';
          '3' : Result := Result + '.';
          '4' : Result := Result + '#';
          '/' : Result := Result + '/';
        end;
        inc (i, 2);
      end
      else
      begin
        Result := Result + s [i];
        inc (i);
      end;
end;

function ExtractSeccion;
var
  p : integer;
begin
  p := pos ('+', Cad);
  if p <> 0
    then Result := copy (cad, 1, p - 1)
    else Result := Cad;
end;

function ExtractItem;
var
  p, p2 : integer;

begin
  p := pos ('+', Cad);
  p2 := pos ('=', Cad);
  if p2 = 0
    then p2 := InvertPos ('.', Cad);
  if p2 = 0
    then p2 := length (cad);
  if p <> 0
    then Result := copy (cad, p + 1, p2 - p - 1)
    else Result := Cad;
end;

function ExtractValue;
var
  p, p2 : integer;
begin
  Result := '';
  p := pos ('=', Cad);
  if p = 0
    then exit;
  p2 := InvertPos ('.', Cad);
  if p2 <> 0
    then Result := copy (Cad, p + 1, p2 - p - 1)
    else Result := copy (Cad, p + 1, length (Cad) - p);
end;

function ExtractComponent;
var
  p : integer;
begin
  p := pos ('+', Cad);
  if p <> 0
    then Result := copy (cad, 1, p - 1)
    else Result := Cad;
end;

function ExtractProperty;
var
  p : integer;
begin
  p := pos ('+', Cad);
  if p <> 0
    then Result := copy (cad, p + 1, length (cad) - p)
    else Result := Cad;
end;

function ExtractGuardar;
var
  p, p2 : integer;
begin
  p := InvertPos ('.', Cad);
  p2 := pos ('#', Cad);
  if p2 = 0
    then p2 := length (cad);
  if p <> 0
    then Result := boolean (StrToInt (copy (cad, p + 1, p2 - p - 1)))
    else Result := false;
end;

function ExtractCargar;
var
  p : integer;
begin
  p := pos ('#', Cad);
  if p <> 0
    then Result := boolean (StrToInt (copy (cad, p + 1, length (cad) - p)))
    else Result := false;
end;

{$IfDef Win32}

{ Encryption procedures }

{ Hey, don't think that I wrote all this numbers at hand!!, I made a little
  program to generate them... I'm not so crazy as to do that; the old only-assembly
  programming days are out, so, the less numbers in code better... }

const
  IndexToNum : array [0..255] of byte = (
    000, 214, 064, 177, 016, 051, 162, 191, 005, 212,
    165, 118, 095, 169, 018, 055, 234, 185, 245, 076,
    084, 073, 238, 255, 178, 039, 057, 195, 175, 050,
    150, 066, 045, 221, 040, 037, 130, 093, 232, 125,
    085, 167, 024, 136, 033, 198, 031, 183, 069, 003,
    211, 228, 213, 071, 244, 059, 019, 067, 176, 124,
    154, 226, 209, 001, 107, 132, 163, 224, 237, 215,
    047, 117, 241, 042, 116, 013, 239, 249, 006, 097,
    201, 021, 099, 222, 254, 098, 144, 108, 206, 022,
    004, 140, 141, 160, 091, 008, 170, 081, 180, 208,
    112, 052, 149, 192, 138, 083, 235, 102, 197, 134,
    247, 087, 188, 096, 062, 023, 139, 174, 133, 026,
    017, 120, 082, 034, 166, 100, 074, 146, 179, 123,
    119, 103, 068, 193, 010, 046, 229, 110, 111, 142,
    182, 202, 058, 089, 246, 151, 207, 171, 216, 002,
    038, 184, 065, 043, 186, 061, 205, 079, 251, 127,
    242, 048, 030, 032, 122, 227, 060, 233, 012, 036,
    199, 020, 217, 168, 126, 049, 157, 114, 181, 092,
    220, 153, 164, 011, 009, 101, 109, 075, 248, 223,
    131, 054, 203, 104, 015, 029, 172, 128, 204, 156,
    250, 090, 106, 190, 014, 027, 230, 080, 158, 231,
    113, 077, 159, 218, 194, 137, 173, 088, 187, 063,
    200, 210, 072, 155, 147, 056, 094, 252, 115, 225,
    025, 135, 028, 253, 121, 152, 243, 240, 143, 189,
    044, 070, 148, 041, 129, 053, 236, 035, 105, 078,
    196, 007, 145, 161, 219, 086);

  NumToIndex : array [0..255] of byte = (
    000, 063, 149, 049, 090, 008, 078, 251, 095, 184,
    134, 183, 168, 075, 204, 194, 004, 120, 014, 056,
    171, 081, 089, 115, 042, 230, 119, 205, 232, 195,
    162, 046, 163, 044, 123, 247, 169, 035, 150, 025,
    034, 243, 073, 153, 240, 032, 135, 070, 161, 175,
    029, 005, 101, 245, 191, 015, 225, 026, 142, 055,
    166, 155, 114, 219, 002, 152, 031, 057, 132, 048,
    241, 053, 222, 021, 126, 187, 019, 211, 249, 157,
    207, 097, 122, 105, 020, 040, 255, 111, 217, 143,
    201, 094, 179, 037, 226, 012, 113, 079, 085, 082,
    125, 185, 107, 131, 193, 248, 202, 064, 087, 186,
    137, 138, 100, 210, 177, 228, 074, 071, 011, 130,
    121, 234, 164, 129, 059, 039, 174, 159, 197, 244,
    036, 190, 065, 118, 109, 231, 043, 215, 104, 116,
    091, 092, 139, 238, 086, 252, 127, 224, 242, 102,
    030, 145, 235, 181, 060, 223, 199, 176, 208, 212,
    093, 253, 006, 066, 182, 010, 124, 041, 173, 013,
    096, 147, 196, 216, 117, 028, 058, 003, 024, 128,
    098, 178, 140, 047, 151, 017, 154, 218, 112, 239,
    203, 007, 103, 133, 214, 027, 250, 108, 045, 170,
    220, 080, 141, 192, 198, 156, 088, 146, 099, 062,
    221, 050, 009, 052, 001, 069, 148, 172, 213, 254,
    180, 033, 083, 189, 067, 229, 061, 165, 051, 136,
    206, 209, 038, 167, 016, 106, 246, 068, 022, 076,
    237, 072, 160, 236, 054, 018, 144, 110, 188, 077,
    200, 158, 227, 233, 084, 023);

procedure Encrypt;
var
  DataArr : array [1..MaxInt - 1] of byte absolute Data;
  i, j : integer;
begin
  if Size > 0
    then if not Basic
      then
      begin
        RandSeed := DataArr [1];
        DataArr [1] := IndexToNum [DataArr [1]];
        for i := 2 to Size do
          begin
            j := Random (256);
            DataArr [i] := (DataArr [i] xor IndexToNum [j]);
          end;
      end
      else for i := 1 to Size do
        DataArr [i] := IndexToNum [DataArr [i]]; { This encryption way is really not big deal }
end;

procedure Decrypt;
var
  DataArr : array [1..MaxInt - 1] of byte absolute Data;
  i, j : integer;
begin
  if Size > 0
    then if not Basic
      then
      begin
        DataArr [1] := NumToIndex [DataArr [1]];
        RandSeed := DataArr [1];
        for i := 2 to Size do
          begin
            j := Random (256);
            DataArr [i] := DataArr [i] xor IndexToNum [j];
          end;
      end
      else for i := 1 to Size do
        DataArr [i] := NumToIndex [DataArr [i]];
end;

function HKEYToIdent (aint : longint; var Ident : string) : boolean;
begin
  Result := {$IfNDef D4and5} (aint >= longint (low (HKEYS))) and {$EndIf} (aint <= longint (high (HKEYS)));
  if Result
    then Ident := HKEYS [aint];
end;

function IdentToHKEY (const Ident : string; var Int : longint) : boolean;
var
  i : HKEY;
begin
  Result := true;
  for i := low (HKEYS) to high (HKEYS) do
    if HKEYS [i] = Ident
      then
      begin
        Int := i;
        exit;
      end;
  Result := false;
end;

initialization
  RegisterIntegerConsts (TypeInfo (HKEY), IdentToHKEY, HKEYToIdent);
{$EndIf}
  {$IfDef D4and5}
  {$IfNDef DESIGNTIME}
  TComObjectFactory.Create(ComServer, TMyDesigner, Class_TMyDesigner,
    'TMyDesigner', '', ciMultiInstance, tmApartment);
  {$EndIf}
  {$EndIf}
end.

