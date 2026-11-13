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
