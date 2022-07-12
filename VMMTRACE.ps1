Write-host `n"To confirme if VMM Server role exist on this server or not" -ForegroundColor Magenta

sleep 2


$SCVMMServiceYesOrNo = service |findstr -i SCVMMService


if (  $SCVMMServiceYesOrNo  -ne $null)  {
	
	


if ( Test-Path C:\Vmmlogs )  {



Write-host `n"To create C:\Vmmlogs folder if not done yet"

sleep 2

Write-Host `n"To remove all old files under C:\Vmmlogs"   -ForegroundColor Magenta


remove-item C:\Vmmlogs\*



} else {

md  C:\Vmmlogs 


}






Write-Host `n"Start VMM ETL logs collection"   -ForegroundColor Magenta

sleep 2

logman delete VMM 

logman create trace VMM -v mmddhhmm -o c:\VMMlogs\VMMLog_$env:computername.ETL -cnf 01:00:00 -p Microsoft-VirtualMachineManager-Debug -nb 10 250 -bs 16 

logman start vmm



Write-Host `n"To Start WINRM trace"  -ForegroundColor Magenta

start explorer c:\VMMlogs


sleep 2

logman.exe start winrmtrace -p Microsoft-Windows-Winrm -max 10000 -o c:\VMMlogs\winrmtrace.etl -ets



Write-host `n"VMM ETL Logs collection and WINRM logs collection started. please start to reproduce the issue, and dont close this prompt"   -ForegroundColor Magenta


sleep 2
Write-host `n"Once issue reproduce done, press ENTER to stop logs collection"   -ForegroundColor Magenta

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


Write-Host `n"Going to stop WINRM Trace" -ForegroundColor Yellow

sleep 2

logman.exe stop winrmtrace -ets




Write-host `n"Going to stop VMM trace logs collection"     -ForegroundColor Yellow

sleep 2

logman stop vmm

write-host `n"To format the VMM trace & WINRM trace files to txt format"   -ForegroundColor Yellow

$filename = Get-ChildItem C:\vmmlogs\VMM*.etl | Select-Object -ExpandProperty Name

Netsh trace convert C:\vmmlogs\$filename

Netsh trace convert c:\VMMlogs\winrmtrace.etl

write-host `n"To copy the application/system/security/scvmm event log to the C:\VMMLOGS folder"    -ForegroundColor Yellow

sleep 2

Copy-Item "C:\Windows\System32\winevt\Logs\application.evtx" -Destination "C:\VMMLOGS\"
Copy-Item "C:\Windows\System32\winevt\Logs\system.evtx" -Destination "C:\VMMLOGS\"
Copy-Item "C:\Windows\System32\winevt\Logs\security.evtx" -Destination "C:\VMMLOGS\"
Copy-Item "C:\Windows\System32\winevt\Logs\Microsoft-VirtualMachineManager-Server%4Admin.evtx" -Destination "C:\VMMLOGS\"
Copy-Item "C:\Windows\System32\winevt\Logs\Microsoft-VirtualMachineManager-Server%4Operational.evtx" -Destination "C:\VMMLOGS\"



$ServerName = $env:computername

$nowtime = Get-Date -Format "yyyy-MM-dd--HH:mm:ss"

Write-Host `n"To zip the whole C:\VMMLOGS\ folder to desktop and name it as $ServerName_$nowtime.ZIP"     -ForegroundColor Yellow

sleep 2


Compress-archive -LiteralPath c:\vmmlogs  -DestinationPath  C:\WINDOWS\TEMP\$ServerName_$nowtime.ZIP -force   



write-host `n"log collection done. Please share the C:\VMMLOGS\$ServerName_$nowtime.ZIP with engineer"   -ForegroundColor Yellow


sleep 2

start-process explorer C:\WINDOWS\TEMP





} else { 


write-host `n"No SCVMM management service on this server" -ForegroundColor Magenta
write-host `n"The scrip will do nothing"  -ForegroundColor Magenta



} 
