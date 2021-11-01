param( $config='sysmonconfig.xml' )

# Script Path
$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# OS Arch for Exe
$OsArch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
$SysmonExe = "Sysmon.exe"
if ($OsArch -match "32-Bit"){ $SysmonExe = "Sysmon.exe" } else {$SysmonExe = "Sysmon64.exe"}

# Update Sysmon config if Sysmon is installed
if (Test-Path "$env:windir\SysmonDrv.sys") {
	iex("$SysmonExe -accepteula -c $ScriptPath\$config")
}
else {
	throw 'Sysmon is not installed on this system' 
}

