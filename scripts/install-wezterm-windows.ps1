[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ArchivePath
)

$ErrorActionPreference = 'Stop'
$version = '20240203-110809-5046fc22'
$sha256 = '57e5d03b585303d81e8b8e96d1230362852eb39aca92b3b29c7a42cfb82f9ac4'
$url = "https://github.com/wezterm/wezterm/releases/download/$version/WezTerm-windows-$version.zip"
$installBase = Join-Path $env:LOCALAPPDATA 'Programs\WezTerm'
$installDirectory = Join-Path $installBase $version

if (-not $PSCmdlet.ShouldProcess($installDirectory, 'Install official WezTerm ZIP, add user PATH and Start menu shortcut')) {
    return
}

$temporary = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-wezterm-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $temporary | Out-Null
try {
    if (-not $ArchivePath) {
        $ArchivePath = Join-Path $temporary 'wezterm.zip'
        Invoke-WebRequest -Uri $url -OutFile $ArchivePath -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ne $sha256) {
        throw 'WezTerm archive SHA256 does not match the official release.'
    }

    if (-not (Test-Path -LiteralPath $installDirectory)) {
        $expanded = Join-Path $temporary 'expanded'
        Expand-Archive -LiteralPath $ArchivePath -DestinationPath $expanded
        $executables = @(Get-ChildItem -LiteralPath $expanded -Recurse -Filter 'wezterm-gui.exe')
        if ($executables.Count -ne 1) {
            throw 'Expected exactly one wezterm-gui.exe in the official archive.'
        }
        New-Item -ItemType Directory -Path (Split-Path $installDirectory) -Force | Out-Null
        Move-Item -LiteralPath $executables[0].Directory.FullName -Destination $installDirectory
    }

    $gui = Join-Path $installDirectory 'wezterm-gui.exe'
    if (-not (Test-Path -LiteralPath $gui -PathType Leaf)) {
        throw "Incomplete existing installation: $installDirectory"
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $managedVersionPath = '^' + [regex]::Escape($installBase) + '\\[0-9]{8}-[0-9]{6}-[0-9a-f]{8}\\?$'
    $pathEntries = @($userPath -split ';' | Where-Object { $_ -and $_ -notmatch $managedVersionPath })
    $updatedPath = ($pathEntries + @($installDirectory)) -join ';'
    if ($userPath -ne $updatedPath) {
        [Environment]::SetEnvironmentVariable('Path', $updatedPath, 'User')
    }
    $shell = New-Object -ComObject WScript.Shell
    $shortcutPath = Join-Path ([Environment]::GetFolderPath('Programs')) 'WezTerm.lnk'
    $shortcut = $shell.CreateShortcut($shortcutPath)
    if ($shortcut.TargetPath -ne $gui) {
        if (Test-Path -LiteralPath $shortcutPath) {
            Copy-Item -LiteralPath $shortcutPath -Destination "$shortcutPath.backup-$([guid]::NewGuid().ToString('N'))"
        }
        $shortcut.TargetPath = $gui
        $shortcut.WorkingDirectory = $env:USERPROFILE
        $shortcut.IconLocation = "$gui,0"
        $shortcut.Save()
    }
    Write-Output "WezTerm $version installed for the current Windows user: $installDirectory"
} finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force
}
