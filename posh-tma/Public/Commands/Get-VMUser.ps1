function Get-VMUser()
{
    <#

    .SYNOPSIS
        Takes VM object(s) from the pipeline and queries them for some basic data about the logged-on user.

    .DESCRIPTION
		Generates a Unix-style timestamp.
    
	.PARAMETER TimeStamp

    .EXAMPLE
        Get-VM -name DERPCOV* | Get-VMUser | Format-Table

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    $vms = @()
    $vminfo = @()

    foreach($obj in $input)
    {
        $vms += $obj
    }

    if($vms.Count -eq 0)
    {
        # Throw exception if invoked without any VMs in the pipeline.
        # TODO: Improve this error message and error handling
        throw 'This Commandlet requires VMs from the pipeline. Also this message needs to be improved.'
    }

    ForEach( $vm in $vms )  
    {
        # Everybody loves a progress bar!
        Write-Progress -PercentComplete ($vminfo.count / $vms.count * 100) -Activity 'Querying VM Details' -Status ([string]::Format('{0} of {1} ({2})', $vminfo.count, $vms.count, $vm.name))
        
        $vmguest = $vm | Get-VMGuest

        $guestHostName = $vmguest.HostName
        $guestName     = $vm.name
        $guestIP       = $vmguest
        $guestOSName   = $vmguest.OSFullName

        if( ($guestHostName -ne $null) -and (Test-Connection -ComputerName $guestHostName -Count 1 -Quiet -TimeToLive 2 -ErrorAction SilentlyContinue))
        {
            try
            {
                $vmUserName = (Get-WmiObject -Class win32_computersystem -ComputerName $guestHostName).UserName
            }
            catch
            {
                $vmUserName = "[OS Not Supported]"
            }

            $obj = [pscustomobject]@{
                                    Name     = $guestName
                                    User     = $vmUserName
                                    State    = 'Online'
                                    Hostname = $guestHostName
                                    VMHost   = $vm.vmhost
                                    IP       = $guestIP.IPAddress.Replace('{','').Replace('}','')
                                    # OS       = $GuestOSName
                                    }
            $vminfo += $obj
        }
        else
        {
            $obj = [pscustomobject]@{
                                    Name     = $guestName
                                    User     = $null
                                    State    = 'offline'
                                    Hostname = $null
                                    VMHost   = $vm.vmhost
                                    IP       = $null
                                    # OS       = $null
                                    }
            $vminfo += $obj
        }

        
    }

    return $vminfo | Sort-Object name
}