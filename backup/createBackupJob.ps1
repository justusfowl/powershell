# @Author: JustusFowl

$configFilePath = "backupVMs.config.ps1"

$arg = -join('-NoProfile -WindowStyle Hidden -File "C:\scripts\powershell\backup\backupVMs.ps1" -flagCoreVMs -PathConfigFile "', $configFilePath, '"')

echo "The Job BackupVMs shall be created with $arg"

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $arg
$trigger =  New-ScheduledTaskTrigger -Daily -At 23pm
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "BackupVMs" -Description "Daily run of the backup script"