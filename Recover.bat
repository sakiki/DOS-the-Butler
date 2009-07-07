@echo off

set DFile=DOS.d

set BaseDir=%cd%
set BinPath=%BaseDir%\dmd\bin

cd "%BinPath%"

move %DFile% "%BaseDir%"