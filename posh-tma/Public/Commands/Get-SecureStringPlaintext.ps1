function Get-SecureStringPlaintext
{
    <#
    .SYNOPSIS
        Converts a SecureString to Plaintext. Warning: This can have serious security implications.

    .DESCRIPTION
        Converts a SecureString to Plaintext. Warning: This can have serious security implications.

    .PARAMETER SecureString
        SecureString to convert to plaintext.

    .EXAMPLE
        New-RandomSecureString | Get-SecureStringPlaintext

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([String])]

    param
    (
        [Parameter(Mandatory=$True, ValueFromPipeline)]
        [SecureString]
        $SecureString
    )

    Process
    {
        [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString))
    }
}