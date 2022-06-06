

Write-Host `n"Starting the script now"  -ForegroundColor Magenta


Sleep 2


function WerDump
{
    [CmdletBinding()]
    Param
    (
        # Computer to enable dumps on
        [Parameter(ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('DNSHostName')]
        [string[]]
        $ComputerName = 'localhost',

        # Name of a process to create dumps for
        [Parameter(Position=1)]
        [string]
        $Process,

        # The path where the dump files are to be stored
        [Parameter(Position=2)]
        [Alias('Path')]
        [string]
        $DumpFolder = '%LOCALAPPDATA%\CrashDumps',

        # The maximum number of dump files in the folder
        [Parameter(Position=3)]
        [int]
        $DumpCount = 10,

        # The type of dump that should be created
        [Parameter(Position=4)]
        [ValidateSet('CustomDump','MiniDump','FullDump')]
        [string]
        $DumpType = 'MiniDump',

        # The custom dump options to be used.
        [Parameter(Position=5)]
        [int]
        $CustomDumpFlags = 121
    )

    Begin
    {
        
        If ($Process)
        {
            Write-Verbose "Validating 'Process' parameter value..."
            switch -regex ($Process)
            {
                '.+\.exe$'   {Write-Verbose "Parameter value is valid.";break}
                '^.+(\..+)$' {throw "Invalid extension '$($Matches[1])' detected. Make sure the process has a '.exe' extension."}
                default      {$Process = "$Process.exe";Write-Verbose "Added '.exe' extension to process value."}
            }
        }
        If ($DumpType -ne 'CustomDump' -and $CustomDumpFlags -ne 121)
            {
                Throw "The parameter 'CustomDumpFlags' can only be used when 'DumpType' is set to 'CustomDump'."
            }
        switch ($DumpType)
        {
            'CustomDump' {$DumpTypeData = 0}
            'MiniDump'   {$DumpTypeData = 1}
            'FullDump'   {$DumpTypeData = 2}
        }
        If ($DumpType -eq 'CustomDump')
        {
            Write-Verbose "Converting CustomDumpFlags value to decimal..."
            $CustomDumpFlags = [Convert]::ToInt32($CustomDumpFlags,16)
            Write-Verbose "Conversion complete."
        }
    }
    Process
    {
        foreach ($Computer in $ComputerName)
        {
            Write-Verbose "Processing computer '$Computer'..."

            Write-Verbose "->`tChecking DumpFolder existence..."
            Try
            {
                If ($DumpFolder -ne '%LOCALAPPDATA%\CrashDumps')
                {
                    $DumpFolderUNC = "\\$Computer\$($DumpFolder.Replace(':','$'))"
                    If (Test-Path $DumpFolderUNC)
                    {
                        Write-Verbose "->`tFolder '$DumpFolder' already exists."
                    }
                    else
                    {
                        Write-Verbose "->`tCreating folder '$DumpFolder'..."
                        $Folder = New-Item $DumpFolderUNC -ItemType Directory -ea 1
                        Write-Verbose "->`tFolder created."
                    }
                }
            }
            catch
            {
                Write-Error $_
                continue
            }
            Write-Verbose "->`tConnecting to registry..."
            try
            {
                $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $Computer)
                Write-Verbose "->`tConnection established."
            }
            catch
            {
                Write-Error $_
                continue
            }
            try
            {
                $Key = $Reg.OpenSubKey('SOFTWARE\Microsoft\Windows\Windows Error Reporting',$true)
                If ($Key.GetSubKeyNames() -notcontains 'LocalDumps')
                {
                    Write-Verbose "->`tCreating LocalDumps registry key..."
                    $Null = $Key.CreateSubKey('LocalDumps')
                    Write-Verbose "->`tKey created."
                }
                else
                {
                    Write-Verbose "->`tKey already exists."
                }
                $DumpKey = $Key.OpenSubKey('LocalDumps',$true)
                If ($Process)
                {
                    If ($DumpKey.GetSubKeyNames() -notcontains $Process)
                    {
                        Write-Verbose "->`tCreating '$Process' subkey..."
                        $null = $DumpKey.CreateSubKey($Process)
                        Write-Verbose "->`tSubkey created."
                    }
                    $DumpKey = $DumpKey.OpenSubKey($Process,$true)
                }
                Write-Verbose "->`tSetting values for User-Mode dumps..."
                $Null = $DumpKey.SetValue('DumpFolder', $DumpFolder, [Microsoft.Win32.RegistryValueKind]::ExpandString)
                Write-Verbose "`t->`tDumpFolder value set to '$DumpFolder'"
                $Null = $DumpKey.SetValue('DumpCount', $DumpCount, [Microsoft.Win32.RegistryValueKind]::DWORD)
                Write-Verbose "`t->`tDumpCount value set to '$DumpCount'"
                $Null = $DumpKey.SetValue('DumpType', $DumpTypeData, [Microsoft.Win32.RegistryValueKind]::DWORD)
                Write-Verbose "`t->`tDumpType value set to '$DumpTypeData'"
                If ($DumpType -eq 'CustomDump')
                {
                    $Null = $DumpKey.SetValue('CustomDumpFlags', $CustomDumpFlags, [Microsoft.Win32.RegistryValueKind]::DWORD)
                    Write-Verbose "->`t`tCustomDumpFlags value set to '$CustomDumpFlags'"
                }
                Write-Verbose "->`tAll required values were set."
            }
            catch
            {
                Write-Error $_
                $Reg.Close()
                continue
            }
            $Reg.Close()
            Write-Verbose "->`tRegistry connection closed."
            $WerSVC = Get-Service WerSvc -ComputerName $Computer
            If ($WerSVC.Status -eq 'Running')
            {
                Write-Verbose "->`tRestarting WER Service (WerSvc)..."
                $WerSVC | Restart-Service
                If ($?)
                {
                    Write-Verbose "->`tService restarted."
                }
            }
            else
            {
                Write-Verbose "->`tStarting WER Service (WerSvc)..."
                $WerSVC | Start-Service
                If ($?)
                {
                    Write-Verbose "->`tService started."
                }
            }
            Write-Verbose "Finished processing computer."
        } #end foreach computer
    }
    End
    {
        Write-Verbose 'All computers have been processed.'
    }
}



Write-Host `n"Please input the process name. You may refer to below example.  


----------------------------------------
System center virtual machine machine (SCVMM): 

!!!For VMM service, please input vmmservice.exe
!!!For VMM console, please input vmmadminui.exe

----------------------------------------
System center Operations manager (SCOM):

For system center data access service, please input Microsoft.Mom.Sdk.ServiceHost.exe
For SCOM  Console, please input Microsoft.EnterpriseManagement.Monitoring.Console.exe
For Microsoft Monitoring agent service, please input healthservice.exe
----------------------------------------
For the full process name of the other service, please check in task manager"  -ForegroundColor Magenta


[string]$ProcessName = $( Read-Host "Input process name now to continue, please" )



if ( !$ProcessName  -or $ProcessName -notlike "*exe" ) {
	
	
Write-Host `n"The process name can not be empty or null , and it has to end with .exe"   -ForegroundColor Magenta

Write-Host `n"Please rerun the script and fill in the corrent process name"   -ForegroundColor Magenta
	
	
	
} else {



	Write-Host `n"The process name is $ProcessName"  -ForegroundColor Magenta

	Write-host `n"To back up the registry HKLM\Software\Microsoft\Windows and save the file on desktop before making any change"  -ForegroundColor Magenta

	sleep 2 


	cd ~\desktop
	Reg export HKLM\Software\Microsoft\Windows  .\RegistryBackup.reg
	
	Write-Host `n"To enable the WER crash report for process  $ProcessName" -ForegroundColor Magenta
	
	sleep 3 
	
	$ServerName = hostname 
	
	WerDump -ComputerName $ServerName -Process $ProcessName -DumpFolder C:\Windows\TEMP -DumpType FullDump
	
	Write-Host `n"Please reproduce the issue now and once service crashed, please check if the dump file been auto created or not under C:\Windows\TEMP" -ForegroundColor Magenta
	
	
	start explorer C:\Windows\TEMP
	sleep 2
	
	Write-Host `n"Exiting.." -ForegroundColor Magenta
	
	
	
}




