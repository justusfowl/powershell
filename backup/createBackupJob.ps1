# @Author: JustusFowl

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -File "C:\scripts\backupVMs.ps1" -flagCoreVMs' 
$trigger =  New-ScheduledTaskTrigger -Daily -At 23pm
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "BackupVMs" -Description "Daily run of the backup script"