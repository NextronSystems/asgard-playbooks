#!/bin/bash

# ASGARD De-Quarantine Script
# 
# Markus Meyer, Mai 2023
# v1.0

# Environment variables required by this script
# ASGARD_CACHE_DIR - directory used for backups

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
  ECHO "Error moving $BACKUP to $OLDBACKUP. Reruns of the quarantine playbook won't save a new firewall configuration."
  exit 1
}
# No firewall tool found
function tool_error() {
  echo "No tool for managing the system firewall found"
  exit 2
}
# Success 
function success() {
  echo "Successfully configured Quarantine rules"
  #EVENTCREATE /SO ASGARDAGENT /ID 400 /D "ASGARD-AGENT: Successfully applied quarantine rules" /T SUCCESS /L APPLICATION
  exit 0
}


function iptables_dequarantine() {
  echo "iptables exists, assuming this is the correct tool and continue"

  # Variables
  # Firewall rule backup file
  BACKUP=$ASGARD_CACHE_DIR/iptables.bak
  OLDBACKUP=$ASGARD_CACHE_DIR/iptables.bak.old

  # Restoring old firewall rules
  echo "Checking if a backup already exists ..."
  if [[ -f $BACKUP ]]; then 
    echo "Restoring firewall rule set from $BACKUP ..."
    iptables-restore $BACKUP
    if ! [[ $? == 0 ]]; then
      restore_error
    fi
  fi

  # Move firewall backup file
  echo "Move $BACKUP to $OLDBACKUP"
  if ! mv $BACKUP $OLDBACKUP; then
    move_error
  fi

  success
}

# placeholders
ASGARD_CACHE_DIR="/root"

if [[ -z "$ASGARD_CACHE_DIR" ]]; then
    var_error
fi

# Check if iptables is running
echo "Checking if iptables exists"
if which iptables &>/dev/null; then
  iptables_dequarantine
fi

tool_error
