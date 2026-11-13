using Microsoft.Win32;
using System.IO;
using System.Text.RegularExpressions;

namespace TruckSimTweaker;

internal static class Steam
{
    public static string? Find(Game game)
    {
        var roots = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var fallback = Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86);
        if (!string.IsNullOrEmpty(fallback))
            roots.Add(Path.Combine(fallback, "Steam"));

        using var key = Registry.CurrentUser.OpenSubKey(@"Software\Valve\Steam");
        if (key?.GetValue("SteamPath") is string root && Path.IsPathFullyQualified(root))
            roots.Add(root);

        foreach (var steam in roots.ToArray())
        {
            var libraries = Path.Combine(steam, "steamapps", "libraryfolders.vdf");
            if (!File.Exists(libraries))
                continue;
            try
            {
                foreach (Match match in Regex.Matches(File.ReadAllText(libraries),
                    """(?m)^\s*"path"[ \t]+"([^"\r\n]+)" """.TrimEnd()))
                {
                    var path = match.Groups[1].Value.Replace(@"\\", @"\");
                    if (Path.IsPathFullyQualified(path))
                        roots.Add(path);
                }
            }
            catch (IOException) { }
            catch (UnauthorizedAccessException) { }
        }

        return roots.Select(root => Path.Combine(root, "steamapps", "common", game.Name))
            .FirstOrDefault(game.MatchesInstallation);
    }
}
