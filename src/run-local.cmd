@echo off
REM One-command local launcher (tunnel + callback + auto-restarting API/Portal).
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-local.ps1"
pause
