#powershell script port of https://github.com/maxhauser/semver/
function toSemVer($version){
    $version -match "^(?<major>\d+)(\.(?<minor>\d+))?(\.(?<patch>\d+))?(\-(?<pre>[0-9A-Za-z\-\.]+))?(\+(?<build>[0-9A-Za-z\-\.]+))?$" | Out-Null
    $major = [int]$matches['major']
    $minor = [int]$matches['minor']
    $patch = [int]$matches['patch']
    
    if($matches['pre'] -eq $null){$pre = @()}
    else{$pre = $matches['pre'].Split(".")}

    New-Object PSObject -Property @{ 
 	# Major = $major
	# Minor = $minor
	# Patch = $patch
	# Pre = $pre
        VersionString = $version
        }
}


function compareSemVer($a, $b){
    $result = 0
#    $result =  $a.Major.CompareTo($b.Major)
    if($result -ne 0){return $result}

#    $result = $a.Minor.CompareTo($b.Minor)
    if($result -ne 0){return $result}

#    $result = $a.Patch.CompareTo($b.Patch)
    if($result -ne 0){return $result}
    $ap = $a.Pre
    $bp = $b.Pre
    if($ap.Length  -eq 0 -and $bp.Length -eq 0) {return 0}
    if($ap.Length  -eq 0){return 1}
    if($bp.Length  -eq 0){return -1}
    
    $minLength = [Math]::Min($ap.Length, $bp.Length)
    for($i = 0; $i -lt $minLength; $i++){
        $ac = $ap[$i]
        $bc = $bp[$i]

        $anum = 0 
        $bnum = 0
        $aIsNum = [Int]::TryParse($ac, [ref] $anum)
        $bIsNum = [Int]::TryParse($bc, [ref] $bnum)

        if($aIsNum -and $bIsNum) { 
           #  Write-Host "2" $a.VersionString $b.VersionString $anum $bnum $anum.CompareTo($bnum)
            $result = $anum.CompareTo($bnum) 
            if($result -ne 0)
            {
                return $result
            }
        }
        if($aIsNum) {
            # Write-Host "3" $a.VersionString $b.VersionString
            return -1
        }
        if($bIsNum) {
           # Write-Host "4" $a.VersionString $b.VersionString $bIsNum $aIsNum $ac $bc $ap.Length $bp.Length $i
        return 1}
        
        $result = [string]::CompareOrdinal($ac, $bc)
        if($result -ne 0) {
        
        return $result
        }
    }
   # Write-Host "comparing lengths" $ap.Length $bp.Length $ap.Length.CompareTo($bp.Length) $a.VersionString $b.VersionString
    return $ap.Length.CompareTo($bp.Length)
}

function rankedSemVer($versions){
    
    for($i = 0; $i -lt $versions.Length; $i++){
        $rank = 0
        for($j = 0; $j -lt $versions.Length; $j++){
            $diff = 0
            $diff = compareSemVer $versions[$i] $versions[$j]
            if($diff -gt 0) {
                #Write-Host $versions[$i].VersionString "is greater than " $versions[$j].VersionString " got diff " $diff
                $rank++
            }
        }
        $current = [PsObject]$versions[$i]
        Add-Member -InputObject $current -MemberType NoteProperty -Name Rank -Value $rank
    }
    return $versions
}



$versionStr = @(
                "1.0.0-alpha",
                "1.0.0-alpha.1",
                "1.0.0-alpha.beta",
                "1.0.0-beta",
                "1.0.0-beta.2",
                "1.0.0-beta.11",
                "1.0.0-rc.1",
                "1.0.0",
                "1.0.1",
                "1.1.0",
                "2.0.0"
            )

$versions = @()
$versions = (Get-Content core-leankit-api-semvers )

foreach  ($line in $lines) {
    # trim off the v for sorting
    $basesemver = $line.Trim("v"," ")
#    write-host "basesemver is $basesemver"
    $basesemvers += $basesemver
#    $basesemvers=@()
#    $basesemvers.Add($basesemver)
#    $basesemvers = $basesemvers+$basesemver
#    $basesemvers
#$basesemvers = $basesemvers+=$basesemver
#Sort-Object Name -Descending
    write-host "basesemver is $basesemver"
}

foreach($v in $versionStr) {$basesemvers += toSemVer $v}
$versions = rankedSemVer($basesemvers)
$versions | Sort-Object -Property Rank -Descending | Select #-First 10

exit

foreach($v in $versionStr) {$versions += toSemVer $v}
$versions = rankedSemVer($versions)
$versions | Sort-Object -Property Rank -Descending | Select #-First 10
