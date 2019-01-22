# Set the size of the window
Function Set-WindowSize {
    Param([int]$x = $host.ui.rawui.windowsize.width,
        [int]$y = $host.ui.rawui.windowsize.heigth)

    $size = New-Object System.Management.Automation.Host.Size($x, $y)
    $host.ui.rawui.WindowSize = $size
}
Set-WindowSize 100 50

# Startup banner
Write-Host "
      _______________________________________________________________________________________
     |                                                                                       |
     |                   Profitbot Pro CPU Miner created by Bearlyhealz.                     |
     |                 :: Automated Mining Software for the Average Joe ::                   |
     |---------------------------------------------------------------------------------------|
     |                       Free to use, donations kindly accepted.                         |
     |                                                                                       |
     |               ETH Address: 0x32cd01077b6cc9cedb17feadfc24cce0a7b775f8                 |
     |                   BTC Address: 1EUFmXVcyWR85c57z9wtr5Q6KxyBbR2UUn                     |
     |                                                                                       |
     |         Credit for XMR-Stak goes to Fierce-UK at http://github.com/fireice-uk         |
     |                                                                                       |
     |                           https://www.profitbotpro.com                                |
     |_______________________________________________________________________________________|
" -ForegroundColor Cyan

# ************************************************************************************************************************************

# Pull in settings from file
$get_settings = Get-Content -Path "settings.conf" | Out-String | ConvertFrom-Json
$get_coin_settings = Get-Content -Path "coin_settings.conf" | Out-String | ConvertFrom-Json
$version = $get_settings.version
$Host.UI.RawUI.WindowTitle = "Profitbot Pro CPU Miner created by Bearlyhealz v$version"

#Pull in the computer name from Windows.
$pc = $env:ComputerName

# Set Log variables
$enable_log = $get_settings.enable_logging
$log_age = $get_settings.log_age

# Get the time and date
$TimeNow = Get-Date

# Set path parameter
$path = $get_settings.path
$update_url = $get_settings.update_url
$upgrade_url = "api.profitbotpro.com"

# ************************************************************************************************************************************

#Check folder structures, create missing folders.
if (Test-Path $path\$pc -PathType Container) {
    Write-Host "$TimeNow : Checking Folder Structure. (OK!)" -ForegroundColor green
}
else {
    Write-Host "$TimeNow : Creating Folder for $pc" -ForegroundColor yellow
    # Create folder structure for PC name.
    $fso = new-object -ComObject scripting.filesystemobject
    $fso.CreateFolder("$path\$pc")
}

# Create previous versions folder
if (Test-Path $path\Previous_Version -PathType Container) {
    Write-Host "$TimeNow : Checking previous version folder structure. (OK!)" -ForegroundColor green
}
else {
    Write-Host "$TimeNow : Creating folder for previous versions. (OK!)" -ForegroundColor yellow
    # Create folder structure for PC name.
    $fso = new-object -ComObject scripting.filesystemobject
    $fso.CreateFolder("$path\Previous_Version")
}

# Create backup folder
if (Test-Path $path\Backups -PathType Container) {
    Write-Host "$TimeNow : Checking backup folder structure. (OK!)" -ForegroundColor green
}
else {
    Write-Host "$TimeNow : Creating folder for backups.(OK!)" -ForegroundColor yellow
    # Create folder structure for PC name.
    $fso = new-object -ComObject scripting.filesystemobject
    $fso.CreateFolder("$path\Backups")
}

# Check for log file, if doesn't exist, create.
if ($enable_log -eq 'yes') {
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Host "$TimeNow : Log file and structure exists. (OK!)" -ForegroundColor Green
    }
    else {
        Write-Output "$TimeNow : Created log file for $pc" | Out-File $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
}
    
# ************************************************************************************************************************************

#Settings for Updater
$my_path = $get_settings.path
$settings_path = "$my_path\Previous_Version\settings.conf"
$coin_settings_path = "$my_path\Previous_Version\coin_settings.conf"

# If check for updates is enabled, pull in version information.
if ($get_settings.update_check -eq 'yes') {
    $check_update = Invoke-RestMethod -Uri "https://$upgrade_url" -Method Get
    $web_version = $check_update.version
    $installed_settings_version = $get_settings.version
    $installed_coin_settings_version = $get_coin_settings.version
    Write-Host "$TimeNow : Installed version: PBP v$installed_settings_version" -ForegroundColor Yellow
    Write-Host "$TimeNow :       Web version: PBP v$web_version" -ForegroundColor Yellow
    # check to see if running the newest version
    if ($web_version -gt $installed_settings_version) {
        Write-Host "$TimeNow : An update is available!" -ForegroundColor Cyan
        # If automatic updates are allowed.
        if ($get_settings.allow_automatic_updates -eq 'yes') {
            # If lockfile exists skip, otherwise download new profit_manager.ps1 file
            if (Test-Path $path\lockfile.lock) {
                $read_lockfile = Get-Content $path\lockfile.lock -First 1
                Write-Host "$TimeNow : Lockfile is owned by $read_lockfile."
                if($PC -ne $read_lockfile){
                    Write-Host "$TimeNow : Another worker has started the update process, waiting 30 seconds." -ForegroundColor Red
                    # Write to log
                    if ($enable_log -eq 'yes'){
                        # Write to the log
                        if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log){
                            Write-Output "$TimeNow : Pausing while worker $read_lockfile performs software upgrade." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                        }
                    }
                    Start-Sleep 30
                    ./profit_manager.ps1
                }
            }
            else {
                # Download updates from server
                $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/profit_manager.ps1"
                $output = "$path\profit_manager.ps1"
                Invoke-WebRequest -Uri $url -OutFile $output
                Start-Sleep 1
                #Restart Worker and pull in new profit_manager.ps1 before updating the rest of the files.
                Write-Host "$TimeNow : Creating lockfile.lock. Lockfile will be removed after update." -ForegroundColor Red
                Write-Output "$PC" | Out-File $path\lockfile.lock
                Write-Host "$TimeNow : Restarting worker before updating additional files." -ForegroundColor Green 
                ./profit_manager.ps1
            }
            if ($installed_settings_version -ne $installed_coin_settings_version) {
                Write-Host "$TimeNow : Version mismatch: Settings.conf v$installed_settings_version and coin_settings.conf $installed_coin_settings_version." -ForegroundColor Red
                Write-Host "$TimeNow : If automatic upadates are enabled, we will attempt to resolve the issue." -ForegroundColor Red
            }

            # Check if Backups folders exists, otherwise create
            if (Test-Path $path\Backups -PathType Container) {
                
                #Test if Previous Versions is empty
                $directoryInfo = Get-ChildItem $path\Previous_Version | Measure-Object
                if ($directoryInfo.Count -eq 0) {
                    Write-Host "$TimeNow : The are no files staged for backup. We will check on the next update cycle." -ForegroundColor Red
                }
                else {
                    Write-Host "$TimeNow : Adding previously backed up files to archive. (OK!)" -ForegroundColor Green
                    $source = "$path\Previous_Version"
                    $destination = "$path\Backups\backup_$(get-date -f 'yyyy-MM-dd_HH-mm_mm_ss').zip"
                    Add-Type -assembly "system.io.compression.filesystem"
                    [io.compression.zipfile]::CreateFromDirectory($Source, $destination) 
                }
            }
                 
            # Copy files from root to previous_version
            Write-Host "$TimeNow : Backing up your current files to Previous_Version." -ForegroundColor Yellow
            Copy-Item -Path $path\*.conf -Destination $path\Previous_Version -force
            Copy-Item -Path $path\*.ps1 -Destination $path\Previous_Version -force
            Write-Host "$TimeNow : Downloading updates...." -ForegroundColor Cyan
            
            # Download Additional Updates
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/settings.conf"
            $output = "$path\settings.conf"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/coin_settings.conf"
            $output = "$path\coin_settings.conf"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/config.txt"
            $output = "$path\config.txt"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/profit_manager.ps1"
            $output = "$path\profit_manager.ps1"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/Profitbot_Pro.ico"
            $output = "$path\Profitbot_Pro.ico"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/Profitbot_Pro_CPU.lnk"
            $output = "$path\Profitbot_Pro_CPU.lnk"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/Profitbot_Pro_CPU.bat"
            $output = "$path\Profitbot_Pro_CPU.bat"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1
            $url = "https://api.profitbotpro.com/releases/profitbot_pro_cpu/LICENSE"
            $output = "$path\LICENSE"
            Invoke-WebRequest -Uri $url -OutFile $output
            Start-Sleep 1

            # Remove old BAT file
            if (Test-Path $path\Start_mining.bat) {
                Remove-Item $path\Start_mining.bat
            }
            
            Write-Host "$TimeNow : Importing settings from coin_settings.conf." -ForegroundColor Yellow
            # Copy user's settings from original config files to new config files.
            $original_coin_settings = Get-Content $coin_settings_path -raw | ConvertFrom-Json
            $original_coin_settings.default_coin = $original_coin_settings.default_coin
            $original_coin_settings.my_coins = $original_coin_settings.my_coins
            $original_coin_settings.mining_params = $original_coin_settings.mining_params
            $original_coin_settings.version = $web_version
            $original_coin_settings | ConvertTo-Json -Depth 10 | set-content 'coin_settings.conf'
            Start-Sleep 2
            
            Write-Host "$TimeNow : Importing settings from settings.conf." -ForegroundColor Yellow
            $original_settings = Get-Content $settings_path -raw | ConvertFrom-Json
            $original_settings.path = $original_settings.path
            $original_settings.static_mode = $original_settings.static_mode
            $original_settings.update_check = $original_settings.update_check
            $original_settings.allow_automatic_updates = $original_settings.allow_automatic_updates
            $original_settings.update_url = $original_settings.update_url
            $original_settings.enable_logging = $original_settings.enable_logging
            $original_settings.log_age = $original_settings.log_age
            $original_settings.delete_cpu_txt = $original_settings.delete_cpu_txt
            $original_settings.mining_timer = $original_settings.mining_timer
            $original_settings.sleep_seconds = $original_settings.sleep_seconds   
            $original_settings.voice = $original_settings.voice
            $original_settings.version = $web_version
            if ($original_settings.stop_worker_delay -ne $null) {
                $original_settings.stop_worker_delay = $original_settings.stop_worker_delay
            }
            else {
                $original_settings | add-member -Name "stop_worker_delay" -value "5" -MemberType NoteProperty
            }
            if ($original_settings.enable_coin_data -ne $null) {
                $original_settings.enable_coin_data = $original_settings.enable_coin_data
            }
            else {
                $original_settings | add-member -Name "enable_coin_data" -value "yes" -MemberType NoteProperty
            }
            if ($original_settings.mine_cpu -ne $null) {
                $original_settings.mine_cpu = $original_settings.mine_cpu
            }
            else {
                $original_settings | add-member -Name "mine_cpu" -value "yes" -MemberType NoteProperty
            }
            if ($original_settings.mine_amd -ne $null) {
                $original_settings.mine_amd = $original_settings.mine_amd
            }
            else {
                $original_settings | add-member -Name "mine_amd" -value "yes" -MemberType NoteProperty
            }
            if ($original_settings.mine_nvidia -ne $null) {
                $original_settings.mine_nvidia = $original_settings.mine_nvidia
            }
            else {
                $original_settings | add-member -Name "mine_nvidia" -value "yes" -MemberType NoteProperty
            }
            if ($original_settings.rig_name -ne $null) {
                $original_settings.rig_name = $original_settings.rig_name
            }
            else {
                $original_settings | add-member -Name "rig_name" -value "" -MemberType NoteProperty
            }
            if ($original_settings.api_key -ne $null) {
                $original_settings.api_key = $original_settings.api_key
            }
            else {
                $original_settings | add-member -Name "api_key" -value "" -MemberType NoteProperty
            }
            if ($original_settings.jce_miner_threads -ne $null) {
                $original_settings.jce_miner_threads = $original_settings.jce_miner_threads
            }
            else {
                $original_settings | add-member -Name "jce_miner_threads" -value "2" -MemberType NoteProperty
            }
            if ($original_settings.jce_miner_threads -ne $null) {
                $original_settings.jce_miner_threads = $original_settings.jce_miner_threads
            }
            else {
                $original_settings | add-member -Name "jce_miner_threads" -value "2" -MemberType NoteProperty
            }
            $original_settings | ConvertTo-Json -Depth 10 | set-content 'settings.conf' 
            
            Write-Host "$TimeNow : Removing lockfile." -ForegroundColor White
            Remove-Item lockfile.lock
            Start-Sleep 2
            
            Write-Host "$TimeNow : Updates installed! Restarting worker." -ForegroundColor Green
            # Pull in settings from file
            $get_settings = Get-Content -Path "settings.conf" | Out-String | ConvertFrom-Json
            $get_coin_settings = Get-Content -Path "coin_settings.conf" | Out-String | ConvertFrom-Json
            $version = $get_settings.version
            ./profit_manager.ps1
        }
    }
    else {
        Write-Host "$TimeNow : You are running the newest version!" -ForegroundColor Green
    }
}

# ************************************************************************************************************************************

# Set a default coin in the event the application wants to mine a coin that you do not have a wallet for.
$default_coin = $get_coin_settings.default_coin

# Mining paramaters
$mine_minutes = $get_settings.mining_timer
$mine_seconds = $mine_seconds = [int]$get_settings.mining_timer * [int]60
$set_sleep = $get_settings.sleep_seconds
$enable_voice = $get_settings.voice
$static_mode = $get_settings.static_mode
$config = "config.txt"
$mine_cpu = $get_settings.mine_cpu
$mine_amd = $get_settings.mine_amd
$mine_nvidia = $get_settings.mine_nvidia
$thread_error_count = 0

# Set date/time
$Timenow = get-date

# Set the variation to auto (depends if pool supports)
$jce_miner_variation = $get_settings.jce_miner_variation
if (!$jce_miner_variation) {
    $jce_miner_variation = 15
}
else {
    $jce_miner_variation = $get_settings.jce_miner_variation
}

# Get rig name from settings file, if does not exist, use PC name.
$rigname = $get_settings.rig_name
if (!$rigname) {
    $rigname = $pc
}
else {
    $rigname = $get_settings.rig_name
}

# Get srb cache setting from settings file, if does not exist, set variable.
$clear_srb_cache = $get_settings.clear_srb_cache
if (!$clear_srb_cache) {
    $clear_srb_cache = "no"
}
else {
    $clear_srb_cache = $get_settings.clear_srb_cache
}

# Get srb cache setting from settings file, if does not exist, set variable.
$jce_miner_threads = $get_settings.jce_miner_threads
if (!$jce_miner_threads) {
    $jce_miner_threads = "2"
}
else {
    $jce_miner_threads = $get_settings.jce_miner_threads
}

# Get API Key from settings.
$apikey = $get_settings.api_key
if (!$apikey) {
}
else {
    $apikey = $get_settings.api_key
}

# Check if worker worker delay exists
if ($get_settings.stop_worker_delay -ne $null) {
    $stop_worker_delay = $get_settings.stop_worker_delay
}
else {
    $stop_worker_delay = 5
}


# Set mode variables for best coin
if ($static_mode -eq "yes") {
    $best_coin = $default_coin
}
else {
    #list all the coins you plan to mine.
    $Array = $get_coin_settings.my_coins
    # Pick the most profitable coin to mine from the top 10 list.
    Write-Host "$TimeNow : Connecting to Profitbot Pro API." -ForegroundColor Magenta
    Write-Host "$TimeNow : Retreiving list of coins." -ForegroundColor Magenta
    $get_coin = Invoke-RestMethod -Uri "https://$update_url" -Method Get 
    
    # Cycle through the API's top list of coins, report error & restart if null.
    Try {
        if ($get_coin.symbol[0] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[0]
            $top_list_position = 1
        }
        elseif ($get_coin.symbol[1] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[1]
            $top_list_position = 2
        }
        elseif ($get_coin.symbol[2] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[2]
            $top_list_position = 3
        }
        elseif ($get_coin.symbol[3] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[3]
            $top_list_position = 4
        }
        elseif ($get_coin.symbol[4] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[4]
            $top_list_position = 5
        }
        elseif ($get_coin.symbol[5] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[5]
            $top_list_position = 6
        }
        elseif ($get_coin.symbol[6] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[6]
            $top_list_position = 7
        }
        elseif ($get_coin.symbol[7] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[7]
            $top_list_position = 8
        }
        elseif ($get_coin.symbol[8] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[8]
            $top_list_position = 9
        }
        elseif ($get_coin.symbol[9] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[9]
            $top_list_position = 10
        }
        elseif ($get_coin.symbol[10] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[10]
            $top_list_position = 11
        }
        elseif ($get_coin.symbol[11] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[11]
            $top_list_position = 12
        }
        elseif ($get_coin.symbol[12] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[12]
            $top_list_position = 13
        }
        elseif ($get_coin.symbol[13] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[13]
            $top_list_position = 14
        }
        elseif ($get_coin.symbol[14] -in $Array.ToUpper()) {
            $best_coin = $get_coin.symbol[14]
            $top_list_position = 15
        }
        else {
            $best_coin = $get_coin_settings.default_coin
            $top_list_position = 1000
        }
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
        Write-Host "$TimeNow : Waiting 10 seconds, then restarting the worker. API data is likely missing." -ForegroundColor Yellow
        Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs."
        Start-Sleep 10
        # Write to the log.
        if ($enable_log -eq 'yes') {
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
        }
        # Clear all variables
        Remove-Variable * -ErrorAction SilentlyContinue
        ./profit_manager.ps1
    }
}
# Establish the date and time
$TimeStart = Get-Date
$TimeNow = Get-Date

# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : Cleaning up old backup files, if older than $log_age days." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}

# Clean up log and backup files older than x
$DatetoDelete = $TimeNow.AddDays(-$log_age)
Get-ChildItem $path\$pc\*.log | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item
Get-ChildItem $path\Backups\*.zip | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item

# Check worker mining mode. Set variables accordingly.
if ($static_mode -eq 'yes') {
    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Worker is set to static mode." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
    Write-Host "$TimeNow : Worker is set to static mode, configured to mine $best_coin." -ForegroundColor red  
}
else {
    #Check if the best coin to mine is in your list.
    if ($best_coin -in $Array.ToUpper()) {
        if($top_list_position -eq 1000){
            Write-Host "$TimeNow : No top list coint match. You will be mining your default coin." -ForegroundColor Magenta  
        }
        else {
            Write-Host "$TimeNow : You will be mining coin number $top_list_position in the API list." -ForegroundColor Magenta  
        }
        
    }
    else {
        Write-Host "$TimeNow : The best coin to mine is $best_coin but it's not in your list" -ForegroundColor red
        $timenow = Get-Date
        # Write to log.
        if ($enable_log -eq 'yes') {
            if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                Write-Output "$TimeNow : Switched mining to $default_coin, $best_coin is not in your list" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
            }
        }
    }
}

Write-Host "$TimeNow : Activating Worker on [$rigname]"

# Get information about the GPU, print to screen
Write-Host "$TimeNow : This system has the following GPU's:" -ForegroundColor Yellow
foreach ($gpu in Get-WmiObject Win32_VideoController) {
    if ($gpu.Description -notlike "*Intel*" -and $gpu.Description -notlike "*Microsoft*") {Write-Host "                       -"$gpu.Description}
}
Write-Host "$TimeNow : Configured to Mine: $best_coin <--------" -ForegroundColor Magenta

# Pull in worker config information from coin_settings.conf
$symbol = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty symbol
$miner_type = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty software
$diff_config = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty static_param
$algo = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty algo
$pool = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty pool
$wallet = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty wallet
$amd_config_file = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty amd_config_file
$payment_id = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty payment_id


if ($miner_type -eq 'jce_cn_cpu_miner64') {
    $jce_miner_variation = $get_coin_settings.mining_params | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty jce_miner_variation 
}
# Check if wallet param exists, if not then display error
if ($symbol -ne $null) {
}
else {


    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Configuration error! Coin list does not match wallet list." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
    [console]::beep(2000, 500)
    Write-Host "$TimeNow : ERROR! You are setup to mine $best_coin, but there's no wallet config." -ForegroundColor Red
    [console]::beep(2000, 500)
    Write-Host "$TimeNow : You can leave this window open while adding the parameters." -ForegroundColor Red
    [console]::beep(2000, 500)
    Write-Host "$TimeNow : When you are done, hit enter." -ForegroundColor Cyan
    Write-Host "  "
    pause
    # Clear all variables
    Remove-Variable * -ErrorAction SilentlyContinue
    #The miner will reload the Powershell file. You can make changes while it's running, and they will be applied on reload.
    .\profit_manager.ps1
}
Write-Host "$TimeNow : Establishing connection to:" $pool
Write-Host "$TimeNow : Switching Algo to:" $Algo
Write-Host "$TimeNow : Authorizing inbound funds to Wallet:" ($wallet.SubString(0,35) + "...") -ForegroundColor Cyan

# Verify Diff config file is present
If (Test-Path -Path $Path\$pc\$symbol.conf) {
    $set_diff_config = "yes"
    $import_diff_value = Get-Content -Path "$path\$pc\$symbol.conf" | Out-String | ConvertFrom-Json
    $set_diff_value = $import_diff_value.difficulty
    Write-Host "$TimeNow : Diffuculty config for $symbol is present, setting to $set_diff_value" -ForegroundColor Yellow
}
else { 
    Write-Host "$TimeNow : No diffuculty config for $symbol is present, skipping this time." -ForegroundColor red
    $set_diff_config = "no"
}
# Check for CPU.txt file, delete if exists, will create a new one once mining app launches.
if (Test-Path $path\$pc\cpu.txt) {
    
    if ($get_settings.delete_cpu_txt -eq 'yes') {
        Write-Host "$TimeNow : Purging old cpu.txt file (OK!)" -ForegroundColor Green
        Remove-Item $path\$pc\cpu.txt
    } 
}
else {
    Write-Host "$TimeNow : Could not find cpu.txt file, there is nothing to delete. (OK!)" -ForegroundColor Green
}
# Check for pools.txt file, delete if exists, will create a new one once mining app launches.
if (Test-Path $path\$pc\pools.txt) {
    Write-Host "$TimeNow : Purging old Pools.txt file (OK!)" -ForegroundColor Green

    del $path\$pc\pools.txt
}
else {
    Write-Host "$TimeNow : Could not find Pools.txt file, there is nothing to delete. (OK!)" -ForegroundColor Green
}
# These are the default apps used for mining. Updated software can be found on Github.

if ($miner_type -eq 'jce_cn_cpu_miner64') {
    Set-Variable -Name "miner_app" -Value "$path\Miner-JCE\jce_cn_cpu_miner64.exe"
}

Write-Host "$TimeNow : Setting Mining Application to $miner_type"

# This section establishes a fixed diff for each worker. The format depends on which pool you connect to.
if ($set_diff_config -eq 'yes') {
    if ($diff_config -eq '1') {
        Set-Variable -Name "fixed_diff" -Value "+$set_diff_value"
    }
    if ($diff_config -eq '2') {
        Set-Variable -Name "fixed_diff" -Value ".$set_diff_value"
    }
    if ($diff_config -eq '3') {
        Set-Variable -Name "fixed_diff" -Value ".$pc+$set_diff_value"
    }
    if ($diff_config -eq '4') {
        Set-Variable -Name "fixed_diff" -Value ".$pc"
    }
    if ($diff_config -eq '5') {
        Set-Variable -Name "fixed_diff" -Value ""
    }
    if ($diff_config -eq '6') {
        Set-Variable -Name "fixed_diff" -Value ".$payment_id"
    }
}
else {
    Set-Variable -Name "fixed_diff" -Value ""
}

# If previous worker is running, kill the process.

# List of mining software processes
$worker_array = @("jce_cn_cpu_miner64")

# Loop through each miner process, and kill the one that's running
foreach ($element in $worker_array) {

    $worker_running = Get-Process $element -ErrorAction SilentlyContinue
    if ($worker_running) {
        # Write to the log.
        if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : $element is already running, attempting to stop." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
        }
        Write-Host "$TimeNow : Worker already running, stopping process." -ForegroundColor Red
        # try gracefully first
        $worker_running.CloseMainWindow() | out-null
        # kill after five seconds
        Write-Host "$TimeNow : Pausing for $stop_worker_delay seconds while worker shuts down." -ForegroundColor Yellow
        
            Start-Sleep $stop_worker_delay

        if (!$worker_running.HasExited) {
            $worker_running | Stop-Process -Force | out-null
        }
    }

    Remove-Variable worker_running
}


if ($miner_type -eq 'jce_cn_cpu_miner64') {
    
    # Configure the attributes for the mining software.
    $worker_settings = "--auto --any --forever --keepalive --variation $jce_miner_variation --low -o $pool -u $wallet$fixed_diff -p $rigname --mport 8081 -t $jce_miner_threads --low"
}


Write-Host "$TimeNow : Starting $miner_type in another window."

# Edit for adding static mining
if ($static_mode -eq 'yes') {
    $best_coin_check = $default_coin
}
else {
    # Check to see if this is the best coin to mine
    $get_coin_check = Invoke-RestMethod -Uri "https://$update_url" -Method Get
    if ($get_coin_check.symbol[0] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[0]
    }
    elseif ($get_coin_check.symbol[1] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[1]
    }
    elseif ($get_coin_check.symbol[2] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[2]
    }
    elseif ($get_coin_check.symbol[3] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[3]
    }
    elseif ($get_coin_check.symbol[4] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[4]
    }
    elseif ($get_coin_check.symbol[5] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[5]
    }
    elseif ($get_coin_check.symbol[6] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[6]
    }
    elseif ($get_coin_check.symbol[7] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[7]
    }
    elseif ($get_coin_check.symbol[8] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[8]
    }
    elseif ($get_coin_check.symbol[9] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[9]
    }
    elseif ($get_coin_check.symbol[10] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[10]
    }
    elseif ($get_coin_check.symbol[11] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[11]
    }
    elseif ($get_coin_check.symbol[12] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[12]
    }
    elseif ($get_coin_check.symbol[13] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[13]
    }
    elseif ($get_coin_check.symbol[14] -in $Array.ToUpper()) {
        $best_coin_check = $get_coin_check.symbol[14]
    }
    else {
        $best_coin_check = $get_coin_settings.default_coin
        $not_in_list = "yes"
    }
}
$timenow = Get-Date
# Write to log.
if ($enable_log -eq 'yes') {
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Configured to mine $best_coin." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
}
# Start the mining software, wait for the process to begin.
# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : Starting the worker $miner_type." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}
start-process -FilePath $miner_app -args $worker_settings -WindowStyle Minimized
Start-Sleep -Seconds 2
$TimeNow = Get-Date
$check_worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
if ($check_worker_running -eq $null) {
    Do {
        Write-Host "$TimeNow : Waiting for worker to start...." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        $check_worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
    } until($check_worker_running -eq $True)  
}
# Mine for established time, then look to see if there's a new coin.
$TimeEnd = $timeStart.addminutes($mine_minutes)
Write-Host " "
Write-Host "$TimeNow : Started Worker" -ForegroundColor Green
if ($static_mode -eq 'no') {
    Write-Host "$TimeNow : Check Profitiability again: $TimeEnd" -ForegroundColor Green
}
# If we are mining the default coin, pause for 5 minutes.
if ($not_in_list -eq 'yes') {
    $TimeNow = Get-Date
    Write-Host "$TimeNow : Worker is set to mine default coin: $best_coin." -ForegroundColor cyan
}
Write-Host " "
# Begin a loop to check if the current coin is the best coin to mine. If not, restart the app and switchin coins.
Do { 
    if ($TimeNow -ge $TimeEnd) {
        
        $TimeNow = Get-Date
        # Edit for adding static mining

        if ($static_mode -eq "yes") {
            $best_coin_check = $default_coin
        }
        else {
            # Check if worker can talk to the API, if not, wait 10 seconds.
            try {
                $get_coin_check = Invoke-RestMethod -Uri "https://$update_url" -Method Get
                if ($get_coin_check.symbol[0] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[0]
                }
                elseif ($get_coin_check.symbol[1] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[1]
                }
                elseif ($get_coin_check.symbol[2] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[2]
                }
                elseif ($get_coin_check.symbol[3] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[3]
                }
                elseif ($get_coin_check.symbol[4] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[4]
                }
                elseif ($get_coin_check.symbol[5] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[5]
                }
                elseif ($get_coin_check.symbol[6] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[6]
                }
                elseif ($get_coin_check.symbol[7] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[7]
                }
                elseif ($get_coin_check.symbol[8] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[8]
                }
                elseif ($get_coin_check.symbol[9] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[9]
                }
                elseif ($get_coin_check.symbol[10] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[10]
                }
                elseif ($get_coin_check.symbol[11] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[11]
                }
                elseif ($get_coin_check.symbol[12] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[12]
                }
                elseif ($get_coin_check.symbol[13] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[13]
                }
                elseif ($get_coin_check.symbol[14] -in $Array.ToUpper()) {
                    $best_coin_check = $get_coin_check.symbol[14]
                }
                else {
                    $best_coin_check = $get_coin_settings.default_coin
                }
            }
            catch {
                Write-Host "$TimeNow : Cannot read from Profitbot Pro API, restarting." -ForegroundColor Red
                Start-Sleep 3
                
                # Clear all variables
                Remove-Variable * -ErrorAction SilentlyContinue
                ./profit_manager.ps1
                
            }
             
            Write-Host "$TimeNow : Checking Coin Profitability." -ForegroundColor Yellow
            Write-Host "$TimeNow : Best Coin to Mine:" $best_coin_check -ForegroundColor Magenta
            if ($best_coin -eq $best_coin_check) {
                Write-Host "$TimeNow : Sleeping for another" $set_sleep "seconds, then checking again."
            }
        }
    }
    else {
        if ($static_mode -eq "no") {
            Write-Host "$TimeNow : Currently mining $best_coin. Checking profits again: $TimeEnd." -ForegroundColor White
            Start-Sleep -Seconds 10
        }
    }
    # Check if worker url is working, then get the current hashrate from mining software
    $TimeNow = Get-Date
    Start-Sleep -Seconds 5
    $statusCode = Invoke-WebRequest http://127.0.0.1:8081 | % {$_.StatusCode}
    If ($statusCode -eq 200) {
    }
    Else {
        Write-Host "$TimeNow : Worker is taking a little longer than expected to start." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
    
        try {
            $statusCode = Invoke-WebRequest http://127.0.0.1:8081 | % {$_.StatusCode}
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
            Write-Host "$TimeNow : If Worker does not have its HTTP API enabled, we cannot get the hashrate." -ForegroundColor Yellow
            Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs." -ForegroundColor Yellow
            # Write to the log.
            if ($enable_log -eq 'yes') {
                if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                }
            }
            Start-Sleep 5
            # Clear all variables
            Remove-Variable * -ErrorAction SilentlyContinue
            ./profit_manager.ps1
        }   
    

    # Refresh coin values
    $get_coin = Invoke-RestMethod -Uri "https://$update_url" -Method Get 
    # Set coin variables from API
    $symbol = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty symbol
    $coin_name = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty coin_name
    $base_coin_price = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty base_coin_price
    $base_coin_symbol = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty base_coin_symbol
    $coin_usd = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty coin_usd
    $last_reward = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty last_reward
    $difficulty = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty difficulty
    $coin_units = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty coin_units
    $last_updated = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty last_updated
    $satoshi = $get_coin | Where-Object { $_.Symbol -like $best_coin } | Select-Object -ExpandProperty satoshi
    
    # Verify the API json is not empty  -----not currently used in code
    $json_count = $get_coin | Measure-Object | Select-Object Count
   
    # Get the current date and time.
    $TimeNow = Get-Date

    

    if($miner_type -eq 'jce_cn_cpu_miner64') {
        Try {
            $get_hashrate = Invoke-RestMethod -Uri "http://127.0.0.1:8081" -Method Get
            $worker_hashrate = $get_hashrate.hashrate.total[0]
            $my_accepted_shares = $get_hashrate.result.shares
            $total_shares = $get_hashrate.result.shares
            $my_rejected_shares = 0
        }
        Catch {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
            Write-Host "$TimeNow : If Worker does not have its HTTP API enabled, we cannot get the hashrate." -ForegroundColor Yellow
            Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs." -ForegroundColor Yellow
            # Write to the log.
            if ($enable_log -eq 'yes') {
                if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                }
            }
            Start-Sleep 5
            # Clear all variables
            Remove-Variable * -ErrorAction SilentlyContinue
            ./profit_manager.ps1
        }
    }

    # Calculate the worker hashrate and accepted shares.
    $suggested_diff = [math]::Round($worker_hashrate * 30)
    if ($worker_hashrate -match "[0-9]" -and $worker_hashrate -ne "0" -and $null -ne $worker_hashrate) {

        
        # If coin value is 0.00, set to min LTC value
        if($coin_usd -eq 0){
            $coin_usd = 0.00000054
        }

        # Print the worker hashrate and accepted share to screen.
        Write-Host "$TimeNow : Worker hashrate:" $worker_hashrate "H/s, $best_coin Accepted Shares: $my_accepted_shares" -ForegroundColor Cyan
        if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
            Write-Output "$TimeNow : Total Worker Hashrate - $worker_hashrate H/s" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
        }
        if ($get_settings.enable_coin_data -eq 'yes') {
            # Caclulate estimated shares over 24 hours if not null
            Try {
                $reward_24H = [math]::round(($worker_hashRate / $difficulty * ($last_reward / $coin_units) * 86400), 8)
            }
            Catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
                Write-Host "$TimeNow : Waiting 10 seconds, then restarting the worker. (Reward 24H Error)" -ForegroundColor Yellow
                Write-Host "$TimeNow : Restarting the worker now. If this happens again, please refer to logs."
                Start-Sleep 10
                # Write to the log.
                if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                    Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                    Write-Output "$TimeNow : Extra Error info: $worker_hashrate $difficulty $last_reward $coin_units ." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                }
                # Clear all variables
                Remove-Variable * -ErrorAction SilentlyContinue
                ./profit_manager.ps1
            }           
            # Hotfix for LOKI
            if ($symbol -eq 'LOKI') {
                $reward_24H = ($reward_24H / 2)
            }

            # Caclulate daily profit in USD if not null
            Try {
                $earned_24H = [math]::round([float]($reward_24H * [float]$coin_usd), 8)
            }
            Catch {
                $ErrorMessage = $_.Exception.Message
                $FailedItem = $_.Exception.ItemName
                Write-Host "$TimeNow : Worker has discovered an error:" $ErrorMessage -ForegroundColor Cyan
                Write-Host "$TimeNow : Waiting 10 seconds, then restarting the worker. (Earned 24H Error)" -ForegroundColor Yellow
                Write-Host "$TimeNow : Occasionally, the worker will query the API data during a db refresh, restarting will fix this error."
                Start-Sleep 10
                # Write to the log.
                if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
                    Write-Output "$TimeNow : Error encountered - $errormessage Restarting worker." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
                }
                # Clear all variables
                Remove-Variable * -ErrorAction SilentlyContinue
                ./profit_manager.ps1
            }
            Write-Host "$TimeNow : API data last refreshed: $last_updated (UTC)." -ForegroundColor White
            Write-Host "$TimeNow : Network Difficulty: $difficulty." $symbol ("$" + $coin_usd + " USD") ("(" + $satoshi + " " + $base_coin_symbol + ")") -ForegroundColor DarkCyan
            Write-Host "$TimeNow : Estimated 24H Reward:" $reward_24H "Estimated 24H Earnings:"("$" + $earned_24H.tostring("00.00")) -ForegroundColor Green
        }
        if ($static_mode -eq 'yes') {
            Write-Host "$TimeNow : Profitbot Pro is set to static mode. Profit Mananager is disabled." -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "$TimeNow : Waiting on worker to display hashrate." -ForegroundColor Yellow
    }

    # Variables to send to Miner API
    if ($static_mode -eq 'yes') {
        $mining_mode = "Static"
    }
    else{
        $mining_mode = "Profit"
    }

    # Communicate mining status with the Miner API if API_Key is not null.
    if (!$apikey) {
        
    }
    else {
        $submit_mining_results = Invoke-RestMethod -Uri "https://www.profitbotpro.com/api/v1/miners.cfm?api_key=$apikey&rig_name=$rigname&mining_mode=$mining_mode&symbol=$symbol&hashrate=$worker_hashRate&reward_24h=$reward_24H&earned_24h=$earned_24H&accepted_shares=$my_accepted_shares&rejected_shares=$my_rejected_shares&algo=$algo&miner_type=$miner_type" -Method Post
    }
    
    
    # Clear variables
    Remove-Variable count -ErrorAction SilentlyContinue
    Remove-Variable start_thread -ErrorAction SilentlyContinue
    Remove-Variable thread_count -ErrorAction SilentlyContinue
    Remove-Variable a -ErrorAction SilentlyContinue
    Remove-Variable i -ErrorAction SilentlyContinue
    Remove-Variable get_coin -ErrorAction SilentlyContinue
    Remove-Variable last_updated -ErrorAction SilentlyContinue
    Start-Sleep -Seconds $set_sleep
}
While ($best_coin -eq $best_coin_check)

# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : Profit has changed, switcing to $best_coin_check." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}
if ($enable_voice -eq 'yes') {
    # Speak the symbol of the coin when switching.
    $speak_coin = ("$best_coin_check" -split "([a-z0-9]{1})"  | Where-Object { $_.length -ne 0 }) -join " "
    Add-Type -AssemblyName System.Speech
    $synthesizer = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
    $synthesizer.Speak("$pc is switching to $speak_coin") | Out-Null
}
If ( Test-Path -Path $Path\$pc\$symbol.conf ) {
    Write-Host "$TimeNow : Diffuculty config for $symbol is present, no need to create a new config." -ForegroundColor Green
}
else {
    Write-Host "$TimeNow : Creating difficulty config file for $symbol on this worker." -ForegroundColor Green
    Write-Host "$TimeNow : We've calulated the fixed difficulty to be $suggested_diff ." -ForegroundColor Green
    
    # Create Diff/Hashrate objects in json
    [hashtable]$build_json = @{}
    $build_json.difficulty = "$suggested_diff"
    $build_json.worker_hashrate = "$worker_hashrate"
    $build_json | convertto-json | Set-Content "$path\$pc\$symbol.conf"
}
if ($static_mode -eq 'no') {
    Write-Host "$TimeNow : Profitability has changed, switching coins now." -ForegroundColor yellow
}
else {
    Write-Host "$TimeNow : Mining $best_coin for another $mine_minutes minutes." -ForegroundColor yellow
    Start-Sleep -Seconds $mine_seconds
}
Write-Host "$TimeNow : Shutting down worker, please wait....."   -ForegroundColor yellow

# Mining statistics for log file.
$Time_End = GET-DATE
$timespan = $Time_End - $TimeStart
$mined_minutes = $timespan.minutes
$mined_hours = $timespan.hours

# Write to log
if ($enable_log -eq 'yes') {
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Finished mining $best_coin, switching to $best_coin_check" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
        Write-Output "$TimeNow : Mined $best_coin for: $mined_hours : $mined_minutes minutes" | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
        Write-Output "$TimeNow : $best_coin worker hashrate: $worker_hashrate H/s, Accepted Shares: $my_accepted_shares"  | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
}
# Wait for the executable to stop before continuing.
$worker_running = Get-Process $miner_type -ErrorAction SilentlyContinue
if ($worker_running) {
    # Write to the log.
    if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
        Write-Output "$TimeNow : Attempting to stop $miner_type for coin-switch." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
    }
    Write-Host "$TimeNow : Stopping Worker process." -ForegroundColor Red
    # try gracefully first
    $worker_running.CloseMainWindow() | Out-Null
    # kill after five seconds
    Write-Host "$TimeNow : Worker already running, stopping process." -ForegroundColor Yellow
    Sleep $stop_worker_delay
    if (!$worker_running.HasExited) {
        Write-Host "$TimeNow : Worker process has not halted, forcing process to stop." -ForegroundColor Red
        $worker_running | Stop-Process -Force | Out-Null
    }
}
Write-Host "$TimeNow : Successfully stopped miner process, reloading." -ForegroundColor Yellow

# Write to the log.
if (Test-Path $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log) {
    Write-Output "$TimeNow : The worker is now restarting." | Out-File  -append $path\$pc\$pc"_"$(get-date -f yyyy-MM-dd).log
}

# Clear all variables
Remove-Variable * -ErrorAction SilentlyContinue

# Reload the worker.
.\profit_manager.ps1