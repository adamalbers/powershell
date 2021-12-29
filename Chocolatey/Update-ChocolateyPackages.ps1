# Upgrade all installed packages
Start-Process -Path "C:\ProgramData\chocolatey\choco.exe" -ArgumentList "upgrade all -y" -Wait

# Remove desktop shortcuts
Remove-Item -Path "C:\Users\Public\Desktop\*.lnk" -Force -Confirm:$false