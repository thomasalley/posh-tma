<#

    Get-SurfBoardStats.ps1

    Inspired by https://www.reddit.com/r/homelab/comments/37fk2i/i_just_got_started_with_prtg_so_i_thought_id/

#>
function Get-SurfboardStatus
{
    Param
    (
        [Parameter(Mandatory=$True)]
        [uri] 
        $ModemAddress, # Example: http://x.x.x.x.x.x/cmSignalData.htm

        [Parameter(Mandatory=$False)]
        [ValidateSet("PSObject", "XML")] `
        [string] $Output = "PSObject"

    )

    $modemStats = @{  `
                        DownstreamSNR  = $null
                        DownstreamPL   = $null
                        UpstreamSR     = $null
                        UpstreamPL     = $null
                        CodeWordsC     = $null
                        CodeWordsUC    = $null
                    }

    $webRequest = Invoke-WebRequest -Uri $ModemAddress -UseBasicParsing 

    # Downstream Signal to Noise
    $downstreamSNR = [regex]::match($webRequest.Content,'<TR><TD>Signal to Noise Ratio</TD>\s<TD>(\d+) dB&nbsp;</TD><TD>(\d+) dB&nbsp;</TD><TD>(\d+) dB&nbsp;</TD><TD>(\d+) dB&nbsp;</TD></TR>')

    # Downstream Power Level
    $downstreamPL = [regex]::match($webRequest.Content,'Reload/Refresh this Page for a new reading\s+</SMALL></TD></TR></TBODY></TABLE></TD>\s+<TD>(\d+) dBmV\s+&nbsp;</TD><TD>(\d+) dBmV\s+&nbsp;</TD><TD>(\d+) dBmV\s+&nbsp;</TD><TD>(\d+) dBmV\s+&nbsp;</TD></TR>')

    # Upstream Symbol Rate
    $upstreamSR = [regex]::match($webRequest.Content,'<TR><TD>Symbol Rate</TD>\s+<TD>(\d+\.\d+) Msym/sec&nbsp;</TD><TD>(\d+\.\d+) Msym/sec&nbsp;</TD><TD>(\d+\.\d+) Msym/sec&nbsp;</TD></TR>')

    # Upstream Power Level
    $upstreamPL = [regex]::match($webRequest.Content,'<TR><TD>Power Level</TD>\s+<TD>(\d+) dBmV&nbsp;</TD><TD>(\d+) dBmV&nbsp;</TD><TD>(\d+) dBmV&nbsp;</TD></TR>')

    # Uncorrectable Codewords, for future implementation.
    $codewordsuc = [regex]::match($webRequest.Content,'<TR><TD>Total Uncorrectable Codewords</TD>\s+<TD>(\d+)&nbsp;</TD><TD>(\d+)&nbsp;</TD><TD>(\d+)&nbsp;</TD><TD>(\d+)&nbsp;</TD></TR>')

    # Correctable Codewords, for future implementation.
    $codewordsc = [regex]::match($webRequest.Content,'<TR><TD>Total Correctable Codewords</TD>\s+<TD>(\d+)&nbsp;</TD><TD>(\d+)&nbsp;</TD><TD>(\d+)&nbsp;</TD><TD>(\d+)&nbsp;</TD></TR>')

    # Definitions for the modem stats
    $modemStats.DownstreamSNR = @{  `
                channel         = 'Downstream SNR'
                customUnit      = 'dB'
                float           = '1'
                LimitMode       = '1'
                LimitMinWarning = '33'
                LimitMinError   = '30'
                LimitWarningMsg = 'Signal level out of recommended range.'
                LimitErrorMsg   = 'Signal level out of recommended range.'
                value           = 0
             }

    $modemStats.DownstreamPL = @{  `
                channel         = 'Downstream Power Level'
                customUnit      = 'dBmV'
                float           = '1'
                LimitMode       = '1'
                LimitMinWarning = '0'
                LimitMinError   = '0'
                LimitWarningMsg = 'Signal level out of recommended range.'
                LimitErrorMsg   = 'Signal level out of recommended range.'
                value           = 0
                }

    $modemStats.UpstreamPL = @{  `
                channel         = 'Upstream Power Level'
                customUnit      = 'dBmV'
                float           = '1'
                LimitMode       = '1'
                LimitMinWarning = '30'
                LimitMinError   = '5'
                LimitWarningMsg = 'Signal level out of recommended range.'
                LimitErrorMsg   = 'Signal level out of recommended range.'
                value           = 0
                }
 
    $modemStats.UpstreamSR = @{  `
                channel         = 'Upstream Symbol Rate'
                customUnit      = 'Msym/sec'
                float           = '1'
                LimitMode       = '1'
                LimitMinWarning = '2'
                LimitMinError   = '1'
                LimitWarningMsg = 'Signal level out of recommended range.'
                LimitErrorMsg   = 'Signal level out of recommended range.'
                value           = 0
                }

    $modemStats.CodewordsC = @{  `
                channel         = 'Codewords (Correctable)'
                customUnit      = 'Codewords'
                float           = '1'
                LimitMode       = '1'
                LimitMinWarning = '2'
                LimitMinError   = '1'
                LimitWarningMsg = 'Signal level out of recommended range.'
                LimitErrorMsg   = 'Signal level out of recommended range.'
                value           = 0
                }

    $modemStats.CodewordsUC = @{  `
                channel         = 'Codewords (Uncorrectable)'
                customUnit      = 'Codewords'
                float           = '1'
                LimitMode       = '1'
                LimitMinWarning = '2'
                LimitMinError   = '1'
                LimitWarningMsg = 'Signal level out of recommended range.'
                LimitErrorMsg   = 'Signal level out of recommended range.'
                value           = 0
                }

    # Calculate and insert stat values
    $modemStats.DownstreamSNR.Value = Get-AverageOfArray $downstreamSNR.Groups
    $modemStats.downstreamPL.Value  = Get-AverageOfArray $downstreamPL.Groups
    $modemStats.upstreamPL.Value    = Get-AverageOfArray $upstreamPL.Groups
    $modemStats.upstreamSR.Value    = Get-AverageOfArray $upstreamSR.Groups
    $modemStats.CodewordsC.Value    = Get-AverageOfArray $CodewordsC.Groups
    $modemStats.CodewordsUC.Value   = Get-AverageOfArray $CodewordsUC.Groups

    
    # Build an XML Doc and write XML output, if that flag is set.
    if($Output -eq "XML")
    {
        [System.XML.XMLDocument]$doc = New-Object System.XML.XMLDocument
        [System.XML.XMLElement]$root = $doc.CreateElement("prtg")

        [System.XML.XMLElement]$result = $null

        foreach($stat in $modemStats.Values)
        {
            $result  = $root.appendChild($doc.CreateElement("result"))

            foreach($key in $stat.Keys)
            {
                $tempBuffer = $result.AppendChild($root.appendChild($doc.CreateElement($key)))
                $tempBuffer = $result[$key].InnerText = $stat[$key]
            }
        }

        # Writing all output to a temp variable to prevent writing to host.
        $tempBuffer = $doc.appendChild($root)

        Out-XMLOutput $doc
    }
    else
    {
        return $modemStats
    }
}