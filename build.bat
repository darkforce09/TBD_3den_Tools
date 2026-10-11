@echo off
setlocal
pushd "%~dp0"
if not "%errorlevel%"=="0" exit /b %errorlevel%

cargo build --release --locked
if not "%errorlevel%"=="0" goto :failed

copy /y "target\release\TBD_DB_x64.dll" "TBD_DB_x64.dll" >nul
if not "%errorlevel%"=="0" goto :failed

hemtt build
if not "%errorlevel%"=="0" goto :failed

echo Complete mod: %~dp0.hemttout\build
popd
exit /b 0

:failed
set "build_exit=%errorlevel%"
echo Build failed with exit code %build_exit%. 1>&2
popd
exit /b %build_exit%
