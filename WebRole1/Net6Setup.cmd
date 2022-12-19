@echo off

if "%EMULATED%"=="true" (
    echo Azure environment is emulated - .NET 6 will not be installed
    EXIT 0
)

echo Running Net6Setup.ps1...
powershell -command "Set-ExecutionPolicy Unrestricted"
powershell -File .\Net6Setup.ps1