<#

NAME
    ps-backup.ps1

DESCRIPTION
    This script will create a backup of a specified path and keep a
    specified number of backups.  This script is designed with the
    expectation that it runs after midnight (all dates are
    subtracted by one to get the backup date).

AUTHOR
    Peter Lindstrom
    peter@plind.net

UPDATED
    2017-Aug-06

CHANGE LOG
    2016-03-06    Created.
    2016-07-16    Use robocopy /PURGE to delete files instead of
                  Remove-Item cmdlet for more reliable deletion.
    2017-08-06    Added logic to remove trailing \ from backup drive
                  if it is present.  Resolves bug #7.

#>



<#
  Functions ---------------------------------------------------------

    Index:

    01   Do-DeleteBackup
    02   Do-Backup
    03   Get-FormattedDate
    04   Send-ActivityReport
    05   Show-ErrorMessage
#>


# Do-DeleteBackup ---------------------------------------------------
function Do-DeleteBackup{
    $tempPath = $PSScriptRoot + "\temp"
    $deleteDate = Get-FormattedDate -type "d"
    $deletePath = $config.Configuration.BaseSettings.SaveBackupTo + "\$deleteDate\"

    # Create new temp backup folder
    if(Test-Path $tempPath){
        Show-Message -type 1 -message "Temporary backup folder already exists."
    } else {
        try{
            if($config.Configuration.BaseSettings.ScriptMode -eq "MakeChanges"){
                New-Item $tempPath -ItemType Directory -ErrorAction Stop | Out-Null
            } else {
                New-Item $tempPath -ItemType Directory -ErrorAction Stop -WhatIf | Out-Null
            }
        } catch {
            Show-Message -type 0 -message $($_.Exception.Message)
        }
    }

    # Delete old backup using robocopy
    Show-Message -type 3 -message "Deleting folder $deletePath... "
    if(Test-Path $deletePath){
        try{
            if($config.Configuration.BaseSettings.ScriptMode -eq "MakeChanges"){
                robocopy $tempPath $deletePath /PURGE /LOG+:$rLogPath
                $summary += (Get-Content "$rLogPath")[-1 .. -7]
                $summary + "`n" | Out-File -FilePath $logPath -Append
                Remove-Item $deletePath -Recurse -ErrorAction SilentlyContinue
                Remove-Item $tempPath -Recurse -ErrorAction SilentlyContinue
            } else {
                Write-Host "What if: Performing the operation `"robocopy $tempPath $deletePath /PURGE /LOG+:$rLogPath`"`n"
                robocopy $tempPath $deletePath /PURGE /L /LOG+:$rLogPath
                $summary += (Get-Content "$rLogPath")[-1 .. -7]
                $summary + "`n" | Out-File -FilePath $logPath -Append
                Remove-Item $deletePath -Recurse -ErrorAction SilentlyContinue -WhatIf
                Remove-Item $tempPath -Recurse -ErrorAction SilentlyContinue -WhatIf
            }
            Show-Message -type 2 -message "Deleted successfully."
        } catch {
            Show-Message -type 1 -message "Error(s) occurred during delete.  Verify directory has been deleted."
        }
    } else {
        Show-Message -type 1 -message "Folder does not exist."
    }
}



# Do-Backup ---------------------------------------------------------
function Do-Backup{
    $backupDate = Get-FormattedDate -type "s"
    $sourcePath = $config.Configuration.BaseSettings.PathToBackup + "\"

    # Remove trailing \ from drive if exists
    $backupDriv = $config.Configuration.BaseSettings.SaveBackupTo
    if($backupDriv.EndsWith("\")){
      $backupDriv = $backupDriv.TrimEnd("\")
    }

    $backupPath = $backupDriv + "\$backupDate\"

    # Verify source path exists
    Show-Message -type 3 -message "Verifying $sourcePath exists... "
    if(Test-Path $sourcePath){
        Show-Message -type 2 -message "Folder exists."
    } else {
        Show-Message -type 0 -message "Unable to locate source folder."
    }

    # Create new backup folder
    Show-Message -type 3 -message "Creating folder $backupPath... "
    if(Test-Path $backupPath){
        Show-Message -type 1 -message "Folder already exists."
    } else {
        try{
            if($config.Configuration.BaseSettings.ScriptMode -eq "MakeChanges"){
                New-Item $backupPath -ItemType Directory -ErrorAction Stop | Out-Null
            } else {
                New-Item $backupPath -ItemType Directory -ErrorAction Stop -WhatIf | Out-Null
            }
            Show-Message -type 2 -message "Created successfully."
        } catch {
            Show-Message -type 0 -message $($_.Exception.Message)
        }
    }

    # Do the backup using robocopy
    Show-Message -type 3 -message "Copying files to $backupPath... "
    try{
        if($config.Configuration.BaseSettings.ScriptMode -eq "MakeChanges"){
            robocopy $sourcePath $backupPath /MIR /XA:H /W:0 /R:0 /MT:64 /LOG+:$rLogPath
            $summary = (Get-Content "$rLogPath")[-1 .. -7]
            $summary + "`n`n" | Out-File -FilePath $logPath -Append
        } else {
            Write-Host "What if: Performing the operation `"robocopy $sourcePath $backupPath /MIR /XA:H /W:0 /R:0 /MT:64 /LOG+:$rLogPath`"`n"
            robocopy $sourcePath $backupPath /MIR /XA:H /W:0 /R:0 /MT:64 /L /LOG+:$rLogPath
            $summary = (Get-Content "$rLogPath")[-1 .. -7]
            $summary + "`n`n" | Out-File -FilePath $logPath -Append
        }
    } catch {
        Show-Message -type 0 -message $($_.Exception.Message)
    }
}



# Get-FormattedDate -------------------------------------------------
function Get-FormattedDate{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage="Do you want to return the delete date [d], save date [s], or current date [c]?")]
        [Alias("type")]
        [string[]] $o
    )

    process{
        $curDate = Get-Date

        switch($o){
            "d"{ $curDate = $curDate.AddDays(-$config.Configuration.BaseSettings.DaysToKeep) }
            "s"{ $curDate = $curDate.AddDays(-1) }
        }

        $year = $curDate.Year.ToString()
        $month = $curDate.Month.ToString()
        $day = $curDate.Day.ToString()

        if($month.Length -eq 1){ $month = "0$month" }
        if($day.Length -eq 1){ $day = "0$day" }

        $output = "$year-$month-$day"
        return $output
    }
}



# Send-ActivityReport -----------------------------------------------
function Send-ActivityReport{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage="Specify the type of activity report.")]
        [Alias("type")]
        [int[]] $n
    )

    process{
        if($config.Configuration.EmailSettings.SendMail -eq "true"){
            $smtpCreds = Import-Clixml "$PSScriptRoot\SMTPCreds.clixml"

            switch($n){
                0{
                    Send-MailMessage -To $config.Configuration.EmailSettings.MailTo -from $config.Configuration.EmailSettings.MailFrom -subject $config.Configuration.EmailSettings.MailSubject -Body "Error(s) occurred during the backup process!  See attached log file for more information." -Attachments "$logPath" -Priority High -SmtpServer $config.Configuration.EmailSettings.SMTPServer -Port $config.Configuration.EmailSettings.SMTPPort -Credential $smtpCreds
                }
                1{
                    Send-MailMessage -To $config.Configuration.EmailSettings.MailTo -from $config.Configuration.EmailSettings.MailFrom -subject $config.Configuration.EmailSettings.MailSubject -Body "The backup process is complete.  See attached log file for more information." -Attachments "$logPath" -SmtpServer $config.Configuration.EmailSettings.SMTPServer -Port $config.Configuration.EmailSettings.SMTPPort -Credential $smtpCreds
                }
            }
        }
    }
}



# Show-Message -------------------------------------------------
function Show-Message{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage="Specify the type of message.")]
        [Alias("type")]
        [int[]] $n,
        [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, HelpMessage="Provide the message text.")]
        [Alias("message")]
        [string[]] $m
    )

    process{
        $logDateTime = Get-Date
        $logDateTime = $logDateTime.ToString()

        switch($n){
            0{
                Write-Host "$m`n" -ForegroundColor Red
                $m = "$logDateTime`tFail`t$m"
                $m | Out-File -FilePath $logPath -Append
                Send-ActivityReport -type 0
                throw "Script has terminated."
            }
            1{
                Write-Host "$m`n" -ForegroundColor Yellow
                $m = "$logDateTime`tWarn`t$m"
                $m | Out-File -FilePath $logPath -Append
            }
            2{
                Write-Host "$m`n" -ForegroundColor Green
                $m = "$logDateTime`tOkay`t$m"
                $m | Out-File -FilePath $logPath -Append
            }
            3{
                Write-Host "$m"
                $m = "$logDateTime`tInfo`t$m"
                $m | Out-File -FilePath $logPath -Append
            }
        }
    }
}


# Main program ------------------------------------------------------
Clear-Host
Write-Host "ps-backup`n"

# Get settings from config file
try{
    [xml]$config = Get-Content "$PSScriptRoot\Settings.config" -ErrorAction Stop
} catch {
    Show-Message -type 0 -message $($_.Exception.Message)
}

# Set log file paths
$logPath = "$PSScriptRoot\"
$logPath += Get-FormattedDate -type c
$logPath += "_BackupLog.txt"

$rLogPath = "$PSScriptRoot\"
$rLogPath += Get-FormattedDate -type c
$rLogPath += "_RoboLog.txt"

# Run the program
Do-Backup
Do-DeleteBackup
Send-ActivityReport -type 1
