unit TestCnvStrUtils;

interface

uses
  TestFramework, Classes;

type
  {$M+}
  TestCnvStrUtilsUnit = class(TTestCase)
  published
    procedure _RemoveEscapeChars;
    procedure _TextToBool;
    procedure _BoolToText;
    procedure _EliminateWhiteSpaces;
    procedure _EliminateChars;
    procedure _SanitizeString;
    procedure _SanitizeJSonValue;
    procedure _LastPartOfName;
    procedure _FirstPartOfName;
    procedure _MixTStrings;
    procedure _CommaList;
    procedure _ListOfItems;
    procedure _QuotedListOfItems;
    procedure _RemoveBlankItems;
    procedure _FirstNonEmptyString;
    procedure _AddStrings;
    procedure _AddStrings2;
    procedure _IndexOf;
    procedure _IndexOf2;
    procedure _DeleteFromArray;
    procedure _ExtractValue;
    procedure _ExtractName;
    procedure _SplitNameAndValue;
    procedure _ConvertToMixedCaseString;
    procedure _CnvWrapText;
    procedure _CnvSimpleWrapText;
    procedure _HexToInt;
    procedure _StringToHex;
    procedure _HexToString;
    procedure _StringListToTStringArray;
    procedure _StrToIntEx;
    procedure _StrCount;
    procedure _MatchRegEx;
    procedure _FormatBytes;
    procedure _RemoveSymbolsAndNumbers;
    procedure _CleanStr;
    procedure _CleanStrToInt;
    procedure _CleanStrToCurr;
    procedure _CleanStrToFloat;
    procedure _CleanStrToDateTime;
    procedure _IsSimpleInteger;
    procedure _IsSimpleFloat;
    procedure _CnvMakeIdentifier;
    procedure _CreateGUIDString;
    procedure _XmlFriendlyName;
    procedure _ShortenString;
    procedure _TAdvStringList;
  end;

implementation

uses CnvStrUtils, Graphics, Windows;

{ TestCnvStrUtilsUnit }

procedure TestCnvStrUtilsUnit._AddStrings;
begin
  CheckEquals('abcdef', AddStrings(['abc', 'def']));
end;

procedure TestCnvStrUtilsUnit._AddStrings2;
begin
  CheckEquals('abefcdgh', AddStrings(['ab', 'cd'], ['ef', 'gh']));
end;

procedure TestCnvStrUtilsUnit._BoolToText;
begin
  CheckEquals('0', BoolToText(False), 'False');
  CheckEquals('1', BoolToText(True), 'True');
end;

procedure TestCnvStrUtilsUnit._CleanStr;
begin
  CheckEquals('bc', CleanStr('abc', ['b', 'c']));
end;

procedure TestCnvStrUtilsUnit._CleanStrToCurr;
var
  IsNull: Boolean;
begin
  CheckEquals(54.5 , CleanStrToCurr('54.5a', IsNull));
  CheckFalse(IsNull);
end;

procedure TestCnvStrUtilsUnit._CleanStrToDateTime;
var
  IsNull: Boolean;
begin
  CheckEquals(42006 , CleanStrToDateTime('01/02/2015', IsNull));
  CheckFalse(IsNull);
end;

procedure TestCnvStrUtilsUnit._CleanStrToFloat;
var
  IsNull: Boolean;
begin
  CheckEquals(54.5 , CleanStrToFloat('54.5a', IsNull));
  CheckFalse(IsNull);
end;

procedure TestCnvStrUtilsUnit._CleanStrToInt;
var
  IsNull: Boolean;
begin
  CheckEquals(545 , CleanStrToInt('545a', IsNull));
  CheckFalse(IsNull);
end;

procedure TestCnvStrUtilsUnit._CnvMakeIdentifier;
begin
  CheckEquals('_a2', CnvMakeIdentifier('1_a2'));
end;

procedure TestCnvStrUtilsUnit._CnvSimpleWrapText;
begin
  CheckEquals('abc', CnvSimpleWrapText('abc', 2));
end;

procedure TestCnvStrUtilsUnit._CnvWrapText;
var
  Canvas: TCanvas;
  dc: HDC;
begin
  Canvas := TCanvas.Create;
  try
    dc := GetWindowDC(0);
    try
      Canvas.Handle := dc;
      CheckEquals('<break>abc', CnvWrapText('abc', '<break>', 2, Canvas));
    finally
      ReleaseDC(0, dc);
    end;
  finally
    Canvas.Free;
  end;
end;

procedure TestCnvStrUtilsUnit._CommaList;
begin
  CheckEquals(',abc', CommaList('abc'));
end;

procedure TestCnvStrUtilsUnit._ConvertToMixedCaseString;
begin
  CheckEquals('Abc Def', ConvertToMixedCaseString('abc def'));
end;

procedure TestCnvStrUtilsUnit._CreateGUIDString;
begin
  CheckNotEquals('', CreateGUIDString);
end;

procedure TestCnvStrUtilsUnit._DeleteFromArray;
var
  Items: TStringArray;
begin
  SetLength(Items, 3);
  Items[0] := 'ab';
  Items[1] := 'cd';
  Items[2] := 'ef';
  DeleteFromArray(Items, 1);
  CheckEquals('ef', Items[1]);
end;

procedure TestCnvStrUtilsUnit._EliminateChars;
begin
  CheckEquals('abc', EliminateChars('azbxc', ['z', 'x']));
end;

procedure TestCnvStrUtilsUnit._EliminateWhiteSpaces;
begin
  CheckEquals('abc', EliminateWhiteSpaces(' a b c '));
end;

procedure TestCnvStrUtilsUnit._ExtractName;
begin
  CheckEquals('name', ExtractName('name=value'));
end;

procedure TestCnvStrUtilsUnit._ExtractValue;
begin
  CheckEquals('value', ExtractValue('name=value'));
end;

procedure TestCnvStrUtilsUnit._FirstNonEmptyString;
begin
  CheckEquals('abc', FirstNonEmptyString(['', 'abc', 'def']));
end;

procedure TestCnvStrUtilsUnit._FirstPartOfName;
begin
  CheckEquals('convey', FirstPartOfName('convey.com'));
end;

procedure TestCnvStrUtilsUnit._FormatBytes;
begin
  CheckEquals('10.73 MB', FormatBytes($ABC123));
end;

procedure TestCnvStrUtilsUnit._HexToInt;
begin
  CheckEquals($ABC123, HexToInt('ABC123')); 
end;

procedure TestCnvStrUtilsUnit._HexToString;
begin
  CheckEquals('abc', HexToString('616263'));
end;

procedure TestCnvStrUtilsUnit._IndexOf;
begin
  CheckEquals(1, IndexOf(['ab', 'cd', 'ef'], 'CD', False));
end;

procedure TestCnvStrUtilsUnit._IndexOf2;
begin
  CheckEquals(-1, IndexOf(['ab', 'cd', 'ef'], 'CD', True));
end;

procedure TestCnvStrUtilsUnit._IsSimpleFloat;
var
  AFloat: Double;
begin
  CheckTrue(IsSimpleFloat('1.2', AFloat));
end;

procedure TestCnvStrUtilsUnit._IsSimpleInteger;
var
  AInt: Integer;
begin
  CheckTrue(IsSimpleInteger('1', AInt));
end;

procedure TestCnvStrUtilsUnit._LastPartOfName;
begin
  CheckEquals('com', LastPartOfName('convey.com'));
end;

procedure TestCnvStrUtilsUnit._ListOfItems;
begin
  CheckEquals('1,2', ListOfItems(['1', '2']));
end;

procedure TestCnvStrUtilsUnit._MatchRegEx;
begin
  CheckTrue(MatchRegEx('^\w+$', 'abc'));
end;

procedure TestCnvStrUtilsUnit._MixTStrings;
const
  SKey = 'key';
  SValue = 'value';
var
  Source, Dest: TStringList;
begin
  Source := TStringList.Create;
  try
    Source.Values[SKey] := SValue;
    Dest := TStringList.Create;
    try
      MixTStrings(Source, Dest, 0);
      CheckEquals(SValue, Dest.Values[SKey]);
    finally
      Dest.Free;
    end;
  finally
    Source.Free;
  end;
end;

procedure TestCnvStrUtilsUnit._QuotedListOfItems;
begin
  CheckEquals('''1'',''2''', QuotedListOfItems(['1', '2']));
end;

procedure TestCnvStrUtilsUnit._RemoveBlankItems;
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    List.Add('');
    RemoveBlankItems(List);
    CheckEquals(0, List.Count);
  finally
    List.Free;
  end;
end;

procedure TestCnvStrUtilsUnit._RemoveEscapeChars;
var
  actual: string;
begin
  actual := RemoveEscapeChars('a\bc', '\');
  CheckEquals('ac', actual);
end;

procedure TestCnvStrUtilsUnit._RemoveSymbolsAndNumbers;
begin
  CheckEquals('abc', RemoveSymbolsAndNumbers('a1b3c'));
end;

procedure TestCnvStrUtilsUnit._SanitizeJSonValue;
begin
  CheckEquals('\\a\"bc\r\n', SanitizeJSonValue('\a"bc'#13#10));
end;

procedure TestCnvStrUtilsUnit._SanitizeString;
var
  S: string;
begin
  S := 'a'#2'b'#16'c';
  SanitizeString(S);
  CheckEquals('a b c', S);
end;

procedure TestCnvStrUtilsUnit._ShortenString;
begin
  CheckEquals('...c', ShortenString('abc', 2));
end;

procedure TestCnvStrUtilsUnit._SplitNameAndValue;
var
  AName, AValue : string;
begin
  CheckTrue(SplitNameAndValue('name=value', AName, AValue));
  CheckEquals('name', AName);
  CheckEquals('value', AValue);
end;

procedure TestCnvStrUtilsUnit._StrCount;
var
  Alpha, Numeric : Integer;
begin
  StrCount('ab1', Alpha, Numeric);
  CheckEquals(3, Alpha);
  CheckEquals(1, Numeric);
end;

procedure TestCnvStrUtilsUnit._StringListToTStringArray;
var
  List: TStringList;
  actual: TStringArray;
begin
  List := TStringList.Create;
  try
    List.Add('ab');
    List.Add('cd');
    List.Add('ef');
    actual := StringListToTStringArray(List);
    CheckEquals('cd', actual[1]);
  finally
    List.Free;
  end;
end;

procedure TestCnvStrUtilsUnit._StringToHex;
begin
  CheckEquals('616263', StringToHex('abc'));
end;

procedure TestCnvStrUtilsUnit._StrToIntEx;
begin
  CheckEquals(123, StrToIntEx('123'));
end;

procedure TestCnvStrUtilsUnit._TAdvStringList;
var
  List: TAdvStringList;
begin
  List := TAdvStringList.Create;
  try
    List.TokenSeparator := ',';
    List.IgnoreChars := [#13, #10];
    List.TokenizedText := 'Token=?xml?\string,xmlns=?xml?\string.xmlns';
    CheckEquals('Token=?xml?\string', List[0]);
    CheckEquals('xmlns=?xml?\string.xmlns', List[1]);
  finally
    List.Free;
  end;
end;

procedure TestCnvStrUtilsUnit._TextToBool;
begin
  CheckEquals(True, TextToBool('1'), '1');
  CheckEquals(True, TextToBool('T'), 'T');
  CheckEquals(False, TextToBool('0'), '0');
  CheckEquals(False, TextToBool('F'), 'F');
  CheckEquals(False, TextToBool(''), '<empty string>');
  CheckEquals(False, TextToBool('Z'), 'Z');
end;

procedure TestCnvStrUtilsUnit._XmlFriendlyName;
begin
  CheckEquals('-lesser than-', XmlFriendlyName('<'));
end;

initialization
  RegisterTest(TestCnvStrUtilsUnit.Suite);

end.
