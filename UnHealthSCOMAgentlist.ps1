#Import the OperationsManager module
Import-Module OperationsManager
   
#Get SCOM agents in grey state
$Agent = Get-SCOMClass -Name Microsoft.Windows.Computer
$Objects = Get-SCOMMonitoringObject -class:$Agent | Where-Object {$_.IsAvailable –eq $false}
  
# Setup array
$SCOMArray = @()
  
# Loop through the servers
ForEach ($Object in $Objects)
{
    Write-Host "Processing: " -NoNewline
    Write-host $object.DisplayName -ForegroundColor Green
     
    # Checking primary managemnt server
    $Mgmt = (Get-SCOMAgent -Name $object.DisplayName).PrimaryManagementServerName
     
    # Create a custom object 
    $SCOMObject = New-Object PSCustomObject
    $SCOMObject | Add-Member -MemberType NoteProperty -Name "Server" -Value $object.DisplayName
    $SCOMObject | Add-Member -MemberType NoteProperty -Name "AD Site" -Value $object."[Microsoft.Windows.Computer].ActiveDirectorySite"
    $SCOMObject | Add-Member -MemberType NoteProperty -Name "Primary Management Server" -Value $Mgmt
    $SCOMObject | Add-Member -MemberType NoteProperty -Name "Last Modified" -Value $object.LastModified
    $SCOMObject | Add-Member -MemberType NoteProperty -Name "IsAvailable" -Value $object.IsAvailable
    $SCOMObject | Add-Member -MemberType NoteProperty -Name "Health state" -Value $object.HealthState
    $SCOMObject | Add-Member -MemberType NoteProperty -Name "In Maintenance Mode" -Value $object.InMaintenanceMode
  
    # Add custom object to our array
    $SCOMArray += $SCOMObject
}
  
# Display results in console
$SCOMArray | Format-Table -AutoSize -Wrap
 
# Open results in pop-up window
$SCOMArray | Out-GridView -Title "Unhealthy SCOM Agents"
 
# Save results to CSV 
$SCOMArray | Export-Csv -Path "C:\temp\results.csv" -NoTypeInformation -Force
notepad c:\temp\results.csv
