# Author: Sebastian Steininger (sebastian.steininger@outlook.com)

# --------------------------------------------------------------------------
# 		Make sure that the drive is decrypted
# --------------------------------------------------------------------------


# Get the drive letter of the current script's location
$driveLetter = (Get-Location).Drive.Name + ":"

# Check if BitLocker is enabled on the drive
if (-not ((manage-bde -status $driveLetter) -match "Decrypted")) {
    Write-Host "BitLocker is enabled on drive $driveLetter. Disabling BitLocker..."
    
    # Disable BitLocker on the drive
    manage-bde -off $driveLetter

    # Wait for decryption to complete
    while ($true) {
        if ((manage-bde -status $driveLetter) -match "Decrypted") {
            Write-Host "Decryption is complete on drive $driveLetter."
            break
        }
        Write-Host "Decryption in progress on drive $driveLetter..."
        Start-Sleep -Seconds 10  # Wait for 10 seconds before checking again
    }
}
else {
    Write-Host "BitLocker is not enabled on drive $driveLetter. No action taken."
}


# --------------------------------------------------------------------------
#     Delete all user specific Appx Packages preventing generalization
# --------------------------------------------------------------------------

Write-Host "Checking for user specific packages that could interfere with sysprep ..."

# Get all packages installed for all users
$allUsersPackages = Get-AppxPackage -AllUsers

# Get packages installed for the current user
$currentUserPackages = Get-AppxPackage

# Find user-specific packages (packages not in the all-users list)
$userSpecificPackages = $currentUserPackages | Where-Object { $_.PackageFullName -notin $allUsersPackages.PackageFullName }

# Display user-specific packages in GridView
$userSpecificPackages | Out-GridView -PassThru | Remove-AppxPackage

Write-Host "Choose Packages to uninstall ... (Check sysprep logs if sysprep fails and choose packages to uninstall.)"

# Let the user select packages to remove.
Get-AppxPackage | Out-GridView -PassThru | Remove-AppxPackage
