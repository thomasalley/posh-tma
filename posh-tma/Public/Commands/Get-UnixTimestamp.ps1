function Get-UnixTimestamp
{
    <#
    .SYNOPSIS
		Generates a Unix-style timestamp.

    .DESCRIPTION
		Generates a Unix-style timestamp.
    
	.PARAMETER TimeStamp
		Datetime object to convert to the Unix-style Long format.

    .EXAMPLE
		Get-UnixTimestamp

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([Long])]

    param
    (
        [Parameter(Mandatory=$false, ValueFromPipeline=$True)]
        [DateTime]
        $TimeStamp = (Get-Date)
    )
    
    begin
    {
        # Define the beginning of the Unix Epoch
        $gdParams = @{
            Year   = 1970
            Month  = 1
            Day    = 1
            Hour   = 0
            Minute = 0
            Second = 0
        }
    }
    process
    {
        foreach($stamp in $TimeStamp)
        {
            [math]::truncate(($TimeStamp).ToUniversalTime().Subtract((Get-Date @gdParams)).TotalSeconds)
        }
    }

}