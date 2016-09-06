Clear-Host

#Connect to Pure Storage FlashArray
$returnIP = Read-Host -Prompt 'Enter the FQDN/IP to the Pure Storage FlashArray'
$user = Read-Host -Prompt 'Username'
$pwd = Read-Host -Prompt 'Password' -AsSecureString

$FlashArray = New-PfaArray -EndPoint $returnIP -UserName $user -Password $pwd -IgnoreCertificateError

$ORAService = Get-Service -Name *OracleService* 
$stopORA = Read-Host "Is it ok to stop the Oracle Service ($($ORAService.Name)) [Y/N]"
If ($stopORA.ToUpper() -eq 'Y') 
{
    # Stop Oracle database service
    Stop-Service -Name $ORAService.Name #-Force

    # Get a list of volumes to select from
    Get-PfaVolumes -Array $FlashArray | Select name | Format-Table -AutoSize
    $returnVols = Read-Host -Prompt 'what volume(s) would you like to snapshot [Eg. vol1,vol2]'
    $snapvolumes = @($returnVols.Split(','))

    #1. On host TCUWRGEQA01, unmount (remove path of) a Windows disk, e.g. volume name GEQA. Example path; E:\app\oracle\oradata\GEQA\DATAFILE
    $oraDataFile = 3 #G:\oracle\oradata\PURE
    $oraLogFile = 4 #H:\oracle\redologs\PURE

    #2. Offline the disk, volume name GEQA.

    Get-Disk -Number 3 | select number, friendlyname, operationalstatus
    Set-Disk -Number 3 -IsOffline $True
    Get-Disk -Number 3 | select number, friendlyname, operationalstatus

    Get-Disk -Number 4 | select number, friendlyname, operationalstatus
    Set-Disk -Number 4 -IsOffline $True
    Get-Disk -Number 4 | select number, friendlyname, operationalstatus

    New-PfaVolumeSnapshots -Array $FlashArray -Sources $snapvolumes[0]
    New-PfaVolumeSnapshots -Array $FlashArray -Sources $snapvolumes[1]

    ForEach($snapvolume in $snapvolumes)
    {
        Write-Host "$snapvolume Snapshots"
        Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $snapvolume | select name, created | Format-Table -Autosize
    }

    #5. Create a new snapshot of the goldcopy.
    #6. Create a R/W copy of the new snapshot of the gold copy.
    #===>>> I think they mean copy the snapshot to destination volume(s)
    $returnSnapshots = Read-Host -Prompt "What snapshot for [$snapvolume] would you like to restore (Eg. datasnap1,logsnap1)"
    $snaprestores = @($returnSnapshots.Split(','))
    New-PfaVolume -Array $FlashArray -VolumeName $snapvolumes[0] -Source $snaprestores[0] -Overwrite | Out-Null
    New-PfaVolume -Array $FlashArray -VolumeName $snapvolumes[1] -Source $snaprestores[1] -Overwrite | Out-Null


    #11. Online the disk, volume name GEQA.
    Set-Disk -Number 3 -IsOffline $False
    Get-Disk -Number 3 | select number, friendlyname, operationalstatus

    Set-Disk -Number 4 -IsOffline $False
    Get-Disk -Number 4 | select number, friendlyname, operationalstatus

    Start-Service $ORAService.Name

} Else {
    Write-Warning 'No operations have been performed on the Pure Storage FlashArray or Oracle.'
}