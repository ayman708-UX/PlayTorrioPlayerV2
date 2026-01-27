@echo off
REM Build script for Windows only
REM Run this on Windows to build the Windows version

echo Building PlayTorrio for Windows...
echo.

flutter clean
flutter build windows --release

if %ERRORLEVEL% EQU 0 (
  echo.
  echo ✓ Windows build complete!
  echo.
  echo Bundle location: build\windows\x64\runner\Release\
  echo.
  echo Copy the entire Release folder to bundle with your Electron app.
) else (
  echo.
  echo ✗ Windows build failed
  exit /b 1
)
