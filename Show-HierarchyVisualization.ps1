Clear-Host
<#$return = Read-Host -Prompt 'Enter the FQDN/IP to the Pure Storage FlashArray'
$user = Read-Host -Prompt 'Username'
$pwd = Read-Host -Prompt 'Password' -AsSecureString
$pattern = Read-Host -Prompt 'Enter Snapshot pattern to destroy and eradicate (Eg. VSS-)'

$FlashArray = New-PfaArray -EndPoint $return -Username $user -Password $pwd -IgnoreCertificateError
#>
$Initiators = Get-PfaHosts -Array $FlashArray

Write-Host '============================'
Write-Host "Hosts on $return"
Write-Host '============================'
ForEach ($Initiator in $Initiators)
{
  Write-Host "  [H] $($Initiator.name)"

  $Volumes = Get-PfaHostVolumeConnections -Array $FlashArray -Name $Initiator.name
  If (!$Volumes)
  {
    Write-Host '   |   |----[No volumes connected]'        
  }
  Else
  {
    ForEach ($Volume in $Volumes)
    {
      Write-Host "   |   |----[V] $($Volume.vol)"
    
      $Snapshots = Get-PfaVolumeSnapshots -Array $FlashArray -VolumeName $Volume.vol
      ForEach ($Snapshot in $Snapshots)
      {
        If (($Snapshot.name) -like "*$pattern*")
        {
          Write-Host ">  |   |       |----[$pattern] $($Snapshot.name)"        
        }
        Else
        {
          #Write-Host "   |   |       |----[S] $($Snapshot.name)"
        }
      }
    }
  }
}

 # $Volumes = Get-PfaHostVolumeConnections -Array $FlashArray -Name 'cody-esxi-05'
