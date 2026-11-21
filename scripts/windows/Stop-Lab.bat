@echo off
title [ENTERPRISE LAB] Stopping Multi-Node Lab (Freeing RAM & CPU for Gaming)...
color 0e
echo ===============================================================================
echo   CLEANLY SHUTTING DOWN ENTERPRISE LAB TO FREE RESOURCES FOR GAMING
echo ===============================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Lab.ps1" -Mode Stop

echo.
echo ===============================================================================
echo   All VMs are powered off. 100%% CPU & RAM freed. Enjoy your gaming!
echo   Press any key to close this window...
echo ===============================================================================
pause >nul
