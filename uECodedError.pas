unit uECodedError;

interface

uses
  SysUtils;

type
  ECodedErrorClass = class of ECodedError;
  ECodedError = class(Exception)
  private
    FErrorCode: Integer;
    FErrorMessage: string;
  protected
    class function ErrorCodePrefix: String; virtual; abstract;
  public
    constructor Create(AErrorCode : integer; const AMessage : string); overload; virtual;
    constructor Create(E: ECodedError); overload;
    property ErrorCode: Integer read FErrorCode;
    property ErrorMessage: string read FErrorMessage;
  end;

implementation

constructor ECodedError.Create(AErrorCode : integer; const AMessage : string);
begin
  inherited Create (Format ('(%s-%.4d) %s', [ErrorCodePrefix, AErrorCode, AMessage]));
  FErrorCode := AErrorCode;
  FErrorMessage := AMessage;
end;

constructor ECodedError.Create(E: ECodedError);
begin
  Create (E.ErrorCode, E.ErrorMessage);
end;

end.
