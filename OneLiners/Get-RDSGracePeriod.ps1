(Get-WmiObject -Namespace "root/CIMV2/TerminalServices" -Class Win32_TerminalServiceSetting).GetGracePeriodDays() | Select DaysLeft
