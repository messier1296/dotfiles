[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ArchivePath,
    [string]$WezTermDirectory = (Join-Path $env:USERPROFILE '.config\wezterm')
)

$ErrorActionPreference = 'Stop'
$version = '6.400'
$sha256 = '2723183407cc5aa17f9cf4f99968cf72313cabc9137ac45e5133c1640efee4da'
$url = "https://github.com/negset/Firple/releases/download/$version/Firple.zip"
$fontDirectory = Join-Path $WezTermDirectory "fonts\firple-$version"
$userFontDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts\firple-$version"
$fontRegistry = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

if (-not $PSCmdlet.ShouldProcess("$fontDirectory; $userFontDirectory; $fontRegistry", 'Install Firple for WezTerm and the current Windows user')) {
    return
}

function Copy-PreservedFont([string]$Source, [string]$Target) {
    if (Test-Path -LiteralPath $Target -PathType Leaf) {
        if ((Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Target).Hash) {
            return
        }
        Copy-Item -LiteralPath $Target -Destination "$Target.backup-$([guid]::NewGuid().ToString('N'))"
    }
    Copy-Item -LiteralPath $Source -Destination $Target -Force
}

$temporary = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-firple-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $temporary | Out-Null
try {
    if (-not $ArchivePath) {
        $ArchivePath = Join-Path $temporary 'firple.zip'
        Invoke-WebRequest -Uri $url -OutFile $ArchivePath -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ne $sha256) {
        throw 'Firple archive SHA256 does not match the official release.'
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $names = @('Regular', 'Bold', 'Italic', 'BoldItalic') | ForEach-Object { "Firple-$_.ttf" }
        foreach ($name in $names) {
            $entries = @($archive.Entries | Where-Object { $_.Name -eq $name })
            if ($entries.Count -ne 1) { throw "Expected exactly one font in the archive: $name" }
            [IO.Compression.ZipFileExtensions]::ExtractToFile($entries[0], (Join-Path $temporary $name))
        }
    } finally {
        $archive.Dispose()
    }

    New-Item -ItemType Directory -Path $fontDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $userFontDirectory -Force | Out-Null
    if (-not (Test-Path -LiteralPath $fontRegistry)) {
        New-Item -Path $fontRegistry -Force | Out-Null
    }
    if (-not ('DotfilesFirple.NativeFonts' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace DotfilesFirple {
    public static class NativeFonts {
        [DllImport("gdi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
        public static extern int AddFontResourceEx(string path, uint flags, IntPtr reserved);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr SendMessageTimeout(IntPtr window, uint message, UIntPtr wparam, IntPtr lparam, uint flags, uint timeout, out UIntPtr result);
    }
}
'@
    }
    foreach ($name in $names) {
        $source = Join-Path $temporary $name
        Copy-PreservedFont $source (Join-Path $fontDirectory $name)
        $userFont = Join-Path $userFontDirectory $name
        Copy-PreservedFont $source $userFont
        $style = $name -replace '^Firple-', '' -replace '\.ttf$', ''
        New-ItemProperty -LiteralPath $fontRegistry -Name "Firple $style (TrueType)" -Value $userFont -PropertyType String -Force | Out-Null
        if ([DotfilesFirple.NativeFonts]::AddFontResourceEx($userFont, 0, [IntPtr]::Zero) -eq 0) {
            throw "Windows could not load font: $name"
        }
    }
    $broadcastResult = [UIntPtr]::Zero
    [DotfilesFirple.NativeFonts]::SendMessageTimeout([IntPtr]0xffff, 0x001d, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 100, [ref]$broadcastResult) | Out-Null
    Write-Output "Firple $version installed for WezTerm and registered for the current Windows user."
} finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force
}
