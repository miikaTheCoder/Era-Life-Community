ERA LIFE COMMUNITY - DESKTOP ALPHA 0.1.3

This is an early playable build, not a finished or fully tested release.
Back up existing saves before testing. Android is a separate experiment.
Source and releases: https://github.com/miikaTheCoder/Era-Life-Community
Community upstream: https://github.com/Browleytheboi/Era-Life-Community
Desktop updates are manual; the inherited upstream live-update channel is disabled.

INSTALL
Extract the whole archive into a writable folder.
Linux: run EraLife.x86_64. Windows: run EraLife.exe.
Keep EraLife.pck next to the Linux/Windows executable from the same archive.
macOS: open the included .app; its game data is inside the bundle.
You do not need to install Godot to play.

START A LIFE
Narrative: choose a story, make choices, then enter the resulting life.
Household: create members, choose whose life to enter, then begin.
God Mode: directly create your character and world.
Allow world generation to finish. Save, quit fully, and reload to test persistence.

PLATFORM STATUS
Linux: creation, aging, and save/reload tested on the development machine.
Windows: exported successfully; native Windows playtest still required.
macOS Intel/Apple Silicon: cross-exported; native Mac playtest still required.
Windows is unsigned. macOS has an ad-hoc testing signature, no Developer ID
signature or Apple notarization. Downloaded builds may trigger OS warnings.
Do not disable system-wide security protections to run a test build.
macOS help: https://docs.godotengine.org/en/4.4/tutorials/export/running_on_macos.html

If graphics initialization fails, try the executable with:
  --rendering-method gl_compatibility
On macOS, use the executable inside the .app/Contents/MacOS/ folder with that
argument (quote paths containing spaces).

KNOWN LIMITS
Full birth-to-death playthroughs, every story branch, and game balance are not
verified. Some cleanup/snapshot warnings remain. Older saves may already have
lost history that these fixes cannot recover. See docs/DESKTOP-GAMEPLAY.md in
the matching source checkout for validation details.

SOURCE AND NOTICES
The release tag and source must match the files you downloaded. BUILD_INFO.txt
records the local commit and whether uncommitted changes were included. A dirty
build is a development snapshot, not a reproducible tagged release.
LICENSE contains the repository's existing GPL v2 license text.
GODOT_LICENSE.txt and GODOT_COPYRIGHT.txt contain Godot 4.4.1 engine notices;
they do not license the game's separately authored code, music, or artwork.
