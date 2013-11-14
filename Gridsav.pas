unit GridSav;

interface

{
  TGridSaver - version 1.0 (part of TINIPropSav package)
  First TGridSaver version shipped with TINIPropSav 2.2 version
  Copyright 1998 - José Sebastián Battig - Maiten Desarrollos Informaticos
  E-Mail: sbattig@bigfoot.com

  This component is intended to use with TINIPropSav.
  It's purpose is to save columns and rows sizes of any
  descendants of TCustomGrid automatically simply relating
  TGridSaver to an TINIPropSav component. TGridSaver uses
  TINIPropSav interface to access the registry, so, all the
  settings in TINIPropSav apply for where the data is stored
  by TGridSaver.
}

uses
  {$IFDef Win32} Windows, {$EndIf} Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, Grids, IniProps;

type
  TGridSaver = class(TComponent)
  private
    FGrid : TCustomGrid;
    FIniPropSav : TIniPropSav;
    FOldStartLoad : TNotifyEvent;
    FOldStartSave : TNotifyEvent;
    FSectionName : string;
    FColumnName : string;
    FRowName : string;
    FSaveColumnWidths : boolean;
    FSaveRowHeights : boolean;
    FSaveColumnsPositions : boolean;
    FOnLoadData : TNotifyEvent;
    FOnSaveData : TNotifyEvent;
    procedure LoadGridData (Sender : TObject);
    procedure SaveGridData (Sender : TObject);
    procedure SetGrid (AGrid : TCustomGrid);
  protected
    procedure Loaded; override;
    procedure Notification (AComponent : TComponent; AOperation : TOperation); override;
  public
    constructor Create (AOwner : TComponent); override;
    procedure LoadData; virtual;
    procedure SaveData; virtual;
  published
    property Grid : TCustomGrid read FGrid write SetGrid;
    property IniPropSav : TIniPropSav read FIniPropSav write FIniPropSav;
    property SectionName : string read FSectionName write FSectionName;
    property ColumnName : string read FColumnName write FColumnName;
    property RowName : string read FRowName write FRowName;
    property SaveColumnWidths : boolean read FSaveColumnWidths write FSaveColumnWidths default true;
    property SaveRowHeights : boolean read FSaveRowHeights write FSaveRowHeights default true;
    property SaveColumnsPositions : boolean read FSaveColumnsPositions write FSaveColumnsPositions default true;
    property OnLoadData : TNotifyEvent read FOnLoadData write FOnLoadData;
    property OnSaveData : TNotifyEvent read FOnSaveData write FOnSaveData;
  end;

procedure Register;

implementation

uses
  DBGrids;

type
  { This class is to access protected properties in TCustomGrid }
  TExposeCustomGrid = class (TCustomGrid)
  end;

  TExposeCustomDBGrid = class (TCustomDBGrid)
  end;

{ TGridSaver }

constructor TGridSaver.Create;
begin
  inherited Create (AOwner);
  FColumnName := 'COLUMN';
  FRowName := 'ROW';
  FSaveColumnWidths := true;
  FSaveRowHeights := true;
  FSaveColumnsPositions := true;
end;

procedure TGridSaver.Notification;
begin
  inherited Notification (AComponent, AOperation);
  if AOperation = opRemove
    then if AComponent = FGrid
      then FGrid := nil
      else if AComponent = FIniPropSav
        then FIniPropSav := nil;
end;

procedure TGridSaver.SetGrid;
begin
  FGrid := AGrid;
  if (FGrid <> nil) and
     ([csLoading, csReading, csDesigning] * ComponentState = [csDesigning]) and
     (FGrid.Owner <> nil)
    then with FGrid do
      FSectionName := Owner.Name + Name;
end;

procedure TGridSaver.SaveData;
var
  i : integer;
begin
  if assigned (FOnSaveData)
    then FOnSaveData (self);
  if FGrid <> nil
    then
    begin
      with FIniPropSav, TExposeCustomGrid (FGrid) do
        begin
          OpenFile;
          if FSaveColumnWidths
            then for i := 0 to ColCount - 1 do
              WriteInteger (FSectionName, Format ('%s%d', [FColumnName, i]), ColWidths [i]);
          if FSaveRowHeights
            then for i := 0 to RowCount - 1 do
              WriteInteger (FSectionName, Format ('%s%d', [FRowName, i]), RowHeights [i]);
          if FSaveColumnsPositions and (FGrid is TCustomDBGrid)
            then with TExposeCustomDBGrid (Grid) do
              begin
                for i := 0 to Columns.Count - 1 do
                  with Columns [i] do
                    WriteInteger (FSectionName, FieldName, i);
              end;
          CloseFile;
        end;
    end;
end;

procedure TGridSaver.SaveGridData;
begin
  if assigned (FOldStartSave)
    then FOldStartSave (Sender);
  SaveData;
end;

procedure TGridSaver.LoadData;
var
  i, j, p : integer;
  NewOrder : TStringList;
  BackColumn : TColumn;
begin
  if assigned (FOnLoadData)
    then FOnLoadData (self);
  if FGrid <> nil
    then
    begin
      with FIniPropSav, TExposeCustomGrid (FGrid) do
        begin
          OpenFile;
          if FSaveColumnsPositions and (FGrid is TCustomDBGrid)
            then
            begin
              NewOrder := TStringList.Create;
              try
                with TExposeCustomDBGrid (FGrid) do
                  begin
                    for i := 0 to Columns.Count - 1 do
                      with Columns [i] do
                        begin
                          j := ReadInteger (FSectionName, FieldName, i);
                          NewOrder.AddObject (FieldName, pointer (j));
                        end;
                    for i := 0 to NewOrder.Count - 1 do
                      for j := 0 to Columns.Count - 1 do
                        if NewOrder [i] = Columns [j].FieldName
                          then
                          begin
                            p := integer (NewOrder.Objects [i]);
                            if p <> j
                              then
                              begin
                                BackColumn := TColumn.Create (nil);
                                try
                                  BackColumn.Assign (Columns [j]);
                                  Columns [j] := Columns [p];
                                  Columns [p] := BackColumn;
                                finally
                                  BackColumn.Free;
                                end;
                              end;
                            break;
                          end;
                  end;
              finally
                NewOrder.Free;
              end;
            end;
          if FSaveColumnWidths
            then for i := 0 to ColCount - 1 do
              ColWidths [i] := ReadInteger (FSectionName, Format ('%s%d', [FColumnName, i]), ColWidths [i]);
          if FSaveRowHeights
            then for i := 0 to RowCount - 1 do
              RowHeights [i] := ReadInteger (FSectionName, Format ('%s%d', [FRowName, i]), RowHeights [i]);
          CloseFile;
        end;
    end;
end;

procedure TGridSaver.LoadGridData;
begin
  if assigned (FOldStartLoad)
    then FOldStartLoad (Sender);
  LoadData;
end;

procedure TGridSaver.Loaded;
begin
  inherited Loaded;
  if (FGrid <> nil) and (FIniPropSav <> nil) and (not (csDesigning in ComponentState))
    then
    begin
      FOldStartLoad := FIniPropSav.OnStartLoadingProperties;
      FIniPropSav.OnStartLoadingProperties := LoadGridData;
      FOldStartSave := FIniPropSav.OnStartSavingProperties;
      FIniPropSav.OnStartSavingProperties := SaveGridData;
    end;
end;

{ Registration Procedure }

procedure Register;
begin
  RegisterComponents('New', [TGridSaver]);
end;

end.
