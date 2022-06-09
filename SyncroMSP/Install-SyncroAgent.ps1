#!ps
$installerURL = 'http://agents.example.com/customername'
$installerPath = "$Env:Temp\agent.msi"

Write-Output $installerPath

$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri "$installerURL" -OutFile "$installerPath"

try {
    Start-Process msiexec.exe -ArgumentList "/i $installerPath /qn /norestart" -NoNewWindow
}
catch {
    Write-Warning $_
    Write-Output "Trying again..."
    Start-Sleep -Seconds 10
    Start-Process msiexec.exe -ArgumentList "/i $installerPath /qn /norestart" -NoNewWindow
}

Exit 0