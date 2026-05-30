@echo off
REM Windows batch wrapper for ntfy-notify.sh
REM This script allows running the notification hook on Windows

REM Check if bash is available (Git Bash or WSL)
where bash >nul 2>&1
if %ERRORLEVEL% equ 0 (
    REM Run the bash script
    bash "%~dp0ntfy-notify.sh" %*
) else (
    REM Fallback: Use PowerShell to send notification directly
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0ntfy-notify.ps1" %*
)
