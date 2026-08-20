$ErrorActionPreference = "Stop"
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
Set-Location $PSScriptRoot

function Run-ST {
  param([string[]]$Arguments)
  & smartthings @Arguments | Out-Host
  if ($LASTEXITCODE -ne 0) {
    throw "SmartThings CLI command failed: smartthings $($Arguments -join ' ')"
  }
}

function Use-ExistingCapability {
  param(
    [string]$Name,
    [string]$CapabilityId,
    [string]$PresentationFile
  )

  Write-Host "Using existing capability: $Name -> $CapabilityId" -ForegroundColor Green

  # These capabilities were already created by an earlier install attempt.
  # Do not call capabilities:create again. Update presentation in-place.
  Write-Host "Updating presentation for: $CapabilityId" -ForegroundColor Cyan
  Run-ST @("capabilities:presentation:update", $CapabilityId, "-i", $PresentationFile)

  return $CapabilityId
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Write-Host "[1/5] Using existing SmartThings custom capabilities..." -ForegroundColor Cyan
Write-Host "Namespace: buildbook37604" -ForegroundColor DarkGray

Write-Host "[2/5] Updating custom capability presentations..." -ForegroundColor Cyan
$doorCapabilityId = Use-ExistingCapability `
  -Name "Door Proximity" `
  -CapabilityId "buildbook37604.doorProximity" `
  -PresentationFile "custom-capability\door-proximity-presentation.json"

$phoneCountCapabilityId = Use-ExistingCapability `
  -Name "Registered Phones" `
  -CapabilityId "buildbook37604.registeredPhones" `
  -PresentationFile "custom-capability\phone-count-presentation.json"

$pairingCapabilityId = Use-ExistingCapability `
  -Name "Phone Pairing" `
  -CapabilityId "buildbook37604.phonePairing" `
  -PresentationFile "custom-capability\phone-pairing-presentation.json"


$driverInfoCapabilityId = Use-ExistingCapability `
  -Name "Driver Information" `
  -CapabilityId "buildbook37604.driverInformation" `
  -PresentationFile "custom-capability\driver-info-presentation.json"

Write-Host "[3/5] Creating device presentation..." -ForegroundColor Cyan
$deviceConfigTemplate = Get-Content "templates\device-config.json.template" -Raw -Encoding UTF8
$deviceConfigText = $deviceConfigTemplate.Replace("__DOOR_PROXIMITY_CAPABILITY_ID__", $doorCapabilityId)
$deviceConfigText = $deviceConfigText.Replace("__PHONE_COUNT_CAPABILITY_ID__", $phoneCountCapabilityId)
$deviceConfigText = $deviceConfigText.Replace("__PHONE_PAIRING_CAPABILITY_ID__", $pairingCapabilityId)
$deviceConfigText = $deviceConfigText.Replace("__DRIVER_INFO_CAPABILITY_ID__", $driverInfoCapabilityId)

$deviceConfigFile = Join-Path $PSScriptRoot "device-config.generated.json"
[System.IO.File]::WriteAllText($deviceConfigFile, $deviceConfigText, $utf8NoBom)

$presentationFile = Join-Path $PSScriptRoot "device-presentation.generated.json"
if (Test-Path $presentationFile) { Remove-Item $presentationFile -Force }
Run-ST @("presentation:device-config:create", "-i", $deviceConfigFile, "-j", "-o", $presentationFile)
$presentation = Get-Content $presentationFile -Raw -Encoding UTF8 | ConvertFrom-Json

$presentationId = $presentation.vid
if (-not $presentationId) { $presentationId = $presentation.presentationId }
$manufacturerName = $presentation.mnmn
if (-not $manufacturerName) { $manufacturerName = $presentation.manufacturerName }
if (-not $manufacturerName) { $manufacturerName = "SmartThingsCommunity" }

if (-not $presentationId) {
  throw "Unable to determine the device presentation VID."
}

Write-Host "Presentation VID: $presentationId" -ForegroundColor Green

Write-Host "[4/5] Generating profile and Lua source..." -ForegroundColor Cyan
$profileTemplate = Get-Content "templates\ble-door-presence.yml.template" -Raw -Encoding UTF8
$profileText = $profileTemplate.Replace("__DOOR_PROXIMITY_CAPABILITY_ID__", $doorCapabilityId)
$profileText = $profileText.Replace("__PHONE_COUNT_CAPABILITY_ID__", $phoneCountCapabilityId)
$profileText = $profileText.Replace("__PHONE_PAIRING_CAPABILITY_ID__", $pairingCapabilityId)
$profileText = $profileText.Replace("__DRIVER_INFO_CAPABILITY_ID__", $driverInfoCapabilityId)
$profileText = $profileText.Replace("__PRESENTATION_ID__", $presentationId)
$profileText = $profileText.Replace("__MANUFACTURER_NAME__", $manufacturerName)
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot "profiles\ble-door-presence.yml"), $profileText, $utf8NoBom)

$luaTemplate = Get-Content "templates\init.lua.template" -Raw -Encoding UTF8
$luaText = $luaTemplate.Replace("__DOOR_PROXIMITY_CAPABILITY_ID__", $doorCapabilityId)
$luaText = $luaText.Replace("__PHONE_COUNT_CAPABILITY_ID__", $phoneCountCapabilityId)
$luaText = $luaText.Replace("__PHONE_PAIRING_CAPABILITY_ID__", $pairingCapabilityId)
$luaText = $luaText.Replace("__DRIVER_INFO_CAPABILITY_ID__", $driverInfoCapabilityId)
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot "src\init.lua"), $luaText, $utf8NoBom)

Write-Host "[5/5] Packaging and installing driver to hub..." -ForegroundColor Cyan
Run-ST @("edge:drivers:package", ".", "--install")

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host "Next: SmartThings app -> Add device -> Scan nearby." -ForegroundColor Green
Write-Host "The driver probes ESP32-S3 at 192.168.1.101:8900 and creates one device." -ForegroundColor Green
Write-Host "For an automation, use '거리 (RSSI)' or '가까움/멀어짐/못찾음'." -ForegroundColor Green
Write-Host "가까움/멀어짐에서는 RSSI가 0에 가까울수록 가깝고, 못찾음에서는 거리값을 0으로 표시합니다." -ForegroundColor Yellow
Write-Host "v1.3.2: 새 custom capability 생성 없이 SmartThings 표준 momentary 버튼을 사용해 현재 핸드폰 삭제 기능을 추가했습니다." -ForegroundColor Yellow

Write-Host "v1.3.2: 기기 설정에서 삭제할 핸드폰(1~4)을 선택한 뒤 상세화면의 선택한 핸드폰 삭제 버튼을 누르세요." -ForegroundColor Yellow

Write-Host "v1.3.2: 상세화면에 핸드폰 1~4 거리/상태를 각각 표시합니다. 신규 custom capability 생성은 하지 않습니다." -ForegroundColor Yellow
