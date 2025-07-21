#!/bin/bash

# Import the configuration file
source /etc/bacula/bacula-zabbix.conf

# Ensure bconsole is available
if [ -z "${baculaConsole}" ]; then
  baculaConsole=`which bconsole`
  if [ -z "${baculaConsole}" ]; then
    echo ERROR: bconsole is not on the PATH
    exit 1
  fi
fi
if [ ! -x "${baculaConsole}" ]; then
  echo ERROR: bconsole ${baculaConsole} is not executable
  exit 1
fi

# Run the 'status dir' command via bconsole and capture the output
output=$(echo "status dir" | ${baculaConsole})

# Counts the number of jobs that are running (Running status)
running_jobs=$(echo "$output" | grep -E -c "is running")

# Captures the current time (time in 24h format)
current_hour=$(date +"%-H")

# Always send the number of running jobs to Zabbix
$zabbixSender -z $zabbixServer \
        -c $zabbixAgentConfig \
        -s "$baculaHost" \
        -k "bacula.running.jobs" \
        -o "$running_jobs" > /dev/null

# Checks if the time is between 9am and 11am or if the number of jobs running is 0
if [[ ($current_hour -ge 9 && $current_hour -le 11 && $running_jobs -ge 1) || $running_jobs -eq 0 ]]; then
    # Sends the alert to Zabbix
    $zabbixSender -z $zabbixServer \
        -c $zabbixAgentConfig \
        -s "$baculaHost" \
        -k "bacula.running.jobs.alert" \
        -o "$running_jobs" > /dev/null
fi
