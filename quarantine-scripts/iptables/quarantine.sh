#!/bin/bash

# ASGARD Quarantine Script
#
# Markus Meyer, Mai 2023
# v1.0

# Environment variables required by this script
# ASGARD_IP - IP address of ASGARD system
# ASGARD_CACHE_DIR - directory used for backups

# Variable errors
function var_error() {
  echo "Error reading the required environment variables"
  #EVENTCREATE /SO ASGARDAGENT /ID 406 /D "ASGARD-AGENT: Quarantine error reading the required environment variables" /T ERROR /L APPLICATION
  exit 1
}
# Errors backup old rules
function backup_error() {
  echo "Error backing up the old rules to file $BACKUP"
  #EVENTCREATE /SO ASGARDAGENT /ID 404 /D "ASGARD-AGENT: Quarantine backup of old rules failed" /T ERROR /L APPLICATION
  exit 17
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

function iptables_quarantine() {
  echo "iptables exists, assuming this is the correct tool and continue"

  # Variables
  # Firewall rule backup file
  BACKUP=$ASGARD_CACHE_DIR/iptables.bak

  # Backup old firewall rules
  echo "Backup existing firewall rules ..."
  echo "Checking if a backup already exists ..."
  if ! [[ -f $BACKUP ]]; then
    echo "Backing up current firewall rule set to $BACKUP"
    iptables-save > $BACKUP
    if ! [[ $? == 0 ]]; then
      backup_error
    fi
  else
    echo "Warning: Backup file $BACKUP already exists! No new backup will be created."
  fi

  # Delete old firewall rules
  echo "Deleting the old iptables rules ..."
  # Deny all traffic first
  iptables -P INPUT DROP
  iptables -P OUTPUT DROP
  iptables -P FORWARD DROP
  # Flush All Iptables Chains/Firewall rules
  iptables -F
  # Delete all Iptables Chains
  iptables -X
  # Flush all counters too
  iptables -Z
  # Flush and delete all nat and mangle
  iptables -t nat -F
  iptables -t nat -X
  iptables -t mangle -F
  iptables -t mangle -X
  iptables -t raw -F
  iptables -t raw -X

  # Setting new firewall rules
  echo "Adding new iptables rules ..."
  iptables -A INPUT -p tcp --dport 53 -j ACCEPT
  iptables -A INPUT -p udp --dport 53 -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
  iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
  iptables -A INPUT -s "$ASGARD_IP" -j ACCEPT
  iptables -A OUTPUT -d "$ASGARD_IP" -j ACCEPT

  success
}

# Check if Environment variables are present
echo "Checking environment variables"
if [[ -z "$ASGARD_IP" ]]; then
    var_error
fi
if [[ -z "$ASGARD_CACHE_DIR" ]]; then
    var_error
fi

# Check if iptables is running
echo "Checking if iptables exists"
if which iptables &>/dev/null; then
  iptables_quarantine
fi

tool_error