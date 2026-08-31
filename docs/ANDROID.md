# Android port (experimental)

The `mobile` branch adds an experimental Android sideload build. The default APK now uses **ARMv7 (32-bit ARM)** after the original ARM64 build failed during startup on the test phone. This is a compatibility workaround, not a Google Play release or a claim that every gameplay system works on a phone.

## Install and play

Copy `build/android/EraLife-android-debug.apk` to your device, open it, and allow installation from that particular file manager/browser if Android requests it. The APK contains the game data; no separate PCK is needed. This build requires support for **armeabi-v7a apps**, Android 5.0/API 21 or newer, and OpenGL ES 3.0. It uses landscape orientation. A 64-bit processor alone is not enough: 64-bit-only Android devices cannot run this APK. These are manifest requirements, not a tested device compatibility range.

**Save warning:** versions through `0.1.2-mobile.6` could report a successful save while omitting ordinary character fields. Version 7 corrects the serializer, but cannot recover fields absent from old files. Version 9 has passed a phone cold-restart, Continue, and re-save check for the tested character and 19 lineage actors. This is not full-world save validation: the diary resumed with birth history and the World feed did not preserve the earlier event history. Those history paths still need work.

Android may display an ABI compatibility warning for this 32-bit build. This was observed on the test phone and acknowledged before playing. The warning has not been disabled or suppressed. Allow roughly **1–1½ minutes** for cold startup there; an Android-only loading screen keeps the UI responsive while the large game script loads. MainScene's subsequent initialization can still briefly pause that screen.

With an authorized USB debugging connection, you can instead install using:

```sh
adb install -r build/android/EraLife-android-debug.apk
adb shell am start -n org.eralife.community.mobile/com.godot.game.GodotApp
```

The package ID is `org.eralife.community.mobile`, separate from any original release. Install updates over the existing app to preserve its data; do not uninstall first. Local saves live in Android's private app storage, which uninstalling removes. Preserve `build/keys/android-debug.keystore` locally to update this test installation with the same signer; do not commit the key. This is a development key, not a production signing identity.

**16 KB page-size limitation:** both architectures in Godot 4.4.1's prebuilt templates contain native libraries with 4 KB ELF load-segment alignment. This port does not provide native 16 KB page support. Some Android versions offer a compatibility mode, but successful installation or operation on those devices is not established. Supporting them reliably requires rebuilding or upgrading the engine templates and repeating compatibility tests; APK ZIP alignment alone is insufficient. See [Android's page-size guidance](https://developer.android.com/guide/practices/page-sizes).

## Build on Linux

Install OpenJDK 17, Python 3, the Android SDK Platform Tools, and Android SDK Build Tools **34.0.0**. The project uses Godot's prebuilt APK exporter, so it does not require Gradle, the NDK, or compiling a custom Android engine.

```sh
# One-time install of the isolated Godot 4.4.1 editor and Android templates.
./scripts/setup-godot.sh android

# With sdkmanager from Google's command-line tools, if packages are missing:
sdkmanager --sdk_root=/absolute/path/to/android-sdk \
  'platform-tools' 'build-tools;34.0.0'

JAVA_HOME=/absolute/path/to/jdk-17 \
ANDROID_SDK_ROOT=/absolute/path/to/android-sdk \
  ./scripts/build.sh android
```

The build script can also discover an existing SDK under `build/tools/android-sdk`, `~/Android/Sdk`, `~/Android/LocalSdk`, or `/opt/android-sdk`. It generates a local debug key if needed, exports the APK, independently verifies the signature, and records the manifest and checksum. With the bundled editor, SDK settings are saved under `build/tools/config`. `GODOT_BIN` selects an external editor and uses its normal Linux editor-settings location instead. The `all` target retains its original meaning: Linux and Windows desktop builds.

The Android setup follows [Godot 4.4's export documentation](https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html). Debug signing is intentionally separate from production signing. Publishing would require a release key, an appropriate AAB/export pipeline, and a fresh review of store SDK requirements and native-library compatibility, including 16 KB page sizes.

## Changes for Android

- OpenGL compatibility renderer on mobile; the desktop renderer is unchanged.
- A 960×540 reference canvas fitted to the display, with Android sensor-landscape orientation, a 60 FPS cap, and immersive fullscreen. Android can temporarily reveal system bars for gestures or the on-screen keyboard.
- A lightweight Android loading scene that loads MainScene in the background, shows elapsed time, and leaves game-state initialization with MainScene. The desktop entry scene is unchanged.
- Touch buttons for account creation, login, Continue, and disconnect, replacing keyboard-only access on the title screen.
- A scrollable single-column mode menu with the currently playable God Mode first. Desktop card-position animations are disabled in this layout because they conflict with vertical container positioning.
- Larger character-creation inputs and picker items, focus-following scrolling, and a scrollable account form.
- Touch gestures inside scrollable content distinguish taps from swipes before activating child controls. Swipes can start over fields, buttons, dropdowns, stat rows, or diary text, with flick scrolling; horizontal slider drags and mouse/keyboard input retain their native behavior. Name fields defer opening Android's keyboard until a tap is confirmed. Dynamically created panels are included.
- A compact gameplay navigation grid, with the diary fitted between the existing stats and action rails instead of overlapping them.
- Steady phone stat/shop/bending glows instead of continuously rebuilding their themes. Stat content refreshes when values, range, context, or theme change, and stat graphics also refresh on resize or hover. Floating HUD theme overrides are batched and unchanged HUD geometry is retained. Read-only incarceration lookups copy only the returned lens rather than four complete tab contracts.
- Hidden crime-target decorations are created when targeting needs them, with target data retained while browsing. The phone retains eight phase-overflow diagnostic reports instead of 80; every overflow still reaches the existing runtime guard and simulation policy is unchanged.
- The World action sidebar scrolls on phones, making the Save/Load buttons and their status messages reachable.
- The resident startup pipeline initializes the existing save/checkpoint services before the Save action can route to them. Existing identity and intent checks remain in place.
- Character snapshots include ordinary `Person` script variables, not just exported Resource properties. Loading another checkpoint wakes the scheduler even when the active life is idle; the older checkpoint decode path also initializes its engine graph worker. The existing transaction retains the active life until the new one can attach.
- Android Back dismisses the keyboard, embedded menus, account form, or an active panel through its existing close signal. At the root it asks before quitting.
- The existing mobile performance profile is retained. No simulation rules were rewritten.

Android Back is not a new general-purpose popup system: legacy overlays without close signals still use their on-screen Back/Close controls. No new background autosave was added. Use the game's Save action before leaving the app, subject to the save warning above; version 9 preserves the tested character and family values, but diary/world-history restoration remains incomplete.

## Validation and remaining checks

The APK signature and manifest are checked by `scripts/build.sh android`. Inspect `build/logs/verify-android.log`, `android-manifest.log`, and `export-android.log`. Only the Internet permission is requested by this preset. `build/android/SHA256SUMS.txt` identifies the built artifact.

Initial desktop checks on 2026-08-30 exercised screen-touch events through account-form opening/dismissal, character creation, world generation, entry into a life, and opening the World tab. The gameplay HUD passed bounds and overlap checks. Desktop startup still passes with the existing shutdown resource warnings.

The final loading-scene smoke test also passed its handoff, account-form touches, and character-creation navigation, and the layout/Back-routing checks passed again. An earlier graphical run failed to register the character-creation tap; a diagnostic rerun passed, but the desktop compositor did not honor the requested fixed window size. These desktop input checks are not a substitute for device testing.

Live device testing used a **HONOR ABR-NX1 running Android 16 with 4 KB pages and PowerVR BXM-8-256 graphics**. The original ARM64 APK crashed before the title screen. A private Godot log recorded an allocation failure while loading `MainScene.gdc`, and native heap use reached about 2.5 GB. Switching to the release engine or text-script exports did not resolve it. The ARMv7 build loaded the game in about 73 seconds, then used roughly 330 MB of native heap. Touch navigation reached character creation and opened the on-screen keyboard; fullscreen hid the status and navigation bars. All device installations used in-place updates without clearing app data.

Versions **0.1.2-mobile.4**, **0.1.2-mobile.5**, and **0.1.2-mobile.6** were subsequently built, signature-checked, and installed over USB. Testing reached character creation, world generation, a playable life, diary scrolling, and the World panel with system bars hidden. Version 4 exposed a keyboard-opening bug during name-field swipes; the gesture adapter now defers that focus transition until a confirmed tap. On version 6, a USB swipe directly over First Name scrolled without opening the keyboard, and a subsequent tap on Last Name opened the keyboard normally. Android Back dismissed it without changing the name.

Version **0.1.2-mobile.4** addresses the subsequently reported drag and gameplay-lag issues. Gesture regression tests inject screen-touch/drag events over interactive widgets and diary text; they also verify normal taps, canceled touches, and horizontal slider input. The same test with the gesture adapter disabled reproduces the failures. The real character-creation smoke test now swipes over name, dropdown, and slider controls instead of setting the scroll offset directly. HUD checks verify that changed stat values, death context, and maximum ranges invalidate the cache, and returned incarceration data remains isolated from its source.

The final graphical run passed form swipes, life entry, and HUD regression assertions, but failed its final World-tab tap after the window changed size. It is not a full smoke-test pass. Earlier graphical runs passed the World-tab check; desktop input automation remains sensitive to window resizing and concurrent interaction. The final headless run passed form gestures but timed out waiting for world generation. Neither limitation is being treated as successful end-to-end validation.

Desktop profiling first identified repeated shop-button theme updates, redundant stat styling, and large deep copies in the HUD's incarceration lookup. USB profiling then found further phone costs: approximately 54 ms per frame copying diagnostic history, 34 ms updating the bending HUD, and 21 ms resetting HUD geometry in one slow sample. The later changes address those measured paths.

On the phone, selection ran at approximately **60 FPS**. Version 4 gameplay samples were around **4–14 FPS**; version 5 samples after world setup were around **25–43 FPS**, and the user independently reported smoother interaction. A later 240-frame sample measured median script time of **4.57 ms** and process time of **15.11 ms**, with process p95 **63.87 ms**. These are separate test lives and interactions with profiler overhead, not a controlled benchmark or a guarantee of sustained frame rate. World generation and occasional gameplay work still cause stalls. Vertical swipes over dropdowns, sliders, buttons, and diary text were exercised over USB; swipes retained the slider value and did not activate the covered buttons.

The **Android** export preset is the tested ARMv7 configuration. **Android ARM64 Experimental** preserves the original architectures for future work and is still known to fail on this phone. Neither the 64-bit allocation problem nor support for 64-bit-only phones is fixed by the compatibility build.

Android development builds keep two rotating private Godot logs. On an authorized debugging connection, retrieve the current one without reading other apps' logs:

```sh
adb shell run-as org.eralife.community.mobile cat files/logs/godot.log
```

The life-entry preview also logs an existing missing `luxury_exchange_shiny_audio_stream_cache` metadata error. The entry assertions can pass despite this error; the smoke result is not a claim of error-free gameplay. That audio-cache path and shutdown resource leaks remain unresolved. Secondary panels still need a broader mobile layout audit; some retain desktop sizing or visual overlap.

Live saving initially failed with `target_engine_unavailable`: the character-creation startup pipeline had not initialized the serialization service or its checkpoint dependencies. Version 6 initializes those existing services during resident startup. Its World Save action reported success on the phone in approximately **662 ms**, wrote a nonempty `.bin` save and summary, and committed the local checkpoint. The files were backed up before restart testing, survived restart, and appeared in the Load picker. Subsequent inspection showed that this was not a valid full character save: the serializer filtered out ordinary script variables, leaving character names and stats absent. This finding supersedes the earlier success report. The log also emitted `snapshot_not_found` during checkpoint commit.

The phone's Load action exposed a second problem: `checkpoint_resolution_pending` remained queued with its scheduler asleep while another life was attached. A new regression test reproduced the failure, then passed after the scheduler fix. An isolated restore then exposed a missing engine-graph worker on the older decode path. Version 7 addresses both problems and the character-field serialization bug. Binary round-trip tests pass for names, age, health, money, family IDs, traits, and nested powers. A synthetic full restore recovered the expected name, age, health, and money. Its initial shutdown crash was traced to a pending `GDScriptFunctionState` waiting on `RenderingServer.frame_post_draw` in the headless diagnostic. That harness was manually advancing the scheduler while also leaving its render-frame coroutine suspended. Overriding only renderer scheduling in the headless harness produced two successful restore runs with exit code 0; the production renderer scheduler was unchanged. Existing resource-leak warnings still occur on exit. No cloud synchronization, account transfer, or complete playthrough was validated.

Version 7 phone testing created a new age-one character and verified the saved binary contained names, year, stats, and 19 lineage actors, including both parents. Cold Continue then exposed a third scheduler issue: pending UI projection could repeatedly return before the checkpoint hydration slice ran. The new progress regression reproduced zero payload slices before the fix and passed afterward. Version 8 gives the existing one-item hydration slice a turn before that return. USB debugging then captured a `GlobalMarketEngine._realm_local_modifier` call from the economy UI while `realm_engine` was still null. Version 9 uses the existing missing-realm fallback during partial restoration; its test also checks that real realm modifiers resume once the service exists. The backed-up phone save subsequently restored locally with correct name, age, year, health, and hunger and exit code 0. This isolated run still reports existing resource leaks at shutdown.

An additional full-interface desktop restore diagnostic crashed before these final corrections; it has not been counted as a passing graphical test. Phone validation is recorded separately. Version 9 was then installed over USB and launched normally without the profiler. Continue completed checkpoint hydration about 27 seconds after the resume shell became ready. A second Save succeeded in about 2.2 seconds. Comparing decoded files before and after restart found no differences across the 19 saved actors for IDs, names, ages, health, hunger, bank balance, family/partner IDs, traits, bending mastery, and alive status; player ID and year also matched. The original and new files were backed up and older saves were left untouched. Fullscreen and diary swipes still worked. Aging after reload advanced the character from age 1/year 80 to age 2/year 81; that life was saved again and left running without the debugger. The restored diary and World feed did not retain all pre-save history, so this is a character/lineage round-trip pass, not a claim of complete world restoration. All six focused regression scripts passed on the final source.

Run the layout and Back-routing regression checks with:

```sh
mkdir -p build/smoke-data/mobile-tests
XDG_DATA_HOME="$PWD/build/smoke-data/mobile-tests" \
  ./build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64 \
  --headless --path project --script "$PWD/tests/test_mobile.gd" \
  -- --mobile-preview
```

Use the same command with `tests/test_mobile_scroll.gd` for gesture regression checks. For a headless account/form input smoke run, use `tests/smoke_mobile_ui.gd` with `-- --mobile-preview --smoke-no-screenshots`. That mode skips screenshot capture and does not validate rendering or Android's keyboard. Keep `--smoke-prewarm` on a graphical run: the final headless attempt did not start world generation.

The same isolated headless invocation can run `tests/test_checkpoint_actor.gd`, `tests/test_checkpoint_schedule.gd`, `tests/test_checkpoint_progress.gd`, and `tests/test_checkpoint_market.gd` for character snapshot round trips, restore scheduling, progress under busy UI projection, and realm lookups during partial restore. They do not replace phone save/reload testing.

For manual desktop layout/input testing, launch the pinned editor binary with `--path project --rendering-method gl_compatibility --resolution 960x540 -- --mobile-preview`. This activates the mobile adaptations and performance profile, but it is not an Android emulator.

The graphical smoke test records screenshots in an existing output directory and uses isolated save data. Screenshot capture requires a desktop display. Omit `--smoke-prewarm` for the shorter account/menu/character-form check. With that option, it additionally taps the world-generation button and attempts to enter the resulting life. Add `--smoke-loader` to exercise the Android loading scene and its handoff too:

```sh
mkdir -p build/mobile-preview build/smoke-data/mobile-ui
ERA_PREVIEW_DIR="$PWD/build/mobile-preview" \
XDG_DATA_HOME="$PWD/build/smoke-data/mobile-ui" \
  timeout 180s ./build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64 \
  --path project --rendering-method gl_compatibility --resolution 960x540 \
  --script "$PWD/tests/smoke_mobile_ui.gd" -- --mobile-preview --smoke-prewarm
```

Require `MOBILE UI SMOKE: PASS` in the output; an early game exit alone is not a passing test. Neither smoke test covers aging, save/reload, online authentication, or a complete playthrough.

Before treating the port as playable on a particular phone, test installation, launch time and memory use, touch scrolling, the on-screen keyboard, display cutouts/system bars, account/guest paths, world creation, aging, pending-situation choices, saving/reloading, and background/resume. Test both landscape rotations and check Back while a popup or keyboard is open. Existing resource-leak warnings on shutdown and the reconstruction's known gameplay issues are not resolved by this port.
