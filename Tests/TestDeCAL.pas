unit TestDeCAL;

interface

uses
  TestFramework, DeCAL;

type
  {$M+}
  TestDeCALUnit = class(TTestCase)
  published
    procedure Test;
  end;

implementation

{ TestLogObject }

procedure TestDeCALUnit.Test;
var
  Sequence: ISequence;
begin
  Sequence := Factory.CreateContainer(STR_LIST) as ISequence;
  CheckNotNull(Sequence);
end;

initialization
  RegisterTest(TestDeCALUnit.Suite);

end.
