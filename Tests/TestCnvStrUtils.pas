unit TestCnvStrUtils;

interface

uses
  TestFramework, CnvStrUtils, Classes;

type
  {$M+}
  TestCnvStrUtilsUnit = class(TTestCase)

  end;

implementation

initialization
  RegisterTest(TestCnvStrUtilsUnit.Suite);

end.
