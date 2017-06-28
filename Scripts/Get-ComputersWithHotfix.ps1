Import-Module ActiveDirectory

$date = (Get-Date).AddDays(-30)
$Computers = Get-ADComputer -Filter {LastLogonDate -gt $date}
ForEach ($computer in $computers) {
    If (Get-HotFix -Id KB4032782 -ComputerName $computer.Name -ErrorAction SilentlyContinue) {
        $computer.Name | Out-File $Env:SystemDrive\AMP\hotfixInstalled.txt
    }
    Else {
        $computer.Name | Out-File $Env:SystemDrive\AMP\hotfixMissing.txt
    }
    
}


