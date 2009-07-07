@echo off

set DFile=DOSInterpreter.d
set EXEName=DOSInterpreter.exe

echo Starting...

set BaseDir=%cd%
set BinPath=%BaseDir%\dmd\bin

move %DFile% "%BinPath%"

echo Moving to ./dmd/bin

cd "%BinPath%"

echo Building %DFile%

dmd %DFile% -O

echo Moving %DFile% and %EXEName% back

move %EXEName% "%BaseDir%"
move %DFile% "%BaseDir%"

echo Done...

pause


