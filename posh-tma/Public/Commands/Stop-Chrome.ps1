Function Stop-Chrome
{
    <#
    .SYNOPSIS
        Kills all of Chrome's processes.

    .DESCRIPTION
    
    .EXAMPLE
        Stop-Chrome

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    
    Param
    (
    )

    taskkill /f /IM Chrom*
}