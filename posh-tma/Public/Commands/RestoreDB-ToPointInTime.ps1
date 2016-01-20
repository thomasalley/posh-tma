<#
    RestoreDB-ToPointInTime.ps1 | v1.0 | thomas@thomasalley.net
    
    Description
        Collection of commandlets enabling easy database restores to a given Point in Time

        Heavily inspired by (And some parts liberated from):
            https://www.simple-talk.com/sql/backup-and-recovery/backup-and-restore-sql-server-with-the-sql-server-2012-powershell-cmdlets/

    Notes
        It is recommended to execute with -Verbose flag, since that will provide plenty of information for troubleshooting.
        When restoring databases, care should usually be taken to ensure that the operation can obtain an exclusive lock on the database in question.
        Setting the DB to Single User mode is usually a good way to 'kick' users and processes off of a database.

    Dependencies
        Nominally dependent on the target backups structure utilizing the SQL Server Maintenance Solution (Or something with a similar naming convention)

        Requires SQL Server 2012 Tools (SQLPS) for Powershell (or later)

    TO DO
        [Testing]
            Fulls and Diffs mix with no valid recent diffs? Not sure if that'd be a problem but I suspect SQL Server would handle it in the roll forward.
        [Improvement]
            Do some research and see if the invoke-sqlcmd statements in final recovery are the most optimal way of ensuring DB recovery.
#>

function Get-DBBackupFile
{
    <#
        Description
            This function will suss out backup files in a SQL Server Maintenance Solution
            Backups structure.

        Notes
            The behavior for the LOG logic branch is distinct from the FULL and DIFF branches.
            When looking for logs the function will return all log files written SINCE the specified
            Point in Time. This provides a point of potential confusion on the surface, but is in line
            with the way backups are actually rolled forward.
    #>
    Param(
        [Parameter(Mandatory=$True)] [ValidateSet("FULL", "DIFF", "LOG")] [string]  $BackupType,
        [Parameter(Mandatory=$True)]                                      [string]  $DatabaseName,
        [Parameter(Mandatory=$True)]                                      [string]  $BackupPath,
        [Parameter(Mandatory=$False)]                                     [DateTime]$PointInTime
    )

    if( ((Test-Path $BackupPath) -eq $false))
    {
        throw "Backups Path Invalid."
    }

    switch($BackupType.ToUpper())
    {
        'FULL'
        {
            if(-not $PointInTime)
            {
                $PointInTime = Get-Date
            }

            Write-Verbose "Grabbing Most Recent Full"
            $fullFile = Get-ChildItem -Filter "*$($DatabaseName)_FULL_*" -Path (Join-Path -Path $BackupPath -ChildPath 'FULL') | Where-Object {$_.LastWriteTime -lt $PointInTime} | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            
            if($fullFile)
            {
                Write-Verbose "Full Backup File Found"
                return $fullFile
            }
            else
            {
                Write-Verbose "No Full Backup Found"
                return $null
            }
        }

        'DIFF'
        {
            if(-not $PointInTime)
            {
                $PointInTime = Get-Date
            }
            if(Test-Path (Join-Path -Path $BackupPath -ChildPath 'DIFF'))
            {
                Write-Verbose "Grabbing Most Recent Differential"
                return (Get-ChildItem -Filter "*$($DatabaseName)_DIFF_*" -Path (Join-Path -Path $BackupPath -ChildPath 'DIFF') | Where-Object {$_.LastWriteTime -lt $PointInTime} | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
            }
            else
            {
                Write-Verbose 'No Differentials Found.'
                return $null
            }
        }

        'LOG'
        {
            if(-not $PointInTime)
            {
                $PointInTime = (Get-Date).AddDays(-1)
            }
            Write-Verbose "Grabbing Logs"
            # Potential point of confusiion: "Point in time" here should be the time of most recent full or differential
            $logFile = Get-ChildItem -Filter "*$($DatabaseName)_LOG_*" -Path (Join-Path -Path $BackupPath -ChildPath 'LOG')  | Where-Object {$_.LastWriteTime -gt $PointInTime} | Sort-Object LastWriteTime

            if($logFile)
            {
                Write-Verbose "Log File(S) Found."
                return $logFile
            }
            else
            {
                Write-Verbose "No Log Files Found."
                return $null
            }
        }
        default
        {
            throw "Invalid Backup type Specified."
        }
    }    
}

function Get-DBRelocateFileList
{
    <#
        Description
            Relocate File Lists (RFL) are required when restoring databases in cases where the physical names of the
            database files need to be altered. It's possible to build these manually, but this function will use SMO
            to build said list easily. It's also worth noting that the returned RFL can be modified before being applied
            against a Restore-SQLDatabase or RestoreDB-ToPointInTime invokation.

        Notes
    #>
    Param(
        [Parameter(Mandatory=$True)]  [string]  $ServerName,
        [Parameter(Mandatory=$True)]  [string]  $DatabaseName,
        [Parameter(Mandatory=$True)]  [string]  $BackupFile,
        [Parameter(Mandatory=$True)]  [string]  $DataFilePath,
        [Parameter(Mandatory=$False)] [string]  $LogFilePath = $DataFilePath
    )

    # Load SMO Assemblies. Unfortunately, no good way to handle this with the SQLPS functionality.
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")            | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended")    | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum")        | Out-Null

    $smo = new-object ('Microsoft.SqlServer.Management.Smo.Server') $serverName
 

    $smoBackupDevice     = new-object ('Microsoft.SqlServer.Management.Smo.BackupDeviceItem') ($BackupFile, 'File')
    $smoRestore          = new-object('Microsoft.SqlServer.Management.Smo.Restore')
    $smoRestore.Database = $databaseName
    $smoRestore.Devices.Add($smoBackupDevice)
 
    # Get the file list from the backup file
    $relocateFileList = @()
    foreach ($file in $smoRestore.ReadFileList($smo))
    {
        $smoRestorefile = new-object('Microsoft.SqlServer.Management.Smo.RelocateFile')
        $smoRestorefile.LogicalFileName = $file.LogicalName

        $fileName = $file.physicalname.Replace((Split-Path -Path $file.physicalname), '').replace('\','')

        switch($file.Type)
        {
            'D' # Case for Data Files
            {
                $smoRestorefile.PhysicalFileName = $dataFilePath + $fileName
            }

            'L' # Case for Log Files
            {
                $smoRestorefile.PhysicalFileName = $logFilePath + $fileName
            }
            
            default # This cmdlet isn't configured to handle other file types.
            {
                Write-Verbose 'Not a log or data file, no provision for move.'
            }
        }

        $relocateFileList += $smoRestorefile
    }
 

    return $relocateFileList

}

function RestoreDB-ToPointInTime
{
    <#

        Description
            Parses a backups directory from the SQL Server Maintenance Solution and restores the given database to a specified
            server and point in time.

        Notes

    #>
    Param(
        [Parameter(Mandatory=$True)]                              [string]  $ServerName,
        [Parameter(Mandatory=$True)]                              [string]  $DatabaseName,
        [Parameter(Mandatory=$True)]                              [string]  $BackupPath,
        [Parameter(Mandatory=$False)]                             [DateTime]$PointInTime      = (Get-Date),
        [Parameter(Mandatory=$False)]                             [Object]  $RelocateFileList = @(),
        [Parameter(Mandatory=$False)][ValidateSet($True, $False)] [Boolean] $ForceRecovery    = $True
    )
    
    # Load SMO assemblies potentially needed to handle RelocateFileList
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO")            | Out-Null
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended")    | Out-Null

    # Big thanks to https://connect.microsoft.com/SQLServer/feedback/details/728027/restore-sqldatabase-timeout-expired-the-timeout-period-elapsed-prior-to-completion-of-the-operation
    # for helping resolve an issue using this module in scheduled tasks from lower versions of windows.
    # Sort of buys the worst of both worlds between SMO and SQLPS from a code clarity perspective, but serves as a workaround for now
    $sco = new-object ("Microsoft.SqlServer.Management.Smo.Server") $ServerName
    $sco.ConnectionContext.StatementTimeout = 0 

    # Requires SQL Server 2012 Management Tools to Execute.
    if( -not (Get-Module).Name.Contains('sqlps'))
    {
        Write-Verbose "Loading SQLPS Module"
        $workingDirectory = $PWD   
        Import-Module sqlps -ErrorAction Stop
        Set-Location $workingDirectory # Have to change directory out of the SQL PSDrive or weird things happen.
    }

    # Flag used to determining whether the script should attempt
    # to force DB recovery at end. Useful in cases where backups do not cover requested point-in-time
    $recovered = $False

    # Indicates detection of Differential Files.
    $diffFile = $null

    # Grab most recent full file in backup path.
    $fullFile     = Get-DBBackupFile -DatabaseName $DatabaseName -BackupPath $BackupPath -PointInTime $PointInTime -BackupType FULL
    $lastFileTime = $fullFile.LastWriteTime

    if(-not $fullFile)
    {
        throw "Candidate Full Backup not found." # Can't find a full backup? Can't restore.
    }

    # Grab Most Recent Differential, if it exists
    if(Test-Path (Join-Path -Path $BackupPath -ChildPath 'DIFF'))
    {
        $diffFile = Get-DBBackupFile -DatabaseName $DatabaseName -BackupPath $BackupPath -PointInTime $PointInTime -BackupType DIFF
    }
    
    # Update last file time only if a diff file was found. Otherwise falls straight through to log iteration.
    if($diffFile -and ($diffFile.LastWriteTime -gt $fullFile.LastWriteTime))
    {
        $lastFileTime = $diffFile.LastWriteTime
    }
    else
    {
        # Diff older than full, consider invalid and discard.
        $diffFile = $null
    }

    $logs = Get-DBBackupFile -DatabaseName $DatabaseName -BackupPath $BackupPath -PointInTime $lastFileTime -BackupType LOG

    try
    {
        <#
            Full Backup Recovery Section
        #>
        if($logs -or $diffFile) # Restore most recent full backup, No recovery
        {
            Restore-SqlDatabase -InputObject        $sco `
                                -Database           $DatabaseName `
                                -BackupFile         $fullFile.FullName `
                                -RelocateFile       $RelocateFileList `
                                -ReplaceDatabase `
                                -NoRecovery
        }
        else # No Logs or diffs? Hope your Point in Time is in the full backup log. We'll do our best.
        {
            Restore-SqlDatabase -InputObject        $sco `
                                -Database           $DatabaseName `
                                -BackupFile         $fullFile.FullName `
                                -RelocateFile       $RelocateFileList `
                                -ToPointInTime      $PointInTime `
                                -ReplaceDatabase
        }

        <#
            Differential Backup Recovery Section
        #>
        if($diffFile -and $logs) # Restore Diff with no recovery, since we have logs
        {
            Write-Verbose "Differential and Logs Found"
            Restore-SqlDatabase -InputObject        $sco `
                                -Database         $DatabaseName `
                                -BackupFile       $diffFile.FullName `
                                -ReplaceDatabase `
                                -NoRecovery
        }
        elseif($diffFile) # Restore diff with recovery, since we have no logs
        {
            Write-Verbose "Differential found."
            Restore-SqlDatabase -InputObject        $sco `
                                -Database         $DatabaseName `
                                -BackupFile       $diffFile.FullName `
                                -ToPointInTime    $PointInTime `
                                -ReplaceDatabase
        }
        

        <#
            Transaction Log Backup Recovery Section
        #>
        foreach ($log in $logs)
        {
            if ($log.LastWriteTime -lt $PointInTime) # Roll forward through each log file older than Point in Time.
            {
                Restore-SqlDatabase -InputObject       $sco `
                                    -Database          $DatabaseName `
                                    -BackupFile        $log.FullName `
                                    -ReplaceDatabase `
                                    -NoRecovery

                $lastFileTime = $log.lastWriteTime
            }
            else # Roll forward only the next one log file written after Point in Time, with recovery.
            {
                if ($recovered -eq $False)
                {
                    Restore-SqlDatabase  -InputObject    $sco `
                                         -Database       $DatabaseName `
                                         -BackupFile     $log.FullName `
                                         -ReplaceDatabase `
                                         -ToPointInTime  $PointInTime
                }
                $recovered = $True # Set recovery flag so we don't waste time with the rest of the logs.
            }
        }

        <# 
            Final Recovery Section
            Unless ForceRecovery is specified as $False, make certain the database has, in fact, been recovered.
            This section will alway fire in cases where backups exist, but do not cover all the way up to the
            specified point in time.
        #>
        if(($recovered -eq $False) -and $ForceRecovery)
        {

            $dbState = Invoke-Sqlcmd `
                            -ServerInstance $ServerName `
                            -Database 'master' `
                            -Query "SELECT state_Desc from sys.databases where name = '$DatabaseName';"

            if($dbState.State_desc -eq 'RESTORING')
            {
                Write-Warning "Backups leading up to specified Point in Time not found. Recovering to latest possible moment."
                Write-Warning "Last file restored written $lastFileTime"
                Invoke-Sqlcmd -ServerInstance $ServerName -Database 'master' -Query "RESTORE DATABASE $DatabaseName WITH RECOVERY;"
            }

        }

    }
    catch
    {
        Write-Error "Restore of database failed. Check that the target SQL Server can access all specified files, and consider using a RelocateFileList if neccesary.`nUsing the -verbose flag will also provide additional information."
        return $Error[1]
    }
}