#Get public and private function definition files.
$Public  = @( Get-ChildItem -Recurse -Path $PSScriptRoot\Public\*.ps* -Exclude *tests* )#-ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Recurse -Path $PSScriptRoot\Private\*.ps* -Exclude *.tests.ps1)# -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Write-Verbose "Importing $import"

        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error "Failed to import function $($import.fullname): $_"
        }
    }

Export-ModuleMember -Function $Public.Basename