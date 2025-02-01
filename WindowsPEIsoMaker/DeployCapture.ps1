# Author: Sebastian Steininger (sebastian.steininger@outlook.com)

# This file is executed on startup of WindowsPE, it contains the logic to capture and deploy windows images.


# ---------------------------- Constants ----------------------------
#
# TODO: Change so it works with your config
# WARNING: THIS IS NOT SECURE !!! Because we want the share to connect automatically we need to write down the username and password
# of a user that can read the network share. MAKE SURE that the user has NO other privileges then reading from the network share!!!
# Consider the NETWORK SHARE to be PUBLIC at this point. (DO NOT STORE ANYTHING IMPORTANT ON THAT SHARE THAT CAN NOT BE MADE PUBLIC!!!)

$networkPath = "\\<hostname>\<path>"

$readOnlyUser = "<readUser>"
$readOnlyUserPassword = "<password>"

# The user used to capture the image, needs write permission, so the password is requested during capture.
$captureUser = "<readWriteUser>"

$defaultFile = "Deploy.wim"

$content = "select disk 0
select volume 1
assign letter=C"

# -------------------------- END Constants --------------------------
Function Get-Mode {
    $type = Read-Host "    --------------------------------------------------------------------------------    

    1 - Deploy       Deploy an captured image to this system.
    2 - Capture      Capture a .wim image from this system.

    --------------------------------------------------------------------------------    
    What would you like to do?"
    Switch ($type) {
        1 { $choice = "Deploy" }
        2 { $choice = "Capture" }
    }
    return $choice
}

Function Clear-ProgramContent {
    Clear-Host

    Write-Host "
     ____                 _     _               ____  _                 ____   ____ 
    |  _ \ _ __ _____   _(_)___(_) ___  _ __   |  _ \(_)___ _ __ ___   |  _ \ / ___|
    | |_) | '__/ _ \ \ / / / __| |/ _ \| '_ \  | | | | / __| '_ ` _  \  | |_) | |    
    |  __/| | | (_) \ V /| \__ \ | (_) | | | | | |_| | \__ \ | | | | | |  __/| |___ 
    |_|   |_|  \___/ \_/ |_|___/_|\___/|_| |_| |____/|_|___/_| |_| |_| |_|    \____|      " -ForegroundColor Green

    Write-Host "
    @Sebastian Steininger (sebastian.steininger@outlook.com)
    " -ForegroundColor DarkGreen
}

$mainLoop = $true
while ($mainLoop) {
    Clear-ProgramContent

    $mode = Get-Mode

    Write-Host "
    "

    IF ($mode -eq "Deploy") {
        # you could replace these with "$cred = Get-Credential -Credential $readOnlyUser" then you would not need the password in the file.

        $securePassword = ConvertTo-SecureString $readOnlyUserPassword -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($readOnlyUser, $securePassword)

        try {
            $driveY = Get-PSDrive -Name Y -ErrorAction SilentlyContinue
            if (-not($driveY -and $driveY.Provider.Name -eq "FileSystem" -and $driveY.DisplayRoot -like $networkPath)) {
                #Assing to avoid console output
                $psres = New-PSDrive -Name "Y" -PSProvider "FileSystem" -Root $networkPath -Persist -Credential $cred -ErrorAction Stop -Scope Global
            }

            # Get .wim files in the directory
            $wimFiles = @(Get-ChildItem -Path "Y:\" -Filter *.wim)

            # Check if there are any .wim files
            if ($wimFiles.Count -gt 0) {
                # Display files in Out-GridView with a timeout
                $selectedFile = $null

                # Check if any .wim files were found
                if ($wimFiles.Count -eq 0) {
                    Write-Host "    No .wim files found in the directory." -ForegroundColor DarkRed

                    Write-Host -NoNewLine '    Press any key to continue...';
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                    continue
                }

                Clear-ProgramContent

                # Display the list of .wim files
                Write-Host "    --------------------------------------------------------------------------------"
                Write-Host ""
                for ($i = 0; $i -lt $wimFiles.Count; $i++) {
                    Write-Host "    $($i + 1) - $($wimFiles[$i].Name)"
                }
                Write-Host ""
                Write-Host "    --------------------------------------------------------------------------------"
                # Ask the user to selewct one of the wim files.
                $selectedIndex = Read-Host "    Select a .wim file (or press ENTER to use default $defaultFile)"
                Write-Host ""

                # If the user only presses Enter, use the default file.
                if ($selectedIndex -match '^\d+$' -and [int]$selectedIndex -ge 1 -and [int]$selectedIndex -le $wimFiles.Count) {
                    $selectedFile = $wimFiles[[int]$selectedIndex - 1]
                    Write-Host "    You selected: $($selectedFile.FullName)"
                }
                # default to the default file if user just presses enter, otherwise loop to ask again
                elseif ($selectedIndex.Length -eq 0) {
                    Write-Host "    Defaulting to $defaultFile."
                    $selectedFile = $wimFiles | Where-Object { $_.Name -eq $defaultFile }
                } 
                else {
                    Write-Host "    Could not map input to image!"

                    Write-Host -NoNewLine '    Press any key to continue...';
                    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
                    continue
                }

                # Check if a file was selected or defaulted
                if ($selectedFile) {
                    Write-Host "    Deploying: $selectedFile"
                    
                    Start-Process -FilePath "diskpart" -ArgumentList "/s Y:\CreatePartitions-UEFI.txt" -NoNewWindow -Wait
                    Start-Process -FilePath "Y:\ApplyImage.bat" -ArgumentList "Y:\$selectedFile" -NoNewWindow -Wait
                }
                else {
                    Write-Host "    No file was selected and default file not found." -ForegroundColor DarkRed
                }
            }
            else {
                Write-Host "    No .wim files found in the provided directory!" -ForegroundColor DarkRed
            }
        }
        catch {
            Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkRed

            Write-Host -NoNewLine '    Press any key to continue...'
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            continue
        }

        # Deployed image successfully.
        Write-Host -NoNewLine '    Image Deployed Successfully!' -ForegroundColor DarkGreen

        Write-Host -NoNewLine '    Press any key to continue...'
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit
    }
    else {
        Write-Host "    Mounting system drive ..."

        #Assing to avoid console output
        $mountText = New-Item -ItemType File -Name "mount.txt" -Value $content -Force

        Start-Process -FilePath "diskpart" -ArgumentList "/s mount.txt" -NoNewWindow -Wait

        Write-Host "    Mounted system drive!"

        Write-Host "    Connecting do Deploymentshare ..."
        Write-Host "    Please endter the credentials of a user that is allowed to write to the deploymentshare"

        $attempt = 2
        $driveY = Get-PSDrive -Name Y -ErrorAction SilentlyContinue

        # Mount the network share needed to load the captured image.
        while (($attempt -gt -1) -and (-not($driveY -and $driveY.Provider.Name -eq "FileSystem" -and $driveY.DisplayRoot -like $networkPath))) {
            try {
                $cred = Get-Credential -Credential $captureUser
                $psres = New-PSDrive -Name "Y" -PSProvider "FileSystem" -Root $networkPath -Persist -Credential $cred -ErrorAction Stop -Scope Global
                break
            }
            catch {
                Write-Host "    Unable to connect to drive! ($attempt attempts left)" -ForegroundColor DarkRed
                Start-Sleep -s 1 
                Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkRed
                $attempt = $attempt - 1
            }

            # Update check for mounted drive.
            $driveY = Get-PSDrive -Name Y -ErrorAction SilentlyContinue
        }
        
        try {
            # if connection was possible go ahead and run the script
            if ($attempt -gt -1) {
                $name = Read-Host "    Enter a name for the image (filename, [A-Za-z0-9]+)"
                Start-Process -FilePath "DISM" -ArgumentList "/Capture-Image /ImageFile:Y:\$name.wim /CaptureDir:C:\ /Name:$name /Compress:max" -NoNewWindow -Wait
            }
        }
        catch {
            Write-Host "    Unable to capture image!" -ForegroundColor DarkRed
            Write-Host "    $($_.Exception.Message)" -ForegroundColor DarkRed

            Write-Host -NoNewLine '    Press any key to continue...';
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
            continue
        }

        # Image was captured successfully, can leave.
        Write-Host "    Image Captured Successfully!" -ForegroundColor DarkGreen
        Write-Host -NoNewLine '    Press any key to continue...';
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
        exit
    }

    Write-Host -NoNewLine '    Press any key to continue...';
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}