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