using System.Globalization;
using System.IO.Compression;
using System.Text;
using System.Text.RegularExpressions;

namespace TruckSimTweaker;

public sealed record Change(string Field, string Before, string After);
public sealed record EconomyPreview(string Contents, IReadOnlyList<Change> Changes);

public static class Economy
{
    private const int MaxBytes = 1024 * 1024;
    private static readonly Encoding Utf8 = new UTF8Encoding(false, true);
    private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(1);

    public static EconomyPreview Read(string path, int money, int xp)
    {
        if (money is not (1 or 2 or 5) || xp is not (1 or 2 or 5))
            throw new ArgumentException("Kies ×1, ×2 of ×5.");

        using var input = File.OpenRead(path);
        if (input.Length > MaxBytes)
            throw new InvalidDataException("Economy-bestand is groter dan 1 MB.");
        var bytes = new byte[(int)input.Length];
        input.ReadExactly(bytes);
        if (input.ReadByte() != -1)
            throw new InvalidDataException("Het bestand is gewijzigd tijdens het lezen.");
        var text = Utf8.GetString(bytes.AsSpan().StartsWith(new byte[] { 239, 187, 191 })
            ? bytes.AsSpan(3) : bytes);

        // Mask strings and comments with spaces so their contents cannot match a field.
        var masked = Regex.Replace(text, """ "(?:\\[^\r\n]|[^"\\\r\n])*" | //[^\r\n]* | \#[^\r\n]* | /\*[\s\S]*?\*/ """,
            match => Regex.Replace(match.Value, @"[^\r\n]", " "),
            RegexOptions.IgnorePatternWhitespace, Timeout);

        var structure = Regex.Match(masked,
            @"\ASiiNunit\s*\{\s*economy_data\s*:\s*[\w.]+\s*\{(?<body>[^{}@""\x00]*)\}\s*\}\s*\z",
            RegexOptions.CultureInvariant, Timeout);
        if (!structure.Success)
            throw new InvalidDataException("Verwacht één tekstuele economy_data-unit zonder includes.");

        var changes = new List<Change>();
        var edits = new List<(int Offset, string Before, string After)>();
        var body = structure.Groups["body"];
        foreach (var (field, factor) in new[] { ("revenue_coef_per_km", money), ("exp_cargo_delivery", xp) })
        {
            var matches = Regex.Matches(body.Value, @"(?m)^[ \t]*" + field + @"[ \t]*:[ \t]*(?<value>[^\r\n]*)",
                RegexOptions.CultureInvariant, Timeout);
            if (matches.Count != 1)
                throw new InvalidDataException($"Verwacht precies één veld '{field}'.");
            var value = matches[0].Groups["value"];
            var before = value.Value.TrimEnd(' ', '\t');
            if (!Regex.IsMatch(before, @"\A[0-9]+(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z", RegexOptions.None, Timeout)
                || !decimal.TryParse(before, NumberStyles.Float, CultureInfo.InvariantCulture, out var number)
                || number <= 0 || number > decimal.MaxValue / 5)
                throw new InvalidDataException($"Ongeldige waarde voor '{field}'.");
            var offset = body.Index + value.Index;
            var suffix = text.AsSpan(offset + before.Length, value.Length - before.Length).TrimStart();
            if (!text.AsSpan(offset, before.Length).SequenceEqual(before.AsSpan())
                || (!suffix.IsEmpty && !suffix.StartsWith("#") && !suffix.StartsWith("//") && !suffix.StartsWith("/*")))
                throw new InvalidDataException($"Onverwachte tekst bij '{field}'.");

            var after = factor == 1 ? before : (number * factor).ToString("G29", CultureInfo.InvariantCulture);
            changes.Add(new(field, before, after));
            if (before != after)
                edits.Add((offset, before, after));
        }

        var result = new StringBuilder(text);
        foreach (var edit in edits.OrderByDescending(edit => edit.Offset))
            result.Remove(edit.Offset, edit.Before.Length).Insert(edit.Offset, edit.After);
        return new(result.ToString(), changes.AsReadOnly());
    }

    public static void Export(EconomyPreview preview, string path, Game game)
    {
        if (!string.Equals(Path.GetExtension(path), ".scs", StringComparison.OrdinalIgnoreCase))
            throw new ArgumentException("Gebruik de extensie .scs.");
        path = Path.GetFullPath(path);
        var temporary = Path.Combine(Path.GetDirectoryName(path)!, $".{Guid.NewGuid():N}.tmp");
        using (var output = new FileStream(temporary, FileMode.CreateNew))
        {
            try
            {
                using var archive = new ZipArchive(output, ZipArchiveMode.Create, leaveOpen: true);
                WriteEntry(archive, "def/economy_data.sii", preview.Contents);
                WriteEntry(archive, "manifest.sii", $$"""
                    SiiNunit
                    {
                    mod_package : .package {
                        package_version: "0.1"
                        display_name: "TruckSim Tweaker ({{game.Code}})"
                    }
                    }
                    """);
            }
            catch
            {
                output.Dispose();
                File.Delete(temporary);
                throw;
            }
        }

        try
        {
            File.Move(temporary, path);
        }
        finally
        {
            File.Delete(temporary);
        }
    }

    private static void WriteEntry(ZipArchive archive, string name, string contents)
    {
        using var writer = new StreamWriter(archive.CreateEntry(name).Open(), Utf8);
        writer.Write(contents);
    }
}
