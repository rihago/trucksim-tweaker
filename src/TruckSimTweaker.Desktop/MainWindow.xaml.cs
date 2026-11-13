using Microsoft.Win32;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Controls;

namespace TruckSimTweaker;

public partial class MainWindow : Window
{
    private readonly Dictionary<Game, string?> installations = new();
    private string? source;
    private EconomyPreview? preview;
    private Game SelectedGame => (Game)Games.SelectedItem;

    public MainWindow()
    {
        InitializeComponent();
        Money.ItemsSource = Xp.ItemsSource = new[] { "×1", "×2", "×5" };
        Money.SelectedIndex = Xp.SelectedIndex = 0;
        Games.ItemsSource = new[] { Game.Ets2, Game.Ats };
        Games.SelectedIndex = 0;
    }

    private void GameChanged(object sender, SelectionChangedEventArgs e)
    {
        source = null;
        InputFile.Text = "Kies een uitgepakt bestand uit deze gameversie.";
        if (!installations.ContainsKey(SelectedGame))
            installations[SelectedGame] = Steam.Find(SelectedGame);
        ShowInstallation();
        RefreshPreview(sender, e);
    }

    private void ShowInstallation() =>
        Installation.Text = installations[SelectedGame] ?? "Geen installatie gevonden. Kies eventueel de spelmap.";

    private void ChooseInstallation(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFolderDialog { Title = $"Kies de spelmap van {SelectedGame.Name}" };
        if (dialog.ShowDialog(this) != true)
            return;
        if (!SelectedGame.MatchesInstallation(dialog.FolderName))
        {
            Status.Text = "Deze map mist def.scs of het spelprogramma van de gekozen game.";
            return;
        }
        installations[SelectedGame] = dialog.FolderName;
        ShowInstallation();
        Status.Text = "";
    }

    private void ChooseEconomy(object sender, RoutedEventArgs e)
    {
        var dialog = new OpenFileDialog
        {
            Title = $"Kies economy_data.sii uit {SelectedGame.Name}",
            Filter = "Economy-bestand|economy_data.sii",
            InitialDirectory = installations[SelectedGame] ?? ""
        };
        if (dialog.ShowDialog(this) != true)
            return;
        source = dialog.FileName;
        InputFile.Text = source;
        RefreshPreview(sender, e);
    }

    private void RefreshPreview(object sender, RoutedEventArgs e)
    {
        preview = null;
        ExportButton.IsEnabled = false;
        PreviewText.Text = Status.Text = "";
        if (source is null)
            return;
        try
        {
            int[] factors = [1, 2, 5];
            preview = Economy.Read(source, factors[Money.SelectedIndex], factors[Xp.SelectedIndex]);
            PreviewText.Text = string.Join(Environment.NewLine,
                preview.Changes.Select(change => $"{change.Field}   {change.Before} → {change.After}"));
            ExportButton.IsEnabled = true;
        }
        catch (Exception error) when (error is IOException or InvalidDataException or UnauthorizedAccessException
            or DecoderFallbackException or RegexMatchTimeoutException)
        {
            Status.Text = $"Lezen mislukt. {error.Message}";
        }
    }

    private void Export(object sender, RoutedEventArgs e)
    {
        if (preview is null)
            return;
        var dialog = new SaveFileDialog
        {
            FileName = $"trucksim-tweaker-{SelectedGame.Code.ToLowerInvariant()}.scs",
            Filter = "SCS-mod|*.scs",
            DefaultExt = ".scs",
            OverwritePrompt = false
        };
        if (dialog.ShowDialog(this) != true)
            return;

        try
        {
            Economy.Export(preview, dialog.FileName, SelectedGame);
            Status.Text = $"Opgeslagen. {dialog.FileName}";
        }
        catch (Exception error) when (error is IOException or UnauthorizedAccessException or ArgumentException)
        {
            Status.Text = $"Opslaan mislukt. Kies bij een bestaand bestand een nieuwe naam. {error.Message}";
        }
    }
}
