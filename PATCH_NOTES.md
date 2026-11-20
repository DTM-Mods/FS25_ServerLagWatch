<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/patch-notes.jpg" alt="Patch notes" width="100%">
</p>

# Patch notes

## 1.6.0.0

- The profanity filter moved to its own mod, **FS25_NoProfanityFilter**. Install that one to keep chat, names and license plates unfiltered; this mod no longer touches the filter.

## 1.5.1.0

- All 27 game languages: the big red "SERVER SAVE" letters and the freeze notification (farm, driver, field, "300 ms in 20 calls" and so on) show in each player's own language. The server sends the line with placeholders and each player's game fills in the words, so players with different languages on one server each read their own. Script and class names stay as they are; the big "SERVER LAG WATCH" letters are the mod's name and stay English.
- The server log writes those words in the server's language; the rest of each log line stays English.
- Mod description in all 27 languages.

## 1.5.0.0

- Freeze lines no longer say "unknown" just because no single call took 40 ms: time is now added up per script across the whole frame, and the script with the biggest total is named with its call count (for example "300 ms in 20 calls"). Time spent inside other timed calls is not counted twice.
- The game's own updateables, systems and managers (environment, AI, vehicles, placeables, missions and more), and mod updateables, are now timed too, named "base game: Class:update" or "mod FS25_X: Class:update".
- Every freeze line now ends with "Watched scripts: X ms, outside: Y ms". When "outside" is close to the freeze time, the engine or untimed base-game code caused it, not a mod.

## 1.4.0.4

- Description in GIANTS' ModHub layout (category, price, upkeep or hotkeys at the top).

## 1.4.0.3

- Updated for the current game version: modDesc descVersion 116 (the game build of 2026-10-27; GIANTS TestRunner 0.9.24 accepts only 116).

## 1.4.0.2
- Meets the GIANTS ModHub checks (TestRunner): textures, icon and modDesc brought up to date.
- Errors are no longer hidden: they show in the log.

## 1.4.0.1

- The author now shows as **DTM Mods, PropaineX** in the mod list.

## 1.4.0.0
- Slow vehicle and placeable calls now say who is responsible: farm name, driver (player, AI helper or no driver) and where it is (field, farmland or off-field). Implements name the driver of the tractor they hang on.

## 1.3.1.0
- The profanity filter is now really turned off (1.3.0.0 only said it was).

## 1.3.0.0
- Turns off the profanity filter: chat, names and license plates show exactly what was typed.

## 1.2.0.0
- Freezes are measured in real time, so long stalls are no longer missed.
- During a save, slow file writes are logged by file name, plus a save breakdown line (system saves, file writes, everything else, memory change).
- When the server stops answering for 3 seconds, every player sees big red "SERVER LAG WATCH" letters until it answers again.

## 1.1.0.0
- Every player sees big red "SERVER SAVE" letters while the server saves.

## 1.0.0.0
- First version: when the server freezes for more than a quarter of a second, every player gets a notification with how long it froze and which mod script was the slowest. The same line goes into the server log.
