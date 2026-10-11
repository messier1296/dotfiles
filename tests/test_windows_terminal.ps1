$ErrorActionPreference = 'Stop'
$deploy = Join-Path $PSScriptRoot '../scripts/deploy-windows-terminal.ps1'
function Assert-SameValue($Expected, $Actual) {
    if ($null -eq $Expected -or $null -eq $Actual) {
        if ($null -ne $Expected -or $null -ne $Actual) { throw 'Null value changed.' }
    } elseif ($Expected -is [array]) {
        if ($Actual -isnot [array] -or $Expected.Count -ne $Actual.Count) { throw 'Array shape changed.' }
        for ($i = 0; $i -lt $Expected.Count; $i++) { Assert-SameValue $Expected[$i] $Actual[$i] }
    } elseif ($Expected -is [pscustomobject]) {
        $keys = @($Expected.PSObject.Properties.Name | Sort-Object)
        if (($keys -join '|') -ne (@($Actual.PSObject.Properties.Name | Sort-Object) -join '|')) { throw 'Object properties changed.' }
        foreach ($key in $keys) { Assert-SameValue $Expected.$key $Actual.$key }
    } elseif ($Expected -cne $Actual) { throw "Value changed: $Expected -> $Actual" }
}
$directory = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-terminal-test-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $directory | Out-Null
try {
    $target = Join-Path $directory 'settings.json'
    foreach ($source in @('Microsoft.WSL', 'Windows.Terminal.Wsl')) {
        $fixture = @{
            profiles = @{ defaults = @{ opacity = 85 }; list = @(
                @{ name = 'Ubuntu'; source = $source; font = @{ face = 'Old'; weight = 700; size = 14 }; colorScheme = 'Campbell' },
                @{ name = 'Windows PowerShell'; font = @{ face = 'Existing'; weight = 500 } }
            ) }
            copyOnSelect = $false
        }
        [IO.File]::WriteAllText($target, ($fixture | ConvertTo-Json -Depth 100), [Text.UTF8Encoding]::new($false))
        $before = [IO.File]::ReadAllText($target)
        & $deploy -SettingsPath $target -WhatIf
        if ([IO.File]::ReadAllText($target) -ne $before) { throw 'WhatIf modified settings.' }
        & $deploy -SettingsPath $target
        $actual = [IO.File]::ReadAllText($target) | ConvertFrom-Json
        if ($actual.profiles.list[0].font.face -ne 'FiraCode Nerd Font Mono, Yu Gothic UI' -or $actual.profiles.list[0].font.weight -ne 350) {
            throw 'Requested font stack and Japanese weight were not applied.'
        }
        $expected = $before | ConvertFrom-Json
        $expected.profiles.list[0].font.face = 'FiraCode Nerd Font Mono, Yu Gothic UI'
        $expected.profiles.list[0].font.weight = 350
        Assert-SameValue $expected $actual
        $backups = @(Get-ChildItem -LiteralPath $directory -Filter 'settings.json.backup-*')
        if (-not ($backups | Where-Object { [IO.File]::ReadAllText($_.FullName) -eq $before })) { throw 'Original settings backup missing.' }
        $count = $backups.Count
        $hash = (Get-FileHash -LiteralPath $target).Hash
        & $deploy -SettingsPath $target
        if ((Get-FileHash -LiteralPath $target).Hash -ne $hash -or @(Get-ChildItem -LiteralPath $directory -Filter 'settings.json.backup-*').Count -ne $count) { throw 'Deployment is not idempotent.' }
    }
    # Same face but wrong weight must still be updated.
    $actual.profiles.list[0].font.weight = 400
    [IO.File]::WriteAllText($target, ($actual | ConvertTo-Json -Depth 100))
    & $deploy -SettingsPath $target
    if (([IO.File]::ReadAllText($target) | ConvertFrom-Json).profiles.list[0].font.weight -ne 350) { throw 'Stale weight was not corrected.' }
    [IO.File]::WriteAllText($target, '{invalid json')
    $hash = (Get-FileHash -LiteralPath $target).Hash
    $rejected = $false
    try { & $deploy -SettingsPath $target } catch { $rejected = $true }
    if (-not $rejected -or (Get-FileHash -LiteralPath $target).Hash -ne $hash) { throw 'Invalid JSON was modified.' }
    Write-Output 'TERMINAL_FONT_STACK_WEIGHT_BACKUP_WHATIF_IDEMPOTENCE_AND_PRESERVATION_OK'
} finally {
    Remove-Item -LiteralPath $directory -Recurse -Force
}
