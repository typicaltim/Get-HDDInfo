# Variables
    # Location to look for and save the catalog file
    $SavedHDDCatalog = "L:\ocation\of\savedhddcatalog.csv"
        # Make sure that a catalog file exists
        if (-not (Test-Path $SavedHDDCatalog)) {
            Write-Host "INFO: No catalog file found. A new Catalog file will be created." -ForegroundColor Yellow
            # Create the Catalog file and spit the output to null so it doesn't bother the user, it looks ugly
            New-Item $SavedHDDCatalog | Out-Null
        }

# Input
    # Ask the user for the drive letter of the connected HDD to make sure it doesn't pull the wrong information
    $SelectedDriveLetter = Read-Host -Prompt 'Enter Drive Letter of HDD'
    $PathToNetSetupLog = "$SelectedDriveLetter" + ":\windows\debug\NetSetup.LOG"

# HDD Index Number
    # Try to pull the last entry from the catalog (suppress the annoying error if it pops up, we will deal with that next)
    $lastDataEntry = import-csv $SavedHDDCatalog | select -last 1 -ErrorAction SilentlyContinue
    # If the last entry index number doesn't exist, or is less than one - the catalog is probably blank so do the following:
    if ($lastDataEntry.HDDIndexNumber -ne "" -and $lastDataEntry.HDDIndexNumber -lt 1){
        # Let the user know that we will set the HDD Index Number Value
        Write-Host "INFO: No data found in catalog file, setting HDD Index Number to 1" -ForegroundColor Yellow
        # Do what we said we were going to do
        [int]$newHDDIndexNumber = 1
    }
    # In the case that the last index number found is not blank and is equal to or greater than one, this is probably an existing file - so do this:
    else {
        # Let the user know that we found the data in the file and new stuff will be appended to the Catalog - verbatim :)
        Write-Host "INFO: Data was found in Catalog file, new entries will be appended to the Catalog" -ForegroundColor Yellow
        # Convert the last HDD Index Number value from a string to an integer and save it to a variable so we can do math with it
        [int]$newHDDIndexNumber = [int]$lastDataEntry.HDDIndexNumber
        # Increase the value of the HDD Index Number by one so that it is ready to be used later if we want to write a new entry to the catalog
        $newHDDIndexNumber++
    }

# Hostname
    # If the HDD doesn't have that log file, give the user a heads up.
    if (-not (Test-Path $PathToNetSetupLog)) {
      Write-Host "INFO: 'NetSetup.LOG' on drive not found, setting hostname to 'UNKNOWN'" -ForegroundColor Yellow
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
        # If the Hostname is blank for whatever reason, set it to UNKNOWN - unfortunately the method for grabbing host name that I'm using isn't a perfect method
        if ($ScrapedHostName -eq $null){
            Write-Host "INFO: Hostname on drive not found, setting hostname to 'UNKNOWN'" -ForegroundColor Yellow
            $ScrapedHostName = "UNKNOWN"
        }
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
      Write-Host "INFO: No users found. Setting user list to null" -ForegroundColor Yellow
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
    $SavedHDDInformation | add-member -membertype NoteProperty -name HDDIndexNumber -Value $NewHDDIndexNumber
    # Add the column for the Host Name information that has been pulled from the HDD
    $SavedHDDInformation | add-member -membertype NoteProperty -name HostName -Value $ScrapedHostName

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
      Add-Member -InputObject $SavedHDDInformation -membertype NoteProperty -name $PropName -Value $_[0].Name
    }

# Write-out
    # Verify with the user that the information pulled from the drive looks alright
    Write-Host "Please note the information scraped from drive '$SelectedDriveLetter', does this look correct?"
    # Show them the object information
    $SavedHDDInformation | Format-List
    # Ask them if it's cool
    $UserConfirmation = Read-Host -Prompt '(Y/N)'

    # If it's cool, do this:
    if ($UserConfirmation -eq 'Y'){

    # Append this information to the spreadsheet file
    $SavedHDDInformation | Export-CSV $SavedHDDCatalog -NoType -Append -Force
    # Let the user know that the information is saved and give them the number to put on the drive
    Write-Host "SAVED: Please Label the HDD/SSD with the number " -ForegroundColor Green -nonewline; Write-Host " $NewHDDIndexNumber " -BackgroundColor White -ForegroundColor Black;
    }

    # If the user doesn't like the info, let them know it won't be saved
    if ($UserConfirmation -eq 'N'){
    Write-Host 'WARNING: User declined save operation. This information will not be appended to the Catalog file.' -ForegroundColor Red
    }
