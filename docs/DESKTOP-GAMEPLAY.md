# Desktop gameplay validation

This checkout contains working source reconstructed from the original game package.
Changes here affect newly exported PC builds; they do not automatically update the
original repository or older executables. Android remains a separate workstream.

## Play

Export with `./scripts/build.sh all`, then extract the archive for your operating
system in `build/`. On Linux and Windows, keep the executable and matching
`EraLife.pck` together. macOS keeps its data inside the app bundle; that export is
experimental and needs native testing. See [release preparation](RELEASING.md).

- **Begin Adventure:** choose a story, make choices, then choose a newborn family
  life or an adult continuation. The authored pressure/history travels into the
  simulation and its checkpoint.
- **Create Household:** select a world, prewarm its seed, add household members,
  and select the member you want to play. You can start as a child; authored
  parent/child links remain reciprocal. The selection screen also allows going
  back to edit the household.
- **Open God mode:** the existing manual character-creation route remains available.
- **Age Up:** advances one year. **World → Save Game** saves a checkpoint.
  On a fresh launch, press **C** at the title screen to continue the saved life.

New Narrative and Household entry buttons are enabled on desktop only. Their
Android menu availability has not been changed.

## Repairs

Both new entries use the existing world-preparation and readiness system. Narrative
initialization no longer silently discards an early click or loses its world seed;
restarting a story resets its completion threshold. Household now opens on the first
click and chooses the controlled member before generating the final playable world.
Newborn Narrative creation initializes its lineage authority inside that world;
ordinary generated parents also receive reciprocal links to the player.
Preparation keeps the current screen visible, prevents duplicate starts, and restores
the controls on failure. An unfinished household draft is removed only after entry succeeds.

Checkpoint repairs retain created household members outside the family graph,
narrative choices, the saved actors' diary streams, and world-feed history. Loading
converts JSON-decoded relationship numbers and affection keys back to integer IDs
so family lookups and relationship scores continue to work. Diary authority state is restored before subsequent years
are appended. Saved presentation snapshots use the current age/year/history rather
than the original character-creation screen.

## Automated checks

Checks run with Godot 4.4.1 on Linux, using isolated saves and an NVIDIA RTX 3060
with the OpenGL compatibility renderer. The PC exports include both Linux x86_64
and Windows x86_64. Windows runtime behavior is not verified here.

Verified on 2026-08-31:

| Desktop flow | Result |
| --- | --- |
| Household: parent + child + roommate; start as child | Entered at age 8, aged to 9, saved, restarted, restored all three members, aged to 10, retained both diary years |
| Narrative newborn route | Entered at age 0, aged to 1, saved, restarted, restored parents and story history, aged to 2, retained all three diary blocks |
| Narrative adult continuation | Entered at age 21, aged to 22, saved, restarted, restored family and story history, aged to 23, retained both diary years |
| Existing God Mode, exported Linux executable | Created a life, aged to 1, saved, restarted, restored family and relationship scores, aged to 2, retained all three diary blocks |
| Focused regression scripts | Actor snapshots, checkpoint scheduling/progress/market, narrative catalog, and mode checkpoint tests passed |
| Desktop packaging | Linux and Windows exports completed; both archive integrity checks passed; Linux executable passed headless startup and graphical gameplay/reload checks |

Logs and selected screenshots from this run are retained locally in
`build/desktop-validation/`, alongside archive checksums. The tests still report
the existing shutdown resource warnings described below.

Release packaging was subsequently expanded on the same date to include a universal
macOS archive, engine notices, launch instructions, source/build metadata, and
`build/SHA256SUMS.txt`. All three archives passed integrity/content checks. The Mac
bundle contains Intel and Apple Silicon executables with ad-hoc signature structures;
native execution, signature acceptance, and Gatekeeper behavior remain untested.
The older checksums in `build/desktop-validation/` refer to the earlier gameplay
validation packages; use `build/SHA256SUMS.txt` for the current three archives.

The 0.1.3 desktop alpha disables the inherited upstream runtime-update polling.
`tests/test_release_channel.gd` runs the real autoload beyond its startup grace
period and verifies that processing stays disabled with no HTTP request nodes.
The original verifier/key remain intact, and Android retains its previous policy.

`tests/test_narrative.gd` exercises one choice sequence through both endings of all
11 catalog stories (22 routes), plus restarting a story. This is not exhaustive
coverage of every branch.

`tests/test_mode_checkpoint.gd` covers selected-child relationship wiring,
roommates, binary checkpoint round-trips, integer relationship lookups, narrative
state, legacy and current diary storage, diary hydration, world history, and
presentation snapshot freshness.

`tests/smoke_desktop_modes.gd` drives the graphical game using mouse input for mode
entries, choices, Age Up, and Save, and the title-screen C shortcut for Continue.
Household form values are assigned through their controls and normal change signals.
The Household fixture includes a parent, an 8-year-old child with custom smarts,
and an unrelated roommate, with the child selected for play. Restore checks wait
for background hydration, validate identity/family/history, then age and save again.

Run graphical checks from a Linux desktop using Godot 4.4.1:

```sh
./scripts/test-desktop-modes.sh household /tmp/eralife-household-test
./scripts/test-desktop-modes.sh restore /tmp/eralife-household-test
./scripts/test-desktop-modes.sh narrative-family /tmp/eralife-family-test
./scripts/test-desktop-modes.sh restore /tmp/eralife-family-test
./scripts/test-desktop-modes.sh narrative-continue /tmp/eralife-adult-test
./scripts/test-desktop-modes.sh restore /tmp/eralife-adult-test
./scripts/test-desktop-modes.sh god /tmp/eralife-god-test
```

For extended aging and repeated cold starts, see the [PC playtest checklist](PC-PLAYTEST.md)
and `bash scripts/test-desktop-long.sh household /tmp/eralife-household-long`.
The extended harness checks school/job scalar fields and relationship scores on
reload, waits for annual simulation work, and records per-year diagnostics. The
commands above still default to one year; `ERA_YEARS=5` selects a five-year batch
and `ERA_YEARS=0` permits a restore-only verification. Use `ERA_RUN_LABEL` to retain
separate logs and screenshots for repeated batches.

Follow-up repair after alpha 1: the immediate Continue actor now normalizes JSON
relationship IDs, just like the normal NPC loader. This actor is skipped by later
spatial hydration, so omitting normalization could hide saved relationship scores.
The regression exercises the actual immediate resume path as well as the normal
deserializer. This source change does not modify the already published binaries.

The extended run also found that packs without an explicit yearly schedule were
injecting placeholder phases that AgeUpRuntimeEngine does not implement. This
could advance the year while skipping player health, school, careers and event
choices. Pack normalization now preserves an absent schedule; resident worlds can
use the implemented age-up fallback. Explicit phase schedules remain unchanged.
`test_year_scheduler.gd` reproduces the missing gameplay phases before the repair
and checks both the fallback and explicit schedules afterward. The graphical
long-run harness rejects years that do not execute the player phase.

Quiet years also now produce an age/year diary entry. Previously the completed
player phase returned empty text when there were no diary-worthy events, so the
diary authority received nothing and Continue could show an older age. The new
`test_year_diary.gd` checks two quiet years and duplicate finalization; the longer
graphical test checks that every completed year has a diary block.

The same test covers a final-frame stall found by the longer graphical runs.
Finishing the final phase could yield for the frame budget before finalization;
the next frame skipped the exhausted phase loop and never finalized the year.
Finalization now resumes outside that loop, including when its own snapshot work
needs another frame. The regression reproduces the old indefinite running state.

The post-alpha-1 extended pass is **not a 25-year certification**. All nine focused
regression scripts pass, and Linux/Windows exports succeed, but graphical runs
still expose yearly relationship/event-processing stalls and unresolved behavior during
background checkpoint hydration. A Narrative newborn's saved relationship score
was correct at the first playable frame and differed after hydration. An adult
Narrative run ended before completing its checks and is not counted as a pass.
Full local logs, screenshots, candidate packages and the measured results are in
`build/desktop-long-validation/`. Manual activity and usability checks remain in
[PC-PLAYTEST.md](PC-PLAYTEST.md); native Windows and macOS gameplay remain untested.

Use a fresh directory for each creation run. Test profiles isolate saves/configuration
and retain logs/screenshots. The test requests a 1440×900 window; tiling window
managers may need that test window floated or resized. No desktop configuration
changes are required.

## Limits

This remains an early playable build. These tests do not establish a complete
birth-to-death playthrough, game balance, every activity/career, every narrative
branch, or simultaneous control of a whole family. Some extended household roles
still use the existing social-link behavior rather than a complete genealogy.

Interactive checkpoints retain a bounded actor group (up to 256 actors), not the
entire simulated universe. World history retains the game's existing feed limit.
The repair cannot recover history already omitted by older saves.

Existing shutdown resource-leak warnings remain. Save logging can also report
`snapshot_not_found` while successfully writing and committing the checkpoint;
cold-reload tests verify the resulting file rather than relying on that message.
Windows exports require separate runtime testing on Windows.
