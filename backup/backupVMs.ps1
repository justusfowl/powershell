# @Author: JustusFowl

###########################################################################
# Parameters
###########################################################################

param(
[Parameter(Position = 0)]

[string[]]$VMs,
[switch]$flagAllVMs = $false,
[switch]$flagIsTest = $false,
[switch]$flagCoreVMs = $false

)


###########################################################################
# Config
###########################################################################

$configFile = "backupVMs.config.ps1"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configPath = join-path -path $scriptDir -childpath $configFile

. $configPath

Start-Transcript -Path $Global:Logpfad -append

echo "Import config file: $configPath"

echo "Overview over export target drive" 

gdr -Name $Global:Exportpfad.substring(0,1)

###########################################################################
# Funktionen
###########################################################################

Function Protokoll ([string]$Protokolltext="",[string]$currVM="General") {
    if ($Global:verbose -eq $true) { 
        Write-Host (Get-Date) $Protokolltext
    }
    $temp1 = (Get-Date)
    $temp2 = $Protokolltext
    Write-Host "$temp1 - $currVM - $temp2"

    $body += "<br>"
	$body += "$temp1 - $currVM - $temp2"

    #"$temp1 - $currVM - $temp2" | Out-File $Global:Logdatei -Append
}

Function BackupVM ([string]$VM) {
    
    $startTimeForVM = (Get-Date)

    if (!$Logpfad) {
        $LogPfadVorhanden = Test-Path ${env:homedrive}\temp\
        if ($LogPfadVorhanden -eq $False) {
            new-item ${env:homedrive}\temp\ -itemtype directory 
        }
        $Global:Logdatei = "${env:homedrive}\temp\BackupVM-$LogDateiDatum.log" 
    } else { 
        $Global:Logdatei = "$Global:Logpfad\BackupVM-$LogDateiDatum.log"
        New-Item $Global:Logdatei -type file 
    }

    # Startzeit ausgeben
    . Protokoll "Backup der VM $VM gestartet" $VM

    # Test auf Integrationskomponente "Herunterfahren"
    $vmHeartBeat = Get-VM -Name $VM | Get-VMIntegrationService -Name Shutdown
    if($vmHeartBeat.enabled -match "True") {
        . Protokoll "Der Integrationsdienst 'Herunterfahren' ist aktiviert" $VM
    } else {
        . Protokoll "Der Integrationsdienst 'Herunterfahren' ist NICHT aktiviert." $VM
    }

    # Export der VM
    . Protokoll "Export der VM" $VM

    # Falls Export-Ordner vorhanden, erst lÃ¶schen        
    $ExportPfadVorhanden = Test-Path $TargetExportFolder\$VM
    if ($ExportPfadVorhanden -eq $true) { 
        . Protokoll "Exportordner zuerst löschen, um sauberen Export zu erlangen: $TargetExportFolder\$VM" $VM
        Remove-Item -Recurse -Force $TargetExportFolder\$VM    
    }

    # Export starten
    Export-VM -Name $VM -Path $TargetExportFolder 
    . Protokoll "Export der VM abgeschlossen" $VM

    # Export abgeschlossen. Start der VM ?
    . Protokoll "Ueberpruefung auf Startverhalten nach Export" $VM
       
     $endTimeForVM = (Get-Date)
     $timeDiff = NEW-TIMESPAN –Start $startTimeForVM –End $endTimeForVM

    . Protokoll "Backup der VM $VM beendet in Minuten: $timeDiff.TotalMinutes" $VM

    #. Protokoll "Zippen und Archivieren für outpath: $Global:Exportpfad"

    #$outZip = $Global:Archivpfad + "\backup_" + $VM + "_" + $LogDateiDatum + ".zip"

    #. Protokoll "Zippen und Archivieren für Zieldatei: $outZip"

    #[System.IO.Compression.ZipFile]::CreateFromDirectory("$Global:Exportpfad\$VM", $outZip )

    #. Protokoll "Zippen und Archivieren fertig"


    . Protokoll "-------------------------" $VM

    $body += "<br>"
	$body += $VM
}


###########################################################################
# Cleanup of older backup files
###########################################################################

. Protokoll "Backup of all VMs complete, prepare cleaning up maintaining the last $noDays days of backups"

$countBackups = (Get-ChildItem -Path $Global:Exportpfad -Directory -Recurse -Force).Count

if ($countBackups -ge $minNoBackups){
    
    get-childitem $Global:Exportpfad |? {$_.psiscontainer -and $_.lastwritetime -le (get-date).adddays(-$noDays)} |% {
        remove-item $Global:Exportpfad\$_ -force -Recurse
        . Protokoll "remove item $Global:Exportpfad\$_"
    }

    . Protokoll "Cleanup of old backups complete, prepare Mailsending"

}else {

    . Protokoll "Cleanup skipped, $countBackups exists"
}

###########################################################################
# AusfÃ¼hrung Backup
###########################################################################

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Logging des Vorgangs
$LogDateiDatum = Get-Date -Format yyyy-MM-dd

# Falls Export-Ordner vorhanden, erst lÃ¶schen sonst erstellen    

$TargetExportFolder = "${Global:Exportpfad}\Export_${LogDateiDatum}"
    
$ExportPfadVorhanden = Test-Path $TargetExportFolder
if ($ExportPfadVorhanden -eq $true) { 
    . Protokoll "Exportordner zuerst löschen, um sauberen Export zu erlangen: $TargetExportFolder"
    Remove-Item -Recurse -Force $TargetExportFolder    
}else{
    New-Item -ItemType directory -Path $TargetExportFolder
}


if ($flagAllVMs -eq $true){

    ForEach ($VM in Get-VM) {
     . BackupVM($VM.Name)
    }

}ElseIf ($flagCoreVMs -eq $true){

    ForEach ($VM in $CoreVMs) {
     . BackupVM($VM)

    }
    
}ElseIf ($flagIsTest -eq $true){

    . BackupVM($testServer)
    
}else{
    ForEach ($VM in $VMs) {    
       . BackupVM($VM)
    }
}



. Protokoll "Overall done for $LogDateiDatum, send mail..."

Stop-Transcript

###########################################################################
# Sending mail about monitoring
###########################################################################

$message = new-object System.Net.Mail.MailMessage
$message.From = $fromaddress
$message.To.Add($toaddress)
$message.IsBodyHtml = $True
$message.Subject = $Subject
#$attach = new-object Net.Mail.Attachment($attachment)

Get-ChildItem $Global:Logpfad -Filter "*$LogDateiDatum.log" | 
Foreach-Object {
    
    $Attachment = join-path -path $_.DirectoryName -childpath $_.Name
	$message.Attachments.Add($Attachment)
}

$message.body = $body
$smtp = new-object Net.Mail.SmtpClient($smtpserver, 25)

#$smtp.EnableSsl = $true 
if ($smtpAddPW -ne ""){
    $smtp.Credentials = New-Object System.Net.NetworkCredential($smtpMonitoringAdd, $smtpAddPW)
}

$smtp.Send($message)



