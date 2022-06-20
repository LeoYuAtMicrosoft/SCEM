<#
//-----------------------------------------------------------------------

//     Copyright (c) {charbelnemnom.com}. All rights reserved.

//-----------------------------------------------------------------------

 .SYNOPSIS
Get the list of all Virtual Machines in SCVMM including their disks.

.DESCRIPTION
Get the list of all  Virtual Machines in Virtual Machine Manager and enumerate all their drives.

.NOTES
File Name : Get-SCVMVirtualDisk.ps1
Author    : Charbel Nemnom
Version   : 4.0
Date      : 05-February-2018
Requires  : PowerShell Version 3.0 or above
OS        : Windows Server 2012 R2 or 2016
Product   : System Center Virtual Machine Manager 2012 R2 or 2016

.LINK
To provide feedback or for further assistance please visit:
https://charbelnemnom.com

.EXAMPLE
./Get-SCVMVirtualDisk -VMMServerName <VMMServerName>
This example will get all Virtual Machines including their Virtual Disks from VMM <VMMServerName>,
Then calculate the size and percentage used by each VM/VHD(X), total disk size of all VMs and send the report via e-mail.

.EXAMPLE
./Get-SCVMVirtualDisk -VMMServerName <VMMServerName> -HostGroupName <HostGroupName>
This example will get all Virtual Machines including their Virtual Disks from a particular VMM Host Group <HostGroupName>,
Then calculate the size and percentage used by each VM/VHD(X), total disk size of all VMs and send the report via e-mail.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,HelpMessage='VMM Server Name')]
    [Alias('VMMServer')]
    [String]$VMMServerName,
      
    [Parameter(HelpMessage='VMM Host Group Name')]
    [Alias('GroupName')]
    [String]$HostGroupName
  )

Try {
    # Connect to VMM Server
    Write-Verbose "Connecting to VMM server..."
    New-CimSession -ComputerName $VMMServerName -ErrorAction Stop | Out-Null
    }
    Catch {
    Write-Error "Cannot connect to VMM Server: $($Error[0].Exception.Message) Exiting"
    Exit
    }

# Variables
$filedate   = Get-date
$FromEmail  = "VMMReport@domain.net"
$ToEmail1   = "ITAdmin@domain.net"
$ToEmail2   = "ITOperator@domain.net"
$tableColor = "WhiteSmoke"
$DiskSpaceUsed = $null

# Establish Connection to SMTP server
$smtpServer = "smtp.mail.net"
$smtpCreds  = new-object Net.NetworkCredential("username", "password")
$smtp       = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.UseDefaultCredentials = $false
$smtp.Credentials = $smtpCreds

# HTML Style Definition
$report = "<!DOCTYPE html  PUBLIC`"-//W3C//DTD XHTML 1.0 Strict//EN`"  `"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd`">"
$report = "<html xmlns=`"http://www.w3.org/1999/xhtml`"><body>"
$report = "<style>"
$report = $report + "TABLE{border-width:2px;border-style: solid;border-color: #C0C0C0 ;border-collapse: collapse;width: 100%}"
$report = $report + "TH{border-width: 2px;padding: 0px;border-style: solid;border-color: #C0C0C0 ;text-align: left}"
$report = $report + "TD{border-width: 2px;padding: 0px;border-style: solid;border-color: #C0C0C0 ;text-align: left}"
$report = $report + "TD{border-width: 2px;padding: 0px;border-style: solid;border-color: #C0C0C0 ;text-align: left}"
$report = $report + "H1{font-family:Calibri;}"
$report = $report + "H2{font-family:Calibri;}"
$report = $report + "Body{font-family:Calibri;}"
$report = $report + "</style>"
$report += "<center><p style=""font-size:12px;color:#BDBDBD"">Get-SCVMVirtualDisk - ScriptVersion: 4.0 | Created By: Charbel Nemnom - CDM MVP | Feedback: https://charbelnemnom.com</p></center>"

# Report Header
$report = $report + "<h1>Virtual Machines and Virtual Hard Disks Report on: $($VMMServerName)</h1>"

If ($HostGroupName)
{
    # Report Title
    $report = $report + "<h2>Data for VMM Host Group: $($HostGroupName) : $($filedate)</h2>"
    Write-Verbose "Get VMM Host Group..."
    $hostGroups = Get-SCVMHostGroup -Name $HostGroupName -VMMServer $VMMServerName
    If (!$hostGroups) {
        Write-Error "VMM Host Group named $($HostGroupName) does not exist... Exiting!"
        Exit }
    $hostGroups =  $hostGroups.AllChildHosts
    Foreach ($hostGroup in $hostGroups)
        {
        $SCVMs += @(Get-SCVirtualMachine -VMMServer $VMMServerName -VMHost $HostGroup.Name) 
        }
}
Else
    {
    $SCVMs += @(Get-SCVirtualMachine -VMMServer $VMMServerName)
    }

Write-Verbose "Generating Report"
Foreach ($SCVM in $SCVMs)
{
$DiskUsed = $null
Write-Verbose "Checking VM: $SCVM Virtual Hard Disks on $($SCVM.HostName)"
$SCVHDs = Get-SCVirtualMachine $SCVM.Name -VMHost $SCVM.HostName | Get-SCVirtualHardDisk | Select-Object Size
Foreach ($SCVHD in $SCVHDs) {
$DiskUsed += $SCVHD.Size
}
$DiskSpaceUsed += $DiskUsed
$report = $report + "<style>TH{background-color:Indigo}TR{background-color:$($tableColor)}</style>"
$report = $report + (Get-SCVirtualMachine $SCVM.Name | Select-Object @{Label="Host Name";Expression={$_.VMHost}},@{Label="VM Name";Expression={$_.Name}},@{Label="Computer Name";Expression={$_.ComputerName}},@{Label="VM Generation";Expression={$_.Generation}} | ConvertTo-HTML -as Table -Fragment)
$report = $report + "<style>TH{background-color:Blue}TR{background-color:$($tableColor)}</style>"
$report = $report + (Get-SCVirtualMachine $SCVM.Name | Get-SCVirtualDiskDrive | Select-Object @{Label="VHD Name";Expression={$_.VirtualHardDisk}},@{Label="Controller Type";Expression={$_.BusType}},Lun | ConvertTo-HTML -as Table -Fragment)
$report = $report + "<style>TH{background-color:DarkGreen}TR{background-color:$($tableColor)}</style>"
$report = $report + (Get-SCVirtualMachine $SCVM.Name | Get-SCVirtualHardDisk | Select-Object @{Label="VHD Type";Expression={$_.VHDType}},@{Label="VHD Location";Expression={$_.Location}}, `
        @{Label="Max Disk Size (GB)";Expression={($_.MaximumSize/1GB)}},@{Label="Disk Space Used (GB)";Expression={"{0:N2}" -f ($_.Size/1GB)}}, `
        @{Label="Disk Space Used (%)";Expression={[math]::Round((($_.Size/1GB)/($_.MaximumSize/1GB))*100)}}, `
        @{Label="Free Disk Space (GB)";Expression={"{0:N2}" -f (($_.MaximumSize/1GB) - ($_.Size/1GB))}} | ConvertTo-HTML -as Table -Fragment)
$report = $report + "<B>Total Disk Space Used for VM: $($SCVM.Name) in (GB) is $({{0:N2}} -f ($DiskUsed/1GB))</B>" + " <br>"
$report = $report + " <br>"
}

Write-Verbose "Calculating Total Disk Space Used for All Virtual Machines..."
$report = $report + "<h4><B>Total Disk Space Used for All VMs in (GB) is $({{0:N2}} -f ($DiskSpaceUsed/1GB))</B></h4>"

# Finalizing Report
Write-Verbose "Finalizing Report"
$report = $report + "</body></html>"

#Save the report to C:\Windows\temp\report.html

write-host "exporting the result to C:\Windows\temp\report.html"

$report  |out-file -FilePath C:\Windows\temp\report.html

write-host "open the report folder"

start-explorer "C:\Windows\temp\"

# Send Email
#Write-Verbose "Sending Report"
#$email = new-object Net.Mail.MailMessage
#$email.Priority = [System.Net.Mail.MailPriority]::High
#$email.Subject = "Virtual Machines and Virtual Hard Disks Report: $($filedate)"
#$email.From = new-object Net.Mail.MailAddress($FromEmail)
#$email.IsBodyHtml = $true
#$email.Body =  $report
#$email.To.Add($ToEmail1)
#$email.To.Add($ToEmail2)
#$smtp.Send($email)
