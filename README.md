# ps-backup
ps-backup is a PowerShell script used to backup files using robocopy.  It also retains backups for a specified number of days and can send email alerts when the backup is complete.

## Requirements

- PowerShell 5.0
- Robocopy 10.0
- Modify permissions to the location where log files will be written
- Modify permissions to the location where backups are saved

## Robocopy

Robocopy is used to perform the actual backup.  The following Robocopy options are used by default:

```
[source] [destination] /MIR /XA:H /W:0 /R:0 /MT:64 /L /LOG+:[logPath]
```

- **Source** - The location of the files to backup.
- **Destination** - The location to save the backup.
- **/MIR** - Mirrors a directory tree.
- **/XA:H** - Excludes files with the hidden attribute set.
- **/W:0** - Wait zero seconds between retries.
- **/R:0** - Do not retry on failed copies.
- **/MT:64** - Uses 64 threads.
- **/L** - Only list files (used when running script in WhatIf mode. 
- **/LOG+** - Appends all results to a log file.

## Creating Scheduled Task

To run this script at a specified time and interval (every day at 2:00am, for example), create a scheduled task using the Windows Task Scheduler.

When creating a new task, input the following settings.

- Program/script: PowerShell
- Add arguments: CIFSBackup.ps1
- Start in: [pathToScript]

**Note:**  This script was designed with the expectation that it runs after midnight (all dates are subtracted by one to get the user-friendly backup date). For example, if the script runs on March 20th, 2016 at 2:00am, the backup directory will be named '2016-03-19' to help users identify the appropriate backup.

## Settings.config file

### BaseSettings

- **DaysToKeep** - Number of backups to keep, in days.
- **PathToBackup** - Path to the directory that needs to be backed up.  Do not include ending '/'
- **SaveBackupTo** - Path to the location where backups are saved. Do not include ending '/'
- **ScriptMode** - Used to test the script without making changes in production.  [WhatIf] will simulate changes, [MakeChange] will execute all changes.

### EmailSettings

- **SendMail** - Enable [true] or disable [false] email alerts.
- **MailTo** - Email address that should receive alerts.
- **MailFrom** - Email address used to send alerts.
- **MailSubject** - Subject line.  May be followed by additional text on error conditions.
- **SMTPServer** - SMTP server address.
- **SMTPPort** - SMTP server port (25, 26, 587 are typical)
- **SMTPCredentials** - SMTP credentials are stored in SMTPCreds.clixml.

## Generate SMTPCredentials.clixml file

If the username and/or password used to authenticate on the SMTP server change, use the following PowerShell commands to generate a new clixml file:

```
$cred = Get-Credential
$cred | Export-CliXml SMTPCreds.clixml
```

## Contact Information

Please let me know if you have any suggestions or questions about this script.

Web: http://www.plind.us

Mail: peter@plind.net

## Terms and Conditions

By downloading or using this script, or any information contained within the file(s) downloaded, (herein referred to as "the script") you agree to be bound by the following Terms and Conditions.

You agree that this script may contain proprietary information including trademarks, service marks, and other information protected by intellectual property laws. Any trademarks, service marks, or logos are the property of their respective owners. The content within this script may not be sold without permission.

You agree that the use of this script is at YOUR OWN RISK and that any information or functionality provided are provided "as is" with no express or implied warranties. In addition, you agree that Peter Lindstrom (herein referred to as "the author") shall not be liable for any direct, indirect, incidental, or consequential damages.

Lastly, you agree that the author reserves the right to modify the Terms and Conditions at any time without any notice. Changes to the TOS are effective as soon as they are posted to the location from which this script was downloaded.

## License Agreement

(c) 2016 Peter Lindstrom. This script is licensed under a Creative Commons Attribution-ShareAlike 4.0 International license.

http://creativecommons.org/licenses/by-sa/4.0/legalcode
