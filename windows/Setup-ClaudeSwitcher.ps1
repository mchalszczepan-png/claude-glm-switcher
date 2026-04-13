# =============================================================================
# claude-glm-switcher — Windows Setup Script
# Run this ONCE to initialise everything on your Windows 11 machine.
#
# Right-click this file -> Run with PowerShell
# Or from PowerShell:
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
#   .\Setup-ClaudeSwitcher.ps1
#
# After running, three icons appear on your Desktop:
#   - Switch to GLM Mode.bat
#   - Switch to Claude Mode.bat
#   - Update Z.ai API Key.bat
#
# Paths configured for:
#   Antigravity IDE:  %APPDATA%\Antigravity\User\settings.json
#   Claude Code CLI:  %USERPROFILE%\.claude\settings.json
# =============================================================================

# ---------------------------------------------------------------------------
# 0. Paths
# ---------------------------------------------------------------------------
$antigravitySettings = "$env:APPDATA\Antigravity\User\settings.json"
$claudeCliSettings   = "$env:USERPROFILE\.claude\settings.json"
$antigravityDir      = Split-Path $antigravitySettings
$claudeCliDir        = Split-Path $claudeCliSettings
$desktopPath         = [System.Environment]::GetFolderPath("Desktop")
$switcherDir         = "$env:USERPROFILE\.claude-switcher"

$agGlmTemplate       = "$antigravityDir\glm.settings.json"
$agClaudeTemplate    = "$antigravityDir\claude.settings.json"
$cliGlmTemplate      = "$claudeCliDir\glm.settings.json"
$cliClaudeTemplate   = "$claudeCliDir\claude.settings.json"

# ---------------------------------------------------------------------------
# 1. Sanity checks
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== claude-glm-switcher Setup ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $antigravitySettings)) {
    Write-Warning "Antigravity settings.json not found at: $antigravitySettings"
    Write-Warning "Make sure Antigravity IDE has been launched at least once."
    $confirm = Read-Host "Continue anyway and create directories? (y/n)"
    if ($confirm -ne 'y') { exit 1 }
}

if (-not (Test-Path $claudeCliDir)) {
    Write-Warning "Claude CLI config dir not found at: $claudeCliDir"
    Write-Warning "Make sure Claude Code CLI has been installed."
    $confirm = Read-Host "Continue anyway and create directories? (y/n)"
    if ($confirm -ne 'y') { exit 1 }
}

New-Item -ItemType Directory -Force -Path $antigravityDir | Out-Null
New-Item -ItemType Directory -Force -Path $claudeCliDir   | Out-Null
New-Item -ItemType Directory -Force -Path $switcherDir    | Out-Null

# ---------------------------------------------------------------------------
# 2. Snapshot current settings as claude.settings.json
#    Skipped if template already exists — never overwrite a known-good backup.
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
Snapshot-AsClaudeTemplate $antigravitySettings $agClaudeTemplate  "Antigravity" '{ "effortLevel": "medium" }'
Snapshot-AsClaudeTemplate $claudeCliSettings   $cliClaudeTemplate "Claude CLI"  '{ "model": "sonnet[1m]", "effortLevel": "medium" }'

# ---------------------------------------------------------------------------
# 3. Create GLM template files
#    Merges GLM env block into the Claude template — MCPs etc. are preserved.
#    Skipped if GLM template already exists.
# ---------------------------------------------------------------------------
function Create-GlmTemplate {
    param($claudeTemplatePath, $destPath, $label, $isIde)

    if (Test-Path $destPath) {
        Write-Host "  [SKIP] $label GLM template already exists." -ForegroundColor Yellow
        return
    }

    if (Test-Path $claudeTemplatePath) {
        $base = Get-Content $claudeTemplatePath -Raw | ConvertFrom-Json
    } else {
        $base = [PSCustomObject]@{}
    }

    $glmEnv = [PSCustomObject]@{
        ANTHROPIC_AUTH_TOKEN           = "YOUR_ZAI_API_KEY_HERE"
        ANTHROPIC_BASE_URL             = "https://api.z.ai/api/anthropic"
        API_TIMEOUT_MS                 = "3000000"
        ANTHROPIC_DEFAULT_OPUS_MODEL   = "GLM-5.1"
        ANTHROPIC_DEFAULT_SONNET_MODEL = "GLM-5"
        ANTHROPIC_DEFAULT_HAIKU_MODEL  = "GLM-4.7"
    }

    if ($isIde) {
        $envArray = @(
            @{ name = "ANTHROPIC_AUTH_TOKEN";           value = "YOUR_ZAI_API_KEY_HERE" },
            @{ name = "ANTHROPIC_BASE_URL";             value = "https://api.z.ai/api/anthropic" },
            @{ name = "API_TIMEOUT_MS";                 value = "3000000" },
            @{ name = "ANTHROPIC_DEFAULT_OPUS_MODEL";   value = "GLM-5.1" },
            @{ name = "ANTHROPIC_DEFAULT_SONNET_MODEL"; value = "GLM-5" },
            @{ name = "ANTHROPIC_DEFAULT_HAIKU_MODEL";  value = "GLM-4.7" }
        )

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

    if ($base.PSObject.Properties.Name -contains "env") {
        $base.env = $glmEnv
    } else {
        $base | Add-Member -NotePropertyName "env" -NotePropertyValue $glmEnv
    }

    $base | ConvertTo-Json -Depth 10 | Set-Content $destPath
    Write-Host "  [OK]   $label GLM template created." -ForegroundColor Green
}

Write-Host ""
Write-Host "Creating GLM template files..." -ForegroundColor Cyan
Create-GlmTemplate $agClaudeTemplate  $agGlmTemplate  "Antigravity" $true
Create-GlmTemplate $cliClaudeTemplate $cliGlmTemplate "Claude CLI"  $false

# ---------------------------------------------------------------------------
# 4. Write switcher scripts into ~/.claude-switcher
# ---------------------------------------------------------------------------

# GLM switcher
@'
$errors = @()
try { Copy-Item "$env:APPDATA\Antigravity\User\glm.settings.json" "$env:APPDATA\Antigravity\User\settings.json" -Force } catch { $errors += "Antigravity: $_" }
try { Copy-Item "$env:USERPROFILE\.claude\glm.settings.json" "$env:USERPROFILE\.claude\settings.json" -Force } catch { $errors += "Claude CLI: $_" }
Add-Type -AssemblyName PresentationFramework
if ($errors.Count -eq 0) {
    [System.Windows.MessageBox]::Show(
        "Switched to GLM Mode`n`nModels:`n  Opus   -> GLM-5.1`n  Sonnet -> GLM-5`n  Haiku  -> GLM-4.7`n`nIf you haven't set your Z.ai API key yet, run 'Update Z.ai API Key' from the Desktop.",
        "claude-glm-switcher", "OK", "Information") | Out-Null
} else {
    [System.Windows.MessageBox]::Show(
        "Switched to GLM Mode with errors:`n`n" + ($errors -join "`n"),
        "claude-glm-switcher", "OK", "Warning") | Out-Null
}
'@ | Set-Content "$switcherDir\switch-glm.ps1"

# Claude switcher
@'
$errors = @()
try { Copy-Item "$env:APPDATA\Antigravity\User\claude.settings.json" "$env:APPDATA\Antigravity\User\settings.json" -Force } catch { $errors += "Antigravity: $_" }
try { Copy-Item "$env:USERPROFILE\.claude\claude.settings.json" "$env:USERPROFILE\.claude\settings.json" -Force } catch { $errors += "Claude CLI: $_" }
Add-Type -AssemblyName PresentationFramework
if ($errors.Count -eq 0) {
    [System.Windows.MessageBox]::Show(
        "Switched to Claude Mode`n`nUsing Anthropic models via official API.",
        "claude-glm-switcher", "OK", "Information") | Out-Null
} else {
    [System.Windows.MessageBox]::Show(
        "Switched to Claude Mode with errors:`n`n" + ($errors -join "`n"),
        "claude-glm-switcher", "OK", "Warning") | Out-Null
}
'@ | Set-Content "$switcherDir\switch-claude.ps1"

# API key updater
@'
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName PresentationFramework

$newKey = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter your new Z.ai API key:",
    "Update Z.ai API Key",
    ""
)

if ([string]::IsNullOrWhiteSpace($newKey)) {
    [System.Windows.MessageBox]::Show("No key entered. Nothing was changed.", "Update Z.ai API Key", "OK", "Warning") | Out-Null
    exit
}

$allFiles = @(
    "$env:APPDATA\Antigravity\User\glm.settings.json",
    "$env:APPDATA\Antigravity\User\settings.json",
    "$env:USERPROFILE\.claude\glm.settings.json",
    "$env:USERPROFILE\.claude\settings.json"
)

$updated = @()
$skipped = @()
$errors  = @()

foreach ($file in $allFiles) {
    if (-not (Test-Path $file)) { $skipped += $file; continue }
    try {
        $content = Get-Content $file -Raw
        if ($content -match '"ANTHROPIC_AUTH_TOKEN"') {
            $content = $content -replace '"ANTHROPIC_AUTH_TOKEN"\s*:\s*"[^"]*"', "`"ANTHROPIC_AUTH_TOKEN`": `"$newKey`""
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
    $msg, "Update Z.ai API Key", "OK",
    $(if ($errors.Count -gt 0) { "Warning" } else { "Information" })
) | Out-Null
'@ | Set-Content "$switcherDir\update-key.ps1"

Write-Host ""
Write-Host "Switcher scripts written to: $switcherDir" -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# 5. Desktop .bat launchers
# ---------------------------------------------------------------------------
@"
@echo off
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%USERPROFILE%\.claude-switcher\switch-glm.ps1"
"@ | Set-Content "$desktopPath\Switch to GLM Mode.bat"

@"
@echo off
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%USERPROFILE%\.claude-switcher\switch-claude.ps1"
"@ | Set-Content "$desktopPath\Switch to Claude Mode.bat"

@"
@echo off
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%USERPROFILE%\.claude-switcher\update-key.ps1"
"@ | Set-Content "$desktopPath\Update Z.ai API Key.bat"

Write-Host ""
Write-Host "Desktop shortcuts created:" -ForegroundColor Cyan
Write-Host "  Switch to GLM Mode.bat"    -ForegroundColor White
Write-Host "  Switch to Claude Mode.bat" -ForegroundColor White
Write-Host "  Update Z.ai API Key.bat"   -ForegroundColor White

# ---------------------------------------------------------------------------
# 6. Done
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEP: Double-click 'Update Z.ai API Key.bat' on your Desktop" -ForegroundColor Yellow
Write-Host "and paste your Z.ai API key to activate GLM mode." -ForegroundColor Yellow
Write-Host ""
