@echo off
title Insurance API (auto-restart)
cd /d "%~dp0InsurancePlatform.Api"
:loop
dotnet run --launch-profile http
echo.
echo [%time%] API stopped (exit %errorlevel%). Restarting in 3s... (close this window to stop)
timeout /t 3 /nobreak >nul
goto loop
