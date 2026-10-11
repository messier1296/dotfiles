[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$SettingsPath,
    [string]$ProfileName = 'Ubuntu'
)

$ErrorActionPreference = 'Stop'
if (-not $SettingsPath) {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )
    $SettingsPath = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $SettingsPath) { throw 'Open Windows Terminal once to create settings.json, or specify -SettingsPath.' }
}

# Parse before touching the file. Invalid or unsupported JSON leaves it intact.
$original = [IO.File]::ReadAllText($SettingsPath)
$settings = $original | ConvertFrom-Json
$profiles = @($settings.profiles.list | Where-Object { $_.name -eq $ProfileName -and $_.source -in @('Microsoft.WSL', 'Windows.Terminal.Wsl') })
if ($profiles.Count -ne 1) { throw "Expected exactly one WSL profile named '$ProfileName'. Use -ProfileName for a different distribution." }
$profile = $profiles[0]
if (-not $profile.font) { $profile | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) -Force }
if ($profile.font.face -eq 'Moralerspace Neon HW') {
    Write-Output "Windows Terminal profile '$ProfileName' already uses Moralerspace Neon HW."
    return
}
$profile.font | Add-Member -NotePropertyName face -NotePropertyValue 'Moralerspace Neon HW' -Force
$updated = $settings | ConvertTo-Json -Depth 100

if ($PSCmdlet.ShouldProcess($SettingsPath, "Set only the '$ProfileName' WSL profile font face to Moralerspace Neon HW")) {
    $backup = "$SettingsPath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N'))"
    $temporary = "$SettingsPath.tmp-$([guid]::NewGuid().ToString('N'))"
    try {
        if ([IO.File]::ReadAllText($SettingsPath) -ne $original) { throw 'Terminal settings changed during deployment; retry.' }
        [IO.File]::WriteAllText($temporary, $updated + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
        [IO.File]::Replace($temporary, $SettingsPath, $backup)
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
    Write-Output "Windows Terminal profile '$ProfileName' updated. Previous settings saved to: $backup"
}
