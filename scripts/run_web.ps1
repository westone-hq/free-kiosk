# Flutter web + 프로젝트 data/runtime/ 저장
# - 계정·주문 JSON → data/runtime/ (재시작해도 유지)
# - PC: http://localhost:<포트>

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$PortFile = Join-Path $ProjectRoot ".web_port"
$StoragePort = 8765
$ChromeProfile = Join-Path $ProjectRoot ".chrome_profile"
$RuntimeDir = Join-Path $ProjectRoot "data\runtime"
Set-Location $ProjectRoot

if (-not (Test-Path $RuntimeDir)) {
    New-Item -ItemType Directory -Path $RuntimeDir -Force | Out-Null
}

function Get-ListeningPorts {
    $ports = [System.Collections.Generic.HashSet[int]]::new()
    foreach ($line in (netstat -ano | Select-String "LISTENING")) {
        if ($line -match ':(\d+)\s') {
            [void]$ports.Add([int]$matches[1])
        }
    }
    return @($ports)
}

function Stop-PortListeners([int]$Port) {
    foreach ($line in (netstat -ano | Select-String "LISTENING" | Select-String ":$Port\s")) {
        if ($line -match '\s(\d+)\s*$') {
            $procId = [int]$matches[1]
            if ($procId -gt 0) {
                taskkill /F /PID $procId 2>$null | Out-Null
            }
        }
    }
}

function Stop-ExistingFlutter {
    Get-Process -Name "dart" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
}

function Read-SavedPort {
    if (-not (Test-Path $PortFile)) { return $null }
    $raw = (Get-Content $PortFile -Raw).Trim()
    if ($raw -match '^\d+$') { return [int]$raw }
    return $null
}

function Start-StorageServer {
    Stop-PortListeners $StoragePort
    $job = Start-Process -FilePath "python" `
        -ArgumentList @("tools/file_storage_server.py", "--port", "$StoragePort") `
        -PassThru -WindowStyle Hidden
    Start-Sleep -Milliseconds 500
    return $job
}

function Invoke-FlutterWeb([int]$Port, [System.Diagnostics.Process]$StorageProc) {
    $launchUrl = "http://localhost:$Port"
    $fileServer = "http://127.0.0.1:$StoragePort"
    Write-Host ""
    Write-Host "데이터 저장: $RuntimeDir" -ForegroundColor Cyan
    Write-Host "PC 브라우저: $launchUrl" -ForegroundColor Green
    Write-Host "휴대폰 QR:   http://<이 PC IP>:$Port" -ForegroundColor DarkGray
    Write-Host ""
    try {
        flutter run -d chrome `
            --web-port=$Port `
            --web-hostname=0.0.0.0 `
            --web-launch-url=$launchUrl `
            --dart-define=KIOSK_FILE_SERVER=$fileServer `
            --web-browser-flag="--user-data-dir=$ChromeProfile"
    } finally {
        if ($StorageProc -and -not $StorageProc.HasExited) {
            Stop-Process -Id $StorageProc.Id -Force -ErrorAction SilentlyContinue
        }
    }
}

$webPort = Read-SavedPort
if (-not $webPort) { $webPort = 8080 }

Write-Host "저장 서버 + Flutter web 시작 (포트 $webPort)..." -ForegroundColor Yellow
Stop-PortListeners $webPort
Stop-PortListeners $StoragePort
Stop-ExistingFlutter

$storageProc = Start-StorageServer
Set-Content -Path $PortFile -Value "$webPort" -NoNewline -Encoding ascii
Invoke-FlutterWeb $webPort $storageProc
