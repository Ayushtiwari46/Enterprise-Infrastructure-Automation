@echo off
title [ENTERPRISE LAB] Starting Multi-Node Lab & Healing Services...
color 0b
echo ===============================================================================
echo   BOOTING ENTERPRISE LAB: Ansible, OLVM Engine, KVM Node 1, KVM Node 2
echo ===============================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Lab.ps1" -Mode Start

echo.
echo ===============================================================================
echo   Lab startup and health checks completed.
echo   Press any key to close this terminal...
echo ===============================================================================
pause >nul
