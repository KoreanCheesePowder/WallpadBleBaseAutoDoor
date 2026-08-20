@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0CLEANUP-DUPLICATE.ps1"
echo.
pause
