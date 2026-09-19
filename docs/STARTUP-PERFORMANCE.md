# Mobile startup performance

Work is isolated on `codex/mobile-startup-performance`, based on portrait commit
`e441171`. The working portrait branch remains available for comparison.

## What changed

The mobile entry scene is now an independent menu. It draws the existing dark/cyan
EraLife theme before requesting the main scene in the background. New life,
Saved life & account, and Watch intro retain the original gameplay, title/account,
and cinematic destinations. A choice made during loading is queued; Back cancels
that choice. No save is read, replaced, or created by the early menu. Continue
availability remains owned by the existing title-card contract.

`GameState` no longer statically references every domain constructor just to load
its script. Constructor calls load their implementation at the same initialization
boundary as before. The 232 ordered residency descriptors carry resource paths and
explicit registered class names; the runner loads a script only when executing its
step, and still accepts existing GDScript callers. Names, ordering, callbacks,
engine properties, initialization arguments, and save contracts are preserved.
The immediate residency authorities remain static dependencies so they load on the
background resource thread instead of introducing a synchronous handoff stall.

Mobile startup retains core tab preparation but defers optional asset/shop/crown/
afterlife panel and death-audio prewarming. Their existing open handlers own their
construction. Browser reality intake is retained. This is not a claim that every
engine or UI dependency is now lazy; MainScene still has many static dependencies.

`StartupTiming` records process-relative milliseconds and static-memory readings
for the early menu, first rendered menu frame, resource request/completion,
instantiation, state construction, main readiness, title/mode menu, and first
visible portrait life shell. Markers appear as `ERALIFE_STARTUP|{...}` in Android
logs, or on desktop with `--startup-profile`. These timestamps do not include the
Android launcher-to-engine interval. Resource-loader progress is used directly;
it is not a fabricated elapsed-time percentage.

## Reproduce

```sh
# Pinned Godot 4.4.1; each run gets an isolated profile and screenshots.
python3 scripts/profile-startup.py
python3 scripts/profile-startup.py --entry title
python3 scripts/profile-startup.py --entry intro

# Full game routes now start through the early menu in portrait mode.
ERA_PORTRAIT=1 scripts/test-desktop-modes.sh god
ERA_PORTRAIT=1 scripts/test-desktop-modes.sh household

python3 scripts/test-headless.py
scripts/build.sh android
```

The profiler writes `output.log`, `timings.json`, and screenshots beneath
`build/startup-profiles/`. A tiling desktop may require its temporary window to be
floated at 420×900; no desktop settings are changed by the profiler. The headless
option is for route checks and cannot establish rendered-frame performance.

## Initial measurements

These are local desktop editor measurements, not phone cold-start results. File
caches, build type and hardware differ from the exported ARMv7 APK.

- Baseline: loading GameState and its dependencies took 7,137 ms; loading MainScene
  after that took 4,755 ms; the binary scene itself took 2 ms.
- The first lazy-loading experiment reduced those script phases to 397 + 5,699 ms,
  but deferred about 800 ms of essential state dependencies onto the handoff.
- Keeping essential dependencies in background loading removed that handoff stall.
  The graphical run `new_life-57jb8dtw` drew the entry menu at 1,262 ms, loaded the
  main resource in 7,085 ms, constructed state in under 1 ms, completed MainScene
  readiness in about 10 ms, and exposed the mode menu at 8,487 ms process time.
- The independent title route `title-dqtswefn` passed, including a choice made
  after loading completed. Its early menu was drawn at 1,233 ms.

Startup resource loading is therefore roughly 40% shorter in these desktop
samples, with an interactive entry menu shown independently. Entering a life still
has initialization work. Phone measurements are recorded below; a 2–3 second fully loaded game target is not achieved.
ARM64 remains experimental because of the previously documented loading/memory
failure; this pass does not silently switch architectures.

## Validation notes

All 21 headless tests passed after the final implementation (`headless-kea3az18`). The dependency test
checks that describing the engine plan does not load bending, preserves the full
catalog including a class/file-name alias, constructs a real engine when its step
runs, and reuses that engine on a repeated request. Menu tests cover dependency
isolation, three viewport sizes, queued choices, Back cancellation and load errors.

The startup harness initially raced deferred scene entry; that test-only wait was
fixed. Quitting immediately from its early mode-menu test crashed the engine during
shutdown; the harness now releases its scene while the tree remains alive, then
exits cleanly. The stripped core did not establish a specific engine cause. This is
not presented as a general shutdown fix. Existing resource-leak warnings remain.

An initial gameplay smoke exposed an unfocusable tooltip consuming Android Back
before the relationship panel. Back now hides informational windows and continues
to the panel's existing close route; focused dialogs still consume one Back action.
The final verification results are recorded below.


## Phone comparison: 0.1.0-portrait.3

Measured on the same HONOR ABR-NX1 running Android 16, using the signed ARMv7
build and cold process launches over wireless ADB. App data was preserved. These
are two startup samples, not a broad benchmark or a measurement of entering a life.

| Stage | Baseline portrait.2 | Updated run 1 | Updated run 2 |
| --- | ---: | ---: | ---: |
| First rendered loading screen / interactive entry menu | 3.852 s | 3.407 s | 3.033 s |
| Main resource loading | 46.025 s | 24.594 s | 24.533 s |
| Main resource ready, process-relative | 49.877 s | 28.001 s | 27.566 s |
| Creation menu ready | Not measured | 35.568 s (late manual selection) | 28.466 s (queued selection) |

The resource phase was about **47% shorter**. The second run queued New life
while loading; the first run selected it after resources were ready. Both reached
the existing creation menu. Screenshots confirmed the dark/cyan menu and queued
selection layout on the actual 1080×2412 phone. The early menu is interactive while
resources load; this does not make the whole game ready in three seconds.

Evidence lives in `build/phone-startup-performance/`: `baseline-godot.log`,
`optimized-godot.log`, `optimized-queued-godot.log`, launcher timings, and screenshots.
Android activity startup timing is a separate measurement from game readiness.
The existing missing `NotoColorEmojiLegacy.ttf` diagnostic appears in both baseline
and updated logs. No new script error appeared in these startup checks.

The installed APK is `build/android/EraLife-portrait-android-debug.apk`, version
`0.1.0-portrait.3` (code 3), SHA-256:
`4443920ea6e2e46f962cea69e44a5ff654856a07ce7b251091b966409d40c9da`.
Signing and manifest verification passed. The original portrait package and save
data were retained; the separate older mobile package was untouched.

## Final graphical checks and limitations

All three independent startup routes passed at an actual 420×900 viewport:
`new_life-57jb8dtw`, `title-dqtswefn`, and `intro-l_ta15uf` beneath
`build/startup-profiles/`. The intro route showed the cinematic and supported skip.

Full portrait God Mode and Household graphical smoke runs passed creation, aging,
core navigation, Back, and saving. One intermediate God Mode run timed out waiting
for readiness without a script error; a subsequent run passed. A separate baseline
God Mode run also passed, so the timeout is **unresolved**, not established as an
existing baseline issue or claimed fixed. Phone checks in this pass cover startup
and the creation menu; they do not establish full gameplay performance on-device.

Structure checks, generated code-map checks, and whitespace checks passed. Further
startup gains require reducing the remaining MainScene dependency graph or safely
resolving the separate ARM64 export problem; the compatibility architecture remains
ARMv7 for this installed build.
