<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-header.jpg" alt="DTM Mods by PropaineX & Fennell" width="100%"></a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/icons/FS25_ServerLagWatch.png" alt="Server Lag Watch icon" width="128">
</p>

<h1 align="center">Server Lag Watch</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Farming%20Simulator-25-2E6B4F" alt="Farming Simulator 25">
  <a href="https://github.com/DTM-Mods/FS25_ServerLagWatch/releases/latest"><img src="https://img.shields.io/github/v/release/DTM-Mods/FS25_ServerLagWatch?label=version&color=D9A441" alt="Latest version"></a>
  <a href="https://github.com/DTM-Mods"><img src="https://img.shields.io/badge/DTM-Mods-143326" alt="DTM Mods"></a>
</p>

<p align="center">
  <b>Finds out which mod freezes your server.</b><br>
  <sub>by PropaineX</sub>
</p>

<p align="center">
  <a href="https://github.com/DTM-Mods/FS25_ServerLagWatch/releases/latest"><img src="https://img.shields.io/badge/Download-latest%20release-D9A441?style=for-the-badge&logo=github&logoColor=143326&labelColor=E9C77A" alt="Download the latest release"></a>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/features.jpg" alt="Features" width="100%">
</p>

- **Freeze alerts**: when the server stops for longer than a quarter of a second, every player gets a notification with how long it froze and which mod script was the slowest at that moment. The same line goes into the server log, so the cause can be found afterwards.
- **Whole-frame totals**: time is added up per script over the whole frame, so many small calls still show ("300 ms in 20 calls"). Base-game and mod updateables and the game's systems and managers are timed too. Every freeze line ends with "Watched scripts: X ms, outside: Y ms": when "outside" is most of it, the engine or untimed base-game code is the cause, not a mod.
- **Who and where**: a slow vehicle or placeable is named with its farm, its driver (player, AI helper or no driver) and where it is (field, farmland or off-field).
- **SERVER SAVE**: every time the server saves, every player sees big red "SERVER SAVE" letters in the middle of the screen until the save is done. Slow file writes during the save are logged by file name.
- **SERVER LAG WATCH**: when the server stops answering for 3 seconds, every player sees big red "SERVER LAG WATCH" letters until it answers again.

Apart from that it changes nothing in the game; it only measures and reports.

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/installation.jpg" alt="Installation" width="100%">
</p>

Download `FS25_ServerLagWatch.zip` from the [latest release](https://github.com/DTM-Mods/FS25_ServerLagWatch/releases/latest) and put it in `Documents/My Games/FarmingSimulator2025/mods`, without unzipping or renaming it. Install it on the server **and** on every player's game, all on the same version.

In the server log, look for lines starting with `[ServerLagWatch]`.

See [PATCH_NOTES.md](PATCH_NOTES.md) for what changed in each version.

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/license.jpg" alt="License" width="100%">
</p>

MIT, see [LICENSE](LICENSE).

---

<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-intro.gif" alt="DTM Mods by PropaineX & Fennell" width="420"></a><br>
  <sub>Part of <a href="https://github.com/DTM-Mods">DTM Mods</a> (Designed To Manage) by PropaineX & Fennell</sub><br><br>
  <a href="https://ko-fi.com/dtmmods"><img src="https://img.shields.io/badge/Ko--fi-support%20DTM%20Mods-1F4D3A?logo=kofi&logoColor=F4F1E8" alt="Support DTM Mods on Ko-fi"></a>
  <a href="https://www.paypal.com/donate/?business=dtmmods%40gmail.com&amp;no_recurring=0&amp;item_name=DTM+Mods&amp;currency_code=USD"><img src="https://img.shields.io/badge/PayPal-donate-1F4D3A?logo=paypal&logoColor=F4F1E8" alt="Donate to DTM Mods with PayPal"></a><br>
  <a href="https://www.youtube.com/@DTMMods"><img src="https://img.shields.io/badge/YouTube-videos-1F4D3A?logo=youtube&logoColor=F4F1E8" alt="DTM Mods on YouTube"></a>
  <a href="https://dtmmods.itch.io"><img src="https://img.shields.io/badge/itch.io-our%20mods-1F4D3A?logo=itchdotio&logoColor=F4F1E8" alt="DTM Mods on itch.io"></a>
  <a href="https://www.kingmods.net/en/profile/dtmmods"><img src="https://img.shields.io/badge/KingMods-our%20mods-1F4D3A" alt="DTM Mods on KingMods"></a>
</p>
