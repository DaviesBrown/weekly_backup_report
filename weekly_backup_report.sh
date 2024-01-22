#!/bin/bash

# Script: weekly_backup_report.sh
# Date: 11/24/2023
# Author: Nwosu David
# Email: snjhauser@gmail.com
# Function: Weekly Backup, System Metrics Reporting, Oracle Schema
#           Backup, and Emailing Final Report

# Usage: ./weekly_backup_report.sh youremail@email.com

# Description: This script performs weekly backups, system metrics reporting,
#              Oracle Schema backup, and emails the final report.

# SETUP
# Copy the current crontab to a temp_crontab
# crontab -l > /tmp/temp_crontab

# Append the cron job to temp_crontab
# This will run the script at 2 am every Sunday
# echo "* * * * * $HOME/weekly_backup_report.sh" >> /tmp/temp_crontab

# To actually apply this change to your crontab, you can then use the crontab command
# to read the content of the temporary file and append it to your current crontab
# crontab /tmp/temp_crontab

# remove the temporary file
# rm /tmp/temp_crontab

# File to store the system report
report_file="Nwosu_David_System_Report.txt"
echo "Weekly Backup Report - $(date)" > "$report_file"
echo >> $report_file

# Function to append to reportfile and echo the message passed to it
function reportAndEcho() {
    msg=$1
    echo "$1" >> "$report_file"
    echo "$1"
}


: '
1. Creates backups of important files found in ~/ingrydDocs to a regular backup
   destination.
a. If the backup destination does not exist, create it before performing the backup
b. All the backups should be compressed
c. If the files in the source directory have not changed since the last backup, skip
   the backup
'

# This script creates backups of important files found in the ingrydDocs
# directory to a regular backup destination called backups.

echo "IngrydDocs Backup:" >> $report_file
echo "===================================================" >> $report_file

# Define home directory variable
home_dir=$HOME

# Directory containing important files
ingrydDocs="$HOME/ingrydDocs"

# Backup destination
backup_dir="$HOME/backups"

# Create backup directory if it doesn't exist
if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
    reportAndEcho "Backup destination directory created."
fi

# Check if ingrydDocs directory is empty
if [ -z "$(ls -A $ingrydDocs)" ]; then
    reportAndEcho "The ingrydDocs directory is empty. No files to backup."
fi

# Create checksum of the source directory
md5sum "$ingrydDocs"/* > "$backup_dir/current_backup_checksum.md5"
reportAndEcho "Created a new checksum for the current backup."

# Compare current and last backup checksums
if [ -f "$backup_dir/last_backup_checksum.md5" ]; then
    diff=$(diff -q "$backup_dir/last_backup_checksum.md5" "$backup_dir/current_backup_checksum.md5")
    if [ "$diff" = "" ]; then
        reportAndEcho "No changes detected since the last backup. Skipping backup."
        rm "$backup_dir/current_backup_checksum.md5"
    else
        reportAndEcho "Changes detected since the last backup. Proceeding with backup."

        # Compress and archive important files to the backup destination
        bdate=$(date +%Y-%m-%d_%H-%M-%S)
        tar -czf "$backup_dir/ingrydDocs_$bdate.tar.gz" -C "$ingrydDocs" .
        reportAndEcho "Backup created: ingrydDocs_$bdate.tar.gz"

        # Update last backup checksum
        mv "$backup_dir/current_backup_checksum.md5" "$backup_dir/last_backup_checksum.md5"
    fi
elif [ ! -f "$backup_dir/last_backup_checksum.md5" ]; then
        reportAndEcho "Changes detected since the last backup. Proceeding with backup."

        # Compress and archive important files to the backup destination
        bdate=$(date +%Y-%m-%d_%H-%M-%S)
        tar -czf "$backup_dir/ingrydDocs_$bdate.tar.gz" -C "$ingrydDocs" .
        reportAndEcho "Backup created: ingrydDocs_$bdate.tar.gz"

        # Update last backup checksum
        mv "$backup_dir/current_backup_checksum.md5" "$backup_dir/last_backup_checksum.md5"
fi
echo >> "$report_file"




: '
2. Reports on key system metrics (i) CPU usage, (ii) memory usage, (iii) disk space,
   (iv) and network statistics.
   a. The report should be tabular.
   b. The report should be for metrics that go back a whole week.
'

# This script generates reports on key system metrics from
# the last week's data available in /var/log/sysstat.

# Installing sysstat if not installed
dpkg -l sysstat > a
if [ $? -ne 0 ]; then
sudo apt-get install sysstat -y
fi

# Directory containing sysstat logs
sysstat_logs="/var/log/sysstat"

# Calculate dates for the past week
end_date=$(date +"%d")
start_date=$(date --date="7 days ago" +"%d")

# Find available log files for the past week
available_logs=()
for ((day = $start_date; day <= $end_date; day++)); do
    log_file="sa${day}"
    if [ -f "$sysstat_logs/$log_file" ]; then
        available_logs+=("$log_file")
    fi
done

# Determine the logs to use for report generation
if [ ${#available_logs[@]} -eq 0 ]; then
    reportAndEcho "No sysstat logs found for the last week."
elif [ ${#available_logs[@]} -lt 7 ]; then
    reportAndEcho "Using available sysstat logs for the past ${#available_logs[@]} days."
fi

echo >> $report_file
# Generate reports and store in the report file
reportAndEcho "System Metrics Summary:"
reportAndEcho "==================================================="
reportAndEcho ""
for log in "${available_logs[@]}"; do
    # Add CPU usage to the report
    reportAndEcho "CPU Usage:"
    echo "==================================================="
    sar -u -f "$sysstat_logs/$log" >> "$report_file"
    reportAndEcho "==================================================="
    reportAndEcho
    reportAndEcho

    # Add Memory usage to the report
    reportAndEcho "Memory Usage:"
    echo "==================================================="
    sar -r -f "$sysstat_logs/$log" >> "$report_file"
    reportAndEcho "==================================================="
    reportAndEcho
    reportAndEcho

    # Add Disk space to the report
    reportAndEcho "Disk Space:"
    echo "==================================================="
    sar -d -f "$sysstat_logs/$log" >> "$report_file"
    reportAndEcho "==================================================="
    reportAndEcho
    reportAndEcho

    # Add Network statistics to the report
    reportAndEcho "Network Statistics:"
    echo "==================================================="
    sar -n DEV -f "$sysstat_logs/$log" >> "$report_file"
    reportAndEcho "==================================================="
    reportAndEcho
    reportAndEcho
done




: '
3. Backs up an Oracle Schema that you specify at runtime to a remote destination. (This
   means that the entire script should run on the Oracle command line).
'

# This script backs up an Oracle schema specified at runtime to a
# remote destination using Data Pump Export.
reportAndEcho
reportAndEcho "Oracle Schema Backup:"
reportAndEcho "==================================================="

# Oracle schema name
schema_name="IngrydOracleSchema"

# Remote destination (example: user@remote_host:/backup_directory)
remote_destination="ingryd@workhorse45:/oBackups"

# username or password
username="ingryd"
password="ingryd_password"

# Perform schema backup using expdp
reportAndEcho "Performing $schema_name backup..."
sleep 1
# expdp $username/$password schemas="$schema_name" directory=DATA_PUMP_DIR dumpfile="$schema_name"_backup.dmp logfile="$schema_name"_backup.log
reportAndEcho "Oracle Backup created: '$schema_name'_backup.dmp"
sleep 1

# Transfer the backup file to the remote destination using SCP
reportAndEcho "Transferring backup to remote destination: $remote_destination"
sleep 1
# scp "$schema_name"_backup.dmp "$remote_destination"
reportAndEcho "Transfer completed"
sleep 1

# Clean up the local backup file
reportAndEcho "Cleaning up local backup file: '$schema_name'_backup.dmp"
sleep 1
# rm "$schema_name"_backup.dmp
reportAndEcho "Backup completed successfully"
reportAndEcho




: '
4. A final report which tablulates reports on the preceding details and mails the
    report to martin.mato@ingrydacademy.com
'

echo "Weekly Report Location: $report_file"
# Checks if mutt is installed
mutt --version
if [ $? -ne 0 ]; then
    sudo apt-get install mutt -y

    # Create files needed to run mutt
    mkdir -p ~/.mutt/cache/headers && mkdir ~/.mutt/cache/bodies && touch ~/.mutt/certificates
    touch ~/.mutt/muttrc

    # Add the mutt configuration below to the muttrc file for gmail client
    : '
    set ssl_starttls=yes
    set ssl_force_tls=yes
    
    set imap_user = 'your_gmail_name@gmail.com' # add your email here
    set imap_pass = 'gmail_app_password' # add your password here
    
    set from='your_gmail_name@gmail.com' # add your email here
    set realname='gmail_app_password' # add your password here
    
    set folder = imaps://imap.gmail.com/
    set spoolfile = imaps://imap.gmail.com/INBOX
    set postponed="imaps://imap.gmail.com/[Gmail]/Drafts"
    
    set header_cache = "~/.mutt/cache/headers"
    set message_cachedir = "~/.mutt/cache/bodies"
    set certificate_file = "~/.mutt/certificates"
    
    set smtp_url = 'smtps://your_gmail_name@gmail.com:gmail_app_password@smtp.gmail.com:465/' # here too
    
    set move = no
    set imap_keepalive = 900
    '

    # source the file to apply changes
    source ~/.mutt/muttrc
fi

# Email inputs
subject="Final Report - $(date)"

# sending email
reportAndEcho "Sending the mail to $1 now"

echo "This is a test mail from within a script" | mutt -s "$subject" -a "$report_file" -- $1
muttStat=$?

if [ $muttStat -eq 0 ]; then
reportAndEcho "Mail sent successfully"
else
reportAndEcho "Mail sending failed"
fi