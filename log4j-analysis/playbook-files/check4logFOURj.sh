#!/bin/bash

outdir="results"
out="$outdir/$(hostname)_check4logFOURj_$(date +'%Y-%m-%d_%H%M')"

echo "$(date -Is) Start running checks"
[[ ! -e "${outdir}" ]] && mkdir "${outdir}"

if [[ -n $(which ps) ]]; then
    ps aux 2>/dev/null | egrep '[l]og4j' > "${out}.lnx.processes"
else
    echo "[ERROR] ps not found on $(hostname)" > "${out}.lnx.processes"
fi

if [[ -n $(which find) ]]; then
    find / -iname "log4j*" 2>/dev/null > "${out}.lnx.fsfiles"
else
    echo "[ERROR] find not found on $(hostname)" > "${out}.lnx.fsfiles"
fi

if [[ -n $(which lsof) ]]; then
    lsof 2>/dev/null | grep log4j > "${out}.lnx.openfiles"
else
    echo "[ERROR] lsof not found on $(hostname)" > "${out}.lnx.openfiles"
fi

grep -r --include *.[ewj]ar "JndiLookup.class" / 2>&1 | grep matches > "${out}.lnx.jndiclass"

echo "$(date -Is) Finished running checks. Results can be found at ${outdir}"
