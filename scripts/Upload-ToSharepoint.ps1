# Specify tenant admin and site URL
$username = "user@example.com"
$passwordFile = "C:\Path\To\passwordFile.txt"
$siteURL = "https://example.sharepoint.com/"
$folder = "C:\Script\HpeQuota"
#Path where you want to Copy
$documentLibraryName = "Documents"


# Docs library
# Add references to SharePoint client assemblies and authenticate to Office 365 site - required
for CSOM
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
# Bind to site collection
$context = New-Object Microsoft.SharePoint.Client.ClientContext($siteURL)
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, (Get-Content $passwordFile | ConvertTo-SecureString)
$context.Credentials = $credentials
# Retrieve list
$list = $context.Web.Lists.GetByTitle($documentLibraryName)
$context.Load($list)
$context.ExecuteQuery()
# Upload file
foreach ($file in (dir $folder -File))
{
    $fileStream = New-Object IO.FileStream($file.FullName, [System.IO.FileMode]::Open)
    $fileCreationInfo = New-Object Microsoft.SharePoint.Client.FileCreationInformation
    $fileCreationInfo.Overwrite = $true
    $fileCreationInfo.ContentStream = $fileStream
    $fileCreationInfo.URL = $file
    $upload = $list.RootFolder.Files.Add($fileCreationInfo)
    $context.Load($upload)
    $context.ExecuteQuery()
}