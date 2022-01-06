$date = Get-Date -Format "yyyy-MM-dd_HHmm"
$ErrorActionPreference= 'silentlycontinue'
$PSDefaultParameterValues['out-file:width'] = 2147483647
$outdir = "results"
$out = -join($outdir, "\",$env:COMPUTERNAME,"_check4logFOURj_",$date)
mkdir $outdir 

handle | Select-String "log4j" | out-file -Encoding ASCII "$out.win.openfiles"

foreach ($drive in gdr -PSProvider 'FileSystem' |  select -exp Root)
{
    dir -Recurse $drive |Select-Object FullName | Select-String -Pattern "log4j" | out-file -Append -Encoding ASCII "$out.win.fsfiles"
}

Get-WmiObject Win32_Process | Select-Object CommandLine | Select-String "log4j" | out-file -Encoding ASCII "$out.win.processes"

foreach ($drive in gdr -PSProvider 'FileSystem' |  select -exp Root)
{
    gci $drive -rec -force -Include "*.jar","*.war","*.ear","*.zip" | foreach {select-string "JndiLookup.class" $_} | select -exp Path | out-file -Append -Encoding ASCII "$out.win.jndiclass"
}
