@ECHO OFF
call "C:\Program Files\Borland\BDS\5.0\bin\rsvars.bat"

msbuild ..\..\convey-public-libs-proj\tmpstrpack_d11.dproj /p:Configuration=%1
IF ERRORLEVEL 1 EXIT /B

msbuild ..\..\convey-public-libs-proj\kbmmemtable\kbmmemtable_d11.dproj /p:Configuration=%1
IF ERRORLEVEL 1 EXIT /B

msbuild ..\..\convey-public-libs-proj\Mk_RegEx\Mk_RegEX_d11.dproj /p:Configuration=%1
IF ERRORLEVEL 1 EXIT /B