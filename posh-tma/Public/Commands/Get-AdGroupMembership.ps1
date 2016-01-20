function Get-ADGroupMembership
{
	<#
    .SYNOPSIS
		Lists groups a given AD User is a member of.

    .DESCRIPTION
		Lists groups a given AD User is a member of. Requires ActiveDirectory Module.

	.PARAMETER UserName

    .EXAMPLE
		Get-ADGroupMembership -Username tma

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([Microsoft.ActiveDirectory.Management.ADPrincipal])]
    Param
    (
        [Parameter(Mandatory=$True)]
        [string]
        $UserName
    )
    Begin
	{
		$membership = @()
		try
		{
			$ADObject = Get-ADUser $UserName -Properties memberof
			Write-Verbose ("Fetching memberships for {0}" -f $ADObject.DistinguishedName )
		}
		catch
		{
			throw $Error[0]
		}

		try
		{
			if($ADObject -eq $null)
			{
				$ADObject = Get-ADUser $UserName -Properties memberof
			 }
		}
		catch
		{
			Write-Verbose "Hit error block."
			throw "AD User or Group Not Found."
		}
    
		foreach($g in $ADObject.memberof)
		{
			Write-Verbose "Grabbing Group Object For $g"
			$membership += Get-ADGroup $g
		}
    
		Write-Verbose "Finished grabbing groups."
		return $membership | Sort-Object name
	}
}