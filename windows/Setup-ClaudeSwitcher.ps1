# =============================================================================
# claude-glm-switcher — Windows Setup Script
# Run this ONCE to initialise everything on your Windows 11 machine.
#
# Right-click this file -> Run with PowerShell
# Or from PowerShell:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#   .\Setup-ClaudeSwitcher.ps1
#
# After running, desktop shortcuts appear for every configured service.
#
# Paths configured in windows/CONFIG.ps1.
# =============================================================================

# ---------------------------------------------------------------------------
# 0. Load config and set up paths
# ---------------------------------------------------------------------------
$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$configPath = Join-Path $scriptDir "CONFIG.ps1"
# shellcheck source=/dev/null
. $configPath

$desktopPath = [System.Environment]::GetFolderPath("Desktop")
$switcherDir = "$env:USERPROFILE\.claude-switcher"

New-Item -ItemType Directory -Force -Path $switcherDir | Out-Null

# ---------------------------------------------------------------------------
# 1. Sanity checks
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== claude-glm-switcher Setup ===" -ForegroundColor Cyan
Write-Host ""

foreach ($settingsPath in $SettingsFiles) {
    $dir = Split-Path $settingsPath
    if (-not (Test-Path $dir)) {
        Write-Warning "Config dir not found: $dir"
        $confirm = Read-Host "Create it? (y/n)"
        if ($confirm -ne 'y') { exit 1 }
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

# ---------------------------------------------------------------------------
# 2. Snapshot current settings as claude.settings.json
#    Never overwrite — the claude template is the known-good backup.
# ---------------------------------------------------------------------------
function Snapshot-AsClaudeTemplate {
    param($sourcePath, $destPath, $label, $fallback)
    if (Test-Path $destPath) {
        Write-Host "  [SKIP] $label claude template already exists." -ForegroundColor Yellow
    } elseif (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath -Force
        Write-Host "  [OK]   $label claude template created from current settings." -ForegroundColor Green
    } else {
        $fallback | Set-Content $destPath
        Write-Host "  [WARN] $label source missing — minimal claude template created." -ForegroundColor Yellow
    }
}

Write-Host "Creating Claude (default) template files..." -ForegroundColor Cyan

$i = 0
foreach ($settingsPath in $SettingsFiles) {
    $templateDir = $TemplateDirs[$i]
    $claudeTemplate = Join-Path $templateDir "claude.settings.json"
    New-Item -ItemType Directory -Force -Path $templateDir | Out-Null
    Snapshot-AsClaudeTemplate $settingsPath $claudeTemplate "App$($i+1)" '{ "effortLevel": "medium" }'
    $i++
}

# ---------------------------------------------------------------------------
# 3. Create service template files
#    Merges env block into the Claude template so MCPs etc. are preserved.
# ---------------------------------------------------------------------------
function Create-ServiceTemplate {
    param(
        $claudeTemplatePath,
        $destPath,
        $label,
        $isIde,
        $svc
    )

    if (Test-Path $destPath) {
        Write-Host "  [SKIP] $label $($svc.Name) template already exists." -ForegroundColor Yellow
        return
    }

    if (Test-Path $claudeTemplatePath) {
        $base = Get-Content $claudeTemplatePath -Raw | ConvertFrom-Json
    } else {
        $base = [PSCustomObject]@{}
    }

    # Build env block
    $placeholder = "YOUR_$($svc.Name.ToUpper())_API_KEY_HERE"
    $keyField = $svc.KeyField

    $envHash = [ordered]@{}
    if ($keyField) {
        $envHash[$keyField] = $placeholder
    }
    $envHash["ANTHROPIC_BASE_URL"] = $svc.BaseURL
    $envHash["API_TIMEOUT_MS"] = "3000000"
    if ($svc.Opus)   { $envHash["ANTHROPIC_DEFAULT_OPUS_MODEL"]   = $svc.Opus }
    if ($svc.Sonnet) { $envHash["ANTHROPIC_DEFAULT_SONNET_MODEL"] = $svc.Sonnet }
    if ($svc.Haiku)  { $envHash["ANTHROPIC_DEFAULT_HAIKU_MODEL"]  = $svc.Haiku }

    # OpenRouter: set ANTHROPIC_API_KEY to empty string to prevent fallback
    if ($svc.Name -eq "openrouter") {
        $envHash["ANTHROPIC_API_KEY"] = ""
    }

    $envObj = [PSCustomObject]$envHash

    # Set env block
    if ($base.PSObject.Properties.Name -contains "env") {
        $base.env = $envObj
    } else {
        $base | Add-Member -NotePropertyName "env" -NotePropertyValue $envObj
    }

    # For IDE settings files, also set claudeCode.* keys
    if ($isIde) {
        $envArray = @()
        foreach ($key in $envHash.Keys) {
            $envArray += @{ name = $key; value = "$($envHash[$key])" }
        }

        if ($base.PSObject.Properties.Name -contains "claudeCode.disableLoginPrompt") {
            $base."claudeCode.disableLoginPrompt" = $true
        } else {
            $base | Add-Member -NotePropertyName "claudeCode.disableLoginPrompt" -NotePropertyValue $true
        }

        if ($base.PSObject.Properties.Name -contains "claudeCode.environmentVariables") {
            $base."claudeCode.environmentVariables" = $envArray
        } else {
            $base | Add-Member -NotePropertyName "claudeCode.environmentVariables" -NotePropertyValue $envArray
        }
    }

    $base | ConvertTo-Json -Depth 10 | Set-Content $destPath
    Write-Host "  [OK]   $label $($svc.Name) template created." -ForegroundColor Green
}

foreach ($svc in $Services) {
    # Skip claude — it's the snapshot, no env block
    if ($svc.Name -eq "claude") { continue }

    Write-Host ""
    Write-Host "Creating $($svc.Name) templates..." -ForegroundColor Cyan

    $i = 0
    foreach ($settingsPath in $SettingsFiles) {
        $templateDir = $TemplateDirs[$i]
        $claudeTemplate = Join-Path $templateDir "claude.settings.json"
        $svcTemplate = Join-Path $templateDir "$($svc.Name).settings.json"
        $isIde = ($i -gt 0)  # First entry is Claude CLI, rest are IDEs

        Create-ServiceTemplate $claudeTemplate $svcTemplate "App$($i+1)" $isIde $svc
        $i++
    }
}

# ---------------------------------------------------------------------------
# 4. LiteLLM config check (needed for litellm and openai modes)
# ---------------------------------------------------------------------------
$litellmConfigDir = "$env:USERPROFILE\.litellm"
$litellmConfigPath = Join-Path $litellmConfigDir "config.yaml"
$hasLitellmMode = $Services | Where-Object { $_.Name -in @("openai", "litellm") }

if ($hasLitellmMode) {
    if (-not (Test-Path $litellmConfigPath)) {
        Write-Host ""
        Write-Host "LiteLLM config not found at: $litellmConfigPath" -ForegroundColor Yellow
        $copyLitellm = Read-Host "Copy the example template there now? (y/n)"
        if ($copyLitellm -eq 'y') {
            New-Item -ItemType Directory -Force -Path $litellmConfigDir | Out-Null
            $templatePath = Join-Path $scriptDir "..\templates\litellm-config.yaml"
            Copy-Item $templatePath $litellmConfigPath -Force
            Write-Host "  [OK]   Copied template to $litellmConfigPath" -ForegroundColor Green
            Write-Host "  [NOTE] Fill in your OpenAI key and LiteLLM master key in that file." -ForegroundColor Yellow
        } else {
            Write-Host "  [SKIP] You'll need to create $litellmConfigPath manually." -ForegroundColor Yellow
        }
    } else {
        Write-Host ""
        Write-Host "[OK]   LiteLLM config found at $litellmConfigPath" -ForegroundColor Green
    }
}

# ---------------------------------------------------------------------------
# 5. Write switcher scripts into ~/.claude-switcher
# ---------------------------------------------------------------------------

# Generic switcher — one per service
foreach ($svc in $Services) {
    $svcName = $svc.Name
    $svcLabel = $svc.Label

    # Build copy commands for each settings location
    $copyLines = @()
    $errorLines = @()
    $i = 0
    foreach ($settingsPath in $SettingsFiles) {
        $dir = Split-Path $settingsPath
        $copyLines += "try { Copy-Item `"$dir\$svcName.settings.json`" `"$settingsPath`" -Force } catch { `$errors += `"App$($i+1): `$_`" }"
        $i++
    }

    $modelsMsg = ""
    if ($svc.Opus)   { $modelsMsg += "`n  Opus   -> $($svc.Opus)" }
    if ($svc.Sonnet) { $modelsMsg += "`n  Sonnet -> $($svc.Sonnet)" }
    if ($svc.Haiku)  { $modelsMsg += "`n  Haiku  -> $($svc.Haiku)" }

    $proxyNote = ""
    if ($svc.IsProxy) {
        $proxyNote = "`n`nMake sure LiteLLM is running: litellm --config ~/.litellm/config.yaml"
    }

    $script = @"
`$errors = @()
$($copyLines -join "`n")
Add-Type -AssemblyName PresentationFramework
if (`$errors.Count -eq 0) {
    [System.Windows.MessageBox]::Show(
        "Switched to $svcLabel$modelsMsg$proxyNote",
        "claude-glm-switcher", "OK", "Information") | Out-Null
} else {
    [System.Windows.MessageBox]::Show(
        "Switched to $svcLabel with errors:`n`n" + (`$errors -join "`n"),
        "claude-glm-switcher", "OK", "Warning") | Out-Null
}
"@
    $script | Set-Content "$switcherDir\switch-$svcName.ps1"
}

Write-Host ""
Write-Host "Switcher scripts written to: $switcherDir" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 6. API key updater script — handles all services
# ---------------------------------------------------------------------------
$keyUpdater = @'
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework

# Load config
. (Join-Path $PSScriptRoot "..\windows\CONFIG.ps1")

# Ask which service
$svcNames = ($Services | Where-Object { $_.Name -ne "claude" } | ForEach-Object { $_.Name }) -join ", "
$newKey = $null
$svcName = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Which service key to update?`n`nAvailable: $svcNames",
    "Update API Key",
    "")

if ([string]::IsNullOrWhiteSpace($svcName)) {
    [System.Windows.MessageBox]::Show("No service entered. Nothing was changed.", "Update API Key", "OK", "Warning") | Out-Null
    exit
}

# Find the service
$svc = $Services | Where-Object { $_.Name -eq $svcName }
if (-not $svc) {
    [System.Windows.MessageBox]::Show("Unknown service: $svcName`nAvailable: $svcNames", "Update API Key", "OK", "Warning") | Out-Null
    exit
}

# Special case: openai — key goes in litellm config
if ($svcName -eq "openai") {
    $newKey = [Microsoft.VisualBasic.Interaction]::InputBox(
        "Enter your new OpenAI API key:",
        "Update OpenAI Key",
        "")

    if ([string]::IsNullOrWhiteSpace($newKey)) {
        [System.Windows.MessageBox]::Show("No key entered. Nothing was changed.", "Update OpenAI Key", "OK", "Warning") | Out-Null
        exit
    }

    $litellmConfig = "$env:USERPROFILE\.litellm\config.yaml"
    if (-not (Test-Path $litellmConfig)) {
        [System.Windows.MessageBox]::Show(
            "LiteLLM config not found at: $litellmConfig`nCopy templates/litellm-config.yaml there first.",
            "Update OpenAI Key", "OK", "Warning") | Out-Null
        exit
    }

    $content = Get-Content $litellmConfig -Raw
    $content = $content -replace "YOUR_OPENAI_API_KEY_HERE", $newKey
    $content = $content -replace 'api_key: "sk-[^"]*"', "api_key: `"$newKey`""
    Set-Content $litellmConfig $content

    [System.Windows.MessageBox]::Show(
        "OpenAI key updated in:`n$litellmConfig",
        "Update OpenAI Key", "OK", "Information") | Out-Null
    exit
}

# Normal service — update key in settings files
$keyField = $svc.KeyField
if ([string]::IsNullOrWhiteSpace($keyField)) {
    [System.Windows.MessageBox]::Show("No key field for service: $svcName", "Update API Key", "OK", "Warning") | Out-Null
    exit
}

$newKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter your new $svcName API key:",
    "Update $svcName API Key",
    "")

if ([string]::IsNullOrWhiteSpace($newKey)) {
    [System.Windows.MessageBox]::Show("No key entered. Nothing was changed.", "Update API Key", "OK", "Warning") | Out-Null
    exit
}

# Update CONFIG.ps1
$configPath = Join-Path $PSScriptRoot "CONFIG.ps1"
if (Test-Path $configPath) {
    $cfgContent = Get-Content $configPath -Raw
    $cfgContent = $cfgContent -replace "$($svcName)\s*=\s*`"[^`"]*`"", "$($svcName) = `"$newKey`""
    Set-Content $configPath $cfgContent
}

$allFiles = @()
$i = 0
foreach ($settingsPath in $SettingsFiles) {
    $templateDir = $TemplateDirs[$i]
    $allFiles += Join-Path $templateDir "$svcName.settings.json"
    $allFiles += $settingsPath
    $i++
}

$updated = @()
$skipped = @()
$errors  = @()

foreach ($file in $allFiles) {
    if (-not (Test-Path $file)) { $skipped += $file; continue }
    try {
        $content = Get-Content $file -Raw
        if ($content -match "\"$keyField\"") {
            $content = $content -replace "\"$keyField\"\s*:\s*`"[^`"]*`"", "`"$keyField`": `"$newKey`""
            Set-Content $file $content
            $updated += $file
        } else {
            $skipped += "$file (no key field)"
        }
    } catch {
        $errors += "${file}: $_"
    }
}

$msg = ""
if ($updated.Count -gt 0) { $msg += "Updated:`n" + ($updated -join "`n") }
if ($skipped.Count -gt 0) { $msg += "`n`nSkipped:`n" + ($skipped -join "`n") }
if ($errors.Count  -gt 0) { $msg += "`n`nErrors:`n" + ($errors  -join "`n") }

[System.Windows.MessageBox]::Show(
    $msg, "Update $svcName API Key", "OK",
    $(if ($errors.Count -gt 0) { "Warning" } else { "Information" })
) | Out-Null
'@
$keyUpdater | Set-Content "$switcherDir\update-key.ps1"

# ---------------------------------------------------------------------------
# 7. Desktop .bat launchers
# ---------------------------------------------------------------------------
foreach ($svc in $Services) {
    $svcName = $svc.Name
    $svcLabel = $svc.Label
    $batName = "Switch to $svcLabel.bat"

    @"
@echo off
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%USERPROFILE%\.claude-switcher\switch-$svcName.ps1"
"@ | Set-Content "$desktopPath\$batName"
}

# API key updater shortcut
@"
@echo off
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%USERPROFILE%\.claude-switcher\update-key.ps1"
"@ | Set-Content "$desktopPath\Update API Key.bat"

Write-Host ""
Write-Host "Desktop shortcuts created:" -ForegroundColor Cyan
foreach ($svc in $Services) {
    Write-Host "  Switch to $($svc.Label).bat" -ForegroundColor White
}
Write-Host "  Update API Key.bat" -ForegroundColor White

# ---------------------------------------------------------------------------
# 8. Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEP:" -ForegroundColor Yellow
Write-Host "  1. Double-click 'Update API Key.bat' on your Desktop" -ForegroundColor White
Write-Host "     to set keys for any service." -ForegroundColor White
if ($hasLitellmMode) {
    Write-Host "  2. For OpenAI mode: fill your OpenAI key in $litellmConfigPath" -ForegroundColor White
    Write-Host "     Then start LiteLLM: litellm --config $litellmConfigPath" -ForegroundColor White
}
Write-Host ""
\r