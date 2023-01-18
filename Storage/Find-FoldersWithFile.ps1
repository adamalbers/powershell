# Find all the folders containing a certain file extension or name (the -Filter parameter)
# Useful for finding all the .locky or .crypto folders on a machine
Get-ChildItem -Path C:\ -Recurse -Filter *.locky | Select-Object -ExpandProperty DirectoryName -Unique

Exit 0