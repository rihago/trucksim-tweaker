param(
    [Parameter(Mandatory)][string]$Definitions,
    [Parameter(Mandatory)][string]$Destination,
    [ValidatePattern('^\d+\.\d+(?:\.\d+)*(?:\.\*)?$')][string]$CompatibleVersion = '1.62.3.3'
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$definitionsPath = (Resolve-Path -LiteralPath $Definitions).Path
$destinationPath = [IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $destinationPath) { throw 'Kies een nieuwe uitvoermap.' }

function Write-Cover($path, $title, $subtitle, $color, [bool]$coach, $width, $height) {
    $bitmap = [Drawing.Bitmap]::new($width, $height)
    $graphics = [Drawing.Graphics]::FromImage($bitmap)
    $font = [Drawing.Font]::new('Segoe UI', 20, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
    $small = [Drawing.Font]::new('Segoe UI', 11, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
    $accent = [Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($color))
    try {
        $graphics.ScaleTransform($width / 276.0, $height / 162.0)
        $graphics.SmoothingMode = 'AntiAlias'
        $graphics.Clear([Drawing.Color]::FromArgb(17, 26, 39))
        $graphics.FillRectangle($accent, 0, 0, 276, 5)
        if ($coach) {
            $graphics.FillRectangle($accent, 135, 26, 116, 38)
            for ($x = 143; $x -lt 240; $x += 19) {
                $graphics.FillRectangle([Drawing.Brushes]::MidnightBlue, $x, 32, 14, 14)
            }
        } else {
            $graphics.FillRectangle($accent, 125, 27, 86, 35)
            $graphics.FillRectangle($accent, 216, 38, 34, 24)
            $graphics.FillRectangle([Drawing.Brushes]::MidnightBlue, 232, 41, 13, 10)
        }
        foreach ($x in @(147, 224)) { $graphics.FillEllipse([Drawing.Brushes]::White, $x, 57, 16, 16) }
        $graphics.DrawString('TRUCKSIM TWEAKER  /  ETS2', $small, $accent, 15, 83)
        $graphics.DrawString($title, $font, [Drawing.Brushes]::White, 14, 100)
        $graphics.DrawString($subtitle, $small, [Drawing.Brushes]::White, 15, 132)
        $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Jpeg)
    } finally {
        $accent.Dispose()
        $small.Dispose()
        $font.Dispose()
        $graphics.Dispose()
        $bitmap.Dispose()
    }
}

function Read-Definition($name, $unit) {
    $file = Join-Path $definitionsPath $name
    $text = [IO.File]::ReadAllText($file, [Text.UTF8Encoding]::new($false, $true))
    if ($text -notmatch "^\s*SiiNunit\s*\{\s*$unit\s*:" -or $text -match '(?m)^\s*@include') {
        throw "Onverwachte structuur in $name."
    }
    return $text
}

function Scale-Field($text, $field, $factor) {
    $pattern = '(?m)^([ \t]*' + [regex]::Escape($field) + '[ \t]*:[ \t]*)([0-9]+(?:\.[0-9]+)?)(?=[ \t]*(?:#|//|\r?$))'
    if ([regex]::Matches($text, $pattern).Count -ne 1) { throw "Verwacht precies een numeriek veld: $field" }
    $culture = [Globalization.CultureInfo]::InvariantCulture
    return [regex]::Replace($text, $pattern, {
        param($match)
        $value = [decimal]::Parse($match.Groups[2].Value, $culture)
        $match.Groups[1].Value + ($value * $factor).ToString($culture)
    })
}

$truck = Read-Definition 'economy_data.sii' 'economy_data'
$truck = Scale-Field $truck 'revenue_coef_per_km' 2
$truck = Scale-Field $truck 'exp_cargo_delivery' 5
$coach = Read-Definition 'bus_economy_data_xp.sii' 'xp_level_data'
$pattern = '(?m)^([ \t]*level_xp\[(\d+)\][ \t]*:[ \t]*)(\d+)(?=[ \t]*(?:#|//|\r?$))'
$levels = [regex]::Matches($coach, $pattern)
if ($levels.Count -ne 30) { throw 'Onverwacht aantal Coaches-levels. Controleer het bestand voor deze gameversie.' }
for ($i = 0; $i -lt $levels.Count; $i++) {
    if ([int]$levels[$i].Groups[2].Value -ne $i -or [int]$levels[$i].Groups[3].Value -le 0) {
        throw "Ongeldige Coaches XP op index $i."
    }
}
$coach = [regex]::Replace($coach, $pattern, {
    param($match)
    $match.Groups[1].Value + [string][Math]::Ceiling(([int]$match.Groups[3].Value) / 5.0)
})

$mods = @(
    @{ Id='truck-economy-xp'; Title='Truck Economy & XP'; Subtitle='Vrachtmarkt x2   /   Afstands-XP x5'; Color='#68BDFA'; Coach=$false
       File='economy_data.sii'; Data=$truck; Description='Verdubbelt de geldcoefficient van de Vrachtmarkt en vermenigvuldigt afstands-XP voor vrachtleveringen met vijf. Het totale ritbedrag hangt ook af van andere factoren.' },
    @{ Id='coaches-levels'; Title='Coaches Levels'; Subtitle='XP-eisen gedeeld door vijf'; Color='#FFAD60'; Coach=$true
       File='bus_economy_data_xp.sii'; Data=$coach; Description='Verlaagt de vereiste XP voor Coaches-levels tot een vijfde. Voor Coach Mode met de Coaches-DLC.' }
)
$utf8 = [Text.UTF8Encoding]::new($false)
foreach ($mod in $mods) {
    $root = Join-Path $destinationPath $mod.Id
    $upload = Join-Path $root 'upload'
    $package = Join-Path $upload 'package'
    $def = (New-Item -ItemType Directory -Path (Join-Path $package 'def') -Force).FullName
    [IO.File]::WriteAllText((Join-Path $def $mod.File), $mod.Data, $utf8)
    [IO.File]::WriteAllText((Join-Path $package 'description.txt'), $mod.Description, $utf8)
    @'
SiiNunit
{
mod_package : .package {
    package_version: "0.1"
    author: "TruckSim Tweaker"
    icon: "mod_icon.jpg"
    description_file: "description.txt"
}
}
'@ | Set-Content (Join-Path $package 'manifest.sii') -Encoding Ascii
    @"
SiiNunit
{
package_version_info : .ets2 {
    package_name: "package"
    compatible_versions[]: "$CompatibleVersion"
}
}
"@ | Set-Content (Join-Path $upload 'versions.sii') -Encoding Ascii
    Write-Cover (Join-Path $package 'mod_icon.jpg') $mod.Title $mod.Subtitle $mod.Color $mod.Coach 276 162
    Write-Cover (Join-Path $root 'preview.jpg') $mod.Title $mod.Subtitle $mod.Color $mod.Coach 552 324
}
