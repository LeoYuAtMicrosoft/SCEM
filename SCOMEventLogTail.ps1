

Function Get-WinEventTail
{
        [CmdletBinding()]
    Param
        (
        [string]$LogName = 'System',
        [int]$ShowExisting = 10
        )
    Begin
    {
        if ($ShowExisting -gt 0)
        {
            $Data = Get-WinEvent -LogName $LogName -MaxEvents $ShowExisting
            $Data |Sort-Object -Property RecordId
            $Index1 = $Data[0].RecordId
            }
        else
        {
            $Index1 = (Get-WinEvent -LogName $LogName -MaxEvents 1).RecordId
            }
        }
    Process
    {
        while ($true)
        {
            Start-Sleep -Seconds 1
            $Index2  = (Get-WinEvent -LogName $LogName -MaxEvents 1).RecordId
            if ($Index2 -gt $Index1)
            {
                Get-WinEvent -LogName $LogName -MaxEvents ($Index2 - $Index1) |Sort-Object -Property RecordId
                }
            $Index1 = $Index2
            }
        }
    End
    {
        }
    }

    Get-WinEventTail -LogName 'Operations Manager'
