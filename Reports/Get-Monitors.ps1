#Originally created by Dale Hudson on SyncroMSP Facebook group.
#Import-Module $env:SyncroModule

$connections = Get-CimInstance -Namespace 'root/wmi' -Classname 'WmiMonitorConnectionParams'
$arrayForSyncroField = @()

foreach ($output in $connections) {
    $monitor = $output.InstanceName
    $monitor = $monitor.Split('\')
    switch ($output.VideoOutputTechnology) {
        -2 { $type = 'UNINITIALIZED' }
        -1 { $type = 'OTHER' }
        0 { $type = 'VGA_HD15' }
        1 { $type = 'SVIDEO' }
        2 { $type = 'SCOMPOSITE_VIDEO' }
        3 { $type = 'COMPONENT_VIDEO' }
        4 { $type = 'DVI' }
        5 { $type = 'HDMI' }
        6 { $type = 'LVDS' }
        7 { $type = 'UNKNOWN' }
        8 { $type = 'D_JPN' }
        9 { $type = 'SDI' }
        10 { $type = 'DP_EXTERNAL' }
        11 { $type = 'DP_EMBEDDED' }
        12 { $type = 'UDI_EXTERNAL' }
        13 { $type = 'UDI_EMBEDDED' }
        14 { $type = 'SDTVDONGLE' }
        15 { $type = 'MIRACAST' }
        16 { $type = 'INDIRECT_WIRED' }

        Default { $type = 'UNKNOWN' }
    }
    $line = $monitor[1] + ' | ' + $type
    $arrayForSyncroField = $arrayForSyncroField + $line + "`n"
    
}

$output = "MonitorID `| ConnectionType`n" + $arrayForSyncroField + "`nType 'unknown' is likely a laptop or all-in-one display."

Write-Output $output

Exit 0