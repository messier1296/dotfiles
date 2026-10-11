[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$TargetDirectory = (Join-Path $env:USERPROFILE '.config\wezterm')
)

$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot '../home/dot_config/wezterm/wezterm.lua'
$target = Join-Path $TargetDirectory 'wezterm.lua'

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Missing WezTerm source configuration: $source"
}

if (Test-Path -LiteralPath $target -PathType Leaf) {
    if ((Get-FileHash -LiteralPath $source).Hash -eq (Get-FileHash -LiteralPath $target).Hash) {
        Write-Output "WezTerm configuration is already up to date: $target"
        return
    }
}

if ($PSCmdlet.ShouldProcess($target, 'Deploy WezTerm configuration (back up any existing file)')) {
    New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
    if (Test-Path -LiteralPath $target) {
        $backup = "$target.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$([guid]::NewGuid().ToString('N'))"
        Copy-Item -LiteralPath $target -Destination $backup
        Write-Output "Previous configuration saved to: $backup"
    }
    Copy-Item -LiteralPath $source -Destination $target -Force
    Write-Output "WezTerm configuration deployed to: $target"
}
