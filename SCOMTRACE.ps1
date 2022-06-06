

Write-host `n"To confirme if SCOM management server / agent /gateway  role exist on this server or not" -ForegroundColor Magenta

sleep 2


$HealthServiceYesOrNo = service |findstr -i healthservice

if (  $HealthServiceYesOrNo   -ne $null)  {



Write-host `n"To check folder C:\Windows\Logs\OpsMgrTrace exit or not"  -ForegroundColor Magenta

sleep 2


if ( Test-Path C:\Windows\Logs\OpsMgrTrace )  {


Write-Host `n"folder C:\Windows\Logs\OpsMgrTrace alerady created. Continue to the next step"   -ForegroundColor Magenta





} else {

md  C:\Windows\Logs\OpsMgrTrace


}

sleep 3
Write-Host `n"Going to start SCOM ETL Logs collection."  -ForegroundColor Magenta

sleep 2


$regkey_property_name = 'InstallDirectory'
$regkey = get-item -Path 'HKLM:\Software\Microsoft\Microsoft Operations Manager\3.0\setup'
$MS_PATH = $regkey.GetValue($regkey_property_name)

Write-Host `n"SCOM installation folder is $MS_PATH"   -ForegroundColor Magenta

sleep 2

Write-Host `n"To stop  SCOM ETL trace process"  -ForegroundColor Magenta

sleep 2

cd $MS_PATH\tools

.\StopTracing.cmd

Write-Host `n"To remove all old files under SCOM ETL trace folders"  -ForegroundColor Magenta


sleep 2

remove-item C:\Windows\Logs\OpsMgrTrace\*


Write-Host `n"To open the trace folder C:\Windows\Logs\OpsMgrTrace"  -ForegroundColor Magenta

sleep 2

start-process explorer C:\Windows\Logs\OpsMgrTrace


Write-Host `n"To start SCOM ETL trace"  -ForegroundColor Magenta

start-sleep 2

.\StartTracing.cmd VER


Write-Host `n"To Start WINRM trace"  -ForegroundColor Magenta


sleep 2

logman.exe start winrmtrace -p Microsoft-Windows-Winrm -max 10000 -o C:\Windows\Logs\OpsMgrTrace\winrmtrace.etl -ets

write-host `n"Please start to reproduce the issue now, and dont close this Powershell prompt"  -ForegroundColor Magenta

start-sleep 1

Write-Host `n"Once issue reproduce done. Please get back to this prompt, and press ENTER on keyboard to trigger the script to stop the log collection" -ForegroundColor Magenta

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


Write-Host `n"Going to stop WINRM Trace" -ForegroundColor Yellow

logman.exe stop winrmtrace -ets


Write-Host `n"Going to format WINRM trace to txt file" -ForegroundColor Yellow


netsh trace convert C:\Windows\Logs\OpsMgrTrace\winrmtrace.etl dump=TXT

write-host `n"Going to stop SCOM ETL Logs collection" -ForegroundColor Yellow

start-sleep 2

.\STOPTracing.cmd VER




Write-Host `n"To copy Windows event log to C:\Windows\Logs\OpsMgrTrace\ folder" -ForegroundColor Yellow


Copy-Item "C:\Windows\System32\winevt\Logs\application.evtx" -Destination "C:\Windows\Logs\OpsMgrTrace\"
Copy-Item "C:\Windows\System32\winevt\Logs\system.evtx" -Destination "C:\Windows\Logs\OpsMgrTrace\"
Copy-Item "C:\Windows\System32\winevt\Logs\Operations Manager.evtx" -Destination "C:\Windows\Logs\OpsMgrTrace\"
Copy-Item "C:\Windows\System32\winevt\Logs\security.evtx" -Destination "C:\Windows\Logs\OpsMgrTrace\"


write-host `n"Going to format the collected SCOM ETL trace log to txt format. This will take a while" -ForegroundColor Yellow

start-sleep 2

move C:\Windows\Logs\OpsMgrTrace\winrmtrace.etl  C:\Windows\Logs\OpsMgrTrace\winrmtrace.etltemp

.\FormatTracing.cmd


move C:\Windows\Logs\OpsMgrTrace\winrmtrace.etltemp C:\Windows\Logs\OpsMgrTrace\winrmtrace.etl

$ServerName = hostname


write-host `n"Going to zip the whole trace folder to file C:\Windows\Logs\$ServerName.zip" -ForegroundColor Yellow

Compress-Archive -LiteralPath C:\Windows\Logs\OpsMgrTrace -DestinationPath C:\Windows\Logs\$ServerName.zip -force


write-host `n"Please share the C:\Windows\Logs\$ServerName.zip with Microsoft Engineer for trouble shooting"  -ForegroundColor Yellow

start-process explorer C:\Windows\Logs\


write-host `n"exiting.."  -ForegroundColor Yellow


sleep 3


} else { 


write-host `n"No SCOM roles been installed on this server" -ForegroundColor Yellow
write-host `n"The scrip will do nothing"  -ForegroundColor Yellow



} 




