Param (
    $SourcePath,
    $DestinationDirectory
)

function Convert-SyncroAssetsToXlsx {
    Param (
        $assetsFile,
        $destDir
    )
    
    if (-not $assetsFile) {
        Write-Host -ForegroundColor Yellow "`nMissing source JSON file path e.g., ~/Downloads/assets.json"
        $assetsFile = Read-Host 'Enter full path to assets JSON file'
    }
    
    if (-not $destDir) {
        Write-Host -ForegroundColor Yellow "`nMissing destination directory path e.g., ~/Downloads"
        $destDir = Read-Host 'Enter path to destination directory'
    }

    $filename = (Get-Item -Path $assetsFile).BaseName
    $outputPath = "${destDir}/${filename}.xlsx"

    try {
        $assets = Get-Content -Path $assetsFile | ConvertFrom-Json -Depth 100
    }
    catch {
        $message = $_
        Write-Host -ForegroundColor Red "`nFailed to import $assetsFile."
        Write-Host -ForegroundColor Red 'Please make sure it is a valid JSON file.'
        Write-Warning $message.Exception.Message
    }

    if (-not $($assets[0].id)) {
        Write-Host -ForegroundColor Red "`n${assetsFile} does not seem to contain any data."
        Write-Host -ForegroundColor Red "Please verify the file is a valid JSON file and try again.`n"
        Exit 1
    }
    
    $assets = $assets | Sort-Object -Property { $_.customer.business_name }

    # Create an array of custom objects that contain only the essential asset info we want
    # We will export these to CSV
    $objects = $assets | Select-Object `
        -Property @{Name = 'customer'; Expression = { $_.customer.business_name } },
    customer_id,
    @{Name = 'asset_id'; Expression = { $_.id } },
    asset_serial,
    asset_type,
    name


    # Ignore errors so that assets without data in a certain field don't spam the console with errors.
    $ErrorActionPreference = 'SilentlyContinue'

    # Loop through and add desired data from $assets to our custom $objects.
    # This is so we can export to XLSX (if available) or CSV for a more readable list of assets than the raw JSON file.
    $objects | ForEach-Object {
        
        # Get the index of the current object in $objects
        $objectIndex = $objects.IndexOf($_)
        $object = $objects[$objectIndex]
    
        # Find the $asset that matches $object in $assets by matching the unique id
        $asset = $assets | Where-Object { $_.id -eq $($object.asset_id) }

        # Syncro
        $object | Add-Member -MemberType NoteProperty -Name last_synced_at -Value $asset.properties.kabuto_information.last_synced_at
        $object | Add-Member -MemberType NoteProperty -Name last_user -Value $asset.properties.kabuto_information.last_user

        # Domain
        $object | Add-Member -MemberType NoteProperty -Name domain -Value $asset.properties.kabuto_information.general.domain

        # OS
        $object | Add-Member -MemberType NoteProperty -Name os_name -Value $asset.properties.kabuto_information.os.name
        $object | Add-Member -MemberType NoteProperty -Name os_version -Value $asset.properties.kabuto_information.os.windows_release_version
        $object | Add-Member -MemberType NoteProperty -Name os_build -Value $asset.properties.kabuto_information.os.build
        $object | Add-Member -MemberType NoteProperty -Name os_install -Value $asset.properties.kabuto_information.install_dates.os_install
        $object | Add-Member -MemberType NoteProperty -Name last_boot_time -Value $asset.properties.kabuto_information.os.last_boot_time

        # WAN IP
        $object | Add-Member -MemberType NoteProperty -Name wan_ip -Value $asset.properties.kabuto_information.general.ip

        # Loop through NICs to get data for each interface
        $nics = $asset.properties.kabuto_information.network_adapters
        $nics | ForEach-Object {
            $nicIndex = $nics.IndexOf($_)
            $nic = $nics[$nicIndex]

            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_name" -Value $nic.name
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_description" -Value $nic.description
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_type" -Value $nic.type
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_mac_address" -Value $nic.physical_address
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_ipv4" -Value $nic.ipv4
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_subnet" -Value $nic.subnet
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_gateway" -Value $nic.gateway
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_dns1" -Value $nic.dns1
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_dns2" -Value $nic.dns2
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_dhcp_server" -Value $nic.dhcp_server
            $object | Add-Member -MemberType NoteProperty -Name "nic${nicIndex}_ipv6" -Value $nic.ipv6
        }

        # System Partition
        $object | Add-Member -MemberType NoteProperty -Name os_disk_size_gb -Value $asset.properties.kabuto_information.system_partition.size_gb
        $object | Add-Member -MemberType NoteProperty -Name os_disk_free_gb -Value $asset.properties.kabuto_information.system_partition.free_gb
        $object | Add-Member -MemberType NoteProperty -Name os_disk_free_percent -Value $asset.properties.kabuto_information.system_partition.free_percent

        # Manufacturer
        $object | Add-Member -MemberType NoteProperty -Name manufacturer -Value $asset.properties.kabuto_information.general.manufacturer
        $object | Add-Member -MemberType NoteProperty -Name model -Value $asset.properties.kabuto_information.general.model
        $object | Add-Member -MemberType NoteProperty -Name serial_number -Value $asset.properties.kabuto_information.general.serial_number
        $object | Add-Member -MemberType NoteProperty -Name form_factor -Value $asset.properties.kabuto_information.general.form_factor

        # BIOS
        $object | Add-Member -MemberType NoteProperty -Name bios_release -Value $asset.properties.kabuto_information.install_dates.bios_release

        # For asset types that we manually entered data and do not have a Syncro agent.
        if ($($asset.asset_type) -ne 'Syncro Device') {
            $object | Add-Member -MemberType NoteProperty -Name device_make -Value $asset.properties.Make
            $object | Add-Member -MemberType NoteProperty -Name device_model -Value $asset.properties.Model
            $object | Add-Member -MemberType NoteProperty -Name device_lan_info -Value $asset.properties.'LAN IP(s)'
            $object | Add-Member -MemberType NoteProperty -Name device_drac_ip -Value $asset.properties.'DRAC IP'
            $object | Add-Member -MemberType NoteProperty -Name device_wan_info -Value $asset.properties.'WAN Info'
        }
    
    }

    # Turn errors back on in case something unexpected happens.
    $ErrorActionPreference = 'Continue'

    try {
        Write-Host "`nExporting data from $assetsFile to $outputPath ...`n"
        
        # Export to Excel
        Import-Module ImportExcel
        $objects | Export-Excel -Path $outputPath -WorksheetName 'Assets' -TableName 'AssetsTable'
        Write-Host -ForegroundColor Green "Export saved to: $outputPath"
    }
    catch {
        Write-Host ''
        Write-Warning 'Failed to create Excel spreadsheet.'
        Write-Warning $_
        Write-Warning 'Exporting to CSV instead...'
        # Export the custom $objects to CSV
        $outputPath = $outputPath.Replace('.xlsx', '.csv')
        $objects | Export-Csv -Path $outputPath -NoTypeInformation
        Write-Host -ForegroundColor Green "Export saved to: $outputPath"
    }

    Write-Host ''

}

Convert-SyncroAssetsToXlsx $SourcePath $DestinationDirectory

Exit 0