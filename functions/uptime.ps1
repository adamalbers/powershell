function uptime {
    Get-WmiObject Win32_OperatingSystem | Select-Object @{LABEL = 'Computer'; EXPRESSION = { $_.CSName } }, @{LABEL = 'LastBootUpTime'; EXPRESSION = { $_.ConverttoDateTime($_.LastBootUpTime) } }
}