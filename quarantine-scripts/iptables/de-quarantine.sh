#!/bin/bash

# ASGARD De-Quarantine Script
#
# Nextron Systems, May 2024
# v1.1

# variables required by this script - if executed via ASGARD, you dont need to uncomment those
# ASGARD_CACHE_DIR="/var/lib/asgard2-agent/cache"

# Variable errors
function var_error() {
  echo "Error reading the required environment variables"
  exit 1
}
# Restore failed
function restore_error() {
  echo "Error restoring the firewall rules from file"
  exit 1
}
# Moving backup file failed
function move_error() {
  echo "Error moving $BACKUP to $OLDBACKUP. Reruns of the quarantine playbook won't save a new firewall configuration."
  exit 1
}
# No firewall tool found
function tool_error() {
  echo "No tool for managing the system firewall found"
  exit 2
}
# Success
function success() {
  echo "Successfully restored iptables rules"
  exit 0
}

function iptables_dequarantine() {
  echo "iptables exists, assuming this is the correct tool and continue"

  # Variables
  # Firewall rule backup file
  BACKUP=$ASGARD_CACHE_DIR/iptables.bak
  OLDBACKUP=$ASGARD_CACHE_DIR/iptables.bak.done

  # Restoring old firewall rules
  echo "Checking if a backup already exists ..."
  if [[ -f $BACKUP ]]; then
    # Checking if the system even had firewall rules before
    filesize=$(stat -c%s "$BACKUP")

    if [[ $filesize -eq 0 ]]; then
      echo "Backup file empty. Restoring to defaults"
      iptables -P INPUT ACCEPT
      iptables -P OUTPUT ACCEPT
      iptables -P FORWARD ACCEPT

      iptables -F

      success
    else
      echo "Restoring firewall rule set from $BACKUP ..."
      if ! iptables-restore "$BACKUP"; then
        restore_error
      fi
    fi

    # Move firewall backup file
    echo "Move $BACKUP to $OLDBACKUP"
    if ! mv "$BACKUP" "$OLDBACKUP"; then
      move_error
    fi
    success
  else
    echo "No backup file found. Restoring to defaults"
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT

    iptables -F

    success
  fi
}

if [[ -z "$ASGARD_CACHE_DIR" ]]; then
    var_error
fi

# Check if iptables is running
echo "Checking if iptables exists"
if which iptables &>/dev/null; then
  iptables_dequarantine
fi

tool_error
