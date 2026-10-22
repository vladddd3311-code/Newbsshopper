<#
    =============================================================================
    ROBLOX AUTO-REJOIN WATCHDOG (Multi-Instance & Crash Recovery)
    =============================================================================
#>

$Host.UI.RawUI.WindowTitle = "Roblox Auto-Rejoin Watchdog (Multi-Instance)"
$Port = 18888
$TempStatePath = "$env:TEMP\roblox_rejoin_state.json"
$DefaultPlaceId = 1537690962 # Bee Swarm Simulator

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "      ROBLOX AUTO-REJOIN WATCHDOG (Multi-Instance)         " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "[*] Status: Starting background HTTP listener on port $Port..." -ForegroundColor Gray

# In-memory account tracking: @{ "Username" = @{ placeId = ..., jobId = ..., lastSeen = ... } }
$Global:Accounts = @{}
$Global:LastRejoinTime = 0
$Global:LastKnownProcessCount = 0

# Helper: Find current Roblox executable dynamically
function Get-RobloxExePath {
    $versionsDir = "$env:LOCALAPPDATA\Roblox\Versions"
    if (Test-Path $versionsDir) {
        $exes = Get-ChildItem -Path $versionsDir -Recurse -Filter "RobloxPlayerBeta.exe" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        if ($exes.Count -gt 0) {
            return $exes[0].FullName
        }
    }
    return $null
}

# Helper: Get ONLY real, active Roblox windows (excludes dead/zombie handles with 0 memory)
function Get-LiveRobloxProcesses {
    return @(Get-Process "RobloxPlayerBeta" -ErrorAction SilentlyContinue | Where-Object { $_.WorkingSet64 -gt 50MB })
}

# Fix Registry Associations if pointing to obsolete Roblox versions
function Ensure-RegistryProtocol {
    try {
        $currentExe = Get-RobloxExePath
        if ($currentExe) {
            $cmd = "`"$currentExe`" %1"
            if (Test-Path "HKCU:\Software\Classes\roblox\shell\open\command") {
                Set-ItemProperty -Path "HKCU:\Software\Classes\roblox\shell\open\command" -Name "(default)" -Value $cmd -ErrorAction SilentlyContinue
            }
            if (Test-Path "HKCU:\Software\Classes\roblox-player\shell\open\command") {
                Set-ItemProperty -Path "HKCU:\Software\Classes\roblox-player\shell\open\command" -Name "(default)" -Value $cmd -ErrorAction SilentlyContinue
            }
        }
    } catch {}
}

Ensure-RegistryProtocol

# Load previously saved state from disk if exists
if (Test-Path $TempStatePath) {
    try {
        $saved = Get-Content $TempStatePath -Raw | ConvertFrom-Json
        if ($saved.accounts) {
            foreach ($prop in $saved.accounts.psobject.Properties) {
                $Global:Accounts[$prop.Name] = @{
                    placeId = $prop.Value.placeId
                    jobId = $prop.Value.jobId
                    lastSeen = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                }
                Write-Host "[+] Loaded previous session for [$($prop.Name)]: $($prop.Value.jobId)" -ForegroundColor Green
            }
        }
    } catch {}
}

# Also check Real's workspace for rejoin files
$realWorkspace = "$env:LOCALAPPDATA\Real\workspace"
if (Test-Path $realWorkspace) {
    Get-ChildItem -Path $realWorkspace -Filter "rejoin_*.json" -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $raw = Get-Content $_.FullName -Raw | ConvertFrom-Json
            $accName = $_.BaseName -replace "^rejoin_", ""
            if ($raw.jobId -and $raw.placeId) {
                $Global:Accounts[$accName] = @{
                    placeId = $raw.placeId
                    jobId = $raw.jobId
                    lastSeen = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
                }
                Write-Host "[+] Synced from Real workspace [$accName]: $($raw.jobId)" -ForegroundColor Green
            }
        } catch {}
    }
}

# Start HTTP Listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listenerStarted = $false
try {
    $listener.Start()
    $listenerStarted = $true
    Write-Host "[+] HTTP Heartbeat Listener is ACTIVE at http://127.0.0.1:$Port/heartbeat" -ForegroundColor Green
} catch {
    Write-Host "[-] Warning: Could not bind HTTP port $Port ($($_.Exception.Message))." -ForegroundColor Yellow
}

function Save-State {
    try {
        $obj = @{ accounts = $Global:Accounts }
        $json = $obj | ConvertTo-Json -Compress
        Set-Content -Path $TempStatePath -Value $json -Force
    } catch {}
}

function Clean-CrashHandlers {
    Get-Process "RobloxCrashHandler", "WerFault" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Launch-Roblox {
    param([string]$placeId, [string]$jobId, [string]$accName = "")

    Clean-CrashHandlers
    Ensure-RegistryProtocol

    $targetPlace = if ($placeId -and $placeId -ne "") { $placeId } else { $DefaultPlaceId }
    $rbxExe = Get-RobloxExePath
    
    $accTag = if ($accName -and $accName -ne "") { "РґР»СЏ Р°РєРєР°СѓРЅС‚Р° [$accName]" } else { "" }
    if ($jobId -and $jobId -ne "") {
        Write-Host "[>>>] РџРµСЂРµР·Р°С…РѕРґ РЅР° РўРћРў Р–Р• СЃРµСЂРІРµСЂ ($jobId) $accTag..." -ForegroundColor Magenta
        $uri = "roblox://experiences/start?placeId=$targetPlace&gameInstanceId=$jobId"
    } else {
        Write-Host "[>>>] Р—Р°С…РѕРґ РІ РёРіСЂСѓ (PlaceId: $targetPlace) $accTag..." -ForegroundColor Magenta
        $uri = "roblox://experiences/start?placeId=$targetPlace"
    }

    $launched = $false
    if ($rbxExe -and (Test-Path $rbxExe)) {
        try {
            Start-Process -FilePath $rbxExe -ArgumentList $uri
            Write-Host "[+] Р—Р°РїСѓСЃРє РІС‹РїРѕР»РЅРµРЅ С‡РµСЂРµР·: $rbxExe" -ForegroundColor Green
            $launched = $true
        } catch {}
    }

    if (-not $launched) {
        try {
            Start-Process $uri
            Write-Host "[+] РљРѕРјР°РЅРґР° РЅР° Р·Р°РїСѓСЃРє РѕС‚РїСЂР°РІР»РµРЅР° С‡РµСЂРµР· РїСЂРѕС‚РѕРєРѕР»." -ForegroundColor Green
        } catch {
            Write-Host "[-] РћС€РёР±РєР° Р·Р°РїСѓСЃРєР°: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

$lastProcessCheck = 0
$pendingAsyncContext = $null

Write-Host "[*] Watchdog Р°РєС‚РёРІРµРЅ. РћР¶РёРґР°РЅРёРµ СЃРёРіРЅР°Р»РѕРІ Рё РјРѕРЅРёС‚РѕСЂРёРЅРі РѕРєРѕРЅ..." -ForegroundColor White

# Initial process scan
$initialProcs = Get-LiveRobloxProcesses
$Global:LastKnownProcessCount = $initialProcs.Count
if ($initialProcs.Count -gt 0) {
    $pidStr = ($initialProcs | ForEach-Object { $_.Id }) -join ", "
    Write-Host "[+] РћР±РЅР°СЂСѓР¶РµРЅРѕ Р°РєС‚РёРІРЅС‹С… РѕРєРѕРЅ Roblox: $($initialProcs.Count) С€С‚. (PID: $pidStr)" -ForegroundColor Green
}

while ($true) {
    # 1. Process HTTP Heartbeats non-blocking
    if ($listenerStarted) {
        if ($null -eq $pendingAsyncContext) {
            $pendingAsyncContext = $listener.BeginGetContext($null, $null)
        }
        
        if ($pendingAsyncContext.IsCompleted) {
            try {
                $context = $listener.EndGetContext($pendingAsyncContext)
                $pendingAsyncContext = $null
                $req = $context.Request
                $resp = $context.Response

                if ($req.HttpMethod -eq "POST" -and $req.Url.AbsolutePath -eq "/heartbeat") {
                    $reader = New-Object System.IO.StreamReader($req.InputStream, $req.ContentEncoding)
                    $body = $reader.ReadToEnd()
                    $data = $body | ConvertFrom-Json
                    
                    $acc = if ($data.account -and $data.account -ne "") { $data.account } else { "RobloxClient" }
                    $pId = if ($data.placeId) { $data.placeId } else { $DefaultPlaceId }
                    $jId = if ($data.jobId) { $data.jobId } else { "" }
                    $nowTs = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()

                    $isNewOrChanged = $false
                    if (-not $Global:Accounts.ContainsKey($acc)) {
                        $isNewOrChanged = $true
                    } elseif ($Global:Accounts[$acc].jobId -ne $jId) {
                        $isNewOrChanged = $true
                    }

                    $Global:Accounts[$acc] = @{
                        placeId = $pId
                        jobId = $jId
                        lastSeen = $nowTs
                    }

                    if ($isNewOrChanged) {
                        Write-Host "[TRACKER] РђРєРєР°СѓРЅС‚ [$acc]: РїСЂРёРІСЏР·Р°РЅ Рє СЃРµСЂРІРµСЂСѓ $jId (Place: $pId)" -ForegroundColor Cyan
                    }

                    Save-State

                    # Send 200 OK
                    $buffer = [System.Text.Encoding]::UTF8.GetBytes('{"status":"ok"}')
                    $resp.ContentType = "application/json"
                    $resp.ContentLength64 = $buffer.Length
                    $resp.OutputStream.Write($buffer, 0, $buffer.Length)
                }

                $resp.Close()
            } catch {
                $pendingAsyncContext = $null
            }
        }
    }

    # 2. Check live Roblox processes every 2 seconds
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    if ($now - $lastProcessCheck -ge 2) {
        $lastProcessCheck = $now
        $liveProcs = Get-LiveRobloxProcesses
        $currentCount = $liveProcs.Count

        if ($currentCount -ne $Global:LastKnownProcessCount) {
            if ($currentCount -gt $Global:LastKnownProcessCount) {
                # New window opened
                $pidStr = ($liveProcs | ForEach-Object { $_.Id }) -join ", "
                Write-Host "[+] РћР±РЅР°СЂСѓР¶РµРЅРѕ РЅРѕРІРѕРµ РѕРєРЅРѕ Roblox! Р’СЃРµРіРѕ РѕРєРѕРЅ: $currentCount С€С‚. (PID: $pidStr)" -ForegroundColor Green
            } elseif ($currentCount -lt $Global:LastKnownProcessCount) {
                # An instance closed or crashed!
                Write-Host "[!] Р’РќРРњРђРќРР•: РћРєРЅРѕ Roblox Р·Р°РєСЂС‹Р»РѕСЃСЊ РёР»Рё РєСЂР°С€РЅСѓР»РѕСЃСЊ! (Р‘С‹Р»Рѕ: $($Global:LastKnownProcessCount), РѕСЃС‚Р°Р»РѕСЃСЊ: $currentCount)" -ForegroundColor Red
                
                Clean-CrashHandlers

                # Cooldown check for relaunch (at least 8 seconds)
                if ($now - $Global:LastRejoinTime -ge 8) {
                    $Global:LastRejoinTime = $now

                    # Identify which account timed out / disappeared
                    $targetAcc = ""
                    $targetJob = ""
                    $targetPlace = $DefaultPlaceId

                    foreach ($name in $Global:Accounts.Keys) {
                        $accData = $Global:Accounts[$name]
                        if ($now - $accData.lastSeen -gt 6) {
                            $targetAcc = $name
                            $targetJob = $accData.jobId
                            $targetPlace = $accData.placeId
                            break
                        }
                    }

                    if (-not $targetJob -and $Global:Accounts.Count -gt 0) {
                        $firstKey = ($Global:Accounts.Keys | Select-Object -First 1)
                        $targetAcc = $firstKey
                        $targetJob = $Global:Accounts[$firstKey].jobId
                        $targetPlace = $Global:Accounts[$firstKey].placeId
                    }

                    if ($targetAcc) {
                        Write-Host "[!] РџРµСЂРµР·Р°РїСѓСЃРє РґР»СЏ Р°РєРєР°СѓРЅС‚Р° [$targetAcc]. РџРѕСЃР»РµРґРЅРёР№ СЃРµСЂРІРµСЂ: $targetJob" -ForegroundColor Yellow
                    }

                    Start-Sleep -Seconds 2
                    Launch-Roblox -placeId $targetPlace -jobId $targetJob -accName $targetAcc
                }
            }
            $Global:LastKnownProcessCount = $currentCount
        }
    }

    Start-Sleep -Milliseconds 100
}
