Function Touch-File
{
    <#
    .SYNOPSIS
		Attempt to recreate *nix-style 'touch' command.

    .DESCRIPTION
		Attempt to recreate *nix-style 'touch' command.
    
	.PARAMETER FileName
		Name of file to touch.

    .EXAMPLE
		Touch-File C:\derp.txt

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([System.IO.FileSystemInfo])]
    
    Param
    (
        [Parameter(Mandatory=$True)]
		[String]
		$FileName
    )

    if(Test-Path $FileName -PathType Leaf)
    {
		Write-Verbose "$FileName exists, setting last write date."

		$file = Get-ChildItem $FileName 
        $file.LastWriteTime = Get-Date

		$file
    }
    else
    {
		Write-Verbose "Creating file $FileName"

        New-Item -ItemType File -Path $FileName
    }
}