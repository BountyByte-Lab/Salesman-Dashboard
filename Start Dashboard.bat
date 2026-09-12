@echo off
cd /d "%~dp0"

netstat -ano | findstr ":8743" | findstr "LISTENING" >nul
if errorlevel 1 (
  start "Salesman Dashboard Server" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
)

set tries=0
:waitloop
netstat -ano | findstr ":8743" | findstr "LISTENING" >nul
if not errorlevel 1 goto ready
set /a tries+=1
if %tries% GEQ 20 goto giveup
timeout /t 1 /nobreak >nul
goto waitloop

:ready
start "" "http://127.0.0.1:8743/salesman_dashboard.html"
goto :eof

:giveup
echo.
echo Could not confirm the local server started after 20 seconds.
echo Check the "Salesman Dashboard Server" PowerShell window that opened
echo behind this one for an error message, then close this window.
echo.
pause
