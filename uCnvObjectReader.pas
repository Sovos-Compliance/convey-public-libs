unit uCnvObjectReader;

interface

uses
  Classes;

type
  TState = (sWaitingObject, sWaitingClassName, sWaitingPropNameOrObject, sWaitingEqual,
            sWaitingValue, sWaitingObjectOrEnd, sWaitingPropNameOrPlus, sWaitingStringPiece);
  TCnvObjectReader = class
  private
    function InternalReadObject(AState : TState; AOwner : TComponent = nil):
        TComponent;
  protected
    FParser: TParser;
    procedure AssignBinary(const APropName: String; AObject: TObject); virtual;
    procedure AssignValue(const APropName: String; const v: variant; AObject:
        TObject); virtual;
    procedure AppendValue(const APropName: String; const v: variant; AObject:
        TObject); virtual;
  public
    function ReadObject(AStream : TStream): TComponent;
  end;

implementation

uses
  TypInfo, sysUtils;

resourcestring
  STR_InternalError = 'Internal error. Wrong finite state machine state';
  STR_ClassNotFound = 'Class not found';
  STR_OnlySymbolValueAllowedIs = 'Only symbol value allowed is NULL, TRUE or FALSE';
  STR_ParsingErrorReadOfStreamLineNumb = 'Object Parsing error: %s. Read of stream: %s. Line Number: %d';
  STR_Waiting = 'Waiting "="';
  STR_WaitingClassName = 'Waiting Class Name';
  STR_WaitingIntegerStringFloatOrBinar = 'Waiting NULL, TRUE, FALSE, integer, string, float or binary datatypes';
  STR_WaitingObject = 'Waiting "Object"';
  STR_WaitingObjectOrEnd = 'Waiting "Object" or "End"';
  STR_WaitingPropertyName = 'Waiting property name';
  STR_WaitingStringValueAfterSign = 'Waiting string value after "+" sign';
  STR_WideStringTypeNotSupported = 'WideString datatype not supported';

procedure TCnvObjectReader.AssignBinary(const APropName: String; AObject:
    TObject);
begin
end;

procedure TCnvObjectReader.AssignValue(const APropName: String; const v:
    variant; AObject: TObject);
var
  p : PPropInfo;
begin
  p := GetPropInfo (AObject, APropName);
  if p <> nil
    then case p^.PropType^.Kind of
      tkInteger  : SetOrdProp (AObject, p,  integer (v));
      tkEnumeration : SetEnumProp (AObject, p, string (v));
      tkFloat : SetFloatProp (AObject, p, extended (v));
      tkString, tkChar, tkWChar : SetStrProp (AObject, p, string(ShortString (v)));
      tkSet : SetSetProp (AObject, p, string (v));
      tkLString : SetStrProp (AObject, p, string (v));
      tkWString : SetStrProp (AObject, p, widestring (v));
    end;
end;

procedure TCnvObjectReader.AppendValue(const APropName: String; const v:
    variant; AObject: TObject);
var
  p : PPropInfo;
begin
  p := GetPropInfo (AObject, APropName);
  if p <> nil
    then case p^.PropType^.Kind of
      tkString, tkChar, tkWChar : SetStrProp (AObject, p, GetStrProp (AObject, p) + string(ShortString (v)));
      tkLString : SetStrProp (AObject, p, GetStrProp (AObject, p) + string (v));
      tkWString : SetStrProp (AObject, p, GetStrProp (AObject, p) + widestring (v));
    end;
end;

function TCnvObjectReader.InternalReadObject(AState : TState; AOwner :
    TComponent = nil): TComponent;
const
  STR_OBJECT = 'OBJECT';
  STR_END = 'END';
  STR_EQUAL = '=';
  STR_PLUS = '+';
  STR_BINARYSTART = '{';
  STR_NULL = 'NULL';
  STR_TRUE = 'TRUE';
  STR_FALSE = 'FALSE';
  FLOATTYPE_DATE = 'D';
  FLOATTYPE_CURRENCY = 'C';
  FLOATTYPE_SINGLE = 'S';

var
  APropName : string;
  p : PPropInfo;

  procedure Error(const s : string);
  begin
    raise Exception.CreateFmt (STR_ParsingErrorReadOfStreamLineNumb, [s, FParser.TokenString, FParser.SourceLine]);
  end;

  procedure CreateObject;
  var
    ACompClass : TComponentClass;
  begin
    ACompClass := TComponentClass (GetClass (FParser.TokenComponentIdent));
    if ACompClass <> nil
      then
      begin
        AState := sWaitingPropNameOrObject;
        Result := ACompClass.Create (AOwner);
      end
      else Error (STR_ClassNotFound);
  end;

  procedure AssignDate;
  var
    ADateTime : TDateTime;
  begin
    ADateTime := FParser.TokenFloat;
    if p <> nil
      then SetFloatProp (Result, p, ADateTime)
      else AssignValue (APropName, ADateTime, Result);
  end;

  procedure AssignSingle;
  var
    ASingle : single;
  begin
    ASingle := FParser.TokenFloat;
    if p <> nil
      then SetFloatProp (Result, p, ASingle)
      else AssignValue (APropName, ASingle, Result);
  end;

  procedure AssignCurrency;
  var
    ACurrency : currency;
  begin
    ACurrency := FParser.TokenFloat / 10000;
    if p <> nil
      then SetFloatProp (Result, p, ACurrency)
      else AssignValue (APropName, ACurrency, Result);
  end;

begin
  Result := nil;
  p := nil;
  APropName := '';
  repeat
    if FParser.Token <> toEOF
      then
      begin
        case AState of
          sWaitingObject : if (FParser.Token = toSymbol) and FParser.TokenSymbolIs (STR_OBJECT)
            then AState := sWaitingClassName
            else Error (STR_WaitingObject);
          sWaitingClassName : if FParser.Token = toSymbol
            then CreateObject
            else Error (STR_WaitingClassName);
          sWaitingPropNameOrObject : if FParser.Token = toSymbol
            then if FParser.TokenSymbolIs (STR_OBJECT)
              then
              begin
                FParser.NextToken;
                InternalReadObject (sWaitingClassName, Result);
                AState := sWaitingObjectOrEnd;
              end
              else if FParser.TokenSymbolIs (STR_END)
                then break
                else
                begin
                  APropName := FParser.TokenString;
                  p := GetPropInfo (Result, APropName);
                  AState := sWaitingEqual;
                end
            else Error (STR_WaitingPropertyName);
          sWaitingObjectOrEnd : if FParser.Token = toSymbol
            then if FParser.TokenSymbolIs (STR_OBJECT)
              then
              begin
                FParser.NextToken;
                InternalReadObject (sWaitingClassName, Result);
              end
              else if FParser.TokenSymbolIs (STR_END)
                then break
                else Error (STR_WaitingObjectOrEnd)
            else Error (STR_WaitingObjectOrEnd);
          sWaitingEqual : if FParser.Token = STR_EQUAL
            then AState := sWaitingValue
            else Error (STR_Waiting);
          sWaitingValue :
            begin
              AState := sWaitingPropNameOrObject;
              case FParser.Token of
                toSymbol : if FParser.TokenSymbolIs (STR_NULL)
                  then { nothing to do, data already clean by default }
                  else if FParser.TokenSymbolIS (STR_TRUE)
                    then if p <> nil
                      then SetOrdProp (Result, p, integer (true))
                      else AssignValue (APropName, true, Result)
                    else if FParser.TokenSymbolIS (STR_FALSE)
                      then if p <> nil
                        then SetOrdProp (Result, p, integer (false))
                        else AssignValue (APropName, false, Result)
                      else Error (STR_OnlySymbolValueAllowedIs);
                Classes.toString :
                  begin
                    if p <> nil
                      then SetStrProp (Result, p, FParser.TokenString)
                      else AssignValue (APropName, FParser.TokenString, Result);
                    AState := sWaitingPropNameOrPlus;
                  end;
                toInteger : if p <> nil
                  then SetOrdProp (Result, p, integer (FParser.TokenInt))
                  else AssignValue (APropName, integer (FParser.TokenInt), Result);
                toFloat   :
                  case UpCase (FParser.FloatType) of
                    FLOATTYPE_DATE : AssignDate;
                    FLOATTYPE_SINGLE : AssignSingle;
                    FLOATTYPE_CURRENCY : AssignCurrency;
                    else if p <> nil
                      then SetFloatProp (Result, p, FParser.TokenFloat)
                      else AssignValue (APropName, FParser.TokenFloat, Result);
                  end;
                toWString : Error (STR_WideStringTypeNotSupported);
                STR_BINARYSTART :
                  begin
                    AState := sWaitingPropNameOrObject;
                    AssignBinary (APropName, Result);
                  end;
                else Error (STR_WaitingIntegerStringFloatOrBinar);
              end;
            end;
          sWaitingPropNameOrPlus : if FParser.Token = STR_PLUS
            then AState := sWaitingStringPiece
            else
            begin
              AState := sWaitingPropNameOrObject;
              continue;
            end;
          sWaitingStringPiece : if FParser.Token = toString
            then
            begin
              if p <> nil
                then SetStrProp (Result, p, GetStrProp (Result, p) + FParser.TokenString)
                else AppendValue (APropName, FParser.TokenString, Result);
              AState := sWaitingPropNameOrPlus;
            end
            else Error (STR_WaitingStringValueAfterSign);
          else Error (STR_InternalError);
        end;
        FParser.NextToken;
      end;
  until FParser.Token = toEOF;
end;

function TCnvObjectReader.ReadObject(AStream : TStream): TComponent;
begin
  FParser := TParser.Create (AStream);
  try
    Result := InternalReadObject (sWaitingObject);
  finally
    FParser.Free;
  end;
end;

end.
