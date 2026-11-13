# TruckSim Tweaker

Een lokale Windows-desktopapp om economie-instellingen voor de vrachtwagencarrière van Euro Truck Simulator 2 en American Truck Simulator te bewerken. Eerste ontwikkelversie. Compatibiliteit moet per game en gamebuild in het spel worden bevestigd.

## Starten op Windows

Installeer de [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0). Open PowerShell in deze map.

```powershell
dotnet build TruckSimTweaker.slnx
dotnet run --project tests/TruckSimTweaker.Tests
dotnet run --project src/TruckSimTweaker.Desktop
```

1. Kies ETS2 of ATS. De app zoekt Steam-installaties in de standaardmap en de geregistreerde Steam-bibliotheken. Kies bij afwijkende installaties zelf de spelmap.
2. Pak `def.scs` van de gekozen installatie uit naar een aparte map met de [officiële SCS Game Archive Extractor](https://modding.scssoft.com/wiki/Documentation/Tools/Game_Archive_Extractor). Selecteer daarna `def/economy_data.sii` in de app. Gebruik de bron uit dezelfde game en build. De app kan de herkomst van een los bestand niet vaststellen.
3. Kies per instelling ×1, ×2 of ×5 en controleer de getoonde waarden. Geld wijzigt uitsluitend `revenue_coef_per_km`, de vrachtmarktcoëfficiënt. XP wijzigt uitsluitend `exp_cargo_delivery`, voorlopig behandeld als afstandsgebonden XP. Vaste bedragen, bonussen, andere jobmarkten en afronding kunnen het eindresultaat beïnvloeden.
4. Sla de mod op met een nieuwe naam, plaats hem in de `mod`-map van de gekozen game en activeer hem in Mod Manager op een testprofiel. Gebruik één economy-mod tegelijk. De export overschrijft de hele `def/economy_data.sii` binnen de virtuele spelbestanden. Genereer hem opnieuw na een game-update.

## Architectuur

- `src/TruckSimTweaker.Core` bevat game-identificatie, begrensde tekstimport, preview en ZIP-export. De parser accepteert één tekstuele economy-unit, zonder includes, met precies één bruikbare waarde per doelveld. Het bronbestand wordt alleen gelezen. De export schrijft eerst een tijdelijke ZIP en verplaatst die naar een nieuw `.scs`-bestand.
- `src/TruckSimTweaker.Desktop` bevat WPF, Windows/Steam-detectie en de gebruikersinterface. WPF past bij Windows als eerste platform en gebruikt de .NET desktop SDK. Avalonia is een optie zodra Linux of macOS een concrete eis wordt. De kern kan dan worden hergebruikt.
- `tests/TruckSimTweaker.Tests` controleert de kern met synthetische invoer. De test draait met Nederlandse getalnotatie en controleert onder andere commentaar, ontbrekende en dubbele velden, ongeldige invoer, archiefstructuur en bescherming tegen overschrijven. De test heeft geen externe testpackages nodig.

## Samen testen en uitbreiden

1. Begin met één game. Noteer de exacte gameversie, jobtype, beide waarden in de preview en de uitkomst op een testprofiel. Vergelijk een lokale vrachtmarktrit met ×1/×1 en een vergelijkbare rit met ×2/×5. Gebruik bij voorkeur dezelfde uitgangssave en noteer geld, afstands-XP en bonussen afzonderlijk. Controleer bij laadproblemen de regels rond de mod in `game.log.txt`.
2. Herhaal voor de andere game. Leg per build vast wat laadt en wat meetbaar verandert. Zet de build- en regressiecontroles daarna in Windows-CI. Deel bij een issue de versie, instellingen en relevante logregels, en gebruik synthetische testdata in de repository.
3. Voeg begeleid uitpakken toe als de bestandsindeling per game is bevestigd. Houd versiecontrole en meldingen voor conflicterende economy-mods dicht bij de import en export.
4. Onderzoek **Coaches XP** als aparte voortgang in ETS2. Identificeer de bron per build en meet een gecontroleerde passagiersrit voordat we bediening toevoegen. Zie [SCS over Mode Switch](https://blog.scssoft.com/2026/09/coaches-road-trip-mode-switch.html).
5. Onderzoek **ATS Road Trip Courier Rating** via afzonderlijke proeven met klantbeoordelingen en bezorgreeksen. SCS beschrijft reputatie als voortgang voor deze modus. Zie [SCS over Road Trip](https://blog.scssoft.com/2026/09/road-trip-quick-jobs-freight-market.html).
6. Onderzoek een optionele savegame-editor pas na de modworkflow. Begin met offline leesmodus en formaatdetectie per versie, inclusief eventuele decryptie. Schrijven vereist een geteste herstelroute met een ongewijzigde back-up en validatie vóór vervanging.

[SCS over economievelden](https://modding.scssoft.com/wiki/Games/ETS2/Modding_guides/1.32) · [Microsoft over WPF](https://learn.microsoft.com/dotnet/desktop/wpf/overview) · [Avalonia-platforms](https://docs.avaloniaui.net/docs/supported-platforms)
