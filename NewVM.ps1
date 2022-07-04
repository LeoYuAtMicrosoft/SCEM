#This script will geenrate multiple VM based on a existed VM. The existed VM need to be in power off state.
#该脚本会基于一个已经存在的脚本批量创建多个新的vm。当前存在的VM需要处于关机状态。


$VM = Get-SCVirtualMachine -Name "cent0s7_vhd"   --cent0s7_vhd是需要被复制的VM的名字
$VMHost = Get-SCVMHost -ComputerName "leoyuhyperv01.leoyudomain33.leoyu.com"  --hyperv节点的名字

$i = 10  --需要创建的虚拟机的台数
$j = 1



while ($j -le $i )  { 



$status = (GET-SCJOB  | ? { $_.NAME -eq 'CREATE VIRTUAL MACHINE'  } ).Status  |select -first 1 

if ($VM.Status -eq "PowerOff"  -and $status -ne 'running' ) {


 
New-SCVirtualMachine -Name "VMNAME_$j" -VM $VM -VMHost $VMHost -Path  "\\SCVMM2022.leoyudomain33.leoyu.com\MSSCVMMLibrary" -RunAsynchronously
$j = $j + 1


 } 




}
