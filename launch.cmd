@echo off
rem dsh-portable - portable DeepSeek Harness (Windows launcher)
rem ASCII only: cmd.exe reads this file with the OEM codepage.
chcp 65001 >nul 2>nul
setlocal
set "ROOT=%~dp0"
set "DSH_HOME=%ROOT%dsh-home"
rem Signal for the patched dsh code that we run portable (exFAT/FAT: no chmod, no symlinks)
set "DSH_PORTABLE=true"
set "BIN=%ROOT%dsh\lib\bin.js"

if not exist "%BIN%" (
  echo dsh: bin.js not found: "%BIN%"
  echo Build the bundle first: bash make-portable.sh
  pause
  exit /b 1
)

if not exist "%ROOT%dsh\node_modules" (
  echo dsh: "%ROOT%dsh\node_modules" is missing - dependencies are not installed.
  echo Build the bundle first: bash make-portable.sh
  pause
  exit /b 1
)

node --version >nul 2>nul
if errorlevel 1 (
  echo dsh: node not found in PATH. Install Node.js ^>= 18.
  pause
  exit /b 1
)

node "%BIN%" %*
set "RC=%ERRORLEVEL%"
endlocal & exit /b %RC%
