$ipAddress = '1.1.1.1'

$response = Invoke-RestMethod -ContentType 'application/json' -Uri "http://ip-api.com/json/$ipAddress"

Write-Output $response