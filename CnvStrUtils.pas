unit CnvStrUtils;

{$I DelphiVersion_defines.inc}

interface

uses
{$IFDEF DELPHIXE4}
  Character,
{$ENDIF}
  Classes, Sysutils, Graphics;

type
  TStringArray = array of string;
  TCharSet = set of AnsiChar;

  TAdvStringList = class (TStringList)
  private
    FIgnoreChars: TCharSet;
    FTokenSeparator: Char;
    FQuoteChar: Char;
    function GetTokenizedText: string;
    procedure SetTokenizedText(const Value: string);
  public
    constructor Create;
    property IgnoreChars: TCharSet read FIgnoreChars write FIgnoreChars;
    property TokenizedText: string read GetTokenizedText write SetTokenizedText;
    property TokenSeparator: Char read FTokenSeparator write FTokenSeparator;
    property QuoteChar: Char read FQuoteChar write FQuoteChar;
  end;

function CharInArray(const aChar: Char; const aCharArray: array of Char): Boolean;
function RemoveEscapeChars (const s : string; EscChar : char) : string;
function TextToBool (const Value : string) : boolean;
function BoolToText (Value : boolean) : char;
function EliminateWhiteSpaces (const s : string) : string;
function EliminateChars(const s: AnsiString; const AnsiEliminatedChars: TCharSet): AnsiString; overload;
{$IFDEF DELPHIXE4}
function EliminateChars(const s : string; const EliminatedChars : array of Char): string; overload;
{$ENDIF}
procedure SanitizeString(var s : string); // Removes control chars, but will keep Word compatible control chars (9, 11, 12, 13, 14, 30, 31 and 160)
function LastPartOfName (const s : String) : string;
function FirstPartOfName(const s : string): string;
procedure MixTStrings(Source, Dest : TStrings; FromIndex : Integer = 0);
function CommaList(const Items : string): string;
function ListOfItems(const Items : array of string): String;
function QuotedListOfItems(const Items : array of string): String;
procedure RemoveBlankItems(List : TStringList);
function FirstNonEmptyString(const Strs : array of string): string;
function AddStrings(const Items : array of string): String; overload;
function AddStrings(const Items, Items2 : array of string): String; overload;
function IndexOf(const Items : array of string; const Item : String;
    CaseSensitive : boolean = false): Integer;
procedure DeleteFromArray(var Items: TStringArray; AElementIndex: integer);
function ExtractValue(const s : string): string;
function ExtractName(const s : string): string;
function SplitNameAndValue(const s : string; var AName, AValue : string): Boolean;
function ConvertToMixedCaseString(const s : string): string;
function CnvWrapText(const Line, BreakStr: string; MaxWidth: Integer; Canvas :
    TCanvas): string;
function CnvSimpleWrapText(const Line: string; MaxWidth: Integer): string;
	
function HexToInt(Value : string) : integer;
function StringToHex(const s : string): string;
function HexToString(const s : string): string;

function StringListToTStringArray(l : TStrings): TStringArray;
function StrToIntEx(const s : string): Integer;
procedure StrCount(const s : string; var Alpha, Numeric : Integer);
function MatchRegEx(const Criteria, Value : string): Boolean;
function FormatBytes(const b : int64): string;

function RemoveSymbolsAndNumbers(const s : string): string;

{ String to type conversion routing with cleaning of data capabilities }

function CleanStr(const s: AnsiString; const AnsiValidChars: TCharSet): AnsiString; overload;
{$IFDEF DELPHIXE4}
function CleanStr(const s: string; const ValidChars: array of Char): string; overload;
{$ENDIF}

function CleanStrToInt(const s: string; var IsNull: Boolean): integer;
function CleanStrToCurr(const s: string; var IsNull: Boolean): currency;
function CleanStrToFloat(const s: string; var IsNull: Boolean): double;
function CleanStrToDateTime(const s: string; var IsNull: Boolean): TDateTime;

function IsSimpleInteger(const s: string; var AInt: Integer): boolean;
function IsSimpleFloat(const s: string; var AFloat: Double): boolean;

function CnvMakeIdentifier(const S : string): string;
function CreateGUIDString: String;

function XmlFriendlyName(const AName : string): string;
function ShortenString(const AStr : string; MaxLen : Integer): string;

var
  UpperArray : array [char] of char;

implementation

uses
  Windows, mkRegEx, ActiveX, ComObj;

const
  _BoolToText : array [False..True] of char = ('0', '1');

var
  RegMatcher : TmkreExpr;

function CharInArray(const aChar: Char; const aCharArray: array of Char): Boolean;
var I: Integer;
begin
  Result := false;
  for I := Low(aCharArray) to High(aCharArray) do
    if aChar = aCharArray[I] then
    begin
      Result := true;
      Break;
    end;
end;

function RemoveEscapeChars;
var
  j : Integer;
begin
  Result := s;
  repeat
    j := Pos (EscChar, Result);
    if j > 0
      then system.Delete (Result, j, 2);
  until j <= 0;
end;

function TextToBool;
begin
  if Trim (Value) <> ''
    then case Value [1] of
      '0', 'F' : Result := False;
      '1', 'T' : Result := True;
      else Result := False;
    end
    else Result := False;
end;

function BoolToText;
begin
  Result := _BoolToText [Value];
end;

function EliminateChars(const s: AnsiString; const AnsiEliminatedChars: TCharSet): AnsiString;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length (s) do
    if not (s [i] in AnsiEliminatedChars)
      then Result := Result + s [i];
end;

{$IFDEF DELPHI2009}
function EliminateChars(const s : string; const EliminatedChars : array of Char): string;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length (s) do
    if not s[i].IsInArray(EliminatedChars)
      then Result := Result + s [i];
end;
{$ENDIF}


function EliminateWhiteSpaces (const s : string) : string;
begin
  Result := EliminateChars (s, [' ', #255, #13, #10]);
end;

function LastPartOfName (const s : String) : string;
var
  i : Integer;
begin
  Result := '';
  for i := Length (s) downto 1 do
   if s [i] = '.'
     then
     begin
       Result := system.Copy (s, i + 1, Length (s) - i);
       Exit;
     end;
  Result := s;
end;

procedure MixTStrings(Source, Dest : TStrings; FromIndex : Integer = 0);
var
  i, j : Integer;
begin
  if (Source <> nil) and (Dest <> nil)
    then
    begin
      Dest.BeginUpdate;
      try
        for i := FromIndex to Source.Count - 1 do
          begin
            j := Dest.IndexOfName (Source.Names [i]);
            if j < 0
              then
              begin
                j := Dest.IndexOf (Source [i]);
                if j < 0
                  then Dest.Add (Source [i]);
              end;
          end;
      finally
        Dest.EndUpdate;
      end;
    end;
end;

function CommaList(const Items : string): string;
begin
  if Items <> ''
    then Result := ',' + Items
    else Result := '';
end;

function ListOfItems(const Items : array of string): String;
var
  i : integer;
begin
  Result := '';
  for i := Low (Items) to High (Items) do
    Result := Result + Items [i] + ',';
  system.Delete (Result, Length (Result), 1);
end;

procedure RemoveBlankItems(List : TStringList);
var
  i : Integer;
begin
  List.BeginUpdate;
  try
    i := 0;
    while i < List.Count do
      if Trim (List [i]) = ''
        then List.Delete (i)
        else Inc (i);
  finally
    List.EndUpdate;
  end;
end;

function FirstNonEmptyString(const Strs : array of string): string;
var
  i : Integer;
begin
  Result := '';
  for i := Low (Strs) to High (Strs) do
    if Strs [i] <> ''
      then
      begin
        Result := Strs [i];
        Exit;
      end;
end;

function AddStrings(const Items : array of string): String;
var
  i : integer;
begin
  Result := '';
  for i := Low (Items) to High (Items) do
    Result := Result + Items [i];
end;

function AddStrings(const Items, Items2 : array of string): String;
var
  i : integer;
begin
  Result := '';
  for i := Low (Items) to High (Items) do
    Result := Result + Items [i] + Items2 [i];
end;

function IndexOf(const Items : array of string; const Item : String; 
    CaseSensitive : boolean = false): Integer;
var
  i : Integer;
  UpItem : string;
begin
  if not CaseSensitive
    then UpItem := UpperCase (Item)
    else UpItem := '';
  Result := -1;
  for i := Low (Items) to High (Items) do
    if (CaseSensitive and (Items [i] = Item)) or
       ((not CaseSensitive) and (UpperCase (Items [i]) = UpItem))
      then
      begin
        Result := i;
        Exit;
      end;
end;

function HexDigitToInt(Ch : char) : integer;
var
  sb : byte;
begin
  sb := ord(ch);
  if (sb >= ord('A')) and (sb <= ord('F')) then
    Result := sb - ord('A') + 10
  else if (sb >= ord('a')) and (sb <= ord('f')) then
    Result := sb - ord('a') + 10
  else if (sb >= ord('0')) and (sb <= ord('9')) then
    Result := sb - ord('0')
  else
    raise Exception.Create(ch + ' is not a hex digit');
end;

function HexToInt(Value : string) : integer;
var
  i : integer;
  base : integer;
begin
  Result := 0;
  Value := UpperCase(Value);
  base := 1;
  for i := Length(Value) downto 1 do
  begin
    Result := Result + HexDigitToInt(Value[i])*base;
    base := base*16
  end;
end;

function StringToHex(const s : string): string;
var
  j : Integer;
  Hex : string [2];
begin
  SetLength (Result, Length (s) * 2);
  for j := 1 to Length (s) do
    begin
      Hex := ShortString(IntToHex (Ord (s [j]), 2));
      Move (Hex [1], Result [(j - 1) * 2 + 1], 2);
    end;
end;

function HexToString(const s : string): string;
var
  i : Integer;
  c : Char;
  Hex : string [2];
begin
  SetLength (Hex, 2);
  SetLength (Result, Length (s) div 2);
  i := 1;
  while i <= Length (s)  do
    begin
      Move (s [i], Hex [1], 2);
      c := char (HexToInt (Hex));
      Move (c, Result [(i + 1) div 2], 1);
      Inc (i, 2);
    end;
end;

function FirstPartOfName(const s : string): string;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length (s) do
   if s [i] = '.'
     then
     begin
       Result := system.Copy (s, 1, i - 1);
       Exit;
     end;
  Result := s;
end;

function StringListToTStringArray(l : TStrings): TStringArray;
var
  i : Integer;
begin
  SetLength (Result, l.Count);
  for i := 0 to l.Count - 1 do
    Result [i] := l [i];
end;

function StrToIntEx(const s : string): Integer;
begin
  if s <> ''
    then
    try
      Result := StrToInt (s);
    except
      on EConvertError do Result := 0;
    end
    else Result := 0;
end;

procedure StrCount(const s : string; var Alpha, Numeric : Integer);
var
  i : Integer;
begin
  Alpha := 0;
  Numeric := 0;
  for i := 0 to Length (s) do
{$IFDEF DELPHIXE4}
    if s [i].IsDigit
{$ELSE}
    if s [i] in ['0'..'9']
{$ENDIF}
      then Inc (Numeric)
      else Inc (Alpha);
end;

function MatchRegEx(const Criteria, Value : string): Boolean;
begin
  with RegMatcher do
    begin
      Pattern := Criteria;
      Str := Value;
      Execute;
      Result := Matches.Count > 0;
    end;
end;

function ExtractValue(const s : string): string;
var
  p : Integer;
begin
  p := Pos ('=', s);
  if p > 0
    then Result := system.Copy (s, p + 1, Length (s) - p)
    else Result := '';
end;

function ExtractName(const s : string): string;
var
  p : Integer;
begin
  p := Pos ('=', s);
  if p > 0
    then Result := system.Copy (s, 1, p - 1)
    else Result := s;
end;

function SplitNameAndValue(const s : string; var AName, AValue : string): 
    Boolean;
var
  p : Integer;
begin
  p := Pos ('=', s);
  if p > 0
    then
    begin
      AName := system.Copy (s, 1, p - 1);
      AValue := system.Copy (s, p + 1, Length (s) - p);
      Result := True;
    end
    else Result := False;
end;

function ConvertToMixedCaseString(const s : string): string;
var
  i : Integer;
  NextUp : Boolean;
begin
  SetLength (Result, Length (s));
  NextUp := True;
  for i := 1 to Length (s) do
    if s [i] <> ' '
      then if NextUp
        then
        begin
          Result [i] := UpCase (s [i]);
          NextUp := False;
        end
        else Result [i] := LowerCase (s [i])[1]
      else
      begin
        NextUp := True;
        Result [i] := ' ';
      end;
end;

function FormatBytes(const b : int64): string;
const
  Units : array[0..4] of string[5] = ('Bytes', 'KB', 'MB', 'GB', 'TB');
var
  I : double;
  UnitType : byte;
begin
  i := b div 1024;
  UnitType := 1;
  while i > 1024 do
    begin
      i := i / 1024;
      Inc(UnitType);
    end;
  if i <= 0 then
    Result := IntToStr(b) + ' ' + Units[UnitType-1]
  else
    Result := FloatToStrF(i, ffNumber, 15, 2) + ' ' + Units[UnitType]
end;

function RemoveSymbolsAndNumbers(const s : string): string;
var
  i : Integer;
begin
  Result := '';
  for i := 1 to Length (s) do
{$IFDEF DELPHIXE4}
    if s [i].IsLetter
{$ELSE}
    if s [i] in ['a'..'z', 'A'..'Z']
{$ENDIF}
      then Result := Result + s [i];
end;

function QuotedListOfItems(const Items : array of string): String;
var
  i : integer;
begin
  Result := '';
  for i := Low (Items) to High (Items) do
    Result := Result + '''' + Items [i] + ''',';
  system.Delete (Result, Length (Result), 1);
end;

{$IFDEF DELPHIXE4}
function CnvWrapText(const Line, BreakStr: string; MaxWidth: Integer; Canvas: TCanvas): string;
const
  QuoteChars: array[0..1] of Char = ('''', '"');
var
  Pos: Integer;
  LinePos, LineLen: Integer;
  BreakLen, OldBreakPos, BreakPos: Integer;
  QuoteChar, CurChar: Char;
  ExistingBreak: Boolean;
  BreakChars, NewLineBreakChars : array of Char;
  procedure CheckBreak;
  begin
    if not CharInArray(QuoteChar, QuoteChars) and (ExistingBreak or
        ((Canvas.TextWidth (system.copy (Line, LinePos, BreakPos - LinePos + 1)) >= MaxWidth) and
         (BreakPos > LinePos))) then
      begin
        BreakPos := OldBreakPos;
        pos := BreakPos;
        Result := Result + Copy(Line, LinePos, BreakPos - LinePos + 1);
        if not CharInArray(CurChar, QuoteChars) then
          while (Pos <= LineLen) and CharInArray(Line[Pos], NewLineBreakChars) do
            Inc(Pos);
        if not ExistingBreak and (Pos < LineLen) then
          Result := Result + BreakStr;
        Inc(BreakPos);
        LinePos := BreakPos;
        ExistingBreak := False;
      end;
  end;
begin
  BreakChars := ['.', ' ',#9,'-'];
  NewLineBreakChars := BreakChars + [#13, #10];
  Pos := 1;
  LinePos := 1;
  BreakPos := 0;
  OldBreakPos := 0;
  QuoteChar := ' ';
  ExistingBreak := False;
  LineLen := Length(Line);
  BreakLen := Length(BreakStr);
  Result := '';
  while Pos <= LineLen do
  begin
    CurChar := Line[Pos];
    if AnsiChar(CurChar) in LeadBytes then
    begin
      Inc(Pos);
    end else
      if CurChar = BreakStr[1] then
      begin
        if QuoteChar = ' ' then
        begin
          ExistingBreak := CompareText(BreakStr, Copy(Line, Pos, BreakLen)) = 0;
          if ExistingBreak then
          begin
            Inc(Pos, BreakLen-1);
            OldBreakPos := BreakPos;
            BreakPos := Pos;
          end;
        end
      end
      else if CharInArray(CurChar, BreakChars) then
      begin
        if QuoteChar = ' '
          then
          begin
            OldBreakPos := BreakPos;
            BreakPos := Pos;
          end;
      end
      else if CharInArray(CurChar, QuoteChars) then
        if CurChar = QuoteChar then
          QuoteChar := ' '
        else if QuoteChar = ' ' then
          QuoteChar := CurChar;
    Inc(Pos);
    CheckBreak;
  end;
  OldBreakPos := BreakPos;
  BreakPos := Pos;
  CheckBreak;
  Result := Result + Copy(Line, LinePos, MaxInt);
end;

{$ELSE}
function CnvWrapText(const Line, BreakStr: string; MaxWidth: Integer; Canvas : TCanvas): string;
const
  QuoteChars = ['''', '"'];
var
  Pos: Integer;
  LinePos, LineLen: Integer;
  BreakLen, OldBreakPos, BreakPos: Integer;
  QuoteChar, CurChar: Char;
  ExistingBreak: Boolean;
  BreakChars : set of char;
  procedure CheckBreak;
  begin
    if not (QuoteChar in QuoteChars) and (ExistingBreak or
        ((Canvas.TextWidth (system.copy (Line, LinePos, BreakPos - LinePos + 1)) >= MaxWidth) and
         (BreakPos > LinePos))) then
      begin
        BreakPos := OldBreakPos;
        pos := BreakPos;
        Result := Result + Copy(Line, LinePos, BreakPos - LinePos + 1);
        if not (CurChar in QuoteChars) then
          while (Pos <= LineLen) and (Line[Pos] in BreakChars + [#13, #10]) do Inc(Pos);
        if not ExistingBreak and (Pos < LineLen) then
          Result := Result + BreakStr;
        Inc(BreakPos);
        LinePos := BreakPos;
        ExistingBreak := False;
      end;
  end;
begin
  BreakChars := ['.', ' ',#9,'-'];
  Pos := 1;
  LinePos := 1;
  BreakPos := 0;
  OldBreakPos := 0;
  QuoteChar := ' ';
  ExistingBreak := False;
  LineLen := Length(Line);
  BreakLen := Length(BreakStr);
  Result := '';
  while Pos <= LineLen do
  begin
    CurChar := Line[Pos];
    if CurChar in LeadBytes then
    begin
      Inc(Pos);
    end else
      if CurChar = BreakStr[1] then
      begin
        if QuoteChar = ' ' then
        begin
          ExistingBreak := CompareText(BreakStr, Copy(Line, Pos, BreakLen)) = 0;
          if ExistingBreak then
          begin
            Inc(Pos, BreakLen-1);
            OldBreakPos := BreakPos;
            BreakPos := Pos;
          end;
        end
      end
      else if CurChar in BreakChars then
      begin
        if QuoteChar = ' '
          then
          begin
            OldBreakPos := BreakPos;
            BreakPos := Pos;
          end;
      end
      else if CurChar in QuoteChars then
        if CurChar = QuoteChar then
          QuoteChar := ' '
        else if QuoteChar = ' ' then
          QuoteChar := CurChar;
    Inc(Pos);
    CheckBreak;
  end;
  OldBreakPos := BreakPos;
  BreakPos := Pos;
  CheckBreak;
  Result := Result + Copy(Line, LinePos, MaxInt);
end;
{$ENDIF !DELPHIXE4}

function CnvSimpleWrapText(const Line: string; MaxWidth: Integer): string;
begin
  Result:= WrapText(Line,MaxWidth);
end;

function CleanStr(const s: AnsiString; const AnsiValidChars: TCharSet): AnsiString;
var
  i, j : integer;
begin
  SetLength (Result, length (s));
  j := 0;
  for i := 1 to length (s) do
    if s [i] in AnsiValidChars
      then
      begin
        inc (j);
        Result [j] := s [i];
      end;
  SetLength (Result, j);
end;

{$IFDEF DELPHIXE4}
function CleanStr(const s: string; const ValidChars: array of Char): string;
var
  i, j : integer;
begin
  SetLength (Result, length (s));
  j := 0;
  for i := 1 to length (s) do
    if s [i].IsInArray(ValidChars)
      then
      begin
        inc (j);
        Result [j] := s [i];
      end;
  SetLength (Result, j);
end;
{$ENDIF}

function CleanStrToInt(const s: string; var IsNull: Boolean): integer;
var
  AStr : string;
begin
  AStr := Trim (s);
  IsNull := AStr = '';
  if not IsNull
    then Result := StrToInt (CleanStr (AStr, ['-', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']))
    else Result := 0;
end;

function CleanStrToCurr(const s: string; var IsNull: Boolean): currency;
var
  AStr : string;
begin
  AStr := Trim (s);
  IsNull := AStr = '';
  if not IsNull
    then Result := StrToCurr (CleanStr (AStr, ['-', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']))
    else Result := 0.0;
end;

function CleanStrToFloat(const s: string; var IsNull: Boolean): double;
var
  AStr : string;
begin
  AStr := Trim (s);
  Astr := CleanStr (AStr, ['-', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '.']);
  IsNull := AStr = '';
  if not IsNull then
  	Result := StrToFloat (Astr)
  else
  	Result := 0.0;
end;

function CleanStrToDateTime(const s: string; var IsNull: Boolean): TDateTime;
var
  AStr : string;
begin
  AStr := Trim (s);
  IsNull := AStr = '';
  if not IsNull
    then Result := StrToDateTime (s)
    else Result := 0.0;
end;

procedure DeleteFromArray(var Items: TStringArray; AElementIndex: integer);
var
  i : integer;
begin
  for i := AElementIndex to length (Items) - 2 do
    Items [i] := Items [i + 1];
  SetLength (Items, length (Items) - 1);
end;

function IsSimpleFloat(const s: string; var AFloat: Double): boolean;
var
  i : integer;
  //DotsCounter : integer;
begin
  Result := False;
  //DotsCounter := 0;
  if (Trim(s) = '') or (s[length(s)] = '.')
    then exit;
  for i := 1 to length (s) do
    begin
      case s[i] of
        '.' :
          begin
            //inc (DotsCounter);
            continue;
          end;
        '-' : if i > 1
          then exit;
        '0'..'9' : continue;
        else exit;
      end;
    end;
  try
    AFloat := StrToFloat (s);
    Result := True;
  except
  end;
end;

function IsSimpleInteger(const s: string; var AInt: Integer): boolean;
var
  i : integer;
begin
  Result := False;
  for i := 1 to length (s) do
    case s[i] of
      '-' : if i > 1 then exit;
      '0'..'9' : continue;
      else exit;
    end;
  try
    AInt := StrToInt (s);
    Result := True;
  except
  end;
end;

function CnvMakeIdentifier(const S : string): string;
var
  I : integer;

  function IsCharacter(ch : char) : boolean;
  begin
    Result := ((ch >= 'A') and (ch <= 'Z')) or
              ((ch >= 'a') and (ch <= 'z')) or (ch = '_');
  end;

  function IsDigit(ch : char) : boolean;
  begin
    Result := (ch >= '0') and (ch <= '9');
  end;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    if IsCharacter(S[I]) or (IsDigit(S[I]) and (I > 1)) then
      Result := Result + S[I];
  end
end;

{ TAdvStringList }


constructor TAdvStringList.Create;
begin
  inherited Create;
  FQuoteChar := '"';
  FTokenSeparator := ',';
end;

function TAdvStringList.GetTokenizedText: string;
var
  S: string;
  P: PChar;
  I, Count: Integer;
begin
  Count := GetCount;
  if (Count = 1) and (Get(0) = '')
    then Result := FQuoteChar + FQuoteChar
    else
    begin
      Result := '';
      for I := 0 to Count - 1 do
        begin
          S := Get(I);
          P := PChar(S);
          while not CharInArray(P^, [#0, FQuoteChar, FTokenSeparator]) do
            P := CharNext(P);
          if P^ <> #0
            then S := AnsiQuotedStr(S, FQuoteChar);
          Result := Result + S + FTokenSeparator;
        end;
      System.Delete(Result, Length(Result), 1);
    end;
end;

procedure TAdvStringList.SetTokenizedText(const Value: string);
var
  P : PChar;
  S: string;
  Buf : PChar;
  i : integer;
begin
  if length (Value) > 0
    then GetMem (Buf, length (Value) * SizeOf(Char))
    else Buf := nil;
  try
    BeginUpdate;
    try
      Clear;
      P := PChar(Value);
      while P^ <> #0 do
        begin
          if P^ = FQuoteChar
            then S := AnsiExtractQuotedStr(P, FQuoteChar)
            else
            begin
              i := 0;
              while (P^ <> #0) and (P^ <> FTokenSeparator) do
                begin
                  if not (P^ in FIgnoreChars)
                    then
                    begin
                      Buf [i] := Char(P^);
                      inc (i);
                    end;
                  P := CharNext(P);
                end;
              SetString(S, PChar (Buf), i);
            end;
          Add(S);
          while (P^ = FTokenSeparator) or (P^ in FIgnoreChars) do
            P := CharNext(P);
        end;
    finally
      EndUpdate;
    end;
  finally
    if length (Value) > 0
      then FreeMem (Buf);
  end;
end;

function CreateGUIDString: String;
var
  Guid : TGUID;
begin
  Result := '';
  if CoCreateGuid(Guid) = S_OK then
    result := GuidToString (Guid);
end;

procedure SanitizeString(var s : string);
var
  i : integer;
begin
  for i := 1 to length(s) do
    if Ord(s[i]) in [0..8, 15..29] then
      s[i] := ' ';
end;

function XmlFriendlyName(const AName : string): string;
var
  i : integer;
begin
  Result := '';
  for i := 1 to length(AName) do
    case AName[i] of
      '<'  : Result := Result + '-lesser than-';
      '>'  : Result := Result + '-greater than-';
      '&'  : Result := Result + '-and-';
      '"'  : Result := Result + '-quot-';
      '''' : Result := Result + '-apos-';
      else Result := Result + AName[i];
    end;
end;

function ShortenString(const AStr : string; MaxLen : Integer): string;
const
  MidStr = '...';
begin
  if length(AStr) > MaxLen then
    begin
      Result := system.Copy(AStr, 1, MaxLen div 2 - length(MidStr)) + MidStr +
                system.Copy(AStr, length(AStr) - MaxLen div 2 + 1, length(AStr));
    end
    else Result := AStr;
end;

var
  c : char;

initialization
  RegMatcher := TmkreExpr.Create (nil);
  RegMatcher.UseFastmap := True;
  RegMatcher.CallProcessMessages := False;
  for c := low (UpperArray) to high (UpperArray) do
    UpperArray [c] := UpCase (c);
finalization
  FreeAndNil (RegMatcher);
end.
