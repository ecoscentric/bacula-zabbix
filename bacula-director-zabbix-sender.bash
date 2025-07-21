#!/bin/bash

# Import configuration file
source /etc/bacula/bacula-zabbix.conf

# Ensure we can write to logger
if ! [ -z "${scriptLogFile}" ]; then
  touch ${scriptLogFile} 2>&1 > /dev/null
  if [ $? -ne 0 ]; then 
    echo "ERROR: Cannot write to ${scriptLogFile}" | ${LOG} > /dev/null
    exit 1
  fi
fi

# Logfiles
LOG="tee -a ${scriptLogFile}"

# Ensure bconsole is available
if [ -z "${baculaConsole}" ]; then
  baculaConsole=`which bconsole`
  if [ -z "${baculaConsole}" ]; then
    echo "ERROR: bconsole ${baculaConsole} is not on the PATH" | ${LOG} > /dev/null
    exit 1
  fi
fi
if [ ! -x "${baculaConsole}" ]; then
  echo "ERROR: bconsole ${baculaConsole} is not executable" | ${LOG} > /dev/null
  exit 1
fi

# Ensure awk is available
AWK=`which awk`
if [ -z "${AWK}" ]; then
  echo "ERROR: awk is not on the PATH or installed" | ${LOG} > /dev/null
  exit 1
fi
GREP=`which grep`
if [ -z "${GREP}" ]; then
  echo "ERROR: grep is not on the PATH or installed" | ${LOG} > /dev/null
  exit 1
fi

# Run the 'status dir' command via bconsole and capture the output
output=$(echo "status dir" | ${baculaConsole})

# Counts the number of jobs waiting for media (label)
label_jobs=$(echo "$output" | ${GREP} -E -c "waiting for media|Cannot find any appendable volumes|is waiting for an appendable Volume")

# Extracts the number of jobs that are running (running=)
running_jobs=$(echo "$output" | ${AWK} '/running=/ { match($0, /running=*([0-9]+)/, a); print a[1]; exit; }')

# Counts the number of jobs that are running (Waiting status)
waiting_jobs=$(echo "$output" | ${GREP} -E -c "is waiting")

# Sends the values to Zabbix via zabbix_sender
result=$($zabbixSender -z $zabbixServer -c $zabbixAgentConfig -i - <<EOF
"${baculaHost}" bacula.label.jobs   $label_jobs
"${baculaHost}" bacula.running.jobs $running_jobs
"${baculaHost}" bacula.waiting.jobs $waiting_jobs
EOF
)

# Ensure that there were no failures
failures=$(echo "$result" | ${AWK} '/failed: / { match($0, /failed: *([0-9]+)/, a); print a[1]; exit; }')
if [ $failures -gt 0 ]; then
  # Report errors
  echo "ERROR: Failed to update Bacula Director items" | ${LOG} > /dev/null
  echo "$result" | ${LOG} > /dev/null
  exit 1
fi
