# @Author: JustusFowl

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -File "C:\scripts\powershell\backup\backupVMs.ps1" -flagCoreVMs *> "..\..\logs\BackupVM-$(get-date -f yyyy-MM-dd).log"'
$trigger =  New-ScheduledTaskTrigger -Daily -At 23pm
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "BackupVMs" -Description "Daily run of the backup script"