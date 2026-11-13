param(
    [Parameter(Mandatory)][string]$Ets2Definitions,
    [Parameter(Mandatory)][string]$AtsDefinitions,
    [Parameter(Mandatory)][string]$Destination
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$culture = [Globalization.CultureInfo]::InvariantCulture
$ets = (Resolve-Path -LiteralPath $Ets2Definitions).Path
$ats = (Resolve-Path -LiteralPath $AtsDefinitions).Path
$out = (Resolve-Path -LiteralPath $Destination).Path

function Read-Definition($folder, $name) {
    [IO.File]::ReadAllText((Join-Path $folder $name), [Text.UTF8Encoding]::new($false, $true))
}

function Scale-Field($data, $field, $factor) {
    $pattern = '(?m)^([ \t]*' + [regex]::Escape($field) + '[ \t]*:[ \t]*)([0-9]+(?:\.[0-9]+)?)(?=[ \t]*(?:#|//|\r?$))'
    if ([regex]::Matches($data, $pattern).Count -ne 1) { throw "Unexpected field: $field" }
    [regex]::Replace($data, $pattern, {
        param($m)
        $m.Groups[1].Value + ([decimal]::Parse($m.Groups[2].Value, $culture) * $factor).ToString('G29', $culture)
    })
}

function Lower-Ratings($data, $field, $expectedCount) {
    $pattern = '(?m)^([ \t]*' + [regex]::Escape($field) + '[ \t]*:[ \t]*)(0|2\.6|3\.6|4\.6)(?=[ \t]*(?:#|//|\r?$))'
    $allFields = '(?m)^[ \t]*' + [regex]::Escape($field) + '[ \t]*:'
    $matches = [regex]::Matches($data, $pattern)
    if ($matches.Count -lt 4 -or $matches.Count -ne [regex]::Matches($data, $allFields).Count -or
        ($expectedCount -gt 0 -and $matches.Count -ne $expectedCount)) { throw "Unexpected rating fields: $field" }
    [regex]::Replace($data, $pattern, {
        param($m)
        $rating = [decimal]::Parse($m.Groups[2].Value, $culture)
        $m.Groups[1].Value + [Math]::Max([decimal]0, ($rating - [decimal]0.5)).ToString('G29', $culture)
    })
}

function Write-Mod($file, $title, $entries) {
    $path = Join-Path $out $file
    $entries['manifest.sii'] = @"
SiiNunit
{
mod_package : .package {
    package_version: "0.1"
    display_name: "$title"
    author: "TruckSim Tweaker"
    category[]: "other"
}
}
"@
    $zip = [IO.Compression.ZipFile]::Open($path, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($item in $entries.GetEnumerator()) {
            $writer = [IO.StreamWriter]::new($zip.CreateEntry($item.Key).Open())
            try { $writer.Write($item.Value) } finally { $writer.Dispose() }
        }
    } finally { $zip.Dispose() }

    $zip = [IO.Compression.ZipFile]::OpenRead($path)
    try {
        if ($zip.Entries.Count -ne $entries.Count) { throw "Unexpected archive size: $file" }
        foreach ($item in $entries.GetEnumerator()) {
            $reader = [IO.StreamReader]::new($zip.GetEntry($item.Key).Open())
            try {
                if ($reader.ReadToEnd() -cne $item.Value) { throw "Archive verification failed: $($item.Key)" }
            } finally { $reader.Dispose() }
        }
    } finally { $zip.Dispose() }
    $path
}

$coach = Read-Definition $ets 'bus_economy_data.sii'
$unit = '(?m)^([ \t]*bus_economy_data\s*:\s*bus_economy\.data\s*\{)'
if ([regex]::Matches($coach, $unit).Count -ne 1 -or
    $coach -match '(?m)^\s*(fixed_revenue|revenue_per_km|exp_full_intime|exp_intime|exp_satisfaction)\s*:') {
    throw 'Unexpected Coaches definition. Check this game build before applying tested defaults.'
}
$coach = [regex]::Replace($coach, $unit, ('$1' + [Environment]::NewLine + @'
    fixed_revenue: 1200
    revenue_per_km: 30.0
    exp_full_intime: 25.0
    exp_intime: 5.0
    exp_satisfaction: 5.0
'@))

$car = Read-Definition $ats 'car_economy_data.sii'
foreach ($field in @('quick_job_revenue_fixed', 'quick_job_revenue_coef_per_km', 'dispatch_job_revenue_fixed', 'dispatch_job_revenue_coef_per_km')) {
    $car = Scale-Field $car $field 2
}
$car = Lower-Ratings $car 'courier_tier_rating[]' 4
$jobs = Lower-Ratings (Read-Definition $ats 'car_job_data.sii') 'required_courier_rating' 0

foreach ($game in @(@{Name='ETS2'; Build='1.62.3.3'; Source=$ets}, @{Name='ATS'; Build='1.62.2.2'; Source=$ats})) {
    $truck = Read-Definition $game.Source 'economy_data.sii'
    foreach ($field in @('revenue_coef_per_km', 'driver_revenue_coef_per_km', 'cargo_market_revenue_coef_per_km')) {
        $truck = Scale-Field $truck $field 2
    }
    $truck = Scale-Field $truck 'exp_cargo_delivery' 5
    $entries = @{ 'def/economy_data.sii' = $truck }
    if ($game.Name -eq 'ETS2') {
        $entries['def/bus_economy_data.sii'] = $coach
    } else {
        $entries['def/car_economy_data.sii'] = $car
        $entries['def/car_job_data.sii'] = $jobs
    }
    Write-Mod "trucksim-tweaker-$($game.Name.ToLowerInvariant())-combined-$($game.Build).scs" "TruckSim Tweaker - $($game.Name) (Combined Test)" $entries
}
