#!/bin/bash

# Import configuration file
source /etc/bacula/bacula-zabbix.conf

# Ensure bconsole is available
if [ -z "${baculaConsole}" ]; then
  baculaConsole=`which bconsole`
  if [ -z "${baculaConsole}" ]; then
    echo ERROR: bconsole ${baculaConsole} is not on the PATH
    exit 1
  fi
fi
if [ ! -x "${baculaConsole}" ]; then
  echo ERROR: bconsole ${baculaConsole} is not executable
  exit 1
fi

# Run the 'status dir' command via bconsole and capture the output
output=$(echo "status dir" | ${baculaConsole})

# Counts the number of jobs waiting for media (label)
label_jobs=$(echo "$output" | grep -E -c "waiting for media|Cannot find any appendable volumes|is waiting for an appendable Volume")

# Sends the value to Zabbix via zabbix_sender
$zabbixSender -z $zabbixServer -c $zabbixAgentConfig -s "$baculaHost" -k "bacula.label.jobs" -o "$label_jobs" > /dev/null
