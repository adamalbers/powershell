# Author: Adam Albers
# Export interactive and remote logons and logoffs to CSV

# Variables
# File for output
$outputFile = "$env:systemdrive\AMP\Reports\LogonHistory-$(Get-Date -Format yyyy-MM-dd).csv"

# Sets to local hostname
$hostname = $env:computername

# ArrayList for our events
$events = New-Object System.Collections.ArrayList
 
# Store each event from the Security Log with the specificed dates and computer in an array 
$log = Get-Eventlog -LogName Security -ComputerName $hostname 
 
# Loop through each security event, print all login/logoffs with type, date/time, status, account name, and IP address 
foreach ($i in $log) { 
    # Logon Successful Events 
    # Local (Logon Type 2) 
    if (($i.EventID -eq 4624 ) -and ($i.ReplacementStrings[8] -eq 2)) { 
        $event = New-Object –TypeName PSObject
        $event | Add-Member –MemberType NoteProperty –Name Type -Value 'Local'
        $event | Add-Member –MemberType NoteProperty –Name Date -Value $i.TimeGenerated
        $event | Add-Member –MemberType NoteProperty –Name Success -Value 'Success'
        $event | Add-Member –MemberType NoteProperty –Name User -Value $i.ReplacementStrings[5]
        $event | Add-Member –MemberType NoteProperty –Name IP -Value ''
 
        $events.Add($event) | Out-Null 
    } 
    # Remote (Logon Type 10) 
    if (($i.EventID -eq 4624 ) -and ($i.ReplacementStrings[8] -eq 10)) { 
        $event = New-Object –TypeName PSObject
        $event | Add-Member –MemberType NoteProperty –Name Type -Value 'Remote'
        $event | Add-Member –MemberType NoteProperty –Name Date -Value $i.TimeGenerated
        $event | Add-Member –MemberType NoteProperty –Name Success -Value 'Success'
        $event | Add-Member –MemberType NoteProperty –Name User -Value $i.ReplacementStrings[5]
        $event | Add-Member –MemberType NoteProperty –Name IP -Value $i.ReplacementStrings[18]
            
        $events.Add($event) | Out-Null      
    } 
         
    # Logon Failure Events 
    # Local 
    if (($i.EventID -eq 4625 ) -and ($i.ReplacementStrings[10] -eq 2)) { 
        $event = New-Object –TypeName PSObject
        $event | Add-Member –MemberType NoteProperty –Name Type -Value 'Local'
        $event | Add-Member –MemberType NoteProperty –Name Date -Value $i.TimeGenerated
        $event | Add-Member –MemberType NoteProperty –Name Success -Value 'Failure'
        $event | Add-Member –MemberType NoteProperty –Name User -Value $i.ReplacementStrings[5]
        $event | Add-Member –MemberType NoteProperty –Name IP -Value ''
            
        $events.Add($event) | Out-Null
    } 
    # Remote 
    if (($i.EventID -eq 4625 ) -and ($i.ReplacementStrings[10] -eq 10)) { 
        $event = New-Object –TypeName PSObject
        $event | Add-Member –MemberType NoteProperty –Name Type -Value 'Remote'
        $event | Add-Member –MemberType NoteProperty –Name Date -Value $i.TimeGenerated
        $event | Add-Member –MemberType NoteProperty –Name Success -Value 'Failure'
        $event | Add-Member –MemberType NoteProperty –Name User -Value $i.ReplacementStrings[5]
        $event | Add-Member –MemberType NoteProperty –Name IP -Value $i.ReplacementStrings[19]
            
        $events.Add($event) | Out-Null
    } 
         
    # Logoff Events 
    if ($i.EventID -eq 4647 ) { 
        $event = New-Object –TypeName PSObject
        $event | Add-Member –MemberType NoteProperty –Name Type -Value 'Logoff'
        $event | Add-Member –MemberType NoteProperty –Name Date -Value $i.TimeGenerated
        $event | Add-Member –MemberType NoteProperty –Name Success -Value 'Success'
        $event | Add-Member –MemberType NoteProperty –Name User -Value $i.ReplacementStrings[1]
        $event | Add-Member –MemberType NoteProperty –Name IP -Value ''
            
        $events.Add($event) | Out-Null
    }
}

$events | Export-Csv $outputFile

Exit 0