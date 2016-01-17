"C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1\"
Import-Module VMware.VimAutomation.Cis.Core

$Creds = Get-Credential
$FlashArray = New-PfaArray -EndPoint 10.21.8.110 -Credentials $Creds -IgnoreCertificateError -Version 1.4

$ESXHosts = @('B200M4-01','B200M4-02','B200M4-03','B200M4-04',`
              'B200M4-05','B200M4-06','B200M4-07','B200M4-08')
$ExVolNamePrefix = 'EX'

For($i=2;$i -le 24; $i++)
{
    For($z=2; $z -le 7; $z++)
    {
        For($x=1; $x -le 4; $x++) 
        {
            #New-PfaVolume -Array $FlashArray -VolumeName "$ExVolName-$i-DB$x" -Size 2 -Unit TB 
            #New-PfaVolume -Array $FlashArray -VolumeName "$ExVolName-$i-LOG$x" -Size 200 -Unit GB
            
            New-PfaHostVolumeConnection -Array $FlashArray `
                -VolumeName "$ExVolName-$i-DB$x" -HostName $ESXHosts[$z]
            New-PfaHostVolumeConnection -Array $FlashArray `
                -VolumeName "$ExVolName-$i-LOG$x" -HostName $ESXHosts[$z]
        }
    }
}


break
$vCenterIP = '10.21.8.162'
$vCenterCluster = 'Pure-ME'
$vCenterAdmin = 'PSME\Administrator'
$Pwd = ConvertTo-SecureString 'Flash4All!' -AsPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential ($vCenterAdmin, $pwd)

Connect-VIServer -Server $vCenterIP -Credential $Creds 
Get-Cluster $vCenterCluster | Get-VMHost | Get-VMHostStorage -RescanAllHba -RescanVmfs | Out-Null
Get-ScsiLun -VmHost (Get-VMHost) | Where-Object { $_.CanonicalName -like 'naa.624*' } | Select-Object CanonicalName