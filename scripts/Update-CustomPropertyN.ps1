$controlURL = "https://control.example.com/App_Extensions/8e78224d-79db-4dbb-b62a-833276b46c6e/Service.ashx/UpdateCustomProperty"
$accessKey = ""

function updateCustomProperty ([string]$customPropertyN, [string]$propertyValue) {
    
    [string]$body = "[`"$accessKey`",`"$controlGUID`",$customPropertyN,`"$propertyValue`"]"
        
	Invoke-RestMethod -Method Post -Uri "$controlURL" -Body "$body" -ContentType 'application/json';
}

# Determine if server or workstation OS and change device type value
	$operatingSystem = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
	if ($operatingSystem -match "Server") {
			$deviceType = "Server"
		} else {
			$deviceType = "Workstation"
		}

updateCustomProperty "4" $deviceType

Exit 0