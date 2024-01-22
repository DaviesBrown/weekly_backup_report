# Weekly Backup Report Script

## Overview

The `weekly_backup_report.sh` script is a versatile tool designed for performing various system-related tasks on a weekly basis. Authored by Nwosu David, the script facilitates weekly backups, system metrics reporting, Oracle schema backup, and concludes by emailing a final report summarizing all activities.

## Usage

To execute the script, run the following command:

```bash
./weekly_backup_report.sh youremail@email.com
```

## Setup

Before utilizing the script, configure a cron job to automate its execution weekly. Follow these steps:

1. Copy the current crontab to a temporary file:

   ```bash
   crontab -l > /tmp/temp_crontab
   ```

2. Append the cron job to the temporary file to run the script at 2 am every Sunday:

   ```bash
   echo "0 2 * * 0 $HOME/weekly_backup_report.sh" >> /tmp/temp_crontab
   ```

3. Apply the changes to your crontab:

   ```bash
   crontab /tmp/temp_crontab
   ```

4. Remove the temporary file:

   ```bash
   rm /tmp/temp_crontab
   ```

## Features

### 1. IngrydDocs Backup

- Creates backups of important files in `~/ingrydDocs` to a regular backup destination.
- Compresses backups and skips the process if files have not changed since the last backup.

### 2. System Metrics Reporting

- Generates tabular reports on key system metrics including CPU usage, memory usage, disk space, and network statistics.
- Utilizes sysstat logs from `/var/log/sysstat` covering the past week.

### 3. Oracle Schema Backup

- Backs up a specified Oracle schema to a remote destination using Data Pump Export.
- Transfers the backup file to the remote destination via SCP.

### 4. Final Report and Emailing

- Combines all reports into a final summary.
- Emails the final report to your email.

## Customization

- Configure Oracle schema details, remote destinations, and email recipients in the script.
- Adjust the cron job timing according to your preference.

## Dependencies

- The script relies on the `sysstat` package for system metrics reporting. Ensure it is installed on your system:

  ```bash
  sudo apt-get install sysstat -y
  ```

- The script uses `mutt` for email functionality. Install it using:

  ```bash
  sudo apt-get install mutt -y
  ```

## Notes

- The script may require adjustments based on specific system configurations and preferences.
- Ensure the script is executed with the necessary permissions.

## License

This project is licensed under the [MIT License](LICENSE).
