@echo off
cd /d "%~dp0"
start "" powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File "Quectel5G_EN.ps1"
