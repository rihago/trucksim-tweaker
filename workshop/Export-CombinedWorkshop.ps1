param(
    [Parameter(Mandatory)][string]$Archive,
    [Parameter(Mandatory)][string]$Destination,
    [Parameter(Mandatory)][ValidatePattern('^\d+\.\d+(?:\.\d+)*$')][string]$GameVersion,
    [Parameter(Mandatory)][string]$Description
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$destinationPath = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $destinationPath) { throw 'Choose a new destination.' }
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $Archive).Path)
try {
    $definitions = @($zip.Entries | Where-Object { $_.FullName -cmatch '^def/[a-z_]+\.sii$' })
    $icon = $zip.GetEntry('mod_icon.jpg')
    if (!$icon -or $definitions.Count -lt 2) { throw 'Expected a combined mod with an icon.' }
    $upload = Join-Path $destinationPath 'upload'
    $package = Join-Path $upload 'package'
    New-Item -ItemType Directory -Path (Join-Path $package 'def') -Force | Out-Null
    foreach ($entry in ($definitions + $icon)) {
        [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, (Join-Path $package $entry.FullName))
    }
    Copy-Item -LiteralPath (Join-Path $package 'mod_icon.jpg') -Destination (Join-Path $destinationPath 'preview.jpg')
    [IO.File]::WriteAllText((Join-Path $package 'description.txt'), $Description)
    @'
SiiNunit
{
mod_package : .package {
    package_version: "0.1"
    author: "TruckSim Tweaker"
    category[]: "other"
    icon: "mod_icon.jpg"
    description_file: "description.txt"
}
}
'@ | Set-Content -LiteralPath (Join-Path $package 'manifest.sii') -Encoding Ascii
    @"
SiiNunit
{
package_version_info : .content {
    package_name: "package"
    compatible_versions[]: "$GameVersion"
}
}
"@ | Set-Content -LiteralPath (Join-Path $upload 'versions.sii') -Encoding Ascii
} finally {
    $zip.Dispose()
}
