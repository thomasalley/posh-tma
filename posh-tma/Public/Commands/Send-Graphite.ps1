function Send-Graphite
{
    <#

    .SYNOPSIS
		Sends a metric to Graphite.

    .DESCRIPTION
		CMDlet to send a simple message to Graphite.
        Sources & Inspirations:
            Timestamp code inspired by https://gist.github.com/rdsimes/4333461
            Basic structure modified from http://pshscripts.blogspot.co.uk/2008/12/send-udpdatagramps1.html
    	
		TODO
		Refactor Comments
		Pipeline support
		Proper commandlet bindings
    
	.PARAMETER ServerName
		Hostname of graphite server.

	.PARAMETER Metric
		Metric Name

	.PARAMETER Value
		Metric value.

	.PARAMETER TimeStamp
		Metric timestamp. Defaults to current timestamp.
    
	.PARAMETER Port
		Port graphite server is listening on.
    
	.PARAMETER TCP
		Flag; Forces TCP connection instead of UDP connection.

    .EXAMPLE
        Send-Graphite -ServerName DERPCOGRAPHSVR -Metric Testing.PSMetrics -Value 30

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
		
    Param
	(
        [Parameter(Mandatory=$True)]
        [string]
        $ServerName,

        [Parameter(Mandatory=$True)]
        [string]
        $Metric,

        [Parameter(Mandatory=$True)]
        [string]
        $Value,

        [Parameter(Mandatory=$False)]
        [DateTime]
        $TimeStamp = (Get-Date),

        [Parameter(Mandatory=$False)]
        [string]
        $Port = "2003",

        [Parameter(Mandatory=$False)]
        [switch]
        $TCP
    )
	Begin
	{
		try
		{
			# Attempt to resolve Hostname.
			$destinationIP  = [system.net.IPAddress]::Parse([System.Net.Dns]::GetHostAddresses($serverName)) 
		}
		catch
		{
			throw "Error Resolving Hostname."
		}

		# Build Message
		# Timestamp has to be seconds since beginning of Unix epoch
		$convertedTimeStamp = Get-UnixTimestamp $TimeStamp
		$message   = "$metric $value $convertedTimeStamp`n"

		try
		{
			#  Build Socket Connection
			$ipEndpoint    = New-Object System.Net.IPEndPoint $destinationIP, $Port 
			$addressFamily = [System.Net.Sockets.AddressFamily]::InterNetwork
        
			switch($tcp)
			{
				$False # Should be the default course
				{
					$socketetType = [System.Net.Sockets.SocketType]::Dgram
					$protocolType = [System.Net.Sockets.ProtocolType]::UDP
				}

				$True
				{
					$socketetType = [System.Net.Sockets.SocketType]::Stream
					$protocolType = [System.Net.Sockets.ProtocolType]::tcp
				}
			}

			# connect to endpoint.
			$socket     = New-Object System.Net.Sockets.Socket $addressFamily, $socketetType, $protocolType 
			$socket.TTL = 64 
			$socket.Connect($ipEndpoint) 

			# Encode Message into an ASCII buffer and transmit.
			$buffer    = [System.Text.Encoding]::ASCII.GetBytes($Message)
			$sentBytes = $socket.Send($buffer) 
        
			# Cleanup connection opbjects.
			$socket.Close()
			$socket.Dispose()
		}
		catch
		{
			throw "Error Sending Message."
		}

		return [pscustomobject] @{
			Metric        = $Metric
			Value         = $Value
			TimeStamp     = $timestamp
			UnixTimestamp = $convertedTimeStamp
			Server        = $destinationIP
			Port          = $Port
			Protocol      = $protocolType.ToString().ToUpper()
			Bytes         = $sentBytes
			Message       = $message
			}
	}
}