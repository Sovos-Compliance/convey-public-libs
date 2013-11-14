{

  ExtINI - Version 1.3

  Copyright 1997 - José Sebastián Battig - Softech S.A.
  E-Mail: sbattig@bigfoot.com

  Extended ini File, this is a very useful unit.... of course the class declared in this unit is not more
  than a simply wrapper class for the TINIFile and TRegINIFile classes

}

unit Extini;

interface

uses
  Classes, IniFiles, Windows, Registry;

type
  TExtIniFile = class (TObject)
  private
    FFileName: string;
    FIniFile : TIniFile;
    FRegFile : TRegIniFile;
    FUseRegistry : boolean;
    FRootKey : HKEY;
    FLazyWrite : boolean;
    FStoreIntegerAsRaw : boolean;
    FStoreFloatAsRaw : boolean;
    procedure OpenFile;
    procedure SetUseRegistry (value : boolean);
    procedure SetRootKey (Value : HKEY);
    procedure SetLazyWrite (value : boolean);
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    function ReadString(const Section, Ident, Default: string): string;
    procedure WriteString(const Section, Ident, Value: String);
    function ReadInteger(const Section, Ident: string; Default: Longint): Longint;
    procedure WriteInteger(const Section, Ident: string; Value: Longint);
    function ReadBool(const Section, Ident: string; Default: Boolean): Boolean;
    procedure WriteBool(const Section, Ident: string; Value: Boolean);
    function ReadFloat (const Section, Ident: string; Default: double) : double;
    procedure WriteFloat (const Section, Ident: string; Value : double);
    procedure ReadSection(const Section: string; Strings: TStrings);
    procedure ReadSections(Strings: TStrings);
    procedure ReadSectionValues(const Section: string; Strings: TStrings);
    procedure EraseSection(const Section: string);
    procedure DeleteKey(const Section, Ident: String);
    property FileName: string read FFileName;
    property UseRegistry : boolean read FUseRegistry write SetUseRegistry default false;
    property RootKey : HKEY read FRootkey write SetRootkey default HKEY_CURRENT_USER;
    property LazyWrite : boolean read FLazyWrite write SetLazyWrite default true;
    property StoreIntegerAsRaw : boolean read FStoreIntegerAsRaw write FStoreIntegerAsRaw default false;
    property StoreFloatAsRaw : boolean read FStoreFloatAsRaw write FStoreFloatAsRaw default false;
    property IniFile : TINIFile read FINIFile;
    property RegINIFile : TRegINIFile read FRegFile;
  end;

implementation

uses
  SysUtils;

type
  TExposeRegistry = class (TRegistry)
  public
    function GetKey (const Key: string): HKEY;
    procedure SetCurrentKey(Value: HKEY);
  end;

function TExposeRegistry.GetKey;
begin
  Result := inherited GetKey (Key);
end;

procedure TExposeRegistry.SetCurrentKey;
begin
  inherited SetCurrentKey (Value);
end;

constructor TExtIniFile.Create;
begin
  inherited Create;
  FFileName := AFileName;
  FRootKey := HKEY_CURRENT_USER;
end;

destructor TExtIniFile.Destroy;
begin
  FIniFile.Free;
  FRegFile.Free;
  inherited Destroy;
end;

procedure TExtIniFile.SetRootKey;
begin
  FRootKey := Value;
  if UseRegistry and (FRegFile <> nil)
    then
    begin
      OpenFile;
      FRegFile.RootKey := Value;
      FRegFile.OpenKey (FileName, true);
    end;
end;

procedure TExtIniFile.SetLazyWrite;
begin
  FLazyWrite := value;
  if UseRegistry and (FRegFile <> nil)
    then FRegFile.LazyWrite := FLazyWrite;
end;

procedure TExtIniFile.SetUseRegistry;
begin
  if value <> FUseRegistry
    then
    begin
      FUseRegistry := value;
      if FRegFile <> nil
        then
        begin
          FRegFile.Free;
          FRegFile := nil;
        end
        else if FIniFile <> nil
          then
          begin
            FIniFile.Free;
            FIniFile := nil;
          end;
    end;
end;

procedure TExtIniFile.OpenFile;
begin
  if (FRegFile = nil) and (FIniFile = nil)
    then if UseRegistry
      then
      begin
        FRegFile := TRegIniFile.Create (FFileName);
        FRegFile.RootKey := FRootKey;
        FRegFile.OpenKey (FileName, true);
        FRegFile.LazyWrite := FLazyWrite;
      end
      else FIniFile := TIniFile.Create (FFileName);
end;

function TExtIniFile.ReadString;
begin
  OpenFile;
  if UseRegistry
    then Result := FRegFile.ReadString (Section, Ident, Default)
    else Result := FIniFile.ReadString (Section, Ident, Default);
end;

procedure TExtIniFile.WriteString;
begin
  OpenFile;
  if UseRegistry
    then FRegFile.WriteString (Section, Ident, Value)
    else FIniFile.WriteString (Section, Ident, Value);
end;

function TExtIniFile.ReadFloat;
var
  Key, OldKey: HKEY;
begin
  OpenFile;
  if UseRegistry
    then if FStoreFloatAsRaw
      then with FRegFile do
        begin
          CreateKey (Section);
          Key := TExposeRegistry (FRegFile).GetKey (Section);
          if Key <> 0
            then
            try
              OldKey := CurrentKey;
              TExposeRegistry (FRegFile).SetCurrentKey(Key);
              try
                if ValueExists (Ident)
                  then Result := ReadFloat (Ident)
                  else Result := Default;
              finally
                TExposeRegistry (FRegFile).SetCurrentKey(OldKey);
              end;
            finally
              RegCloseKey(Key);
            end
            else Result := Default;
        end
      else Result := StrToFloat (FRegFile.ReadString (Section, Ident, FloatToStr (Default)))
    else Result := StrToFloat (FIniFile.ReadString (Section, Ident, FloatToStr (Default)));
end;

procedure TExtIniFile.WriteFloat;
var
  Key, OldKey: HKEY;
begin
  OpenFile;
  if UseRegistry
    then if FStoreFloatAsRaw
      then with FRegFile do
        begin
          CreateKey (Section);
          Key := TExposeRegistry (FRegFile).GetKey (Section);
          if Key <> 0
            then
            try
              OldKey := CurrentKey;
              TExposeRegistry (FRegFile).SetCurrentKey(Key);
              try
                WriteFloat (Ident, Value)
              finally
                TExposeRegistry (FRegFile).SetCurrentKey(OldKey);
              end;
            finally
              RegCloseKey(Key);
            end;
        end
      else FRegFile.WriteString (Section, Ident, FloatToStr (Value))
    else FIniFile.WriteString (Section, Ident, FloatToStr (Value));
end;

function TExtIniFile.ReadInteger;
var
  Key, OldKey: HKEY;
begin
  OpenFile;
  if UseRegistry
    then if FStoreIntegerAsRaw
      then with FRegFile do
        begin
          CreateKey (Section);
          Key := TExposeRegistry (FRegFile).GetKey (Section);
          if Key <> 0
            then
            try
              OldKey := CurrentKey;
              TExposeRegistry (FRegFile).SetCurrentKey(Key);
              try
                if ValueExists (Ident)
                  then Result := TRegistry (FRegFile).ReadInteger (Ident)
                  else Result := Default;
              finally
                TExposeRegistry (FRegFile).SetCurrentKey(OldKey);
              end;
            finally
              RegCloseKey(Key);
            end
            else Result := Default;
        end
      else Result := FRegFile.ReadInteger (Section, Ident, Default)
    else Result := FIniFile.ReadInteger (Section, Ident, Default);
end;

procedure TExtIniFile.WriteInteger;
var
  Key, OldKey: HKEY;
begin
  OpenFile;
  if UseRegistry
    then if FStoreIntegerAsRaw
      then with FRegFile do
        begin
          CreateKey (Section);
          Key := TExposeRegistry (FRegFile).GetKey (Section);
          if Key <> 0
            then
            try
              OldKey := CurrentKey;
              TExposeRegistry (FRegFile).SetCurrentKey(Key);
              try
                TRegistry (FRegFile).WriteInteger (Ident, Value)
              finally
                TExposeRegistry (FRegFile).SetCurrentKey(OldKey);
              end;
            finally
              RegCloseKey(Key);
            end;
        end
      else FRegFile.WriteInteger (Section, Ident, Value)
    else FIniFile.WriteInteger (Section, Ident, Value);
end;

function TExtIniFile.ReadBool;
begin
  OpenFile;
  if UseRegistry
    then Result := FRegFile.ReadBool (Section, Ident, Default)
    else Result := FIniFile.ReadBool (Section, Ident, Default);
end;

procedure TExtIniFile.WriteBool;
begin
  OpenFile;
  if UseRegistry
    then FRegFile.WriteBool (Section, Ident, Value)
    else FIniFile.WriteBool (Section, Ident, Value);
end;

procedure TExtIniFile.ReadSection;
begin
  OpenFile;
  if UseRegistry
    then FRegFile.ReadSection (Section, Strings)
    else FIniFile.ReadSection (Section, Strings);
end;

procedure TExtIniFile.ReadSections;
begin
  OpenFile;
  if UseRegistry
    then FRegFile.ReadSections (Strings)
    else FIniFile.ReadSections (Strings);
end;

procedure TExtIniFile.ReadSectionValues;
begin
  OpenFile;
  if UseRegistry
    then FRegFile.ReadSectionValues (Section, Strings)
    else FIniFile.ReadSectionValues (Section, Strings);
end;

procedure TExtIniFile.EraseSection;
begin
  OpenFile;
  if UseRegistry
    then FRegFile.EraseSection (Section)
    else FIniFile.EraseSection (Section);
end;

procedure TExtIniFile.DeleteKey;
begin
  OpenFile;
  if UseRegistry
    then FRegFile.DeleteKey (Section, Ident)
    else FIniFile.DeleteKey (Section, Ident);
end;

end.
