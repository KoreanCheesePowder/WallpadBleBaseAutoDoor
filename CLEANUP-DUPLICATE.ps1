$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

$TargetName = "C.P BLE Door Presence"
$PreferredPackageKey = "cp-ble-door-presence-discovery"

function Run-STJson {
  param([string[]]$Arguments)
  $text = (& smartthings @Arguments 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "SmartThings CLI failed: smartthings $($Arguments -join ' ')`n$text"
  }
  if ([string]::IsNullOrWhiteSpace($text)) { return @() }
  try { return ($text | ConvertFrom-Json) }
  catch { throw "Could not parse SmartThings CLI JSON output.`n$text" }
}

function As-Array {
  param($Value)
  if ($null -eq $Value) { return @() }
  if ($Value.PSObject.Properties.Name -contains "items") { return @($Value.items) }
  if ($Value -is [System.Array]) { return @($Value) }
  return @($Value)
}

function Get-Id {
  param($Object)
  foreach ($n in @("driverId", "driver_id", "id")) {
    if ($Object.PSObject.Properties.Name -contains $n) {
      $v = [string]$Object.$n
      if (-not [string]::IsNullOrWhiteSpace($v)) { return $v }
    }
  }
  return $null
}

function Get-Name {
  param($Object)
  foreach ($n in @("name", "driverName")) {
    if ($Object.PSObject.Properties.Name -contains $n) {
      return [string]$Object.$n
    }
  }
  return ""
}

function Has-DiscoveryPermission {
  param($Object)
  if (-not ($Object.PSObject.Properties.Name -contains "permissions")) { return $false }
  $p = $Object.permissions
  if ($null -eq $p) { return $false }
  if ($p.PSObject.Properties.Name -contains "discovery") { return $true }
  $s = ($p | ConvertTo-Json -Depth 10 -Compress)
  return ($s -match '"discovery"')
}

function Get-PackageKey {
  param($Object)
  foreach ($n in @("packageKey", "package_key")) {
    if ($Object.PSObject.Properties.Name -contains $n) { return [string]$Object.$n }
  }
  return ""
}

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host " C.P BLE Door Presence duplicate cleanup" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "This script keeps the discovery-enabled driver and removes only stale duplicates." -ForegroundColor DarkGray
Write-Host ""

$ownedRaw = Run-STJson @("edge:drivers", "-j")
$owned = As-Array $ownedRaw
$matches = @($owned | Where-Object { (Get-Name $_) -eq $TargetName })

if ($matches.Count -lt 2) {
  Write-Host "No duplicate driver found. Nothing to clean." -ForegroundColor Green
  exit 0
}

$details = @()
foreach ($m in $matches) {
  $id = Get-Id $m
  if (-not $id) { continue }
  try {
    $d = Run-STJson @("edge:drivers", $id, "-j")
    $arr = As-Array $d
    if ($arr.Count -gt 0) { $details += $arr[0] } else { $details += $m }
  } catch {
    $details += $m
  }
}

Write-Host "Found $($details.Count) drivers named '$TargetName':" -ForegroundColor Yellow
foreach ($d in $details) {
  $id = Get-Id $d
  $disc = Has-DiscoveryPermission $d
  $key = Get-PackageKey $d
  Write-Host "  ID=$id  discovery=$disc  packageKey=$key"
}

$preferred = @($details | Where-Object { (Has-DiscoveryPermission $_) -and ((Get-PackageKey $_) -eq $PreferredPackageKey) })
if ($preferred.Count -eq 0) {
  $preferred = @($details | Where-Object { Has-DiscoveryPermission $_ })
}

if ($preferred.Count -ne 1) {
  Write-Host ""
  Write-Host "ABORT: Could not identify exactly one safe driver to keep." -ForegroundColor Red
  Write-Host "No driver was changed or deleted." -ForegroundColor Red
  exit 2
}

$keep = $preferred[0]
$keepId = Get-Id $keep
$stale = @($details | Where-Object { (Get-Id $_) -ne $keepId })

Write-Host ""
Write-Host "KEEP: $keepId" -ForegroundColor Green
Write-Host ""

# Verify stale drivers are not used by devices before touching them.
foreach ($s in $stale) {
  $sid = Get-Id $s
  $deviceRaw = Run-STJson @("edge:drivers:devices", "--driver", $sid, "-j")
  $devices = As-Array $deviceRaw
  if ($devices.Count -gt 0) {
    Write-Host "ABORT: stale candidate $sid is still used by $($devices.Count) device(s)." -ForegroundColor Red
    Write-Host "No stale driver was deleted." -ForegroundColor Red
    exit 3
  }
}

$channelsRaw = Run-STJson @("edge:channels", "-j")
$channels = As-Array $channelsRaw

foreach ($s in $stale) {
  $sid = Get-Id $s
  Write-Host "Removing stale driver: $sid" -ForegroundColor Yellow

  foreach ($ch in $channels) {
    $cid = $null
    foreach ($n in @("channelId", "channel_id", "id")) {
      if ($ch.PSObject.Properties.Name -contains $n) {
        $cid = [string]$ch.$n
        if ($cid) { break }
      }
    }
    if (-not $cid) { continue }

    try {
      $cdrRaw = Run-STJson @("edge:channels:drivers", $cid, "-j")
      $cdr = As-Array $cdrRaw
      $inChannel = @($cdr | Where-Object { (Get-Id $_) -eq $sid }).Count -gt 0
      if ($inChannel) {
        Write-Host "  Unassigning from channel $cid ..."
        & smartthings edge:channels:unassign $sid -C $cid | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Failed to unassign $sid from channel $cid" }
      }
    } catch {
      throw
    }
  }

  Write-Host "  Deleting stale driver $sid ..."
  & smartthings edge:drivers:delete $sid | Out-Host
  if ($LASTEXITCODE -ne 0) { throw "Failed to delete stale driver $sid" }
}

Write-Host ""
Write-Host "Duplicate cleanup complete." -ForegroundColor Green
Write-Host "Refresh the SmartThings channel page. Only one '$TargetName' should remain." -ForegroundColor Green
