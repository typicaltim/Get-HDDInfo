# Variables
$SavedHDDCatalog = "Drive:\Path\of\catalog.csv"
$HDDIndexNumberFile = "Drive:\Path\of\HDDIndexNumber.txt"
$SavedHDDInformation = New-Object PSObject

# Ask the user for the drive letter of the connected HDD to make sure it doesn't pull the wrong information
$SelectedDriveLetter = Read-Host -Prompt 'Enter Drive Letter of HDD'
$PathToNetSetupLog = "$SelectedDriveLetter" + ":\windows\debug\NetSetup.LOG"

# If the HDD doesn't have that log file, give the user a heads up.
if (-not (Test-Path $PathToNetSetupLog)) {
  Write-Host "WARNING: The Hostname associated with this HDD/SSD was not found, this column will be left blank. This is okay." -ForegroundColor Red
  $ScrapedHostName = 'UNKNOWN'
}

# If the HDD does have that log file, go ahead and do this:
if (Test-Path $PathToNetSetupLog) {
# Find the line that contains the Host Name
$DebugHostnameScrape = select-string -path $PathToNetSetupLog -SimpleMatch -Pattern "NetpGetComputerObjectDn: Cracking account name" | Select-Object -First 1
# Seperate the strings into an arrray
$SplitDebugHostnameScrape = $DebugHostnameScrape -split ' '
# Select the Host Name from the array
$ScrapedHostName = $SplitDebugHostnameScrape[6]
}

# Set the path to the user folders to the default location for Windows 7
$PathToUserDir = "$SelectedDriveLetter" + ":\users\"
# If the user folders can't be found at C:\users, it's probably an XP machine. Check at "C:\Documents and Settings" instead
if (-not (Test-Path $PathtoUserDir)) {
  $PathToUserDir = "$SelectedDriveLetter" + ":\Documents and Settings\"
}
# If the user folders cannot be found with the Windows XP path, it probably doesn't exist, let the user know
if (-not (Test-Path $PathtoUserDir)) {
  Write-Host "WARNING: No users were found on this HDD/SSD. Bummer." -ForegroundColor Red
  # Set the scraped user list variable anyways so that the rest of the script has data to put in the csv
  #changed this to update the variable with 'error' information
  $SavedHDDInformation = "Drive #" + $HDDIndexNumber + " is Unreadable"
}
# otherwise If the user folders can be found, get a list of all the profile folders found there
else #(Test-Path $PathtoUserDir)
{
  $ScrapedUserList = Get-ChildItem -Force $PathToUserDir | Select-Object Name


# Create an Object that will contain the information
#$SavedHDDInformation = New-Object PSObject
# Add the column for the HDDIndexNumber that will be used to identify the individual HDD
$SavedHDDInformation | add-member –membertype NoteProperty –name HDDIndexNumber –Value NotSet
# Add the column for the Host Name information that has been pulled from the HDD
$SavedHDDInformation | add-member –membertype NoteProperty –name HostName –Value NotSet

# Set a counter that will increment for each user profile found on the HDD
$UserCount = 0

# Read the HDD Index Number value that is stored in the following file and convert it to a number
[decimal]$HDDIndexNumber = Get-Content $HDDIndexNumberFile

# Do the following for every user profile name:
$ScrapedUserList | ForEach{
  # Increment the user counter by one
  $UserCount++
  # Create a variable to hold the name "User" and append it with the user counter's current value
  $PropName = "User" + "$UserCount"
  # Set the Object's HDD Index Number value to it's current value
  $SavedHDDInformation.HDDIndexNumber = $HDDIndexNumber
  # Set the Object's Host name Value to the HostName Value pulled from the HDD
  $SavedHDDInformation.HostName = $ScrapedHostName
  # Create a column named after the user counter value and set the value to the current user in the list
  Add-Member -InputObject $SavedHDDInformation –membertype NoteProperty –name $PropName –Value $_[0].Name
}
}

# Verify with the user that the information pulled from the HDD/SSD looks alright
Write-Host 'Please note the information scraped from the HDD/SSD, does this look correct?'
# Show them the object information
$SavedHDDInformation
# Ask them if it's cool
$UserConfirmation = Read-Host -Prompt '(Y/N)'

# If it's cool, do this:
if ($UserConfirmation -eq "Y"){
# Increment the HDD Index Number
$HDDIndexNumber++
# Write the new HDD Index Number value back to the file to store it
Set-Content $HDDIndexNumberFile $HDDIndexNumber

# Append this information to the spreadsheet file
$SavedHDDInformation | Export-CSV $SavedHDDCatalog -NoType -Append -Force
Write-Host Saved. Please Label the HDD/SSD with the HDD Index Number found above. -ForegroundColor Green
}
if ($UserConfirmation -eq "N"){
Write-Host "!!!THIS INFORMATION HAS NOT BEEN SAVED!!!" -ForegroundColor Red
}
