@echo off
REM Starts the API first, then the Admin Portal, each in its own window.
cd /d "%~dp0"
start "InsurancePlatform.Api" cmd /k "cd InsurancePlatform.Api && dotnet run --launch-profile http"
timeout /t 15 /nobreak >nul
start "InsurancePlatform.AdminPortal" cmd /k "cd InsurancePlatform.AdminPortal && dotnet run --launch-profile http"
