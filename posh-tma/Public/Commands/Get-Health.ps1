function Get-Health
{
    <#
    .SYNOPSIS
        WMI Query Script to ascertain the general health of a given machine.

    .DESCRIPTION

	.PARAMETER XXX

    .EXAMPLE

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    try
    {
        if(Check-Online($ComputerName))
        {
            # Set up WMI Connections

            $wmi_OS       = Get-WmiObject -Class Win32_OperatingSystem -computerName $ComputerName
            $wmi_MEM      = Get-WmiObject -Class Win32_PhysicalMemory  -computerName $ComputerName
            $wmi_DISK     = Get-WmiObject -Class Win32_logicaldisk     -computerName $ComputerName
            $wmi_CS       = Get-WmiObject -Class Win32_ComputerSystem  -computername $ComputerName
            $wmi_PROC     = Get-WmiObject -Class Win32_processor       -ComputerName $ComputerName
            $wmi_BIOS     = Get-WmiObject -Class Win32_BIOS            -ComputerName $ComputerName
            $wmi_MONITORS = Get-WmiObject -Class Win32_DesktopMonitor  -ComputerName $ComputerName
            $wmi_VIDEO    = Get-WmiObject -Class Win32_VideoController -ComputerName $ComputerName
         
            # Pull AD Data for Computer
            $computerADObject = Get-ADComputer $ComputerName
        
            # Determine Installed Memory
            foreach($device in $wmi_MEM)
            {
                $memTotal += $device.Capacity
            }
            $MemoryInstalled = ($memTotal/1MB)

            # Build array of display adapter objects.
            # Filter out Dameware and LANDesk display adapters.
            $displayAdapters = @()
            foreach($adapter in ($wmi_VIDEO | select Name | where { $_.Name -notlike "LANdesk*"} | where {$_.Name -notlike "DameWare*"}))
            {
                $displayAdapters += [pscustomobject] @{ Name = $adapter.Name }
            }

            # Build array of monitor objects.
            $monitors = @()
            foreach($monitor in ($wmi_MONITORS | where {$_.ScreenHeight -ge 0} | select DeviceID, ScreenHeight, ScreenWidth))
            {
                $monitors += [pscustomobject]@{
                                                    ID = $monitor.deviceid
                                                    Width = $monitor.screenWidth
                                                    Height = $monitor.screenHeight
                                                }
            }


            # Rounded Disk Statistics
            $disks = @()
            foreach($device in $wmi_DISK)
            {
                $disks += [pscustomobject]@{
                                                Volume = $device.name
                                                Name = $device.VolumeName
                                                Size = [decimal]::round($device.Size/1Gb,1)
                                                Free = [decimal]::round($device.FreeSpace/1Gb,1)
                                            }
            }

            # Build and Return Final Computer Health Object
            return [pscustomobject] @{
                                            Name = $computerADObject.DNSHostName
                                            IP = (([System.Net.Dns]::GetHostAddresses($ComputerName)) | Select-Object -ExpandProperty IPAddressToString)
                                            OS = $wmi_OS.Caption + $wmi_OS.OSArchitecture
                                            BootTime = $wmi_OS.ConvertToDateTime($wmi_OS.LastBootUpTime)
                                            CurrentUser = $wmi_CS.UserName
                                            Type = $wmi_CS.SystemType
                                            Model = $wmi_CS.Model
                                            Serial = $wmi_BIOS.SerialNumber
                                            Description = $wmi_OS.description
                                            Status = $wmi_OS.status
                                            MemoryMBs = $MemoryInstalled
                                            Monitors = $monitors
                                            DisplayAdapters = $displayAdapters
                                            Disks = $disks
                                            ADObject = $computerADObject
                                        }
        }
        else
        {
            throw "Object Not Reachable"
        }
    }
    catch
    {
        throw "Error Connecting to Computer."
    }
}