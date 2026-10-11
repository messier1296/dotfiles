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

if (-not $PSCmdlet.ShouldProcess($fontDirectory, 'Install official Moralerspace Neon HW for WezTerm')) {
    return
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
    foreach ($name in $names) {
        $source = Join-Path $temporary $name
        $target = Join-Path $fontDirectory $name
        if (Test-Path -LiteralPath $target -PathType Leaf) {
            if ((Get-FileHash -LiteralPath $source).Hash -eq (Get-FileHash -LiteralPath $target).Hash) {
                continue
            }
            Copy-Item -LiteralPath $target -Destination "$target.backup-$([guid]::NewGuid().ToString('N'))"
        }
        Copy-Item -LiteralPath $source -Destination $target -Force
    }
    Write-Output "Moralerspace Neon HW $version installed for WezTerm: $fontDirectory"
} finally {
    Remove-Item -LiteralPath $temporary -Recurse -Force
}
