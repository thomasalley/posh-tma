function Out-XMLOutput
{
    <#
      Liberated from http://stackoverflow.com/questions/6142053/powershell-output-xml-to-screen
      Seemed like the easiest quick and dirty way to get the XML output into the output buffer for PRTG
      to pick up on.
    #>
    Param
    (
        [Parameter(Mandatory=$True)]
        [object]
        $xml
    )

    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter    = New-Object System.XMl.XmlTextWriter $StringWriter 
    
    $xmlWriter.Formatting = "indented" 
    
    $xml.WriteTo($XmlWriter) 
    
    $XmlWriter.Flush() 
    $StringWriter.Flush()

    Write-Output $StringWriter.ToString() 
}