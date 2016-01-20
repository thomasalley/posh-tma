Function Get-PushBulletDevice(){
    <#
    .SYNOPSIS

    .DESCRIPTION
		Simple script interfacing PS with Pushbullet. Requires a PB account
        and API key. Works best with the
            
            $env:PushBulletAPIKey = "xxxx"

        Defined in the PS profile.

        TODO
		Comments Refactor
		need Set-PushBulletApiKey
		Pipeline support
    
	.PARAMETER XXXX

    .EXAMPLE

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    Param
	(
        [Parameter(Mandatory=$True)]
		[string]
		$Nickname,

        [Parameter(Mandatory=$False)]
		[string]
		$ApiKey = $env:PushBulletAPIKey
    )

    $ApiAddress = "https://api.pushbullet.com/v2/devices"

    if($ApiKey)
    {
        # Manufacture PS Cred for the Rest request
        $cred = New-Object System.Management.Automation.PSCredential ($ApiKey, (ConvertTo-SecureString " " -AsPlainText -Force))
        
        # Return results from Rest invokation
        $device = (Invoke-RestMethod $ApiAddress -Credential $cred  -Method Get).devices | Where-Object nickname -eq $Nickname
        if($device)
        {
            return $device
        }
        else
        {
            throw "No Device With Nickname $Nickname Found."
        }
    }
    else
    {
        throw 'PushBullet API key required. Preferably specified as $env:PushBulletAPIKey = "xxxx"'
    }

}


Function Send-PushBullet(){
    <#
    .SYNOPSIS

    .DESCRIPTION
		Simple script interfacing PS with Pushbullet. Requires a PB account
        and API key. Works best with the
            
            $env:PushBulletAPIKey = "xxxx"

        Defined in the PS profile.
        TODO
		Comments Refactor
		need Set-PushBulletApiKey
		Pipeline support
    
	.PARAMETER XXXX

    .EXAMPLE

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$True)]
        [string]
        $Content,
        
        [Parameter(Mandatory=$False)]
        [string]
        $Title = "Push from Send-PushBullet",
        
        [Parameter(Mandatory=$False)]
        [string]
        $DeviceNickname,

        [Parameter(Mandatory=$False)]
        [switch]
        $StrictDelivery,
        
        [Parameter(Mandatory=$False)]
        [string]
        $ApiKey = $env:PushBulletAPIKey
    )
    
    $ApiAddress = "https://api.pushbullet.com/v2/pushes"
    
    $restBody = "type=note;title=$Title;body=$content;"
    
    if($DeviceNickname)
    {
        try
        {
            $pbDevice = Get-PushBulletDevice -Nickname $DeviceNickname
            $restBody = "target_device_iden=" + $pbDevice.iden + ";" + $restBody   
        }
        catch
        {
            if($StrictDelivery)
            {
                Write-Error "Specified device not found, and StrictDelivery flag has been set. Exiting."
                return $null
            }
            else
            {
                Write-Warning "Specified device not found, and StrictDelivery flag not set. Pushing as broadcast to all devices."
            }
        }
    }

    if($ApiKey)
    {
        # Manufacture PS Cred for the Rest request
        $cred = New-Object System.Management.Automation.PSCredential ($ApiKey, (ConvertTo-SecureString " " -AsPlainText -Force))
        
        # Return results from Rest invokation
        return Invoke-RestMethod $ApiAddress -Credential $cred  -Method Post -Body $restBody
    }

    else
    {
        Write-Error 'PushBullet API key required. Preferably specified as $env:PushBulletAPIKey = "xxxx"'
        return $null
    }

}
