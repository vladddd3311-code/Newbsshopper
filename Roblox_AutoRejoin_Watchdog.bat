@echo off
title Roblox Auto-Rejoin Watchdog
cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0watchdog.ps1"
pause
