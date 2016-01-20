function Send-SpotifyCommand
{
	<#
    .SYNOPSIS

    .DESCRIPTION

    .PARAMETER 

    .EXAMPLE

    .FUNCTIONALITY

    .NOTES

    .LINK
        
    #>

    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param
	(
        [Parameter(Mandatory=$True)]
		[switch]
		$All
    )
     
	Begin
	{
        try
        {
            # Take a stab at grabbing Spotify's window handle
            $HWND = Get-Process 'Spotify' | Where-Object MainWindowHandle -ne 0 | Select -ExpandProperty MainWindowHandle

            # Stole these from
            # https://code.google.com/p/spotifycmd/source/browse/trunk/spotify_cmd.cpp
            $APPCOMMAND     = 0x0319

            # TO DO
            # Convert this to a dictionary
            # Use a validated command name param to index

            $CMD_PLAYPAUSE  = 917504
            $CMD_MUTE       = 524288
            $CMD_VOLUMEDOWN = 589824
            $CMD_VOLUMEUP   = 655360
            $CMD_STOP       = 851968
            $CMD_PREVIOUS   = 786432
            $CMD_NEXT       = 720896

            # Stole this from
            # http://stackoverflow.com/questions/9891585/sendmessage-is-causing-script-to-hang
            #Store the C# signature of the SendMessage function. 
            $signature = @"
[DllImport("user32.dll")]
public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
"@

            #Add the SendMessage function as a static method of a class
            $SendMessage = Add-Type -MemberDefinition $signature -Name "Win32SendMessage" -Namespace Win32Functions -PassThru

            #Invoke the SendMessage Function

            [void]($SendMessage::SendMessage($HWND, $APPCOMMAND, 0, $CMD_PLAYPAUSE))
        }
        catch
        {
            throw "Send Command Failed"
        }
    }
}