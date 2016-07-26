$FlashArrayID = Read-Host -Prompt "Enter the Pure Storage FlashArray (IP/FQDN)" 
$FlashArray = New-PfaArray -EndPoint $FlashArrayID -Credentials (Get-Credential) -IgnoreCertificateError

$ConnectedVolumes = @($null)
$AllVolumes = @($null)
$DisconnectedVolumes = @($null)
$z=0

$Hosts = Get-PfaHosts -Array $FlashArray
ForEach ($HostVol in $Hosts) {
    $ConnectedVolumes += @(Get-PfaHostVolumeConnections -Array $FlashArray -Name $HostVol.name | select vol)
}

$AllVolumes = @(Get-PfaVolumes -Array $FlashArray | select name)
$hash= @{}

foreach ($i in $ConnectedVolumes) {
    $Vol = $i.vol
    $hash.Add($z, $Vol)
    $z++
}

foreach($j in $AllVolumes) {
   if(!$hash.ContainsValue($j.name)){
        $DisconnectedVolumes += $j.name
    }
    else {
        $hash.Remove($j.name)
    }
}

$DisconnectedVolumes


