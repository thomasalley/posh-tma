function Send-Dashing
{
    <#

    .SYNOPSIS
		Updates a value in the Dashing dashboard system.

    .DESCRIPTION
		Wrapper for Invoke-RestMethod which ensures that connections are forcibly closed
        once the message has been sent to Dashing.
    
	.PARAMETER xxx

    .EXAMPLE
            $url = "http://derpcodashing:3030/widgets/derpcoboard"
            $json = @{
                        auth_token = "YOUR_AUTH_TOKEN";
                        current    = 10
                    } | ConvertTo-Json

            Send-Dashing -URL $url -JSON $json

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([Object])]
    
    Param
	(
        [Parameter(Mandatory=$true)]
		[string]
		$url,
        
		[Parameter(Mandatory=$true)]
		[object]
		$json,
        
		[Parameter()]
		[int]
		$Timeout = 5
    )


    $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($url)
    
    $ReturnData = Invoke-RestMethod -TimeoutSec 2 -uri $url -Method Post -Body $json
    
    $ServicePoint = $ServicePoint.CloseConnectionGroup("")

    return $ReturnData
}