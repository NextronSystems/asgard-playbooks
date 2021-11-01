# OS Arch for Exe
$OsArch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture
$SysmonExe = "Sysmon.exe"
if ($OsArch -match "32-Bit"){ $SysmonExe = "Sysmon.exe" } else {$SysmonExe = "Sysmon64.exe"}

# Uninstall Sysmon if installed
if (Test-Path "$env:windir\SysmonDrv.sys") { iex("$SysmonExe -accepteula -u") }

# Sometimes the exe is removed by -u, sometimes not
if (Test-Path "$env:windir\$SysmonExe") {
    echo "Removing $SysmonExe."
    del "$env:windir\$SysmonExe" 
}
