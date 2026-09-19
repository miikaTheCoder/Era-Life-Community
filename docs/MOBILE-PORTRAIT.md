# EraLife Portrait

The `codex/mobile-portrait` branch presents the existing game as a portrait Android life simulator. It uses EraLife's dark surfaces, cyan buttons, and serif journal heading. The layout has a compact identity/balance header, a scrolling life journal, four summary stats, and a five-action dock: School/Career, Assets, Age, People, and Activities. Me opens the original character details; Menu holds World/Save and the available gameplay shortcuts.

## Ownership

- `project/ui/EraMobileShell.gd` arranges the existing gameplay controls and dispatches their existing signals. It does not own simulation state.
- `project/ui/EraMobilePanels.gd` adapts existing forms, hubs, and modal panels to the safe portrait area, with scrollable content and original Back actions.
- `project/platform/mobile/MobileSupport.gd` owns Android viewport scaling, safe-area conversion, keyboard focus restoration, and platform Back handling.
- `project/ui/EraInterface.gd` selects the mobile shell on Android or with `--mobile-preview`; desktop keeps its existing shell.

The logical viewport is 420 units wide and preserves the phone's aspect ratio. Actual Android display insets are mapped into that viewport. The APK manifest locks portrait orientation.

The package is `org.eralife.community.portrait`, labelled **EraLife Portrait**. The previous `org.eralife.community.mobile` app and its saves remain separate. Upstream runtime updates are disabled for this fork so they cannot replace the portrait source. The debug APK retains the earlier port's ARMv7 compatibility workaround; this is a development preview, not a store release.

## Run and build

From this checkout:

```sh
# Desktop portrait preview, with your normal local save profile.
build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64 \
  --path project --rendering-method gl_compatibility --resolution 420x900 \
  -- --mobile-preview

# Signed Android debug build; see ANDROID.md for SDK/JDK requirements.
scripts/build.sh android

# Isolated portrait touch/gameplay test (creates its own test save profile).
ERA_PORTRAIT=1 scripts/test-desktop-modes.sh household
ERA_PORTRAIT=1 scripts/test-desktop-modes.sh god

python3 scripts/test-headless.py
python3 scripts/check-structure.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
```

The APK is `build/android/EraLife-portrait-android-debug.apk`. Local editor settings, signing keys, logs, and output stay in this checkout's ignored build directory. A shared `build/tools` symlink may provide the pinned Godot editor and export templates without changing another checkout's editor profile.

## Validation and limits

The initial full pinned Godot 4.4.1 suite passed all 19 tests. The portrait Household graphical smoke created three related characters, entered the selected child, aged from eight to nine, opened School, People, Activities, Assets, character details and Menu, verified Android Back, and saved. God Mode also created, aged and saved a character in the first graphical run; that initial run caught a school sizing issue subsequently fixed and covered by the passing Household run.

Narrative's mobile entry remains visibly disabled. An experimental enabled run reached its birth handoff, then Godot crashed on a background thread after reporting a scene-tree thread access error. The core confirms the worker-thread crash and no OOM kill was recorded, but the stripped executable does not establish the exact GDScript cause. This fork does not claim to fix it. The prior Android port already disabled this entry.

Existing persistence limitations and shutdown resource-leak warnings remain. Saving a life does not prove a complete cold restore or full world-history round trip. Headless layout tests do not establish correctness of every gameplay panel, a full lifetime, or online accounts.

### Final branch verification

- Final import and all 19 regression scripts: PASS (`build/tests/headless-7y3hvr51/`).
- Structure, regenerated code map, and whitespace checks: PASS.
- Final God Mode graphical smoke at an actual 420×900 viewport: PASS (`build/portrait-graph-reviewed/portrait-fixed.log`). It verifies creation, Age, School, People, Activities, Assets, Menu, character details, Android Back routing, and save. The inspected Activities screenshot has readable, horizontally scrollable tabs and a full Back label.
- Two intermediate graphical reruns were constrained by the tiling desktop to short/wide windows and failed the portrait-size assertions. The final run floated only its own temporary window and set its dimensions explicitly; no desktop configuration was changed.
- Final signed APK: `build/android/EraLife-portrait-android-debug.apk`; SHA-256 `58cbbfba53c2c4847d7bd6fcf9a72bb666ed986cbe4ee68658aceba37906f88e`. Package/label/ARMv7 manifest and signing verification passed.
- An earlier preview APK was installed over USB on the HONOR ABR-NX1 and entered a generated life in portrait. Keyboard opening/dismissal and form swiping were observed. Keyboard testing prompted the final focus-scroll fix. The phone subsequently disconnected; final-APK installation, verification of that keyboard fix on-device, and phone save/reload remain pending. The final APK must not be described as device-verified.

## Portrait update 0.1.0-portrait.2

Dropdowns now open `ui/common/MobileOptionSheet.gd`, a scrollable in-viewport list. Selection updates the original OptionButton index and emits its existing item_selected callback once; item IDs, metadata, disabled choices, separators and icons remain with their existing owner. Swipes do not select, and Back cancels without changing the field. The user confirmed dropdowns work on the phone after installation.

The early boot PNG is included as a raw image (Godot's boot image reader cannot use only the imported texture). The mobile loader is the default entry, with a PC override retaining the desktop entry. The loader waits for drawing before requesting the heavy scene. Device diagnostics found its text at y=962 in a 938-high viewport during startup; the final layout uses viewport anchors rather than initial absolute Android geometry. The loading-layout regression checks centering and bounds across three phone sizes. These presentation changes do not claim to shorten scene-loading time.

Validation: all 19 existing tests passed (`build/tests/headless-yjlymjo5`); the added loader test and final mobile configuration checks are in `build/tests/headless-ko2x511z`. APK signing and raw splash inclusion checked. USB disconnected before the final anchored-loader build could be installed, so final loader visibility still needs a device recheck. Earlier iterations are not counted as successful visual checks.


## Startup update 0.1.0-portrait.3

The `codex/mobile-startup-performance` branch adds an independent dark/cyan entry
menu, defers domain script loading to existing initialization boundaries, and
avoids optional mobile panel prewarming. New life can be selected during loading;
Back cancels the selection. Saved life & account and Watch intro retain their
existing destinations. Informational tooltips no longer consume panel Back.

The signed ARMv7 build is installed on the paired HONOR phone. Resource loading
fell from 46.0 seconds to 24.5–24.6 seconds in the measured cold starts. The entry
menu appeared at 3.0–3.4 seconds; queued New life reached the creation menu at
28.5 seconds. All 21 headless tests and the final God Mode/Household graphical
smokes passed. One intermittent God Mode readiness timeout remains unresolved.
See [startup performance](STARTUP-PERFORMANCE.md) for evidence and limitations.
