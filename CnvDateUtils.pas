unit CnvDateUtils;

interface

{$Include DelphiVersion_defines.inc}

uses
  {$IFDEF DELPHIXE}
  System.Classes;
  {$ELSE}
  Classes;
  {$ENDIF}

type
  TDateTimePart = (dtpYear, dtpMonth, dtpDay, dtpHour, dtpMinute, dtpSecond, dtpMillisecond);

function LocalDateTimeToUTC(LocalDateTime : TDateTime): TDateTime;
function UTCToLocalDateTime(UTC : TDateTime): TDateTime;
function CnvIncDate(Date : TDateTime; Dif : integer; Part : TDateTimePart): TDateTime;
procedure SetEnglishLocales;
procedure RestoreLocales;
function EngFormatDateTime(const Format: string; DateTime: TDateTime): string;
function AddBusinessDays(const StartDate : TDateTime; const Days : integer) : TDateTime;
function AddBusinessWithoutFederalDays(const StartDate : TDateTime; const Days : integer) : TDateTime;
function BusinessDaysBetween(SourceDate, TargetDate: TDateTime): Double;

var
  Holidays, HolidaysFederal : TStringList;

implementation

uses
  Windows, SysUtils, Math;

function EngFormatDateTime(const Format: string; DateTime: TDateTime): string;
begin
  SetEnglishLocales;
  try
    Result := FormatDateTime (Format, DateTime);
  finally
    RestoreLocales;
  end;
end;

function ApplyTimeZone (Source : TDateTime; Operator : smallint) : TDateTime;
const
  MinMsecs = 60 * 1000;
var
  TimeZoneInfo : TIME_ZONE_INFORMATION;
begin
  case GetTimeZoneInformation (TimeZoneInfo) of
    TIME_ZONE_ID_UNKNOWN : Result := Source;
    TIME_ZONE_ID_STANDARD : Result := TimeStampToDateTime (MSecsToTimeStamp (TimeStampToMSecs (DateTimeToTimeStamp (Source)) + Operator * MinMsecs * TimeZoneInfo.StandardBias));
    TIME_ZONE_ID_DAYLIGHT : Result := TimeStampToDateTime (MSecsToTimeStamp (TimeStampToMSecs (DateTimeToTimeStamp (Source)) + Operator * MinMsecs * TimeZoneInfo.DaylightBias));
    else Result := Source;
  end;
end;

function UTCToLocalDateTime(UTC : TDateTime): TDateTime;
begin
  Result := ApplyTimeZone (UTC, -1);
end;

function LocalDateTimeToUTC(LocalDateTime : TDateTime): TDateTime;
begin
  Result := ApplyTimeZone (LocalDateTime, 1);
end;

function CnvIncDate(Date : TDateTime; Dif : integer; Part : TDateTimePart): TDateTime;
var
  MSecsInTime, MSecsGivenDate : Comp;
begin
  MSecsInTime := 0;
  case Part of
    dtpYear :
      begin
        Result := IncMonth (Date, Dif * 12);
        Exit;
      end;
    dtpMonth :
      begin
        Result := IncMonth (Date, Dif);
        Exit;
      end;
    dtpDay : MSecsInTime := MSecsPerDay;
    dtpHour : MSecsInTime := MSecsPerDay / 24;
    dtpMinute : MSecsInTime := MSecsPerDay / 1440;
    dtpSecond : MSecsInTime := MSecsPerDay / SecsPerDay;
    dtpMillisecond : MSecsInTime := 1;
  end;
  MSecsGivenDate := TimeStampToMSecs (DateTimeToTimeStamp (Date));
  Result := TimeStampToDateTime(MSecsToTimeStamp(MSecsGivenDate + (MSecsInTime * Dif)));
end;

const
  EShortMonthNames : array [1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr',
                                                'May', 'Jun', 'Jul', 'Aug',
                                                'Sep', 'Oct', 'Nov', 'Dec');
  ELongMonthNames: array[1..12] of string = ('January', 'February', 'March', 'April',
                                             'May', 'June', 'July', 'August',
                                             'September', 'October', 'November', 'December');
  EShortDayNames: array[1..7] of string = ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');
  ELongDayNames: array[1..7] of string = ('Monday', 'Tuesday', 'Wednesday',
                                          'Thursday', 'Friday', 'Saturday', 'Sunday');
var
  FShortMonthNames: array[1..12] of string;
  FLongMonthNames: array[1..12] of string;
  FShortDayNames: array[1..7] of string;
  FLongDayNames: array[1..7] of string;
  FDecimalSeparator : Char;
  FThousandSeparator : Char;

  ChangesCount : Integer;

procedure SetEnglishLocales;
var
  i : Integer;
begin
  Inc (ChangesCount);
  if ChangesCount > 0
    then Exit;
  {$IFDEF DELPHIXE}
  with FormatSettings do
    begin
  {$ENDIF}
      for i := Low (ShortMonthNames) to High (ShortMonthNames) do
        FShortMonthNames [i] := ShortMonthNames [i];
      for i := Low (LongMonthNames) to High (LongMonthNames) do
        FLongMonthNames [i] := LongMonthNames [i];
      for i := Low (ShortDayNames) to High (ShortDayNames) do
        FShortDayNames [i] := ShortDayNames [i];
      for i := Low (LongDayNames) to High (LongDayNames) do
        FLongDayNames [i] := LongDayNames [i];
      FDecimalSeparator := DecimalSeparator;
      FThousandSeparator := ThousandSeparator;
      for i := Low (ShortMonthNames) to High (ShortMonthNames) do
        ShortMonthNames [i] := EShortMonthNames [i];
      for i := Low (LongMonthNames) to High (LongMonthNames) do
        LongMonthNames [i] := ELongMonthNames [i];
      for i := Low (ShortDayNames) to High (ShortDayNames) do
        ShortDayNames [i] := EShortDayNames [i];
      for i := Low (LongDayNames) to High (LongDayNames) do
        LongDayNames [i] := ELongDayNames [i];
      DecimalSeparator := '.';
      ThousandSeparator := ',';
  {$IFDEF DELPHIXE}
    end;
  {$ENDIF}
end;

procedure RestoreLocales;
var
  i : Integer;
begin
  Dec (ChangesCount);
  if ChangesCount > 1
    then Exit;
  {$IFDEF DELPHIXE}
  with FormatSettings do
    begin
  {$ENDIF}
      for i := Low (ShortMonthNames) to High (ShortMonthNames) do
        ShortMonthNames [i] := FShortMonthNames [i];
      for i := Low (LongMonthNames) to High (LongMonthNames) do
        LongMonthNames [i] := FLongMonthNames [i];
      for i := Low (ShortDayNames) to High (ShortDayNames) do
        ShortDayNames [i] := FShortDayNames [i];
      for i := Low (LongDayNames) to High (LongDayNames) do
        LongDayNames [i] := FLongDayNames [i];
      DecimalSeparator := FDecimalSeparator;
      ThousandSeparator := FThousandSeparator;
  {$IFDEF DELPHIXE}
    end;
  {$ENDIF}
end;

function AddBusinessDays(const StartDate : TDateTime; const Days : integer) : TDateTime;
var
  i : integer;
begin
  i := 0;
  result := StartDate;
  while i < Days do
    begin
      result := result + 1;
      if DayOfWeek (result) in [1, 7]
        then continue;
      if holidays.indexOf (FormatDateTime('yyyy/mm/dd', result)) > 0
        then continue;
      inc(i);
    end;
end;

function AddBusinessWithoutFederalDays(const StartDate : TDateTime; const Days : integer) : TDateTime;
var
  i : integer;
begin
  i := 0;
  result := StartDate;
  while i < Days do
    begin
      result := result + 1;
      if DayOfWeek (result) in [1, 7]
        then continue;
      if holidaysFederal.indexOf (FormatDateTime('yyyy/mm/dd', result)) > 0
        then continue;
      inc(i);
    end;
end;

function BusinessDaysBetween(SourceDate, TargetDate: TDateTime): Double;
var
  Dif : double;
  Weeks : integer;
begin
  Result := 0;
  if SourceDate > TargetDate
    then exit;
  Dif := TargetDate - SourceDate;
  Weeks := Trunc (Dif) div 7;
  Result := Dif - Weeks * 2;
  Dif := Dif - Weeks * 7;
  case DayOfWeek (SourceDate) of
    //1 : Result := Result - Max (Min (Dif, 1), 1);
    2 : Result := Result - Max (Dif - 4, 0);
    3 : Result := Result - Max (Min (Dif - 3, 2), 0);
    4 : Result := Result - Max (Min (Dif - 2, 2), 0);
    5 : Result := Result - Max (Min (Dif - 1, 2), 0);
    6 : Result := Result - Max (Min (Dif, 2), 0);
    7 : Result := Result - Max (Min (Dif, 1), 1);
  end;
end;

initialization
  ChangesCount := 0;
  Holidays := TStringList.Create;
  HolidaysFederal := TStringList.Create;
finalization
  FreeAndNil (Holidays);
  FreeAndNil (HolidaysFederal);
end.
