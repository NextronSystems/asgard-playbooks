#!/bin/bash

# ASGARD Quarantine Script
#
# Nextron Systems, May 2024
# v1.1

# variables required by this script - if executed via ASGARD, you dont need to uncomment those
# ASGARD_IP=""
# ASGARD_CACHE_DIR="/var/lib/asgard2-agent/cache"

# Variable errors
function var_error() {
  echo "Error reading the required environment variables"
  exit 1
}
# Errors backup old rules
function backup_error() {
  echo "Error backing up the old rules to file $BACKUP"
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
    if ! iptables-save > "$BACKUP"; then
      backup_error
    fi
  else
    echo "Warning: Backup file $BACKUP already exists! No new backup will be created."
  fi

  echo "Printing current firewall rules for documentation ..."
  echo "---"
  iptables -S
  echo "---"

  # Delete old firewall rules
  echo "Deleting the old iptables rules ..."
  # Flush All Iptables Chains/Firewall rules
  iptables -t nat -F
  iptables -t mangle -F
  iptables -F
  iptables -X

  # Setting new firewall rules
  echo "Adding new iptables rules ..."
  iptables -A INPUT -p tcp --dport 53 -j ACCEPT
  iptables -A INPUT -p udp --dport 53 -j ACCEPT
  iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
  iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
  iptables -A INPUT -s "$ASGARD_IP" -j ACCEPT
  iptables -A OUTPUT -d "$ASGARD_IP" -j ACCEPT

  # Deny all traffic via policy
  iptables -P INPUT DROP
  iptables -P OUTPUT DROP
  iptables -P FORWARD DROP
    
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