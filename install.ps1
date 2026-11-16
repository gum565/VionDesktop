# VionDesktop Windows Native Installer
# Usage:
#   irm https://raw.githubusercontent.com/gum565/VionDesktop/main/install.ps1 | iex

[CmdletBinding()]
param(
    [Parameter(ValueFromPipeline = $false)]
    [switch]$Portable,
    [Parameter(ValueFromPipeline = $false)]
    [string]$Prefix = "",
    [Parameter(ValueFromPipeline = $false)]
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$null = $input

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

$isRu = [System.Globalization.CultureInfo]::CurrentUICulture.Name.StartsWith("ru")

function Write-Step($ruText, $enText) {
    if (-not $Quiet) {
        $msg = if ($isRu) { $ruText } else { $enText }
        Write-Host "  √ " -ForegroundColor Green -NoNewline
        Write-Host $msg
    }
}

function Write-Title($ruText, $enText) {
    if (-not $Quiet) {
        $msg = if ($isRu) { $ruText } else { $enText }
        Write-Host "* " -ForegroundColor Cyan -NoNewline
        Write-Host $msg -ForegroundColor White
    }
}

function Write-Warn($ruText, $enText) {
    if (-not $Quiet) {
        $msg = if ($isRu) { $ruText } else { $enText }
        Write-Host "  ! " -ForegroundColor Yellow -NoNewline
        Write-Host $msg
    }
}

function Write-Err($ruText, $enText) {
    if (-not $Quiet) {
        $msg = if ($isRu) { $ruText } else { $enText }
        Write-Host "  × " -ForegroundColor Red -NoNewline
        Write-Host $msg
    }
}

Write-Title "Установщик VionDesktop" "VionDesktop Installer"
Write-Step "Определено: Windows x64" "Detected: Windows x64"

$repo = "gum565/VionDesktop"
$headers = @{ "User-Agent" = "VionDesktop-Installer" }

Write-Step "Поиск последнего релиза на GitHub..." "Checking latest release on GitHub..."

$release = $null

try {
    $apiUrl = "https://api.github.com/repos/$repo/releases?per_page=10"
    $releases = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
    foreach ($r in $releases) {
        if ($r.tag_name -ne "ci-cache" -and $r.assets -and ($r.assets | Where-Object { $_.name -match "(installer|setup|portable|windows)" })) {
            $release = $r
            break
        }
    }
    if (-not $release -and $releases) {
        foreach ($r in $releases) {
            if ($r.tag_name -ne "ci-cache") {
                $release = $r
                break
            }
        }
    }
} catch {
    try {
        $apiUrl = "https://api.github.com/repos/$repo/releases/latest"
        $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
    } catch {
    }
}

if (-not $release -or -not $release.assets -or $release.assets.Count -eq 0) {
    Write-Warn "Релизы с бинарными сборками еще подготавливаются к публикации." "Release binaries are currently being prepared for publishing."
    Write-Warn "Следите за обновлениями в официальном канале: https://t.me/VionDesktop" "Stay tuned in the official channel: https://t.me/VionDesktop"
    return
}

$pattern = if ($Portable) {
    "(portable|portable-x64|windows-portable).*\.zip$"
} else {
    "(setup|installer|windows-installer).*\.(exe|zip)$"
}

$asset = $release.assets | Where-Object { $_.name -match $pattern } | Select-Object -First 1

if (-not $asset) {
    $asset = $release.assets | Where-Object { $_.name -match "(installer|setup|portable|windows)" } | Select-Object -First 1
}

if (-not $asset) {
    Write-Warn "Файл релиза под Windows не найден в текущем выпуске." "Windows release asset not found in current release."
    return
}

$tempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    $outPath = Join-Path $tempDir $asset.name
    Write-Step "Загрузка $($asset.name)..." "Downloading $($asset.name)..."
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $outPath -UseBasicParsing

    if ($Portable) {
        $targetDir = if ($Prefix) { $Prefix } else { Join-Path $env:LOCALAPPDATA "VionDesktop" }
        Write-Step "Распаковка в $targetDir..." "Extracting to $targetDir..."
        if (Test-Path $targetDir) { Remove-Item -Recurse -Force $targetDir }
        Expand-Archive -Path $outPath -DestinationPath $targetDir -Force
        Write-Step "Готово! Запуск: $targetDir\VionDesktop.exe" "Ready! Launch: $targetDir\VionDesktop.exe"
    } else {
        $installerPath = $outPath
        if ($outPath.EndsWith(".zip", [System.StringComparison]::OrdinalIgnoreCase)) {
            Write-Step "Распаковка установщика..." "Extracting installer..."
            $extractSubDir = Join-Path $tempDir "extracted"
            Expand-Archive -Path $outPath -DestinationPath $extractSubDir -Force
            $foundExe = Get-ChildItem -Path $extractSubDir -Filter "*.exe" -Recurse | Select-Object -First 1
            if ($foundExe) {
                $installerPath = $foundExe.FullName
            }
        }

        Write-Step "Запуск тихого установщика Windows..." "Launching Windows silent installer..."
        $proc = Start-Process -FilePath $installerPath -ArgumentList "/SILENT", "/NORESTART", "/SP-" -Wait -PassThru
        if ($proc.ExitCode -eq 0) {
            Write-Step "Установка VionDesktop успешно завершена!" "VionDesktop installation successfully completed!"
        } else {
            Write-Warn "Код завершения установщика: $($proc.ExitCode)" "Installer exit code: $($proc.ExitCode)"
        }
    }
} finally {
    if (Test-Path $tempDir) {
        Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
    }
}
