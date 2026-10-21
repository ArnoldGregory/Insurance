@echo off
title Insurance Portal (auto-restart)
cd /d "%~dp0InsurancePlatform.AdminPortal"
:loop
dotnet run --launch-profile http
echo.
echo [%time%] Portal stopped (exit %errorlevel%). Restarting in 3s... (close this window to stop)
timeout /t 3 /nobreak >nul
goto loop
