[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$ArchivePath,
    [string]$WezTermDirectory = (Join-Path $env:USERPROFILE '.config\wezterm')
)

$ErrorActionPreference = 'Stop'
$version = 'v2.0.0'
$sha256 = '500a7774297c829265ebd472b6d8c1159cfb3e9daa4ca0570170af541b991b7d'
$url = "https://github.com/yuru7/moralerspace/releases/download/$version/MoralerspaceHW_$version.zip"
$fontDirectory = Join-Path $WezTermDirectory "fonts\moralerspace-neon-hw-$version"
$userFontDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts\moralerspace-neon-hw-$version"
$fontRegistry = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

if (-not $PSCmdlet.ShouldProcess("$fontDirectory; $userFontDirectory; $fontRegistry", 'Install Moralerspace Neon HW for WezTerm and the current Windows user')) {
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

$temporary = Join-Path ([IO.Path]::GetTempPath()) "dotfiles-moralerspace-$([guid]::NewGuid().ToString('N'))"
New-Item -ItemType Directory -Path $temporary | Out-Null
try {
    if (-not $ArchivePath) {
        $ArchivePath = Join-Path $temporary 'moralerspace.zip'
        Invoke-WebRequest -Uri $url -OutFile $ArchivePath -UseBasicParsing
    }
    if ((Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash -ne $sha256) {
        throw 'Moralerspace archive SHA256 does not match the official release.'
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($ArchivePath)
    try {
        $names = @('Regular', 'Bold', 'Italic', 'BoldItalic') | ForEach-Object { "MoralerspaceNeonHW-$_.ttf" }
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
    if (-not ('DotfilesMoralerspace.NativeFonts' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace DotfilesMoralerspace {
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
        $style = $name -replace '^MoralerspaceNeonHW-', '' -replace '\.ttf$', ''
        New-ItemProperty -LiteralPath $fontRegistry -Name "Moralerspace Neon HW $style (TrueType)" -Value $userFont -PropertyType String -Force | Out-Null
        if ([DotfilesMoralerspace.NativeFonts]::AddFontResourceEx($userFont, 0, [IntPtr]::Zero) -eq 0) {
            throw "Windows could not load font: $name"
        }
    }
    $broadcastResult = [UIntPtr]::Zero
    [DotfilesMoralerspace.NativeFonts]::SendMessageTimeout([IntPtr]0xffff, 0x001d, [UIntPtr]::Zero, [IntPtr]::Zero, 2, 100, [ref]$broadcastResult) | Out-Null
    Write-Output "Moralerspace Neon HW $version installed for WezTerm and registered for the current Windows user."
} finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force
}
