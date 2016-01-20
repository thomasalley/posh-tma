Function Get-SshPublicKey
{
    <#
    .SYNOPSIS
        Retrieves content of SSH public key, found at ~\.ssh\id_rsa.pub

    .DESCRIPTION
        Retrieves content of SSH public key, found at ~\.ssh\id_rsa.pub
    
	.PARAMETER Path
        Optional param specifying an alternative public key path

    .EXAMPLE
        Get-SshPublicKey | Clip

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([String])]
    
    Param
    (
        [Parameter(Mandatory=$False)]
		[String]
		$Path = "~\.ssh\id_rsa.pub"
    )

    $Path = Resolve-Path $Path

    if(Test-Path $Path -PathType Leaf)
    {
        Get-Content -Path $Path
    }
    else
    {
		Throw "Public Key not found at $Path"
    }
}