<#
.SYNOPSIS
    Reads txt file to download list of files
.DESCRIPTION
     Save list of URLs (one per line) to downloadList.txt in the same folder as this script and run it.
     This is a dumb script and will not create folders. Everything downloads to the folder in which you run the script.
.NOTES
    Author: Adam Albers
#>

$downloadList = Get-Content downloadList.txt

$webClient = New-Object System.Net.WebClient

foreach ($url in $downloadList) { 

	#Get the filename 
	$filename = [System.IO.Path]::GetFileName($url)

	#Create the output path
	$file = [System.IO.Path]::Combine($pwd.Path, $filename)

	Write-Host "Getting ""$url""... "

	#Download the file using the WebClient 
	$client.DownloadFile($url, $file)

	Write-Host 'Done.'
}

Exit 0