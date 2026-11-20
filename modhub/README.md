# ModHub upload: Server Lag Watch

What to enter in the GIANTS ModHub upload form for this mod. Each text box below has a copy button on GitHub.

<img src="icon_512.png" alt="Mod icon" width="160">

**Mod Icon (512x512):** [`icon_512.png`](icon_512.png)

| Field | Value |
|-------|-------|
| Title English | Server Lag Watch |
| Title German | Server Lag Watch |
| Title French | Server Lag Watch |
| Version | `1` `5` `0` `0` |
| Author | DTM Mods, PropaineX |
| Manufacturer | Lizard |
| Category 1 | Gameplay |
| Category 2 | Not Set |
| Category 3 | Not Set |

## Title English
```text
Server Lag Watch
```

## Title German
```text
Server Lag Watch
```

## Title French
```text
Server Lag Watch
```

## Description English
```text
Description: Finds out which mod freezes your server. Every freeze over a quarter of a second is shown to every player and written to the server log, with the mod script or the save that caused it.
Hotkeys: none, it works on its own. Install it on the server and on every player's game.
GitHub: https://github.com/DTM-Mods/FS25_ServerLagWatch

Whenever the server stops for longer than a quarter of a second, every player gets a notification on screen: how long the server froze and which mod script was the slowest at that moment. The same line is written to the server log, so the cause can be found afterwards.

Time is added up per script over the whole frame, so many small calls still show ("300 ms in 20 calls"), and the game's own updateables, systems and managers are timed too. Each freeze line splits the time into watched scripts and time outside them: when "outside" is most of it, the engine or untimed base-game code caused the freeze, not a mod.

Every time the server saves the game, every player sees big red "SERVER SAVE" letters in the middle of the screen until the save is done.

When the server stops answering for 3 seconds, every player sees big red "SERVER LAG WATCH" letters in the middle of the screen until it answers again.

It also turns off the profanity filter: chat, names and license plates show exactly what was typed. Apart from that it changes nothing in the game, it only measures and reports.

Changelog 1.5.0.0:
- Freeze lines no longer say "unknown" when no single call was slow: time is added up per script over the whole frame and the biggest total is named with its call count.
- The game's own updateables, systems and managers (and mod updateables) are now timed too.
- Every freeze line shows "Watched scripts: X ms, outside: Y ms", so engine or base-game freezes can be told apart from mod freezes.
```

## Description German
```text
Beschreibung: Findet heraus, welcher Mod deinen Server einfrieren lässt. Jeder Hänger über eine Viertelsekunde wird jedem Spieler angezeigt und ins Server-Log geschrieben, mit dem Mod-Skript oder dem Speichern als Ursache.
Tastenkombinationen: keine, der Mod arbeitet von selbst. Auf dem Server und im Spiel jedes Spielers installieren.
GitHub: https://github.com/DTM-Mods/FS25_ServerLagWatch

Sobald der Server länger als eine Viertelsekunde stehen bleibt, bekommt jeder Spieler eine Meldung auf den Bildschirm: wie lange der Server eingefroren war und welches Mod-Skript in diesem Moment am langsamsten war. Dieselbe Zeile wird ins Server-Log geschrieben, damit die Ursache auch später noch gefunden werden kann.

Die Zeit wird pro Skript über den ganzen Frame zusammengezählt, damit auch viele kleine Aufrufe auffallen ("300 ms in 20 calls"), und die Updateables, Systeme und Manager des Spiels werden ebenfalls gemessen. Jede Hänger-Zeile teilt die Zeit in gemessene Skripte und Zeit außerhalb: Ist "outside" der größte Teil, war die Engine oder ungemessener Basisspiel-Code die Ursache, kein Mod.

Jedes Mal, wenn der Server das Spiel speichert, sieht jeder Spieler große rote Buchstaben "SERVER SAVE" in der Mitte des Bildschirms, bis das Speichern fertig ist.

Wenn der Server 3 Sekunden lang nicht antwortet, sieht jeder Spieler große rote Buchstaben "SERVER LAG WATCH" in der Mitte des Bildschirms, bis er wieder antwortet.

Er schaltet außerdem den Schimpfwortfilter aus: Chat, Namen und Kennzeichen zeigen genau das, was eingegeben wurde. Abgesehen davon ändert er nichts am Spiel, er misst nur und meldet.

Changelog 1.5.0.0:
- Hänger-Zeilen sagen nicht mehr "unknown", wenn kein einzelner Aufruf langsam war: Die Zeit wird pro Skript über den ganzen Frame zusammengezählt und die größte Summe mit der Anzahl der Aufrufe genannt.
- Updateables, Systeme und Manager des Spiels (und Updateables von Mods) werden jetzt auch gemessen.
- Jede Hänger-Zeile zeigt "Watched scripts: X ms, outside: Y ms", damit Hänger durch Engine oder Basisspiel von Mod-Hängern unterschieden werden können.
```

## Description French
```text
Description : trouve quel mod fait geler votre serveur. Chaque gel de plus d'un quart de seconde est affiché à chaque joueur et écrit dans le journal du serveur, avec le script de mod ou la sauvegarde en cause.
Raccourcis : aucun, le mod fonctionne tout seul. À installer sur le serveur et dans le jeu de chaque joueur.
GitHub : https://github.com/DTM-Mods/FS25_ServerLagWatch

Dès que le serveur s'arrête plus d'un quart de seconde, chaque joueur reçoit une notification à l'écran : la durée du gel et le script de mod le plus lent à ce moment-là. La même ligne est écrite dans le journal du serveur, pour retrouver la cause plus tard.

Le temps est additionné par script sur toute l'image, pour que beaucoup de petits appels ressortent aussi ("300 ms in 20 calls"), et les updateables, systèmes et gestionnaires du jeu sont mesurés aussi. Chaque ligne de gel sépare le temps des scripts mesurés du temps en dehors : si "outside" en fait la plus grande partie, la cause est le moteur ou du code du jeu de base non mesuré, pas un mod.

Chaque fois que le serveur sauvegarde la partie, chaque joueur voit de grandes lettres rouges "SERVER SAVE" au milieu de l'écran jusqu'à la fin de la sauvegarde.

Quand le serveur ne répond plus pendant 3 secondes, chaque joueur voit de grandes lettres rouges "SERVER LAG WATCH" au milieu de l'écran jusqu'à ce qu'il réponde à nouveau.

Il désactive aussi le filtre de grossièretés : chat, noms et plaques affichent exactement ce qui a été tapé. À part cela, il ne change rien au jeu, il mesure et signale seulement.

Changelog 1.5.0.0 :
- Les lignes de gel n'indiquent plus "unknown" quand aucun appel isolé n'était lent : le temps est additionné par script sur toute l'image et le plus gros total est nommé avec son nombre d'appels.
- Les updateables, systèmes et gestionnaires du jeu (et les updateables des mods) sont maintenant mesurés aussi.
- Chaque ligne de gel affiche "Watched scripts: X ms, outside: Y ms", pour distinguer les gels du moteur ou du jeu de base de ceux d'un mod.
```

## Screenshots

Upload the three in [`screenshots/`](screenshots/) (1600x900, unedited in-game shots from `../screenshots/`), in order: 1 a tractor with no UI, 2 a "Server froze ... game save" message, 3 a freeze message naming the mod script. 2 and 3 show other mods' HUDs (Advanced Farm Manager's control group, AutoDrive, Courseplay, ADAddOn) and 3 a Screenshot Studio message.

## Before uploading

- The icon was upscaled from 256 px; a native 512 px icon would look sharper on ModHub.
- The mod turns off the game's profanity filter for chat, names and license plates. GIANTS may reject a mod that switches off this filter; owner's decision whether to keep that part in a ModHub version.
- Missing translations in the mod itself: the modDesc title and description and the on-screen messages are English only. The German/French texts here do not add them to the mod.
