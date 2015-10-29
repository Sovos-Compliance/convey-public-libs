{$IFDEF VER120} { Delphi 4.0 }
  {$DEFINE LEVEL4 }
  {$DEFINE DELPHI }
{$ENDIF}
{$IFDEF VER125} { C++Builder 4.0 }
  {$DEFINE LEVEL4 }
  {$DEFINE CBUILDER }
{$ENDIF}
{$IFDEF VER130} { Delphi 5.0/C++Builder 5.0 }
  {$DEFINE LEVEL4 }
  {$DEFINE LEVEL5 }
{$ENDIF}

{$IFDEF BCB}
  {$DEFINE CBUILDER }
{$ELSE}
  {$DEFINE DELPHI }
{$ENDIF}

{$IFDEF ConditionalExpressions}
  { Delphi 5 and previous that didn't support conditional IF defines }  
  {$DEFINE LEVEL4 }
  {$DEFINE LEVEL5 }

  {$IF CompilerVersion >= 14.0} { Delphi 6.0 }
    {$DEFINE LEVEL6}
  {$IFEND}

  {$IF CompilerVersion >= 15.0} { Delphi 7.0 }
    {$DEFINE LEVEL7}
  {$IFEND}

  {$IF CompilerVersion >= 18.0} { Delphi 2006/2007 }
    {$DEFINE LEVEL10}
  {$IFEND}

  {$IF CompilerVersion >= 25.0} { Delphi XE4 }
    {$DEFINE LEVEL17}
  {$IFEND}

{$ENDIF !ConditionalExpressions}