# Organization pass — 2026-09-05

## Scope

- Reorganized 335 existing scripts and their resource UIDs into core, gameplay,
  presentation, mod, integration and platform folders.
- Replaced the two catch-all scene support classes with 28 subject-specific
  modules containing the same 881 static functions.
- Updated callers, autoload resource paths and the mobile scrolling preload.
- Corrected the duplicated extension in `PopulationLifecycleManager.gd.gd`.
- Added the architecture guide, generated code map, live symbol search,
  structure checks, isolated regression runner and root `AGENTS.md` guidance.
- Preserved gameplay content, assets, scene resources, themes and export presets.

This is a repository-wide organization pass, not a claim that every inherited
implementation is clean. The main scene and several engines remain large;
[architecture and ownership](ARCHITECTURE.md) records that debt and the next
extraction boundaries.

## Preservation checks

Compared the final sources against the original commit, `a174e11`:

- All 881 moved functions retain their signatures, defaults and bodies after
  normalizing static owner qualifiers and trailing code whitespace. String
  literals and comments were included in the comparison.
- The main scene and its mobile regression differ only in those static call
  owners and trailing code whitespace.
- All 335 moved scripts retain their implementation and `.gd.uid`; the single
  implementation-file difference is the mobile scrolling preload's new path.
- All 39 other tracked content/asset/configuration resources checked, including
  the binary main scene and export presets, are byte-for-byte unchanged.

The local report is retained in `build/organization-preservation.log`. This is
strong evidence for a structural change, but does not replace runtime tests.

## Automated checks

Godot **4.4.1 stable**, Linux, isolated save/config/cache profiles:

| Check | Result |
| --- | --- |
| Original-code focused regression baseline | 17/17 pass |
| Fresh import after moving scripts and splitting support classes | Pass |
| Final focused regression suite | 17/17 pass |
| Global class/UID uniqueness and direct script/scene resource links | Pass: 372 scripts, 363 global classes, 17 direct links |
| Generated code-map freshness | Pass |
| Navigation scanner: comments/multiline strings and line positions | Pass |
| Python tooling compilation | Pass |
| Tracked diff whitespace check | Pass |

The focused suite covers checkpoint actor/assets/market/progress/scheduling,
mode checkpoints, crime world and target refresh, deferred events, mobile input
and scrolling, narrative choices, release channel policy, residency projection,
UI presentation, year diary and year scheduling.

Baseline suite logs are under `build/organization-baseline/`; the final suite
summary is `build/organization-tests-final.log`. Per-test output paths are printed
in that summary. The mobile baseline uses the required `--mobile-preview` flag.

The final gameplay edits following the suite were limited to removal of trailing
whitespace outside string literals. The preservation comparison and graphical
runs use those final sources.

## Graphical checks

All four creation routes passed one year of aging and checkpoint saving using
the existing graphical desktop harness:

| Route | Result | Evidence directory |
| --- | --- | --- |
| Household | Pass | `build/organization-desktop-household/` |
| Newborn Narrative | Pass | `build/organization-desktop-narrative-family/` |
| Adult Narrative | Pass | `build/organization-desktop-narrative-continue/` |
| God Mode | Pass | `build/organization-desktop-god/` |

Screenshots were captured, and the playable household screen was visually
inspected against the original-code capture.

Eight corresponding household screenshots from the original and reorganized
code are byte-for-byte identical: menu, world setup, the three member editors,
household setup, member selection, and the initial playable life screen. The
other captures include animation or simulated state and are not claimed to be
identical.

The cold-restore check reached the playable first frame but timed out waiting for
checkpoint hydration. The same creation/save/restore sequence was then run against
an untouched archive of original commit `a174e11`, with a fresh profile and a
fresh Godot import. Creation, aging and saving passed there too, and restoration
failed at the same `Checkpoint hydration did not finish` assertion. This is a
reproduced pre-existing limitation, not a new failure attributed to the refactor.

Original-code comparison evidence is under `build/organization-original-import/`
and `build/organization-original-household/`. The code snapshot used for the
comparison is retained in `build/organization-original/`.

## Limits

The existing shutdown resource-leak warnings remain. No native Windows/macOS
playtest, Android device test, long-lifetime certification, external mod API
compatibility audit, or release rebuild is claimed by these checks.

The structural checker validates literal direct script/scene loads and declared
resources. Optional dynamic path candidates and the binary scene require Godot
checks. The older optional minigame-pack and historical contract-view fallback
paths remain documented in the architecture guide.
