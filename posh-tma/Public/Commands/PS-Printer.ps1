<#
	TODO
		Pipeline support!
		Refactor commenting / documentaiton
		Consider breaking out into commandlets?

    Description
        Functions for administration of local printers.
        Originally based on http://www.adminarsenal.com/admin-arsenal-blog/how-to-add-printers-with-powershell ; Heavily Modified from original.
    
    Example Usage
        $drivername = 'Xerox Global Print Driver PCL6'
        $printers = @()
        $printers += [PSCustomObject] @{
                                printerName = 'North Medical Records MFP'
                                printerPort = '172.100.1.77'
                                }

        $printers += [PSCustomObject] @{
                                printerName = 'North Nurse Storage MFP'
                                printerPort = '172.100.1.75'
                                }
        foreach($printer in $printers){Add-Printer -ComputerName $ComputerName -Caption $printer.printerName -Shared -PortName $printer.printerPort -driverName $drivername}
#>

Function Add-PrinterIpPort {
	<#
    .SYNOPSIS

    .DESCRIPTION
    
	.PARAMETER 

    .EXAMPLE

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

	[CmdletBinding()]
    #[OutputType([Long])]
    
	param
	(
        [Parameter(Mandatory = $true)]
		$IP,
        
		[Parameter()]
		$ComputerName  = $env:COMPUTERNAME,
        
		[Parameter()]
		$Port          = 9100,
        
		[Parameter()]
		$Name          = $Address,
        
		[Parameter()]
		$SNMP          = $true,
        
		[Parameter()]
		$SNMPCommunity = 'public' 
        )

    $wmi = [wmiclass]"\\$ComputerName\root\cimv2:win32_tcpipPrinterPort"

    $wmi.psbase.scope.options.enablePrivileges = $true

    $port               = $wmi.createInstance()
    $port.name          = $Name
    $port.hostAddress   = $IP
    $port.portNumber    = $Port
    $port.SNMPEnabled   = $SNMP
    $port.SNMPCommunity = $SNMPCommunity
    $port.Protocol      = 1
    $port.put()

    # Cleanup
    $port.Dispose()
    $wmi.Dispose()
}

<#
    Admittedly, not well-tested.
#>
Function Add-PrinterDriver {
	<#
    .SYNOPSIS

    .DESCRIPTION
    
	.PARAMETER 

    .EXAMPLE

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

	[CmdletBinding()]
    #[OutputType([Long])]

    param
	(
        [Parameter(Mandatory = $true)]
		$Name,

        [Parameter(Mandatory = $true)]
		$Path,
        
		[Parameter(Mandatory = $true)]
		$INF,
        
		[Parameter()]$ComputerName  = $env:COMPUTERNAME
        
	)

    $wmi                                       = [wmiclass]"\\$ComputerName\Root\cimv2:Win32_PrinterDriver"
    $wmi.psbase.scope.options.enablePrivileges = $true
    $wmi.psbase.Scope.Options.Impersonation    = [System.Management.ImpersonationLevel]::Impersonate

    $driver            = $wmi.CreateInstance()
    $driver.Name       = $Name
    $driver.DriverPath = $Path
    $driver.InfName    = $INF
    
    $wmi.AddPrinterDriver($driver)
    $wmi.Put()
    
    # Cleanup
    $driver.Dispose()
    $wmi.Dispose()
}

Function Add-Printer {
    Param(
        [Parameter(Mandatory = $true)]
		[string]
		$Name,
        
		[Parameter(Mandatory = $true)]
		[string]
		$PortName,
        
		[Parameter(Mandatory = $true)]
		[string]
		$DriverName,

        [Parameter()]
		[string]
		$ComputerName = $env:COMPUTERNAME,
        
		[Parameter()]
		[switch]
		$Shared       = $false
        
        )

    $wmi = ([WMIClass]"\\$ComputerName\Root\cimv2:Win32_Printer")

    $printer = $wmi.CreateInstance()
    $printer.Caption       = $Name
    $printer.DriverName    = $driverName
    $printer.PortName      = $PortName
    $printer.DeviceID      = $Name
    $printer.location      = $portname
    $printer.description   = $portname

    if($shared)
    {
        $printer.shared    = $Shared
        $printer.shareName = $Name    
    }

    $printer.Put()
    
    # Cleanup
    $printer.Dispose()
    $wmi.Dispose()
}
