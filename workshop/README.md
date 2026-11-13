# Steam Workshop-pakketten bouwen

Pak `def.scs` van de gekozen game uit met de officiële SCS Game Archive Extractor. Geef de uitgepakte `def`-map en de versie van die installatie aan de bouwer. Kies een nieuwe uitvoermap.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File workshop/Build-Workshop.ps1 -Game ETS2 -Definitions C:\SCS\ETS2\def -Destination workshop-output-ets2 -CompatibleVersion 1.62.3.3
powershell -NoProfile -ExecutionPolicy Bypass -File workshop/Build-Workshop.ps1 -Game ATS -Definitions C:\SCS\ATS\def -Destination workshop-output-ats -CompatibleVersion 1.62.2.2
```

Open SCS Workshop Uploader via Steam en selecteer de juiste game. Maak per mod een eigen item. Kies de submap `upload` als modmap en `preview.jpg` uit de bovenliggende map als Workshop-afbeelding. Begin met zichtbaarheid Privé en laat de Uploader het pakket valideren. Test de Workshop-versie op een testprofiel met de lokale versie van diezelfde mod uitgeschakeld.

- ETS2 en ATS krijgen elk een eigen **TruckSim Tweaker - Truck Economy & XP**. De geldcoëfficiënt voor de vrachtmarkt is ×2 en afstands-XP voor vrachtleveringen is ×5.
- ETS2 krijgt apart **TruckSim Tweaker - Coaches Levels**. De XP-eisen zijn gedeeld door vijf. Het effect op Coach-ritbeloningen en ATS Road Trip Courier Rating blijft onderzoek.

Na een game-update pak je de nieuwe definities uit en bouw je opnieuw met het nieuwe versienummer. Controleer de waarden en test in het spel. Selecteer in de Uploader het bestaande item voor de update. Om een oudere gameversie te blijven ondersteunen, geef je beide pakketmappen unieke namen en wijs je elke versie in `versions.sii` naar de bijbehorende map.

[SCS-handleiding voor uploaden](https://modding.scssoft.com/wiki/Tutorials/SCS_Workshop_Uploader/How_to_upload_new_mod%3F) · [SCS-handleiding voor updates](https://modding.scssoft.com/wiki/Tutorials/SCS_Workshop_Uploader/How_to_update_workshop_mod%3F)
