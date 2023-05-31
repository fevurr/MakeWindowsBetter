### Custom functions 
function Start-TunerCleanup {
    # List of bloatware apps to remove
    $bloatwareApps = @(
        "Microsoft.3DBuilder"
        "Microsoft.BingNews"
        "Microsoft.BingWeather"
        "Microsoft.GetHelp"
        "Microsoft.Getstarted"
        "Microsoft.MicrosoftOfficeHub"
        "Microsoft.MicrosoftSolitaireCollection"
        "Microsoft.MinecraftUWP"
        "Microsoft.NetworkSpeedTest"
        "Microsoft.People"
        "Microsoft.Print3D"
        "Microsoft.SkypeApp"
        "Microsoft.StorePurchaseApp"
        "Microsoft.Wallet"
        "Microsoft.WindowsAlarms"
        "Microsoft.WindowsCalculator"
        "Microsoft.WindowsCamera"
        "Microsoft.WindowsCommunicationsApps"
        "Microsoft.WindowsFeedbackHub"
        "Microsoft.WindowsMaps"
        "Microsoft.WindowsPhone"
        "Microsoft.WindowsSoundRecorder"
        "Microsoft.XboxApp"
        "Microsoft.XboxGameOverlay"
        "Microsoft.XboxIdentityProvider"
        "Microsoft.XboxSpeechToTextOverlay"
        "Microsoft.YourPhone"
    )

    # Remove bloatware apps
    foreach ($app in $bloatwareApps) {
        Write-Output "Removing app: $app"
        Get-AppxPackage -Name $app | Remove-AppxPackage
    }

    Write-Output "Bloatware removal completed."
}
function Start-TunerDiskClean {
    # Get all local disks
    $disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"

    # Perform cleanup on each disk
    foreach ($disk in $disks) {
        $driveLetter = $disk.DeviceID

        Write-Output "Performing cleanup on disk: $driveLetter"

        # Run the cleanup command on the disk
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/d$driveLetter /sagerun:1" -Wait
    }

    Write-Output "Disk cleanup completed."
}
function Start-TunerPatching {
    # Start the PowerShell process
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = 'powershell.exe'
    $startInfo.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "Get-WindowsUpdate"'
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $process = [System.Diagnostics.Process]::Start($startInfo)

    # Read the output from the process
    $output = $process.StandardOutput.ReadToEnd()

    # Wait for the process to exit
    $process.WaitForExit()

    # Check if there are any missing or pending updates
    if ($output -ne $null) {
        $missingUpdates = $output | ConvertFrom-Csv | Where-Object { $_.UpdateType -eq 'Software' -and $_.InstallationState -ne 'Installed' }

        if ($missingUpdates.Count -gt 0) {
            $progressBar.Value = 50  # Update progress bar

            # Install the updates
            $startInfo.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "Install-WindowsUpdate -AcceptAll -AutoReboot"'
            $process = [System.Diagnostics.Process]::Start($startInfo)
            $process.WaitForExit()

            $progressBar.Value = 100  # Update progress bar

            # Show a message box indicating updates have been installed
            [System.Windows.Forms.MessageBox]::Show("Updates installed successfully.", "Update Status", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } else {
            # Show a message box indicating no updates found
            [System.Windows.Forms.MessageBox]::Show("No missing or pending updates found.", "Update Status", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } else {
        # Show a message box indicating an error occurred
        [System.Windows.Forms.MessageBox]::Show("An error occurred while checking for updates.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
function Start-TunerClearTemp {
    $tempDirectories = @(
        "$env:TEMP",                           # User's temporary directory
        "$env:LOCALAPPDATA\Temp",               # Local AppData temporary directory
        "$env:WINDIR\Temp"                      # Windows temporary directory
        # Add more directories as needed
    )

    foreach ($directory in $tempDirectories) {
        if (Test-Path -Path $directory) {
            Write-Output "Clearing files in directory: $directory"
            Get-ChildItem -Path $directory -File -Force | Remove-Item -Force
        } else {
            Write-Output "Directory not found: $directory"
        }
    }

    Write-Output "Temporary files cleared."
}

$operatingSystem = [System.Environment]::OSVersion.VersionString

# UI [Form Controls/Inputs]
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#Form setup
$form = New-Object System.Windows.Forms.Form
$form.Text = 'MakeWindowsBetter'
$form.Size = New-Object System.Drawing.Size(800,900)
$form.StartPosition = 'CenterScreen'
$form.BackColor = '#e8f5ff'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $False

$file = Join-Path -Path $PSScriptRoot -ChildPath "Assets\windows11icon.png"
$img = [System.Drawing.Image]::FromFile($file)

# FontTypes
$Headingfont = [System.Drawing.Font]::new("Calibri", 25, [System.Drawing.FontStyle]::Bold)
$Subtextfont = [System.Drawing.Font]::new("Calibri Light", 14, [System.Drawing.FontStyle]::Regular)
$Bodytextfont = [System.Drawing.Font]::new("Calibri Light", 12, [System.Drawing.FontStyle]::Regular)
$Buttonfont = [System.Drawing.Font]::new("Calibri Light", 12, [System.Drawing.FontStyle]::Bold)
$Versiontextfont = [System.Drawing.Font]::new("Calibri Light", 12, [System.Drawing.FontStyle]::Bold)

# Building the form

$pictureBox = New-Object System.Windows.Forms.PictureBox
$pictureBox.Location = New-Object System.Drawing.Point(625,15)
$pictureBox.Size = New-Object System.Drawing.Size(115,115)
$pictureBox.Image = $img
$pictureBox.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$form.Controls.Add($pictureBox)

$Headerlabel = New-Object System.Windows.Forms.Label
$Headerlabel.location = New-Object System.Drawing.Point(50,50)
$Headerlabel.Size = New-Object System.Drawing.Size(400,50)
$Headerlabel.Font = $Headingfont
$Headerlabel.Text = 'Debloater and Optimizer'
$form.controls.Add($Headerlabel)

$Descriptionlabel = New-Object System.Windows.Forms.Label
$Descriptionlabel.location = New-Object System.Drawing.Point(75,125)
$Descriptionlabel.Size = New-Object System.Drawing.Size(800,100)
$Descriptionlabel.Font = $Subtextfont
$Descriptionlabel.Text = 'Windows tends to come with bloatware and poorly optimized settings. 
This tool will clean and optimize your system to make sure your PC is running optimally. 
Some options and features may only be compatible with Windows 11.'
$form.controls.Add($Descriptionlabel)

$installpsgetButton = New-Object System.Windows.Forms.Button
$installpsgetButton.Location = New-Object System.Drawing.Point(50,250)
$installpsgetButton.Size = New-Object System.Drawing.Size(200,40)
$installpsgetButton.Font = $Buttonfont
$installpsgetButton.Text = 'Install PSGet Module'
$installpsgetButton.BackColor = '#196ef7'
$installpsgetButton.ForeColor = 'white'
$form.controls.Add($installpsgetButton)

$restartwarninglabel = New-Object System.Windows.Forms.Label
$restartwarninglabel.location = New-Object System.Drawing.Point(550,365)
$restartwarninglabel.Size = New-Object System.Drawing.Size(200,65)
$restartwarninglabel.Font = $Bodytextfont
$restartwarninglabel.Text = '*Its recommended that you restart your machine after applying fixes.'
$form.controls.Add($restartwarninglabel)

$restartButton = New-Object System.Windows.Forms.Button
$restartButton.Location = New-Object System.Drawing.Point(550,430)
$restartButton.Size = New-Object System.Drawing.Size(200,40)
$restartButton.Font = $Buttonfont
$restartButton.Text = '*Restart Machine'
$restartButton.BackColor = '#fc5d00'
$restartButton.ForeColor = 'black'
$form.controls.Add($restartButton)

$restoredefaultlabel = New-Object System.Windows.Forms.Label
$restoredefaultlabel.location = New-Object System.Drawing.Point(550,290)
$restoredefaultlabel.Size = New-Object System.Drawing.Size(200,65)
$restoredefaultlabel.Font = $Bodytextfont
$restoredefaultlabel.Text = '**You cannot undo this. You will have to reapply OS Tweaks and Fixes.'
$form.controls.Add($restoredefaultlabel)

$resetdefaultButton = New-Object System.Windows.Forms.Button
$resetdefaultButton.Location = New-Object System.Drawing.Point(550,250)
$resetdefaultButton.Size = New-Object System.Drawing.Size(200,40)
$resetdefaultButton.Font = $Buttonfont
$resetdefaultButton.Text = '**Restore Default Settings'
$resetdefaultButton.BackColor = '#ff0303'
$resetdefaultButton.ForeColor = 'white'
$form.controls.Add($resetdefaultButton)

$initTweaksButton = New-Object System.Windows.Forms.Button
$initTweaksButton.Location = New-Object System.Drawing.Point(50,775)
$initTweaksButton.Size = New-Object System.Drawing.Size(700,40)
$initTweaksButton.Font = $Buttonfont
$initTweaksButton.Text = 'Apply OS Tweaks and Fixes [Windows 10/11]'
$initTweaksButton.BackColor = '#196ef7'
$initTweaksButton.ForeColor = 'white'
$form.controls.Add($inittweaksButton)

$Descriptionlabel = New-Object System.Windows.Forms.Label
$Descriptionlabel.location = New-Object System.Drawing.Point(50,300)
$Descriptionlabel.Size = New-Object System.Drawing.Size(200,65)
$Descriptionlabel.Font = $Bodytextfont
$Descriptionlabel.Text = 'You need to install the PSGet Module to utilize all of these scripts.'
$form.controls.Add($Descriptionlabel)

$tunerScripts = New-Object System.Windows.Forms.ListBox
$tunerScripts.Location = New-Object System.Drawing.Point(50,365)
$tunerScripts.Size = New-Object System.Drawing.Size(200,60)
$tunerScripts.BorderStyle = 'None'
$tunerScripts.Items.Add('Start-TunerCleanup')
$tunerScripts.Items.Add('Start-TunerDiskClean')
$tunerScripts.Items.Add('Start-TunerPatching')
$tunerScripts.Items.Add('Start-TunerClearTemp')
$form.controls.Add($tunerScripts)

$initiatetunerButton = New-Object System.Windows.Forms.Button
$initiatetunerButton.Location = New-Object System.Drawing.Point(50,430)
$initiatetunerButton.Size = New-Object System.Drawing.Size(200,40)
$initiatetunerButton.Font = $Buttonfont
$initiatetunerButton.Text = 'Run Tuner Script'
$initiatetunerButton.BackColor = '#196ef7'
$initiatetunerButton.ForeColor = 'white'
$form.controls.Add($initiatetunerButton)

$osLabel = New-Object System.Windows.Forms.Label
$osLabel.Text = "Windows Build: 
$operatingSystem"
$osLabel.Font = $Versiontextfont
$osLabel.Location = New-Object System.Drawing.Point(270,250)
$osLabel.AutoSize = $true
$form.controls.Add($osLabel)

### TREEVIEW CONTROL AND FUNCTIONS ###
$TreeView = New-Object System.Windows.Forms.TreeView
$TreeView.Location = New-Object System.Drawing.Point(50,475)
$TreeView.Size = New-Object System.Drawing.Size(700,300)
$TreeView.Font = $Treeviewfont
$TreeView.CheckBoxes = $True
$TreeView.ShowLines = $False
$TreeView.ItemHeight = 30
$TreeView.BorderStyle = 'None'
$form.Controls.Add($TreeView)

# Event handler for the AfterCheck event
$TreeView_AfterCheck = {
    param($sender, $e)
    $node = $e.Node
    $checked = $node.Checked

    # Function to check or uncheck child nodes recursively
    function SetChildNodesChecked($parentNode, $checked) {
        foreach ($childNode in $parentNode.Nodes) {
            $childNode.Checked = $checked
            SetChildNodesChecked $childNode $checked
        }
    }

    SetChildNodesChecked $node $checked
}

# Attach the event handler to the TreeView control
$TreeView.add_AfterCheck($TreeView_AfterCheck)
### END REGION ###

# Root Node
$rootNode = $TreeView.Nodes.Add("OS Tweaks & Fixes")
$rootNode.Checked = $true
$TreeView.ExpandAll()

# Child Nodes
$childNode1 = $rootNode.Nodes.Add("Browser")
$childNode1.Checked = $true
$childNode2 = $rootNode.Nodes.Add("Explorer")
$childNode2.Checked = $true
$childNode3 = $rootNode.Nodes.Add("Desktop")
$childNode3.Checked = $true
$childNode4 = $rootNode.Nodes.Add("Taskbar and Start menu")
$childNode4.Checked = $true
$childNode5 = $rootNode.Nodes.Add("System")
$childNode5.Checked = $true
$childNode6 = $rootNode.Nodes.Add("GPU")
$childNode6.Checked = $true
$childNode7 = $rootNode.Nodes.Add("Privacy")
$childNode7.Checked = $true
$childNode8 = $rootNode.Nodes.Add("Feature Recommendation")
$childNode8.Checked = $true

# Sub-child Nodes
$grandchildNode1 = $childNode1.Nodes.Add("Disable Google Chrome Telemetry")
$grandchildNode1.Checked = $true
$grandchildNode1 = $childNode1.Nodes.Add("Disable Mozilla Firefox Telemetry")
$grandchildNode1.Checked = $true
$grandchildNode2 = $childNode1.Nodes.Add("Enable Windows 10 File Explorer[CURRENTLY UNAVAILABLE ON WINDOWS VERSION 22H2]")
$grandchildNode2.Checked = $true
$grandchildNode2 = $childNode2.Nodes.Add("Show hidden files, folders and drives in File Explorer")
$grandchildNode2.Checked = $true
$grandchildNode2 = $childNode2.Nodes.Add("Show hidden file name extensions")
$grandchildNode2.Checked = $true
$grandchildNode3 = $childNode3.Nodes.Add("Use Windows dark theme")
$grandchildNode3.Checked = $true
$grandchildNode3 = $childNode3.Nodes.Add("Disable Snap Assist")
$grandchildNode3.Checked = $true
$grandchildNode3 = $childNode3.Nodes.Add("Disable Widgets")
$grandchildNode3.Checked = $true
$grandchildNode3 = $childNode3.Nodes.Add("Remove Desktop Stickers")
$grandchildNode3.Checked = $true
$grandchildNode4 = $childNode4.Nodes.Add("Hide Search icon on taskbar")
$grandchildNode4.Checked = $true
$grandchildNode4 = $childNode4.Nodes.Add("Hide Chat icon (Microsoft Teams) on taskbar")
$grandchildNode4.Checked = $true
$grandchildNode4 = $childNode4.Nodes.Add("Hide Task view button on taskbar")
$grandchildNode4.Checked = $true
$grandchildNode4 = $childNode4.Nodes.Add("Hide most used apps in start menu")
$grandchildNode4.Checked = $true
$grandchildNode4 = $childNode4.Nodes.Add("Show All apps on Start menu")
$grandchildNode4.Checked = $true
$grandchildNode5 = $childNode5.Nodes.Add("Enable Full Context Menus in Windows 11")
$grandchildNode5.Checked = $true
$grandchildNode5 = $childNode5.Nodes.Add("Remove Fax Printer")
$grandchildNode5.Checked = $true
$grandchildNode5 = $childNode5.Nodes.Add("Remove XPS Documents Writer")
$grandchildNode5.Checked = $true
$grandchildNode5 = $childNode5.Nodes.Add("Uninstall OneDrive")
$grandchildNode5.Checked = $true
$grandchildNode6 = $childNode6.Nodes.Add("Disable Game DVR feature")
$grandchildNode6.Checked = $true
$grandchildNode6 = $childNode6.Nodes.Add("Disable PowerThrottling")
$grandchildNode6.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Diagnostic data")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Connected User Experiences and Telemetry")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Compatibility Telemetry")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Location tracking")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Advertising ID for Relevent Ads")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Feedback notifications")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disabled Suggested content in Settings app")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable windows Hello Biometrics")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disble Automatic Installation of apps")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Windows tips")
$grandchildNode7.Checked = $true
$grandchildNode7 = $childNode7.Nodes.Add("Disable Tailored experiences")
$grandchildNode7.Checked = $true
$grandchildNode8 = $childNode8.Nodes.Add("It is recommeneded to enable Microsoft Windows Subsystem for Linux")
$grandchildNode8.Checked = $true

# Add the functions
$installpsgetButton.add_click({Install-Module PowerShellGet -Force})
$initiatetunerButton.add_click({
    $selectedScript = $tunerScripts.SelectedItem
    & $selectedScript
})
$restartButton.add_click({
        # Prompt the user for confirmation before restarting
    $result = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to restart this machine?", "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        # Restart the computer
        Restart-Computer -Force
    }
})
$initTweaksButton.add_Click({
    ApplyActions
})
$resetdefaultButton.add_Click({
    $result1 = [System.Windows.Forms.MessageBox]::Show("Are you sure you want reset windows back to its default settings? All preferences will be lost.", "RESET WINDOWS PREFERENCES", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

    if ($result1 -eq [System.Windows.Forms.DialogResult]::Yes) {
        # Reset Settings app
        Get-AppxPackage *Windows.ImmersiveControlPanel* | Reset-AppxPackage
    }
})

# Define actions for each node
$actions = @{
    "Disable Google Chrome Telemetry" = {
        # Action for Disable Google Chrome Telemetry
        $chromeRegPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"
        $telemetryValueName = "MetricsReportingEnabled"
        $telemetryValue = 0

        # Check if the registry path exists
        if (Test-Path $chromeRegPath) {
            # Set the telemetry value to disable telemetry
            Set-ItemProperty -Path $chromeRegPath -Name $telemetryValueName -Value $telemetryValue
            Write-Host "Google Chrome telemetry has been disabled."
        }
    }
    "Disable Mozilla Firefox Telemetry" = {
        # Action for Disable Mozilla Firefox Telemetry
        $ffRegPath = "HKLM:\SOFTWARE\Policies\Mozilla\Firefox"
        $telemetryValueName = "DisableTelemetry"
        $telemetryValue = 1

        # Check if the registry path exists
        if (Test-Path $ffRegPath) {
            $ Set the telemetry value to disable telemetry
            Set-ItemProperty -Path $ffRegPath -Name $telemetryValueName -Value $telemetryValue
            Write-Host "Mozilla Firefox telemetry has been disabled."
        } else {
            Write-Host "Mozilla Firefox registry path not found. Telemetry could not be disabled."

        }
    }
    "Enable Windows 10 File Explorer" = {
        # Action for Enable Windows 10 File Explorer
        New-ItemProperty -Path
        taskkill /F /IM explorer.exe
        start explorer
        Write-Host "Windows 10 File Explorer has been Enabled."
    }
    "Show hidden files, folders and drives in File Explorer" = {
        # Action for Show hidden files, folders, and drives in File Explorer
        New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -PropertyType DWORD -Force
        taskkill /F /IM explorer.exe
        start explorer
        Write-Host "Showing hidden files, folders, and drives in File Explorer."
    }
    "Show hidden file name extensions" = {
        # Action for Show hidden file name extensions
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Force 
        taskkill /F /IM explorer.exe
        start explorer
        Write-Host "Showing hidden file name extensions"
    }
    "Use Windows dark theme" = {
        # Action for Use Windows dark theme
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type Dword -Force 
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type Dword -Force 
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1 -Force 
        taskkill /F /IM explorer.exe
        start explorer
        Write-Host "Dark theme has been enabled for Windows and it's apps."
    }
    "Disable Snap Assist" = {
        # Action for Disable Snap Assist
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableSnapAssistFlyout" -Value 0
        Write-Host "Snap assist has been disabled."
    }
    "Disable Widgets" = {
        # Action for Disable Widgets
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "EnableWidgets" -Value 0
        Write-Host "Windows 11 widgets habe been disabled."
    }
    "Remove Desktop Stickers" = {
        # Action for Remove Desktop Stickers
        Set-ItemProperty -Path "HKLM:\Software\Microsoft\PolicyManager\current\device\Stickers" -Name "EnableStickers" -Value 0
        Write-Host "Desktop stickers have been removed."
    }
    "Hide Search icon on taskbar" = {
        # Action for Hide Search icon on taskbar
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "SearchboxTaskbarMode" -Value 0
        Write-Host "Search icon has been hidden."
    }
    "Hide Chat icon (Microsoft Teams) on taskbar" = {
        # Action for Hide Chat icon (Microsoft Teams) on taskbar
         Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDaIconPolicy" -Value 0
         Write-Host "Chat icon has been hidden."
    }
    "Hide Task view button on taskbar" = {
        # Action for Hide Task view button on taskbar
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0
        Write-Host "Task view button has been hidden."
    }
    "Hide most used apps in start menu" = {
        # Action for Hide most used apps in start menu
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackDocs" -Value 0
        Write-Host "Most used apps hidden."
    }
    "Show All apps on Start menu" = {
        # Action for Show All apps on Start menu
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_ShowAppsView" -Value 1
        Write-Host "Start menu default view set to show all apps in Windows 11."
    }
    "Enable Full Context Menus in Windows 11" = {
        # Action for Enable Full Context Menus in Windows 11
        New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Value "" -Force 
        taskkill /F /IM explorer.exe
        start explorer
        Write-Host "Full context menus have been enabled for Windows 11."
    }
    "Remove Fax Printer" = {
        # Action for Remove Fax Printer
        Remove-Printer -Name "Fax"
        Write-Host  "Fax Printer removed."
    }
    "Remove XPS Documents Writer" = {
        # Action for Remove XPS Documents Writer
        $printerName = "Microsoft XPS Document Writer"

        $timeoutSeconds = 10  # Adjust the timeout value as needed

        try {
            # Start a background job to remove the printer
            $job = Start-Job -ScriptBlock {
                param($name)
                Remove-Printer -Name $name
            } -ArgumentList $printerName

            # Wait for the job to complete or timeout
            Wait-Job -Job $job -Timeout $timeoutSeconds

            if ($job.State -eq "Running") {
                # If the job is still running after the timeout, terminate it
                Stop-Job -Job $job
                Remove-Job -Job $job -Force
                Write-Host "Printer removal timed out."
            } elseif ($job.State -eq "Completed") {
                Write-Host "Printer has been removed."
            }
        } catch {
            Write-Host "An error occurred while removing the printer: $_"
        }

    }
    "Uninstall OneDrive" = {
        # Action for Uninstall OneDrive
        # Check if OneDrive is installed
    if (Test-Path "$env:ProgramFiles\Microsoft OneDrive\onedrive.exe") {
        # Uninstall OneDrive
        & "$env:SYSTEMROOT\System32\OneDriveSetup.exe" /uninstall
        Write-Host "OneDrive has been uninstalled."
    } else {
        Write-Host "OneDrive is not installed."
    }
    }
    "Disable Game DVR feature" = {
        # Action for Disable Game DVR feature
        $packageName = "Microsoft.XboxGamingOverlay"
        # Check if the Game Bar package is installed
        if (Get-AppxPackage -Name $packageName) {
            # Uninstall the Game Bar package
            Remove-AppxPackage -Package $packageName -AllUsers
            Write-Host "Game Bar has been uninstalled."
        } else {
            Write-Host "Game Bar is not installed."
        }
    }
    "Disable Power Throttling" = {
        # Action for Disable Power Throttling 
        Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Power\PowerThrottling" -Name "PowerThrottlingOff" -Value 1
        Write-Host "Power Thottling has been disabled."    }
    "Disable Diagnostic data" = {
        # Action for Disable Diagnostic data
        Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
        Write-Host "Diagnostic Data has been disabled."
    }
    "Disable Connected User Experiences and Telemetry" = {
        # Action for Disable Connected User Experiences and Telemetry
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
        Write-Host "Connected user experiences and telemetry have been disabled."
    }
    "Disable Compatibility Telemetry" = {
        # Action for Disable Compatibility Telemetry 
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
        Write-Host "Compatibility telemetry has been disabled."
    }
    "Disable Location tracking" = {
        # Action for Disable Location tracking
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value 0
        Write-Host "Location tracking has been disabled."
    }
    "Disable Advertising ID for Relevent Ads" = {
        # Action for Disable Advertising ID for Relevant Ads
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
        Write-Host "Advertising ID for relevant ads has been disabled."
    }
    "Disable Feedback notifications" = {
        # Action for Disable Feedback notifications
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0
        Write-Host "Feedback notifications have been disabled."
    }
    "Disabled Suggested content in Settings app" = {
        # Action for Disabled Suggested content in Settings app
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -Value 0
        Write-Host "Suggested content in the Settings app has been disabled."
    }
    "Disable windows Hello Biometrics" ={
        # Action for Disable windows Hello Biometrics
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics" -Name "Enabled" -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics\FacialFeatures" -Name "Enabled" -Value 0
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Biometrics\Fingerprint" -Name "Enabled" -Value 0
        Write-Host "Windows Hello biometrics has been disabled."
    }
    "Disable Automatic Installation of apps" = {
        # Action for Disable Automatic Installation of apps
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Value 0
        Write-Host "Automatic installation of apps has been disabled."
    }
    "Disable Windows tips" = {
        # Action for Disable Windows tips
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications" -Value 0
        Write-Host "Windows tips have been disabled."
    }
    "Disable Tailored experiences" = {
        # Action for Disable Tailored experiences
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ContentDeliveryAllowed" -Value 0
        Write-Host "Tailored experiences have been disabled."
    }
    "It is recommeneded to enable Microsoft Windows Subsystem for Linux" = {
        # Action for enable Microsoft Windows Subsystem for Linux
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        Write-Host "Windows Subsystem for Linux has been enabled. Please restart your computer to apply the changes."
    }
}

# Define function to apply actions for selected nodes
function ApplyActions() {
    $selectedNodes = GetSelectedNodes($TreeView.Nodes)
    foreach ($node in $selectedNodes) {
        $action = $node.Text
        if ($actions.ContainsKey($action)) {
            Write-Host "Performing action: $action"
            $actions[$action].Invoke()
        }
    }
}

# Define function to get selected nodes recursively
function GetSelectedNodes($nodes) {
    $selectedNodes = @()
    foreach ($node in $nodes) {
        if ($node.Checked) {
            $selectedNodes += $node
        }
        $selectedNodes += GetSelectedNodes($node.Nodes)
    }
    return $selectedNodes
}


# Show the form 
$form.ShowDialog()