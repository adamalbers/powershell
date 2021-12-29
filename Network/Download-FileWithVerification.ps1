[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null

$downloadForm = New-Object System.Windows.Forms.Form
$downloadForm.Size = '400,400'
$downloadForm.Text = "Download with File Verification"

$pathTextLabel = New-Object System.Windows.Forms.Label
$pathTextLabel.Location = '120,23'
$pathTextLabel.Szie = '240,40'
$pathTextLabel.Text = 'Download Folder'

$pathTextBox = New-Object System.Windows.Forms.TextBox
$pathTextBox.Location = '120,50'
$pathTextBox.Size = '240,40'
$pathTextBox.Text = "$Env:USERPROFILE\Downloads"

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = '23,50'

$folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$browseButton.Add_Click({
    $folderBrowser.ShowDialog()
    $pathTextBox.Text = $folderBrowser.SelectedPath
    $pathTextBox.ReadOnly = $true
})

$hashTypeLabel = New-Object System.Windows.Forms.Label
$hashTypeLabel.Location = '23,100'
$hashTypeLabel.Text = 'Hash Type'

$hashTypesGroupBox = New-Object System.Windows.Forms.GroupBox
$hashTypesGroupBox.Location = '23,100'
$hashTypesGroupBox.Size = '350,60'
$hashTypesGroupBox.Text = 'Hash Type'

$md5RadioButton = New-Object System.Windows.Forms.RadioButton
$md5RadioButton.Location = '10,20'
$md5RadioButton.Size = '60,20'
$md5RadioButton.Checked = $true
$md5RadioButton.Text = 'MD5'

$sha1RadioButton = New-Object System.Windows.Forms.RadioButton
$sha1RadioButton.Location = '120,20'
$sha1RadioButton.Size = '60,20'
$sha1RadioButton.Checked = $false
$sha1RadioButton.Text = 'SHA1'

$sha256RadioButton = New-Object System.Windows.Forms.RadioButton
$sha256RadioButton.Location = '200,20'
$sha256RadioButton.Size = '80,20'
$sha256RadioButton.Checked = $false
$sha256RadioButton.Text = 'SHA256'

$hashTypesGroupBox.controls.AddRange(@($md5RadioButton,$sha1RadioButton,$sha256RadioButton))

$urlLabel = New-Object System.Windows.Forms.Label
$urlLabel.Location = '20,150'
$urlLabel.Size = '150,20'
$urlLabel.Text = 'Download URL'

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = '23,320'
$cancelButton.Size = '80,20'
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$downloadForm.CancelButton = $cancelButton

$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Location = '240,320'
$downloadButton.Size = '120,20'
$downloadButton.Text = 'Download'
$downloadButton.DialogResult = [System.Windows.Form.DialogResult]::OK
$downloadForm.AcceptButton = $downloadButton



$downloadForm.Controls.AddRange(@($pathTextLabel,$pathTextBox,$browseButton,$hashTypeLabel,$hashTypesGroupBox,$cancelButton,$downloadButton))
$downloadForm.ShowDialog()



$hashType = ''
if ($md5RadioButton.Checked) {
    $hashType = 'MD5'
} elseif ($sha1RadioButton.Checked) {
    $hashType = 'SHA1'
} elseif ($sha256RadioButton.Checked) {
    $hashType = 'SHA256'
}



Exit 0