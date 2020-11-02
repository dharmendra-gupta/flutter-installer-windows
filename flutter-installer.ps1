$android_cli_tools_url = "https://dl.google.com/android/repository/commandlinetools-win-6858069_latest.zip"
$android_cli_tools_zip_path = "$pwd\commandlinetools-win-6858069_latest.zip"
$installation_path = "$((wmic OS GET SystemDrive /VALUE) -match 'SystemDrive=' -replace 'SystemDrive=', '')\src"
$android_sdk = "$installation_path\android-sdk"
New-Item $installation_path -ItemType "directory" -Force | Out-Null
New-Item $android_sdk -ItemType "directory" -Force | Out-Null
Write-Output "Created installation directories, installation path: $installation_path"

Import-Module BitsTransfer

# downloading 7zip for unzipping
Write-Output "Downloading 7zip for faster extraction. Please Wait..."
Start-BitsTransfer -Source "https://www.7-zip.org/a/7za920.zip" -Destination "7zip.zip" -Priority Foreground
Expand-Archive -LiteralPath "7zip.zip" -DestinationPath $pwd
Write-Output "Download Complete, 7zip for faster extraction"
# Download Section
Write-Output "Getting Flutter Latest Stable Version for Windows x64, Please Wait..."
$response = Invoke-WebRequest "https://storage.googleapis.com/flutter_infra/releases/releases_windows.json" -UseBasicParsing
$flutter_version = ($response.Content |  ConvertFrom-Json | Select -expand releases | Where {$_ -match "stable"} |  select channel, version, archive).Get(0).version
Write-Output "Flutter Latest Stable Version for Windows x64 found: $flutter_version."
$flutter_url = "https://storage.googleapis.com/flutter_infra/releases/stable/windows/flutter_windows_$flutter_version-stable.zip"
Write-Output "Downloading Flutter v$flutter_version, Please Wait..."
Start-BitsTransfer -Source $flutter_url -Destination "flutter_windows_$flutter_version-stable.zip" -Priority Foreground
Write-Output "Download Complete, Flutter v$flutter_version."
Write-Output "Downloading AdoptOpenJDK8 latest stable. Please Wait..."
(New-Object System.Net.WebClient).DownloadFile("https://api.adoptopenjdk.net/v3/binary/latest/8/ga/windows/x64/jdk/hotspot/normal/adoptopenjdk?project=jdk","$pwd\OpenJDK8U-jdk_x64_windows_hotspot.zip")
Write-Output "Download Complete AdoptOpenJDK8 Latest Stable., "
Write-Output "Downloading Android CLI tools, Please Wait..."
Start-BitsTransfer -Source $android_cli_tools_url -Destination $android_cli_tools_zip_path -Priority Foreground
Write-Output "Download Complete, Android CLI tools. "

# Extraction Section
Write-Output "Extracting Flutter v$flutter_version at $installation_path, Please Wait..."
Invoke-Command { & .\7za.exe x "flutter_windows_$flutter_version-stable.zip" -y -o"$installation_path" | Out-Null }
Write-Output "Extraction Complete, Flutter v$flutter_version. "
Write-Output "Extracting OpenJDK8 at $installation_path, Please Wait..."
Invoke-Command { & .\7za.exe x "OpenJDK8U-jdk_x64_windows_hotspot.zip" -y -o"$installation_path" | Out-Null }
Write-Output "Extraction Complete, OpenJDK8 at $installation_path. "
Write-Output "Extracting Android CLI tools at $installation_path, Please Wait..."
Invoke-Command { & .\7za.exe x $android_cli_tools_zip_path -y -o"$pwd" | Out-Null }
Rename-Item -LiteralPath "$pwd\cmdline-tools\" -NewName 'latest'
New-Item "$android_sdk\cmdline-tools" -ItemType "directory" -Force | Out-Null
Move-Item -LiteralPath "$pwd\latest" -Destination "$android_sdk\cmdline-tools"
Write-Output "Extraction Complete, Android CLI tools at $installation_path. "

# Configuration Section
Write-Output "Configuring Flutter and OpenJDK8..."
$java_home = (Get-ChildItem -LiteralPath $installation_path -Directory).FullName | Where {$_ -match "jdk"}
[System.Environment]::SetEnvironmentVariable('JAVA_HOME',$java_home,[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('JAVA_HOME',$java_home,[System.EnvironmentVariableTarget]::Process)
$path = [System.Environment]::GetEnvironmentVariable("PATH",[System.EnvironmentVariableTarget]::User) + "$java_home\bin;" + "$installation_path\flutter\bin;"
[System.Environment]::SetEnvironmentVariable('PATH',$path,[System.EnvironmentVariableTarget]::User)
$path_for_process = [System.Environment]::GetEnvironmentVariable("PATH",[System.EnvironmentVariableTarget]::Process)+ "$java_home\bin;" + "$installation_path\flutter\bin;"
[System.Environment]::SetEnvironmentVariable('PATH',$path_for_process,[System.EnvironmentVariableTarget]::Process)
Write-Output "OpenJDK8 and Flutter Configured."
Write-Output "Configuring Android SDK..."
[System.Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT', $android_sdk ,[System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('ANDROID_SDK_ROOT',$android_sdk,[System.EnvironmentVariableTarget]::Process)
Write-Output "Installing Android SDK, Please Wait..."
Write-Host "Please accept licenses when prompt..." -BackgroundColor Red
pause
$sdk_mgr_path = [System.Environment]::GetEnvironmentVariable("ANDROID_SDK_ROOT",[System.EnvironmentVariableTarget]::User) + "\cmdline-tools\latest\bin"
$a = Invoke-Command { &  $sdk_mgr_path\sdkmanager.bat --list | Where {$_ -match "build-tools"}}
$buildtools_latest = $a.Get($a.Length-1).split("|").Get(0).Trim()
$a = Invoke-Command { &  $sdk_mgr_path\sdkmanager.bat --list | Where {$_ -match "platforms" }}
$b = $a.ForEach({$_.split("|").Get(0).trim() -replace "platforms;android-", ""})  | sort { [int]($_ -replace '\D')}
$platforms_version = $b.Get($b.Length-1)
Invoke-Command { & $sdk_mgr_path\sdkmanager.bat "platform-tools" }
Invoke-Command { & $sdk_mgr_path\sdkmanager.bat "$buildtools_latest" }
Invoke-Command { & $sdk_mgr_path\sdkmanager.bat "platforms;android-$platforms_version"  }
Write-Output "Android SDK installed successfully at $env:ANDROID_SDK_ROOT"
Invoke-Command { &  flutter doctor --android-licenses }
Invoke-Command { &  flutter doctor }

# Clean up Section
Write-Output "Cleaning up temporary files..."
Remove-Item "$pwd\*.zip" -Force
Remove-Item "$pwd\*.txt" -Force
Remove-Item "$pwd\7*" -Force
Write-Output "Cleaning done."

Write-Host "Congratulations Minimal Flutter Setup Complete." -BackgroundColor Green