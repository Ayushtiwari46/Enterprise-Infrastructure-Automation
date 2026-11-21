@echo off
title [ENTERPRISE LAB] Checking Multi-Node Lab Status...
color 0a

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Lab.ps1" -Mode Status

echo.
pause
