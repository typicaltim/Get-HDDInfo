# Variables
    # Location to look for and save the catalog file
    $SavedHDDCatalog = "L:\ocation\of\savedhddcatalog.csv"

# Input
    # Ask the user for the drive letter of the connected HDD to make sure it doesn't pull the wrong information
    $SelectedDriveLetter = Read-Host -Prompt 'Enter Drive Letter of HDD'
    $PathToNetSetupLog = "$SelectedDriveLetter" + ":\windows\debug\NetSetup.LOG"

# HDD Index Number
    # Get the last row from the savedhddcatalog.csv
    $ReadLastDataRow = (Get-Content $SavedHDDCatalog)[-1]
    # Split each column apart into an array
    $LastDataRowArray = $ReadLastDataRow.Split(",")
    # Select the first column (which is the last index number) and write that into a variable
    $LastHDDIndexNumber = $LastDataRowArray[0]
    # Take the last index number and convert it to a decimal (it's text right now)
    [decimal]$NewHDDIndexNumber = $LastHDDIndexNumber
    # Increment it by one, that will be the new number for our object to use later
    $NewHDDIndexNumber++

# Hostname
    # If the HDD doesn't have that log file, give the user a heads up.
    if (-not (Test-Path $PathToNetSetupLog)) {
      Write-Host "     WARNING: The Hostname associated with this HDD/SSD was not found, this column will be marked 'UNKNOWN'. This is okay." -ForegroundColor Yellow
      $ScrapedHostName = "UNKNOWN"
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

# User list
    # Set the path to the user folders to the default location for Windows 7
    $PathToUserDir = "$SelectedDriveLetter" + ":\users\"
    # If the user folders can't be found at C:\users, it's probably an XP machine. Check at "C:\Documents and Settings" instead
    if (-not (Test-Path $PathtoUserDir)) {
      $PathToUserDir = "$SelectedDriveLetter" + ":\Documents and Settings\"
    }
    # If the user folders cannot be found with the Windows XP path, it probably doesn't exist, let the user know
    if (-not (Test-Path $PathtoUserDir)) {
      Write-Host "     WARNING: No users were found on this HDD/SSD. Bummer. These will be left blank." -ForegroundColor Yellow
      # Set the scraped user list variable to a blank array so that the rest of the script has "data" to put in the csv
      $ScrapedUserList = @()
    }
    # If the user folders can be found, get a list of all the profile folders found there
    if (Test-Path $PathtoUserDir){
      $ScrapedUserList = Get-ChildItem -Force $PathToUserDir | Select-Object Name
    }

# Creating Custom Object
    # Create an Object that will contain the information
    $SavedHDDInformation = New-Object PSObject
    # Add the column for the HDDIndexNumber that will be used to identify the individual HDD
    $SavedHDDInformation | add-member –membertype NoteProperty –name HDDIndexNumber –Value $NewHDDIndexNumber
    # Add the column for the Host Name information that has been pulled from the HDD
    $SavedHDDInformation | add-member –membertype NoteProperty –name HostName –Value $ScrapedHostName

    # Set a counter that will increment for each user profile found on the HDD
    $UserCount = 0

    # Do the following for every user profile name:
    $ScrapedUserList | ForEach{
      # Increment the user counter by one
      $UserCount++
      # Create a variable to hold the name "User" and append it with the user counter's current value
      $PropName = "User" + "$UserCount"
      # Set the Object's HDD Index Number value to it's current value
      $SavedHDDInformation.HDDIndexNumber = $NewHDDIndexNumber
      # Set the Object's Host name Value to the HostName Value pulled from the HDD
      $SavedHDDInformation.HostName = $ScrapedHostName
      # Create a column named after the user counter value and set the value to the current user in the list
      Add-Member -InputObject $SavedHDDInformation –membertype NoteProperty –name $PropName –Value $_[0].Name
    }

# Write-out
    # Verify with the user that the information pulled from the HDD/SSD looks alright
    Write-Host 'Please note the information scraped from the HDD/SSD, does this look correct?'
    # Show them the object information
    $SavedHDDInformation
    # Ask them if it's cool
    $UserConfirmation = Read-Host -Prompt '(Y/N)'

    # If it's cool, do this:
    if ($UserConfirmation -eq "Y"){

    # Append this information to the spreadsheet file
    $SavedHDDInformation | Export-CSV $SavedHDDCatalog -NoType -Append -Force
    Write-Host "Saved. Please Label the HDD/SSD with the HDD Index Number found above." -ForegroundColor Green
    }

    # If the user doesn't like the info, let them know it won't be saved
    if ($UserConfirmation -eq "N"){
    Write-Host "!!!THIS INFORMATION HAS NOT BEEN SAVED!!!" -ForegroundColor Red
    }
