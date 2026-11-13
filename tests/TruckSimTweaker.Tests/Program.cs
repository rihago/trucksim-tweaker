using System.Globalization;
using System.IO.Compression;
using TruckSimTweaker;

CultureInfo.CurrentCulture = CultureInfo.GetCultureInfo("nl-NL");
var directory = Directory.CreateTempSubdirectory("trucksim-tests-");
try
{
    var source = Path.Combine(directory.FullName, "economy_data.sii");
    const string original = """
        SiiNunit
        {
        economy_data : economy.data {
          /* exp_cargo_delivery: 999 */
          revenue_coef_per_km: 1.25 # geld
          exp_cargo_delivery: 2
          test_label: "example { } @"
          unrelated: 100
        }
        }
        """;
    File.WriteAllText(source, original);
    Require(Economy.Read(source, 1, 1).Contents == original, "×1 preserves input text");
    var preview = Economy.Read(source, 2, 5);
    var expected = original.Replace("1.25 #", "2.5 #").Replace("exp_cargo_delivery: 2", "exp_cargo_delivery: 10");
    Require(preview.Contents == expected, "×2/×5, invariant decimals and text preservation");
    Require(File.ReadAllText(source) == original, "input remains byte-for-byte intact");
    foreach (var game in new[] { Game.Ets2, Game.Ats })
    {
        var output = Path.Combine(directory.FullName, game.Code + ".scs");
        Economy.Export(preview, output, game);
        Reject<IOException>(() => Economy.Export(preview, output, game));
        using var zip = ZipFile.OpenRead(output);
        Require(zip.Entries.Count == 2, "archive contains two entries");
        using var content = new StreamReader(zip.GetEntry("def/economy_data.sii")!.Open());
        Require(content.ReadToEnd() == expected, "archive override path and content");
        using var manifest = new StreamReader(zip.GetEntry("manifest.sii")!.Open());
        Require(manifest.ReadToEnd().Contains(game.Code), "game-specific package name");
    }
    Require(!Directory.EnumerateFiles(directory.FullName, "*.tmp").Any(), "temporary archive cleanup");

    foreach (var invalid in new[]
    {
        original.Replace("exp_cargo_delivery: 2", "other_xp: 2"),
        original.Replace("exp_cargo_delivery: 2", "exp_cargo_delivery: 2\n exp_cargo_delivery: 3"),
        original.Replace("exp_cargo_delivery: 2", "exp_cargo_delivery: 2.0oops"),
        original.Replace("unrelated: 100", "@include \"extra.sii\""),
        new string(' ', 1024 * 1024 + 1),
        "ScsC"
    })
    {
        File.WriteAllText(source, invalid);
        Reject<InvalidDataException>(() => Economy.Read(source, 2, 5));
    }

    Directory.CreateDirectory(Path.Combine(directory.FullName, "bin", "win_x64"));
    File.WriteAllText(Path.Combine(directory.FullName, "def.scs"), "");
    File.WriteAllText(Path.Combine(directory.FullName, "bin", "win_x64", Game.Ets2.Executable), "");
    Require(Game.Ets2.MatchesInstallation(directory.FullName), "ETS2 installation signature");
    Require(!Game.Ats.MatchesInstallation(directory.FullName), "ATS requires its own executable");
    Console.WriteLine("Alle MVP-controles geslaagd.");
}
finally
{
    directory.Delete(recursive: true);
}

static void Require(bool condition, string description)
{
    if (!condition)
        throw new InvalidOperationException(description);
}

static void Reject<T>(Action action) where T : Exception
{
    try { action(); }
    catch (T) { return; }
    throw new InvalidOperationException($"Verwachtte {typeof(T).Name}.");
}
