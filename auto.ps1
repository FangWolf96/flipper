#Download and Run MSI package for Automated install
$uri = "https://armadyne.systems/logmein.msi"
$out = "c:\FireFoxInstaller.msi"
Invoke-WebRequest -uri $uri -OutFile $out
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $out /quiet /norestart /l c:\installlog.txt"