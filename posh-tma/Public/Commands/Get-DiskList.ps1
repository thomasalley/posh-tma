function Get-DiskList
{
	<#
    .SYNOPSIS
		Lists basic disk information for a given computer.

    .DESCRIPTION
		Lists basic disk information for a given computer.

    .PARAMETER ComputerName
		Computer name to query.
	
	.PARAMETER Table
		Flag, forces output through Format-Table -Autosize

	.PARAMETER All
		Lists all drives, not just HDDs

    .EXAMPLE
        Get-DiskList -ComputerName dc-01 -table

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param
	(
        [Parameter()]
		[string]
		$ComputerName = $env:COMPUTERNAME,

        [Parameter()]
		[switch]
		$Table,

        [Parameter()]
		[switch]
		$All
    )
     
	Begin
	{
		# Initialize drives array.
		$drives = @()

		$disks = Get-WmiObject -Class win32_logicaldisk -ComputerName $computername

		if( -not $All)
		{
			$disks = $disks | Where-Object DriveType -eq 3
		}

		foreach($disk in $disks)
		{
    
			$ID           = $disk.DeviceID
			$Status       = $disk.Status
			$Description  = $disk.Description
			$Name         = $disk.VolumeName
			$Size_GB      = [math]::Round(($disk.Size / 1GB),2)
			$Used_GB      = [math]::Round((($disk.Size - $disk.FreeSpace) / 1GB),2)
			$Free_GB      = [math]::Round(($disk.FreeSpace / 1GB),2)
			$Serial       = $disk.VolumeSerialNumber

			if($disk.size -gt 0)
			{
				$Free_Percent = [math]::Round((($disk.FreeSpace / $disk.Size) * 100), 2)
			}
			else
			{
				$Free_Percent = 0
			}

			$drives += [pscustomobject] @{
											ID           = $ID
											Status       = $Status
											Name         = $Name
											Description  = $Description
											Size_GB      = $Size_GB
											Used_GB      = $Used_GB
											Free_GB      = $Free_GB
											Free_Percent = $Free_Percent
											Serial       = $Serial


										}


		}

		if($Table)
		{
			$drives | Format-Table -AutoSize
			return
		}

		return ( $drives | Sort-Object ID)
	}
}