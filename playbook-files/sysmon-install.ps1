param ($config='sysmonconfig.xml')

# Script Path
$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# OS Arch for Exe
$OsArch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
$SysmonExe = "Sysmon.exe"
if ($OsArch -match "32-Bit"){ $SysmonExe = "Sysmon.exe" } else {$SysmonExe = "Sysmon64.exe"}

# Uninstall previous Sysmon version if installed
if (Test-Path "$env:windir\SysmonDrv.sys") { iex("$ScriptPath\$SysmonExe -accepteula -u") }

# Install Sysmon with config
iex("$ScriptPath\$SysmonExe -accepteula -i $config")
# Throw an error if the installation was not successful
if(!$?) {
	throw 'Error during Sysmon Installation.'
}
