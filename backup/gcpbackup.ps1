
param(
[Parameter(Position = 0)]

[string]$logfile,
[string]$sourceDir,
[string]$targetDir, 
[string]$passphrase,
[switch]$flagEncryptFile = $false

)

# ensure CLI is loaded and available to the path

$env:Path = "$env:Path;C:\Program Files (x86)\Google\Cloud SDK\google-cloud-sdk\bin"

# Logging des Vorgangs
$LogDateiDatum = Get-Date -Format yyyy-MM-dd

$configFile = "backupVMs.config.ps1"
$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configPath = join-path -path $scriptDir -childpath $configFile

. $configPath

$startTime = (Get-Date)

if ($logfile -eq ""){
    $logfile = "$Global:LogpfadBase\GCP_Tape-Backup-$LogDateiDatum.log"
}else{
    echo "Logging to $logfile"
}

Start-Transcript -Path $logfile -append

if ($sourceDir -eq "" -Or $targetDir -eq ""){
    throw "Please provide both source and target directories for backup"
}

echo "Starting backup to GCP process at $startTime"



    
if ($flagEncryptFile){

    if (!$passphrase){
        throw "If Encryption is chosen to be done with the script, please provide a passphrase"
    }

    # This is the reference source directory from where files are being withdrawn (limit on files only)

    $f = gci $sourceDir | where Mode -ne 'd-----' | sort LastWriteTime | select -last 1

    $fileName = $f.Name

    $fileFullName = $f.FullName

    echo "The following file will be encrypted: $fileFullname"

    # if encryption should be done in the script, ensure that encrypted directory exists

    $sourceEncryptedPath = "$sourceDir\encrypted"

    # if encryption is chosen, the source directory for the GCP sync is set to the encrypted subdir

    $sourceDirSync = $sourceEncryptedPath

    $sourceEncryptedPathExist = Test-Path $sourceEncryptedPath

    if ($sourceEncryptedPathExist -eq $False) {
        new-item $sourceEncryptedPath -itemtype directory 
    }

    # define encrypted output file

    $encryptFile = "$sourceEncryptedPath\tape-$fileName.7z"

    # if this file exists, no further encryption needs to be done

    $encryptFileVorhanden = Test-Path $encryptFile

    if ($encryptFileVorhanden -eq $True) {
        echo "The file $encryptFile already exists. Encryption skipped, this file is taken instead."
    }else{

        $thetime = (Get-Date)
        
        echo "Starting encrypting $fileName into $encryptFile at $thetime..."

        Compress-7Zip -Path $f.FullName -ArchiveFileName $encryptFile -Format SevenZip -Password $passphrase -EncryptFilenames

        if($?){
            $thetime = (Get-Date)
            echo "Encrypting, result: $encryptFile. at $thetime "
            #Write-EventLog -LogName "FFA-Backup" -Source "FFA-GCP-Backup" -EventID 0 -Message "Encrypting, result: $encryptFile."
        }
        else{
            Write-Warning "Encrypting failed"
            #Write-EventLog -LogName "FFA-Backup" -Source "FFA-GCP-Backup" -EventID 1002 -EntryType Information -Message "FFA-Backup failed upon encrypting the file $encryptFile" -Category 1
        }

    }

    
}else{
    echo "The following directory will be backed up: $sourceDir" 
    $sourceDirSync = $sourceDir
}

echo "Starting upload to GCP... "

gsutil rsync $sourceDirSync $targetDir

$thetime = (Get-Date)

if($?){
    echo "Uploading complete. at $thetime"
    #Write-EventLog -LogName "FFA-Backup" -Source "FFA-GCP-Backup" -EventID 0 -Message "Uploading complete."
}
else{
    Write-Warning "Uploading to GCP failed"
    #Write-EventLog -LogName "FFA-Backup" -Source "FFA-GCP-Backup" -EventID 2001 -EntryType Information -Message "FFA-Backup failed upon uploading to GCP" -Category 1
}


Stop-Transcript 