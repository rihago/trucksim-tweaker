# Verder werken aan TruckSim Tweaker

## Op een nieuwe pc

1. Meld je aan bij GitHub en clone `rihago/trucksim-tweaker` met GitHub Desktop of met `git clone https://github.com/rihago/trucksim-tweaker.git`.
2. Open de gekloonde map als project in Codex. Vraag bijvoorbeeld: “Lees README.md en HANDOFF.md en pak de eerstvolgende test op.”
3. Installeer de .NET 10 SDK en volg de build- en testinstructies in [README.md](README.md). Installeer de gewenste game via Steam en pak voor de speltest opnieuw het economy-bestand uit dezelfde gamebuild uit.

GitHub bevat broncode, tests, documentatie en de gepushte geschiedenis. Bewaar werk dat je na een herinstallatie nodig hebt in commits en push die vóór de herinstallatie. Houd bevindingen en open vragen bij in [GitHub Issues](https://github.com/rihago/trucksim-tweaker/issues). Werk dit bestand bij zodra de projectstatus of de eerstvolgende stap wijzigt. Lokale Codex-chats, gamebestanden, saves en gegenereerde mods worden via deze repository niet meegenomen.

## Huidige status

- Windows-MVP met C#/.NET 10 en WPF. De kernbibliotheek verwerkt tekstuele economy-bestanden en genereert .scs-archieven.
- Build en automatische controles zijn geslaagd met synthetische invoer. De desktopworkflow en de effecten in beide games moeten nog in de praktijk worden bevestigd.
- Coaches XP en ATS Road Trip Courier Rating staan op de onderzoeksagenda. Een savegame-editor met formaatdetectie, eventuele decryptie, back-ups en herstel is toekomstig werk.

## Eerstvolgende test

Kies ETS2 of ATS en noteer de exacte gamebuild. Importeer `def/economy_data.sii` uit die installatie en genereer op een testprofiel een mod met geld ×2 en XP ×5. Controleer of hij verschijnt in Mod Manager en vergelijk een lokale vrachtmarktrit met een vergelijkbare ×1/×1-rit. Noteer de previewwaarden, uitbetaling, afstands-XP en bonussen. Voeg bij laadproblemen de relevante regels uit `game.log.txt` toe aan een issue. Herhaal daarna voor de andere game.

## Speltest ETS2 1.62.3.3s (64-bit)

- Vrachtwagen-XP ×5 bevestigd bij een Snelle opdracht: 149 km gaf 745 basis-XP en 15 XP parkeerbonus. Geld ×2 op de Vrachtmarkt moet nog worden gemeten.
- De aparte Coaches-testmod verlaagt de waarden in `def/bus_economy_data_xp.sii` tot een vijfde. De gamelog bevestigde dat de mod geladen was en het voortgangsscherm toonde op level 0 **0 / 40 XP**. De standaardwaarde in het uitgepakte spelbestand is 200 XP. XP-beloning per coachrit en coachinkomsten blijven onderzoek.

## Modindeling en directe profielwijzigingen

- Houd twee onafhankelijke .scs-mods aan. De vrachtwagenmod past `def/economy_data.sii` aan. Coaches Levels past `def/bus_economy_data_xp.sii` aan. Beide kunnen tegelijk actief zijn.
- Onderzoek een aparte functie in de Windows-app om geld of XP direct aan een lokale save toe te voegen. Begin met één ETS2-testsave en bevestig eerst formaat, saldo en afzonderlijke vrachtwagen- en Coaches-XP. Voeg schrijven pas toe na een geteste back-up, validatie en herstel. De officiële SCS Telemetry & Input SDK documenteert geen schrijffunctie voor deze profielwaarden. Een live knop in ETS2 is vooralsnog onbevestigd.

### Coaches-geldtest ETS2 1.62.3.3s

Een lokale mod voegt `fixed_revenue: 1200` en `revenue_per_km: 30.0` toe aan de originele `def/bus_economy_data.sii`. De gamelog bevestigde dat de mod geladen was. Screenshots van dezelfde Snelle opdrachten tonen zonder/met mod: Amsterdam–Brussel €5.625 → €11.250 en Amsterdam–Düsseldorf €6.075 → €12.150, beide €15/km → €30/km. De aangeboden prijs verdubbelt. Uitbetaling na afronding, andere opdrachttypes en de bijdrage van het vaste veld afzonderlijk zijn nog niet gemeten.

## Gecombineerde Workshop-pakketten

De beoogde publicatie is één item per spel. Gebruik `workshop/Build-CombinedTest.ps1` met de uitgepakte definities van de juiste builds, voeg een JPG van 276 × 162 toe als `mod_icon.jpg` en exporteer met `workshop/Export-CombinedWorkshop.ps1`. Selecteer de map `upload` en de bijbehorende `preview.jpg` in SCS Workshop Uploader.

- ETS2 1.62.3.3: Coaches Snelle opdracht Amsterdam–Düsseldorf betaalde €12.150 met de gecombineerde mod. Het oorspronkelijke aanbod was €6.075. Coaches-basis-XP bleef 1/km. De aangepaste XP-bonussen vragen een vergelijkende test. Truck-afstands-XP ×5 is eerder bevestigd in de losse mod.
- ATS 1.62.2.2: Road Trip vaste en kilometerbeloning ×2. Ratingdrempels voor opdrachten en tiers zijn met een halve ster verlaagd. Speltest staat open.
- Beide pakketten wachten op validatie in SCS Workshop Uploader. Begin privé, met oudere lokale varianten uitgeschakeld op het testprofiel.
