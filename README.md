# Zabbix monitoring of Bacula's backup jobs and its processes

## Overview

This project is composed of a Zabbix template, a configuration template and bash scripts. The Bacula template is attached to hosts in Zabbix that are backed up by Bacula, defining the Items, Tiggers, Alerts and Graphs for each host. The bash scripts are set up on the host running the Bacula Director and are called by Bacula on completion of a job and by cron to periodically update Bacula's status to push key values to the Zabbix server. Updated values are obtained from Bacula's database (PostgreSQL or MySQL/MariaDB) or read via bconsole from the Bacula Catalog, and sent indirectly through a Proxy or directly to the Zabbix Server. This material was originally created using Bacula 7.0.5 and Zabbix 2.4.5 in a GNU/Linux CentOS 7 operational system, but has been updated for Bacula 9.6.x and Zabbix 7.4.x on GNU/Linux Debian 11.

Original from [germanodlf/bacula-zabbix](https://github.com/germanodlf/bacula-zabbix)  
Updated from [samuk10/bacula-zabbix](https://github.com/samuk10/bacula-zabbix)

Tested with:
- Bacula 9.4.x with PostgreSQL 11 backend, Zabbix 4.0.x on GNU/Linux Debian 9
- Bacula 13.0.x with PostgreSQL 14 backend, Zabbix 6.4.x on GNU/Linux Ubuntu 22.04
- Bacula 9.6.x with MariaDB 10.5 backend, Zabbix 7.4.x on GNU/Linux Debian 11

## Abilities

- Customizable and easy to set up
- Separate monitoring for each backup job
- Different job levels have different severities
- Monitoring of Bacula Director, Storage and File processes
- Generates graphs to follow the data evolution
- Dashboards with graphs ready for display
- Works with MySQL/MariaDB and PostgreSQL used by Bacula Catalog

## Features

### Data collected using scripts and sent to Zabbix

- Job exit status
- Number of bytes transferred by the job
- Number of files transferred by the job
- Time elapsed by the job
- Job transfer rate
- Job compression rate
- Number of running and waiting jobs

### Zabbix template configuration

Link this Zabbix template to each host that has a Bacula backup job implemented.

- **Items** \
  This Zabbix template has two types of items, the items to receive data of backup jobs, and the items to receive data of Bacula's processes.  

  **1. Items that receive data of Bacula's processes:** \
    These items are disabled by default and must be enabled for each host which runs the Bacula Director, Bacula Storage and Bacula File daemons respectively.
    - *Bacula Director is running*: Get the Bacula Director process status. The process name is defined by the variable {$BACULA.DIR}, and has its default value as 'bacula-dir'. This item needs to be disabled in hosts that are Bacula's clients only.
    - *Bacula Storage is running*: Get the Bacula Storage process status. The process name is defined by the variable {$BACULA.SD}, and has its default value as 'bacula-sd'. This item needs to be disabled in hosts that are Bacula's clients only.
    - *Bacula File is running*: Get the Bacula File process status. The process name is defined by the variable {$BACULA.FD}, and has its default value as 'bacula-fd'.

  **2. Items that receive data of backup jobs:** \
    These are divided into the three backup's levels: Full, Differential and Incremental. For each level there are six items as described below:
    - *Bytes*: Receives the value of bytes transferred by each backup job
    - *Compression*: Receives the value of compression rate of each backup job
    - *Files*: Receives the value of files transferred by each backup job
    - *OK*: Receives the value of exit status of each backup job
    - *Speed*: Receives the value of transfer rate of each backup job
    - *Time*: Receives the value of elapsed time of each backup job

- **Triggers** \
  The triggers are configured to identify the host that started the trigger through the variable {HOST.NAME}. In the same way as the items, the triggers also have two types:

  **1. Triggers that are related to Bacula's processes:**
    - *Bacula Director is DOWN in {HOST.NAME}*: Starts a disaster severity alert when the Bacula Director process goes down
    - *Bacula Storage is DOWN in {HOST.NAME}*: Starts a disaster severity alert when the Bacula Storage process goes down
    - *Bacula File is DOWN in {HOST.NAME}*: Starts a high severity alert when the Bacula File process goes down
    - Backup jobs are running during prime work periods (default: Weekdays, 9am-12pm)
    - The number of waiting jobs is too high (default: 10)

  **2. Triggers that are related to backup jobs:**
    - *Backup Full FAIL in {HOST.NAME}*: Starts a high severity alert when a full backup job fails
    - *Backup Differential FAIL in {HOST.NAME}*: Starts a average severity alert when a differential backup job fails
    - *Backup Incremental FAIL in {HOST.NAME}*: Starts a warning severity alert when a incremental backup job fails

- **Graphs** \
  In the same way as the items are related to backup jobs, graphs are divided into the three backup's levels: Full, Differential and Incremental. For each level there are five graphs as described below:

  - *Bytes transferred*: Displays a graph with the variation of the bytes transferred by backup jobs, faced with the variation of the exit status of these jobs
  - *Compression rate*: Displays a graph with the variation of the compression rate by backup jobs, faced with the variation of the exit status of these jobs
  - *Elapsed time*: Displays a graph with the variation of the elapsed time by backup jobs, faced with the variation of the exit status of these jobs
  - *Files transferred*: Displays a graph with the variation of the files transferred by backup jobs, faced with the variation of the exit status of these jobs
  - *Transfer rate*: Displays a graph with the variation of the transfer rate by backup jobs, faced with the variation of the exit status of these jobs

- **Dashboards** \
  There are three dashboards, one for each backup level, that displays the five graphs previously configured for that level.

### Requirements
- Knowledge about Bacula and the local installation
- Knowledge about Zabbix and the local installation
- Knowledge about MySQL or PostgreSQL databases
- Knowledge about GNU/Linux operational systems

### Installation
> [!NOTE]
>  - The bash scripts are assumed to be installed in `/var/spool/bacula` although they can be installed elsewhere, im which case adjust the path accordingly for the `crontab` and `/etc/bacula/bacular-dir.conf` instructions provided here, as well as within the `bacula-director-zabbix-sender.bash` file.
>  - Bacula.org and these instructions use `/etc/bacula` as the installation directory for bacula's configuration files. If your Bacula installation uses a different config path (e.g. `/opt/bacula/etc`), fix the path to `bacula-zabbix.conf` in the installed bash scripts.

On the host running Bacula Director, from this repository:
1. Copy the configuration file `bacula-zabbix.conf` into `/etc/bacula` (or your custom directory) and modify the configuration settings accordingly. 

    This file also contains the hash variable `hostmap` which maps host names defined by Bacula to host names defined by Zabbix, allowing the primary `bacula-zabbix.bash` script to correctly associate Bacula job results and statistics between Bacula host names and Zabbix host names. If the names are the same on both systems, this does not need to be defined. However, typical Bacula installations append `-fd` to their host names, while Zabbix users use a variety of schemes. Example:
    ```
    declare -A hostmap
    hostmap=(
      [host1-fd]="Host1"
      [host2-fd]="Host2"
      [host3-fd]="Host3"
      ...
    )
    ```

2. Secure the configuration file's permissions:
    ```
    chown root:bacula /etc/bacula/bacula-zabbix.conf
    chmod 640 /etc/bacula/bacula-zabbix.conf
    ```

3. Install all the `.bash` files into the directory `/var/spool/bacula` and secure them:
    ```
    mkdir -p /var/spool/bacula
    for f in *.bash; do 
      cp ${f} /var/spool/bacula/${f}
      chown bacula:bacula /var/spool/bacula/${f}
      chmod 0500 /var/spool/bacula/${f}
    done
    ```

4. Modify the **Bacula Director** configuration file `/etc/bacula/bacula-dir.conf` to run either the `bacula-zabbix.bash` script or the `bacula-sender.bash` script at the end of *each* job you wish Zabbix to monitor. This is done by modifying the `Messages` resource that is used by **all of** those jobs.

    If there is no `mailcommand` in the `Messages` resource, set it as follows:
    ```
    Messages {
      ...
      mailcommand = "/var/spool/bacula/bacula-zabbix.bash %i"
      mail = 127.0.0.1 = all, !skipped
      ...
    }
    ```

    If there is, you will need to use a wrapper script, such as the `bacula-zabbix.bash` script, to run both your current `mailcommand` as well as the `bacula-zabbix.bash` script. This script already contains the default `bsmtp` example provided by Bacula as well as an alternative for `postfix` as the `mailcommand`,  so if you use a different configuration you will need to modify this script accordingly.

    For example if the original mailcommand was:
    ```
    mailcommand = "/usr/sbin/bsmtp -h localhost -f \"\(Bacula\) \<bacula@example.com\>\" -s \"Bacula: %t %e of %c (%n) %l\" %r"
    ```
    replace it with
    ```
    mailcommand = "/var/spool/bacula/bacula-sender.bash '%t' '%e' '%c' '%n' '%l' '%r' '%i' '\"Bacula\" <bacula@example.com>' B"
    ```
    The 9th/last parameter may be either `B` (for bsmtp), `P` (for postfix/mail), or `0` (which will not send any mail).  All three options call `bacula-zabbix.bash` after sending mail. Note also that option 8 must be a single email address that is to be is the sender's email address.  If you are only sending the message to a single mail address, you can use `%r`, the recipient.  If there are multiple recipenents you must provide an email address to be used as the sender as `%r` will expand to all recipients..

    If you use Baculum WEB(Prefered and no reload needed), when you edit the Message check the `all` box in the `mail` Message option and in `mailcommand`,  drop the "\" from the example. i.e:
    ```
    # Using WEB:
    mailcommand = /var/spool/bacula/bacula-sender.bash "%t" "%e" "%c" "%n" "%l" "%r" "%i" '"Bacula" <bacula@example.com>' "B"
    ```

 5. Reload the configuration, or restart the Bacula Director service.
    ```
    echo reload | bconsole
    ```
    OR
    ```
    systemctl restart bacula-dir
    ```

6. Import the Zabbix template (`bacula-template.yaml` or `bacula-template.xml`) into your Zabbix server. The template includes the following macros for the executable names of the Bacula Director, Storage Daemon and File Daemon respectively:
    - `{$BACULA.DIR}` = `bacula-dir`
    - `{$BACULA.SD}` = `bacula-sd`
    - `{$BACULA.FD}` = `bacula-fd`

      If these names differ from your installation, change these either in the Template (if installation-wide) or add overriding macros per host on which they differ:

7. Within Zabbix, add the template `Bacula` to all hosts that have configured backup jobs which you wish to monitor using Zabbix. The template includes Items that are disabled by default to check the Bacula File, Director and Storage processes are running. If you are _not_ using a Systemd Template also for these hosts, enable these Items on each host accordingly:
    - `Template Bacula: Bacula Director is running`
    - `Template Bacula: Bacula Storage is running` 
    - `Template Bacula: Bacula File is running`

### New Features:
- monitor running jobs and trigger alerts when they shouldn't be running during (default: Weekdays 9am-12pm)
- monitor waiting jobs and trigger alerts when they exceed a configured limit
- trigger alerts when there is an action needed for labeling media

To add these features, update the template if you have not already done so and perform these remaining steps on the host running the Bacula Director:

8. For the host configured as the `baculaHost` within the configuration file `/etc/bacula/bacula-zabbix.conf`: \
    a) Within Zabbix, add the following macros and set their values to you own preferences:
    - `{$BACULA.RUNNING.JOBS.NWD.START} = 090000` \
      _Start time of weekday window when no jobs permitted_
    - `{$BACULA.RUNNING.JOBS.NWD.END} = 120000` \
      _End time of weekday window when no jobs permitted_
    - {`$BACULA.WAITING.JOBS.MAX} = 10` \
      _Maximum permitted number of waiting jobs_

    The trigger conditions may also be modified accordingly if you wish to switch from weekdays, or add multiple time periods.

    b) Within Zabbix, _enable_ the following three items:
    -  `Template Bacula: Backup Server Label Jobs`
    -  `Template Bacula: Backup Server Running Jobs`
    -  `Template Bacula: Backup Server Waiting Jobs`

    c) Add a cron entry that will update the number of running and waiting jobs as well as jobs requiring action. The following example runs the script every 10 minutes:
    ```
    */10 * * * * /var/spool/bacula/bacula-director-zabbix-sender.bash
    ```

# Troubleshooting Commands:
- `tail -f /var/log/syslog`
- `tail -f /var/log/bacula/bacula-zabbix.log`
- `docker logs -f zabbix-snmptraps-1 -n 100`
- `/var/log/zabbix/zabbix_server.log`

### References

- **Bacula**:

  - http://www.bacula.org/7.0.x-manuals/en/main
  - https://www.bacula.org/9.4.x-manuals/en/main/
  - http://www.bacula.com.br/manual/Messages_Resource.html
  - https://www.bacula.org/9.4.x-manuals/en/main/Messages_Resource.html
  - http://www.bacula-web.org/docs.html
  - http://resources.infosecinstitute.com/data-backups-bacula-notifications

- **Zabbix**:

  - http://novatec.com.br/livros/zabbix
  - http://www.zabbix.org/wiki/InstallOnCentOS_RHEL
  - https://www.zabbix.com/documentation/2.4/start
  - http://zabbixoverflow.com/index.php?topic=51.0
  - https://support.zabbix.com/browse/ZBX-7790

- **Integration**:

  - https://www.zabbix.com/forum/showthread.php?t=8145
  - http://paje.net.br/?p=472
  - https://github.com/selivan/bacula_zabbix_integration

### Feedback

Feel free to send bug reports and feature requests here:

- https://github.com/germanodlf/bacula-zabbix/issues
- germanodlf@gmail.com
- alexs@ecoscentric.com

If you are using this solution in production, please write me about it. It's very important for me to know that my work is not meaningless.
