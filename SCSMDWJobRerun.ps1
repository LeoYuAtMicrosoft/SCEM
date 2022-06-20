#To import SCSM modules 

# Service Manager Administrator Module
$InstallationConfigKey = 'HKLM:SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup'
$AdminModule = (Get-ItemProperty -Path $InstallationConfigKey -Name InstallDirectory).InstallDirectory + "Powershell\System.Center.Service.Manager.psd1"
Import-Module -Name $AdminModule
 
# Service Manager Data Warehouse Module
$InstallationConfigKey = 'HKLM:SOFTWARE\Microsoft\System Center\2010\Service Manager\Setup'
$DWModule = (Get-ItemProperty -Path $InstallationConfigKey -Name InstallDirectory).InstallDirectory + "Microsoft.EnterpriseManagement.Warehouse.Cmdlets.psd1"
Import-Module -Name $DWModule

#To stop all jobs


Get-SCDWJob | ForEach-Object{ Stop-SCDWJob -JobName $_.Name}
Get-SCDWJob | ForEach-Object{ Disable-SCDWJob -JobName $_.Name}
Get-SCDWJob | ForEach-Object{ Disable-SCDWJobSchedule -JobName $_.Name}


#To get DB server name 


$regkey_property_name = 'StagingSQLInstance'

$regkey = get-item -Path 'HKLM:\Software\Microsoft\system center\2010\common\database\'
$DW_DBServerName = $regkey.GetValue($regkey_property_name)

if ($DW_DBServerName -eq '.') {
	
$current_server_name = hostname
$DW_DBServerName = $current_server_name
} 

Write-host "The SCSM DW DB server name is $DW_DBServerName " -ForegroundColor Magenta

$regkey_property_name_02 = 'StagingDatabaseName'

$regkey = get-item -Path 'HKLM:\Software\Microsoft\system center\2010\common\database\'
$Staging_DB_Name = $regkey.GetValue($regkey_property_name_02)


write-host "The SCSM DW DB server staging DB name is $Staging_DB_Name  " -ForegroundColor Magenta



#To declare DB connection details.

$SQLServer = $DW_DBServerName
$DB_NAME  = $Staging_DB_Name 



#To retrieve all job name 

  
$Job_List = (get-scdwjob).name


#To disable all jobs


Get-SCDWJob | ForEach-Object{ Stop-SCDWJob -JobName $_.Name}
Get-SCDWJob | ForEach-Object{ Disable-SCDWJob -JobName $_.Name}
Get-SCDWJob | ForEach-Object{ Disable-SCDWJobSchedule -JobName $_.Name}


#To delete all locks

$query01 = "   Delete from LockDetails " 
Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DB_NAME -Query $query01

#To mark all jobs as completed 

$jobs= get-scdwjob

foreach ( $job in $jobs.name ) {
	
	if  ($jobs.status -ne  'Not Started' -or $jobs.status -ne 'Completed' ) 
	
	$job_batchid = $jobs.batchid
	
	$query02 = " UPDATE INFRA.WorkItem SET StatusId = 6 WHERE BatchId = $job_batchid;UPDATE INFRA.Batch SET StatusId = 6 WHERE BatchId = $job_batchid "
	Invoke-Sqlcmd -ServerInstance $SQLServer -Database $DB_NAME -Query $query02
	
	
	
	
} 

