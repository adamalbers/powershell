Start-Transcript $env:SystemDrive\AMP\Logs\RestartWiFi_$(Get-Date -Format "yyyy-MM-dd-HH-mm").txt

$pingTest = ping www.google.com | Select-String "Reply from"

If ( $pingTest.count -eq 0 )
{
    Disable-NetAdapter "Wi-Fi" -Confirm:$false
    Start-Sleep 5
    Enable-NetAdapter "Wi-Fi" -Confirm:$false
}

Stop-Transcript