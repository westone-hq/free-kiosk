# Flutter web 실행: 첫 실행 포트를 .web_port 에 저장, 이후 같은 포트로 재실행.
# 이미 떠 있으면 해당 포트 프로세스를 종료한 뒤 다시 시작.
# PC 브라우저: http://localhost:<포트>
# 휴대폰 QR: http://<PC IP>:<포트>  (0.0.0.0 은 주소창에 넣지 마세요)

$ErrorActionPreference = "Continue"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
$PortFile = Join-Path $ProjectRoot ".web_port"
Set-Location $ProjectRoot

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

function Start-PortDetectionJob([int[]]$BeforePorts) {
    return Start-Job -ArgumentList @($PortFile, $BeforePorts) -ScriptBlock {
        param($File, $Before)
        $beforeSet = [System.Collections.Generic.HashSet[int]]::new([int[]]$Before)
        $deadline = (Get-Date).AddSeconds(60)
        while ((Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 1
            foreach ($line in (netstat -ano | Select-String "LISTENING")) {
                if ($line -match ':(\d+)\s') {
                    $p = [int]$matches[1]
                    if ($p -ge 1024 -and $p -notin 9100, 9101 -and -not $beforeSet.Contains($p)) {
                        if ($p -ge 5000 -or $beforeSet.Count -gt 0) {
                            Set-Content -Path $File -Value "$p" -NoNewline -Encoding ascii
                            return
                        }
                    }
                }
            }
        }
    }
}

function Invoke-FlutterWeb([int]$Port) {
    $launchUrl = "http://localhost:$Port"
    Write-Host "PC 브라우저: $launchUrl" -ForegroundColor Green
    Write-Host "휴대폰 QR:   http://<이 PC IP>:$Port" -ForegroundColor DarkGray
    flutter run -d chrome `
        --web-port=$Port `
        --web-hostname=0.0.0.0 `
        --web-launch-url=$launchUrl
}

$savedPort = Read-SavedPort

if ($savedPort) {
    Write-Host "저장된 포트 $savedPort — 기존 프로세스 종료 후 재시작..." -ForegroundColor Yellow
    Stop-PortListeners $savedPort
    Stop-ExistingFlutter
    Invoke-FlutterWeb $savedPort
} else {
    Write-Host "첫 실행 — Flutter가 정한 포트를 자동 저장합니다." -ForegroundColor Yellow
    Write-Host "브라우저: http://localhost:<자동할당>" -ForegroundColor Green
    $before = Get-ListeningPorts
    $detectJob = Start-PortDetectionJob $before
    try {
        flutter run -d chrome --web-hostname=localhost
    } finally {
        Stop-Job $detectJob -ErrorAction SilentlyContinue
        Remove-Job $detectJob -Force -ErrorAction SilentlyContinue
        if (Test-Path $PortFile) {
            $p = Read-SavedPort
            if ($p) {
                Write-Host ""
                Write-Host "포트 $p 저장 (.web_port) — 다음 실행부터 이 포트를 사용합니다." -ForegroundColor Cyan
            }
        }
    }
}
