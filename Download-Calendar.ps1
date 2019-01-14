<#
        .SYNOPSIS
            Downloads monthly calendar sheets from WinCalendar.net and merges them into one workbook for the year.

        .NOTES
            Created By Adam Albers
            Created on 14-JAN-2019
            Version 1

        .PARAMETER Year
            The year in yyyy format. Defaults to current year.
#>

param([string]$year = (Get-Date -Format yyyy)

### Download monthly calendar spreadsheets ###

$months = @("January","February","March","April","May","June","July","August","September","October","November","December")
$server = "http://calendar.wincalendar.net/Printable-Calendar/"
$client = New-Object System.Net.WebClient
$path = Get-Location | Select-Object -ExpandProperty Path

New-Item -Type Directory -Path "$path\\$year" -Force

foreach ($month in $months)
	{
		$thisMonth = [string]$month
		$uri = "$($server)$($thisMonth)-$($year)-Calendar-with-Holidays.xlsx"
		$index = "{0:00}" -f $([array]::indexOf($months,$month))
		$filename = "$path\$year\$index-$month-$year-Calendar.xlsx"
		Write-Host "$filename"
		$client.DownloadFile($uri,$filename)
	}

# Path for a spreadsheet with the legend to be copied into each worksheet
$legendPath = "$path\legend.xlsx"

### Merge the individual spreadsheets into one workbook ###

$excelObject=New-Object -ComObject excel.application
$excelObject.visible=$false

$excelFiles=Get-ChildItem -Path "$path\\$year\\*.xlsx"

$workbook=$ExcelObject.Workbooks.add()
$worksheet=$Workbook.Sheets.Item("Sheet1")

$legendWorkbook=$ExcelObject.Workbooks.Open($legendPath)
$legendWorksheet=$LegendWorkbook.Sheets.Item("Legend")
$legendRange=$LegendWorksheet.Range("A1","I10")

$searchText = "*Calendar*"

foreach($ExcelFile in $ExcelFiles){
 
$everyExcel=$excelObject.Workbooks.Open($excelFile.FullName)
$everySheet=$everyExcel.sheets.item(1)
$range=$everySheet.Range("O1","O1")
$range.clear()
$range=$everySheet.Range("B2","B2")
$range.clear()

	for ($i = $everySheet.usedrange.rows.count; $i -gt 33; $i--)
	{
		$foundText = $everySheet.Range("A:Z").Find($searchText)
		If ($foundText) {
		Write-Host ($foundText.Row)
		$foundText.EntireRow.Delete()
		}
	}

$legendRange.Copy() | Out-Null
$lastRow = $Everysheet.UsedRange.Rows.Count + 2
$everySheet.Range("C"+$lastrow).Activate()
$everySheet.Paste()



$everySheet.Copy($Worksheet)
$everyExcel.Close($false)
 
}

$workbook.Worksheets.item("Sheet1").Delete()



$workbook.SaveAs("$path\$year\$year-Calendar.xlsx")
$excelObject.Quit()

$excelFiles | Remove-Item -Force -Confirm:$false

