namespace TruckSimTweaker;

public sealed record Game(string Name, string Code, string Executable)
{
    public static Game Ets2 { get; } = new("Euro Truck Simulator 2", "ETS2", "eurotrucks2.exe");
    public static Game Ats { get; } = new("American Truck Simulator", "ATS", "amtrucks.exe");

    public bool MatchesInstallation(string folder) =>
        File.Exists(Path.Combine(folder, "def.scs")) &&
        File.Exists(Path.Combine(folder, "bin", "win_x64", Executable));

    public override string ToString() => Name;
}
