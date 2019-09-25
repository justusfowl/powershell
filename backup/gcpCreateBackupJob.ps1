# @Author: JustusFowl

###########################################################################
# Parameters
###########################################################################

param(
[Parameter(Position = 0)]
[string]$sourceDir,
[string]$targetDir
)

$arg = -join('-NoProfile -WindowStyle Hidden -File "C:\scripts\powershell\backup\gcpbackup.ps1" -sourceDir "', $sourceDir, '" -targetDir "', $targetDir, '"')

echo "The Job GCPProcessBackups shall be created with $arg"

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $arg
$trigger =  New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GCPProcessBackups" -Description "Daily run of the tape GCP backups"