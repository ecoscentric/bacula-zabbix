#!/bin/bash

# wrapper for sending mail and running zabbix sender script

# just parse for each command line option
job_type="$1";        # %t
job_exit_status="$2"; # %e
client_name="$3";     # %c
job_name="$4";        # %n
job_level="$5";       # %l
recipients="$6";      # %r
job_id="$7";          # %i
sender="$8"           # %r or no-reply/automated address
transport="$9"        # P for postfix, B for bsmtp, N for none

if [ "$transport" == "B" ]; then
  # for bsmtp
  /usr/sbin/bsmtp -h localhost \
                  -f "${sender}" \
                  -s "Bacula: ${job_type} ${job_exit_status} of ${client_name} ${job_level}" \
                  ${recipients}
elif [ "$transport" == "P" ]; then
  # for postfix
  /usr/bin/mail -r "${sender}" \
                -s "Bacula: ${job_type} ${job_exit_status} of ${client_name} ${job_level}" \
                 "${recipients}"
elif [ "$transport" != "0" ]; then
  echo ERROR: Invalid transport ${transport}
fi

/var/spool/bacula/bacula-zabbix.bash $job_id;

exit;
