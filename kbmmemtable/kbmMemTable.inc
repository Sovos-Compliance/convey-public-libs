{$ifdef VER100}      // Delphi 3
  {$define LEVEL3}
  {$define DELPHI}
{$endif}

{$ifdef VER110}      // C++ Builder 3
  {$define LEVEL3}
  {$define BCB}
{$endif}

{$ifdef VER120}      // Delphi 4
  {$define LEVEL4}
  {$define DELPHI}
{$endif}

{$ifdef VER125}      // C++ Builder 4
  {$define LEVEL4}
  {$define BCB}
{$endif}

{$ifdef VER130}      // Delphi 5 or Builder 5
  {$define LEVEL4}
  {$define LEVEL5}
  {$ifndef BCB}        // Delphi 5
    {$define DELPHI}
  {$else}              // Builder 5
    {$undef DELPHI}	     // ( Ensure Delphi off )
  {$endif}
{$endif}

{$ifdef VER140}      // Delphi/BCB 6 & Kylix 1.
  {$define LEVEL4}
  {$define LEVEL5}
  {$define LEVEL6}
  {$ifndef BCB}        // Delphi 6
    {$define DELPHI}
  {$else}              // Builder 6
    {$undef DELPHI}	     // ( Ensure Delphi off )
  {$endif}
  {$ifdef LINUX}
      {$define KYLIX1}
  {$endif}
{$endif}

{$ifdef VER180}      // Delphi/BCB 6 & Kylix 1.
  {$define LEVEL4}
  {$define LEVEL5}
  {$define LEVEL6}
  {$define LEVEL7}
  {$define LEVEL8}
  {$define LEVEL9}
  {$define LEVEL10}
  {$ifndef BCB}        // Delphi 6
    {$define DELPHI}
  {$else}              // Builder 6
    {$undef DELPHI}	     // ( Ensure Delphi off )
  {$endif}
  {$ifdef LINUX}
      {$define KYLIX1}
  {$endif}
{$endif}

{$ifdef LINUX}
  {$define CLX}
{$endif}

//***********************************************************************

{$ifdef BCB}
{$ObjExportAll On}
{$ASSERTIONS ON}
{$endif}

