$flutter_path = [System.Environment]::GetEnvironmentVariable("FLUTTER_HOME",[System.EnvironmentVariableTarget]::User) + "\bin"
Invoke-Command { &  $flutter_path\flutter doctor --android-licenses }
Invoke-Command { &  $flutter_path\flutter doctor }