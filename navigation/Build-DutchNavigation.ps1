param(
    [Parameter(Mandatory)][string]$Ffmpeg,
    [Parameter(Mandatory)][string]$Output,
    [string]$Preview
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[Windows.Media.SpeechSynthesis.SpeechSynthesizer,Windows.Media.SpeechSynthesis,ContentType=WindowsRuntime] | Out-Null
[Windows.Media.SpeechSynthesis.SpeechSynthesisStream,Windows.Media.SpeechSynthesis,ContentType=WindowsRuntime] | Out-Null
$asTask = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object {
    $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1
} | Select-Object -First 1
$asTask = $asTask.MakeGenericMethod([Windows.Media.SpeechSynthesis.SpeechSynthesisStream])
$voice = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::AllVoices | Where-Object Language -eq 'nl-NL' | Select-Object -First 1
if (!$voice) { throw 'Installeer een Nederlandse Windows-spraakstem.' }
$lines = [ordered]@{
    turn_left = 'Sla linksaf.'
    turn_right = 'Sla rechtsaf.'
    keep_left = 'Houd links aan.'
    keep_right = 'Houd rechts aan.'
    exit_left = 'Neem de afrit links.'
    exit_right = 'Neem de afrit rechts.'
    go_straight = 'Ga rechtdoor.'
    exit_now = 'Neem nu de afslag.'
    prepare_turn_left = 'Straks linksaf.'
    prepare_turn_right = 'Straks rechtsaf.'
    prepare_exit_left = 'Neem zo de afrit links.'
    prepare_exit_right = 'Neem zo de afrit rechts.'
    compound_turn_left = 'Sla linksaf.'
    compound_turn_right = 'Sla rechtsaf.'
    compound_keep_left = 'Houd links aan.'
    compound_keep_right = 'Houd rechts aan.'
    compound_exit_left = 'Neem de afrit links.'
    compound_exit_right = 'Neem de afrit rechts.'
    compound_go_straight = 'Ga rechtdoor.'
    and_then_turn_left = 'En sla dan linksaf.'
    and_then_turn_right = 'En sla dan rechtsaf.'
    and_then_keep_left = 'En houd dan links aan.'
    and_then_keep_right = 'En houd dan rechts aan.'
    and_then_exit_left = 'En neem dan de afrit links.'
    and_then_exit_right = 'En neem dan de afrit rechts.'
    and_then_go_straight = 'En ga dan rechtdoor.'
    start = 'De route is klaar. Goede reis.'
    finish = 'Je bent op je bestemming.'
    recomputing = 'Ik bereken een nieuwe route.'
    u_turn = 'Keer om zodra dat veilig kan.'
    speed_warning = 'Let op je snelheid.'
    roundabout_1 = 'Neem op de rotonde de eerste afslag.'
    roundabout_2 = 'Neem op de rotonde de tweede afslag.'
    roundabout_3 = 'Neem op de rotonde de derde afslag.'
    roundabout_4 = 'Neem op de rotonde de vierde afslag.'
    roundabout_5 = 'Neem op de rotonde de vijfde afslag.'
    roundabout_6 = 'Neem op de rotonde de zesde afslag.'
}
$ffmpegPath = (Resolve-Path -LiteralPath $Ffmpeg).Path
$outputPath = [IO.Path]::GetFullPath($Output)
$stage = Join-Path ([IO.Path]::GetDirectoryName($outputPath)) ('.navigation-' + [guid]::NewGuid().ToString('N'))
$audio = Join-Path $stage 'sound/navigation/tts_frank_nl'
$archive = $null
$synth = [Windows.Media.SpeechSynthesis.SpeechSynthesizer]::new()
try {
    $synth.Voice = $voice
    New-Item -ItemType Directory -Path $audio -Force | Out-Null
    $wave = Join-Path $stage 'voice.wav'
    foreach ($line in $lines.GetEnumerator()) {
        $task = $asTask.Invoke($null, @($synth.SynthesizeTextToStreamAsync($line.Value)))
        $speech = [System.IO.WindowsRuntimeStreamExtensions]::AsStreamForRead($task.GetAwaiter().GetResult())
        try {
            $file = [IO.File]::Create($wave)
            try { $speech.CopyTo($file) } finally { $file.Dispose() }
        } finally { $speech.Dispose() }
        if ($Preview -and $line.Key -eq 'speed_warning') {
            Copy-Item -LiteralPath $wave -Destination $Preview
        }
        & $ffmpegPath -v error -nostdin -i $wave -ac 2 -ar 44100 -strict experimental -c:a vorbis (Join-Path $audio ($line.Key + '.ogg'))
        if ($LASTEXITCODE -ne 0) { throw "Audio failed: $($line.Key)" }
    }
    & $ffmpegPath -v error -nostdin -f lavfi -i 'sine=frequency=880:sample_rate=44100:duration=0.22' -af 'afade=t=in:d=0.025,afade=t=out:st=0.12:d=0.10' -ac 2 -strict experimental -c:a vorbis (Join-Path $audio 'speed_signal.ogg')
    if ($LASTEXITCODE -ne 0) { throw 'Speed signal failed.' }

    $archive = [IO.Compression.ZipFile]::Open($outputPath, [IO.Compression.ZipArchiveMode]::Create)
    $metadata = @{
        'sound/navigation/tts_frank_nl.sii' = @'
SiiNunit
{
sound_data_voice_navigation : .tts_frank_nl {
    pack_name: "Nederlands - Frank (TruckSim Tweaker)"
    pack_dir: "/sound/navigation/tts_frank_nl"
}
}
'@
        'manifest.sii' = @'
SiiNunit
{
mod_package : .package {
    package_version: "0.1"
    display_name: "TruckSim Tweaker - Nederlandse Navigatie"
    author: "TruckSim Tweaker"
    description_file: "description.txt"
}
}
'@
        'description.txt' = 'Nederlandse routeaanwijzingen en snelheidswaarschuwing, ingesproken met Windows-stem Frank.'
    }
    foreach ($item in $metadata.GetEnumerator()) {
        $writer = [IO.StreamWriter]::new($archive.CreateEntry($item.Key).Open())
        try { $writer.Write($item.Value) } finally { $writer.Dispose() }
    }
    foreach ($clip in Get-ChildItem -LiteralPath $audio -Filter '*.ogg') {
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $clip.FullName, "sound/navigation/tts_frank_nl/$($clip.Name)")
    }
} finally {
    if ($archive) { $archive.Dispose() }
    $synth.Dispose()
    if (Test-Path -LiteralPath $stage) {
        # The staging tree contains only the generated clips and the WAV.
        $resolvedStage = (Resolve-Path -LiteralPath $stage).Path
        if ($resolvedStage -ceq $stage -and [IO.Path]::GetDirectoryName($resolvedStage) -ceq [IO.Path]::GetDirectoryName($outputPath)) {
            Remove-Item -LiteralPath $resolvedStage -Recurse
        }
    }
}
