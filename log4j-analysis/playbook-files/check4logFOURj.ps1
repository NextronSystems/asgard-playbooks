$date = Get-Date -Format "yyyy-MM-dd_HHmm"
$ErrorActionPreference= 'silentlycontinue'
$outdir = "results"
$out = -join($outdir, "\",$env:COMPUTERNAME,"_check4logFOURj_",$date)
mkdir $outdir 

handle | Select-String "log4j" | out-file "$out.win.openfiles"

foreach ($drive in gdr -PSProvider 'FileSystem' |  select -exp Root)
{
    dir -Recurse $drive |Select-Object FullName | Select-String -Pattern "log4j" | out-file "$out.win.fsfiles"
}

Get-WmiObject Win32_Process | Select-Object CommandLine | Select-String "log4j" | out-file "$out.win.processes"

foreach ($drive in gdr -PSProvider 'FileSystem' |  select -exp Root)
{
    gci $drive -rec -force -include *.jar | foreach {select-string "JndiLookup.class" $_} | select -exp Path | out-file "$out.win.jndiclass"
}
