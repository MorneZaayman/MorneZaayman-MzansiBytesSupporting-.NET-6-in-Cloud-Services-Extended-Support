# This script must be run with Admistrator privileges in order for .NET 6 to be able to be installed properly

$nl = "`r`n"

# Load the Cloud Service assembly
[Reflection.Assembly]::LoadWithPartialName("Microsoft.WindowsAzure.ServiceRuntime") | Out-Null

# Using the Net6Setup path that has a higher limit than the 100 MB default.
$tempPath = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetLocalResource("Net6Setup").RootPath.TrimEnd('\\')
[Environment]::SetEnvironmentVariable("TEMP", $tempPath, "Machine")
[Environment]::SetEnvironmentVariable("TEMP", $tempPath, "User")

Write-Output "============ .NET 6 Windows Hosting Installation ============$nl" 
Function TestIf-DotNet6Exists
{
    $ErrorActionPreference = 'stop'

    try {
        if (Get-Command dotnet)
        {
            $dotnetRuntimes = dotnet --list-runtimes
            $net6AppInstalled = if ($dotnetRuntimes -Like "*Microsoft.NETCore.App 6*") { $true } else { $false }
            $aspnet6Installed = if ($dotnetRuntimes -Like "*Microsoft.AspNetCore.App 6*") { $true } else { $false }

            if ($net6AppInstalled -And $aspnet6Installed)
            {
                return $true
            }
            else
            {
                return $false
            }
        }
    }
    Catch 
    {
        return $false
    }
}

if (TestIf-DotNet6Exists) 
{
    Write-Output ".NET 6 is already installed. $nl"
}  
else
{
    Write-Output ".NET 6 not installed.$nl"

    $tempPath = [Microsoft.WindowsAzure.ServiceRuntime.RoleEnvironment]::GetLocalResource("AppTemp").RootPath.TrimEnd('\\')

    Write-Output "Downloading the Microsoft Visual C++ 2017 Redistributable.$nl"
	$tempFile = New-Item ($tempPath + "\vcredist.exe")
    Invoke-WebRequest -Uri https://aka.ms/vs/16/release/vc_redist.x64.exe -OutFile $tempFile -Verbose:$false

    Write-Output "Installing the Microsoft Visual C++ 2017 Redistributable.$nl"
    $proc = (Start-Process $tempFile -PassThru "/quiet /install /log C:\Logs\vcredist.x64.log")
    $proc | Wait-Process
    Write-Output "Deleting the Microsoft Visual C++ 2017 Redistributable installer file.$nl"
    Remove-Item -Path ($tempPath + "\vcredist.exe") -Force
	
    Write-Output "Downloading the .NET 6 Hosting Bundle.$nl"
	$tempFile = New-Item ($tempPath + "\netcore-bundle.exe")
    Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/b69fc347-c3c8-49bc-b452-dc89a1efdf7b/ebac64c8271dab3b9b1e87c72ef47374/dotnet-hosting-6.0.1-win.exe -OutFile $tempFile -Verbose:$false
    
    Write-Output "Installing the .NET 6 Hosting Bundle.$nl"
	$proc = (Start-Process $tempFile -PassThru "/quiet /install /log C:\Logs\dotnet_install.log")
	$proc | Wait-Process
    Write-Output "Deleting the .NET 6 Hosting Bundle installer file.$nl"
    Remove-Item -Path ($tempPath + "\netcore-bundle.exe") -Force
}

Write-Output "Stop w3svc and IIS"
net stop w3svc
iisreset /stop

Write-Output "Remove ASP.NET Framework application"
Get-ChildItem -Path "E:\sitesroot\0\" -Exclude @('Net6Setup.ps1','WebApplication1*') |
Remove-Item -Recurse -Force

Write-Output "Move ASP.NET Core application"
Get-ChildItem "E:\sitesroot\0\WebApplication1\" | Move-Item -Destination "E:\sitesroot\0\"
Remove-Item "E:\sitesroot\0\WebApplication1\"

Write-Output "Start w3svc and IIS"
net start w3svc
iisreset /start