@echo off
setlocal
set "ROOT=%~dp0"
set "DSH_HOME=%ROOT%dsh-home"
set "BIN=%ROOT%dsh\lib\bin.js"
if not exist "%BIN%" (
  echo dsh: bin.js not found at %BIN%
  pause
  exit /b 1
)
node "%BIN%" %*
endlocal
