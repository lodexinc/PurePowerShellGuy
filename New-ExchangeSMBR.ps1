Add-PsSnapin VMware.VimAutomation.Core -ea "SilentlyContinue" -Verbose
Add-pssnapin Microsoft.Exchange.Management.PowerShell.E2010
 
$EndPoint = '10.21.8.17'
$MailboxDbVol = 'Barkz-Ex13-Db-01'
$Datastore = 'Barkz-Datastore-1'
$MailboxDbVolSnapSuffix = 'MANUAL-05'
$HostGroupName = 'Barkz-SJ-vCenter'
$vCenter = '10.21.8.11'
$VMHost = '10.21.8.31'
$VM = 'Exchange 2013'
 
$FlashArray = New-PfaArray -EndPoint $EndPoint -Credentials(Get-Credential) -IgnoreCertificateError
 
#region Provision new volume and new mailbox database.
#<#
$VolName = Read-Host "Name of the volume to create?"
$VolSize = Read-Host "Size of $VolName in TB?"
$Serial = New-PfaVolume -Array $FlashArray -VolumeName $VolName -Unit TB -Size $VolSize | Select serial
New-PfaHostGroupVolumeConnection -Array $FlashArray -VolumeName $VolName -HostGroupName $HostGroupName
 
Connect-ViServer -Server $vCenter -User 'administrator@csglab.purestorage.com' -Password 'Flash4All!' | Out-Null
Get-VMHostStorage -VMHost $VMHost  -RescanAllHba -RescanVmfs | Out-Null
$CanonicalName = "naa.624a9370" + ($Serial.serial).ToLower()
Get-ScsiLun -vmhost $VMHost -CanonicalName $CanonicalName
$DeviceName = "/vmfs/devices/disks/naa.624a9370" + ($Serial.serial).ToLower()
New-HardDisk -VM $VM -DiskType rawPhysical -DeviceName $DeviceName
Disconnect-VIServer  -Server $vCenter -Force -Confirm:$false | Out-Null
 
$NewPartition = (Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' } | Select Number).Number
Initialize-Disk -Number $NewPartition
$Drive = New-Partition -DiskNumber $NewPartition -UseMaximumSize -AssignDriveLetter | Select DriveLetter
Format-Volume -DriveLetter $Drive.DriveLetter -Confirm:$false -Force
 
New-MailboxDatabase -Name $VolName -Server 'EX13-1.csglab.purestorage.com' -EdbFilePath "F:\$VolName\$VolName.edb" -LogFolderPath 'F:\Logs'
Restart-Service -Name MSExchangeIS -Force
Get-MailboxDatabase
 
#>
#endregion
 
#region Create snapshot and mount for recovery use.
#<#
New-PfaVolumeSnapshots -Array $FlashArray -Sources $MailboxDbVol -Suffix $MailboxDbVolSnapSuffix
$Serial = New-PfaVolume -Array $FlashArray -Source "$MailboxDbVol.$MailboxDbVolSnapSuffix" -VolumeName "Mailbox-SMBR-$MailboxDbVolSnapSuffix" | Select serial
New-PfaHostGroupVolumeConnection -Array $FlashArray -VolumeName "Mailbox-SMBR-$MailboxDbVolSnapSuffix" -HostGroupName $HostGroupName
 
Connect-ViServer -Server $vCenter -User 'administrator@csglab.purestorage.com' -Password 'Flash4All!' | Out-Null
Get-VMHostStorage -VMHost $VMHost  -RescanAllHba -RescanVmfs | Out-Null
$CanonicalName = "naa.624a9370" + ($Serial.serial).ToLower()
Get-ScsiLun -vmhost $VMHost -CanonicalName $CanonicalName
$DeviceName = "/vmfs/devices/disks/naa.624a9370" + ($Serial.serial).ToLower()
New-HardDisk -VM $VM -DiskType rawPhysical -DeviceName $DeviceName
Disconnect-VIServer  -Server $vCenter -Force -Confirm:$false | Out-Null
 
$NewHD = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Offline' } | Select Number
Set-Disk -Number $NewHD.Number -IsOffline:$false
#>
#endregion
 
#region Restore mailbox database from snapshot.
#<#
Get-MailboxDatabase
$MailboxDb = (Get-MailboxDatabase).Name
Get-MailboxDatabaseCopyStatus -Identity $MailboxDb
Dismount-Database $MailboxDb
Get-Disk -Number 1
Set-Disk -Number 1 -IsOffline:$true
Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $MailboxDbVol | Select name, created | Format-Table -AutoSize
$snapshotsource = Read-Host "Which snapshot do you want to restore? "
New-PfaVolume -Array $FlashArray -Source $snapshotsource -VolumeName $MailboxDbVol -Overwrite
Set-Disk -Number 1 -IsOffline:$false
Mount-Database -Identity $MailboxDb
Get-MailboxDatabaseCopyStatus -Identity $MailboxDb
#>
