# Era Life Community — Desktop Alpha 1

Version **v0.1.3-alpha.1**. An early desktop playtest of the reconstructed community
project. Back up your existing saves before playing.

## What changed

- Narrative and Household creation now lead into playable lives.
- Household members and family links survive character selection and save/reload.
- Narrative choices, diary entries, and world history carry into the simulation
  and its checkpoints; continued aging resumes the saved history.
- Existing God Mode creation remains available.
- Desktop builds no longer poll the original project's runtime-update server.
  Updates to this fork are installed manually from its GitHub Releases.

## Downloads

Download the archive for your system and extract it fully. Godot installation is
not required. On Linux and Windows, keep the executable and `EraLife.pck` together.
On macOS, open the included app bundle. Launch instructions and license notices
are included; `SHA256SUMS.txt` lists the archive checksums.

| Platform | File | Validation |
| --- | --- | --- |
| Linux x86_64 | `EraLife-linux-x86_64.tar.gz` | Creation, aging, save, full restart, and continued aging tested on Linux |
| Windows x86_64 | `EraLife-windows-x86_64.zip` | Experimental: export/archive checks passed; native Windows playtest pending; unsigned |
| macOS Intel / Apple Silicon | `EraLife-macos-universal.zip` | Experimental: universal bundle/archive checks passed; native Mac playtests pending |

The macOS app has an ad-hoc testing signature, **not** a Developer ID signature or
Apple notarization. Downloaded builds may be blocked by Gatekeeper. Do not disable
system-wide security protections to run a test build. Windows may also display
unsigned-app warnings. Android APKs are not included in this desktop release.

## Known limits

This is an alpha, not a complete birth-to-death validation. Not every story branch,
career, or balance scenario has been tested. Shutdown cleanup warnings and a snapshot
warning remain. Old saves may already have lost history that cannot be recovered.
See [desktop validation](https://github.com/miikaTheCoder/Era-Life-Community/blob/v0.1.3-alpha.1/docs/DESKTOP-GAMEPLAY.md)
for the tested paths and remaining limitations.

## Source and credits

Based on [Browleytheboi/Era-Life-Community](https://github.com/Browleytheboi/Era-Life-Community),
with original and community contributor history preserved. The repository's GPL v2
license text and Godot engine notices accompany the downloads. The existing media
assets are unchanged from the community source.

The matching source is tagged
[`v0.1.3-alpha.1`](https://github.com/miikaTheCoder/Era-Life-Community/tree/v0.1.3-alpha.1).
Build with pinned Godot 4.4.1 using the included setup/build scripts. Each archive's
`BUILD_INFO.txt` identifies the source commit.
