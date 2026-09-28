# Desktop upstream integration, 2026-09-28

Status: verified on Linux desktop on `codex/sync-upstream-2026-09-28`, with the
concurrent cold-load timing limitation retained below.

**Promoted 2026-09-28:** integration commit `cffca1d` is now on desktop `main`.
The old integration branch and checkout are retired after preserving their
history and local evidence. Use [branch workflow](BRANCHES.md) for current paths.
The remaining text records the original integration run.

This branch merges upstream `57ee128` into desktop `b399a33`. Its isolated
worktree is `/home/nextg/Work/miikaTheCoder/Era-Life-Community-upstream-sync`.
The existing desktop and Portrait branches remain separate. This integration
does not port the changes to Portrait or publish a release.

## Included upstream changes

The eight commits after the shared base `0e729bd` are:

| Commit | Change |
| --- | --- |
| `ee3db3d` | Pet checkpoint surfaces and restoration |
| `cc570ff` | Activity and school age refresh |
| `579c79f` | Player, NPC and pet aging |
| `1478d8e` | Crime age restrictions and related fixes |
| `f52fc16` | Relationship and world follow-up fixes |
| `de6640a` | Crime actions, inventory and HUD follow-up fixes |
| `415f93a` | Checkpoint threading changes |
| `57ee128` | Cooperative relationship row rendering |

## Integration decisions

- Git recognized the reorganized script paths. New `MainSceneHelpers` references
  were adapted to the existing `ValueSceneSupport` owner.
- The main-scene conflict retains upstream's crime-result popup and the desktop
  helper path. Existing focus and live diary/balance repairs remain present.
- Checkpoint engine construction retains the desktop's tested, bounded main-thread
  implementation. Upstream independently removed its background worker; introducing
  its second scheduling representation would duplicate this responsibility.
- Asset restoration uses the existing deep-copying numeric owner-key normalizer
  for both the resident and manager runtimes. Upstream's redundant helper was
  removed; its pet and asset restoration changes remain included.
- The relationship conflict retains the new Dead Pets group and all seven dead
  relationship groups in the cooperative projection.
- The desktop scheduler already runs `player_phase_contract`. The new direct
  prison tick in the UI was removed so a year advances a sentence once. The
  graphical three-year run recorded one scheduled prison tick per year.
- Upstream row streaming called `get_tree()` on detached section containers.
  The graphical test reproduced this every year, and the added focused test
  reproduced it headlessly. Streaming now uses the application's frame clock.
  The regression also checks row order and cancellation of superseded work.
- The desktop graphical runner now rejects engine errors, consistent with the
  story runners. The known resource-cleanup warning remains excluded.

## Verification

Use Godot 4.4.1 stable. Test profiles are isolated from normal player saves.

- Initial full suite: 23/23 passed, `build/tests/headless-bfuwl1e_`.
- Expanded pet and aging-anchor checkpoint checks passed in
  `build/tests/headless-mukrsxx3`. Its UI test intentionally failed before the
  detached-row fix; this was not an entirely passing run.
- Initial graphical creation completed three consecutive years, ages 8 through
  11, and saved year 2003. It exposed the detached-row error before the repair.
  Profile: `/tmp/eralife-upstream-20260928-desktop`.
- Final full suite: 23/23 passed, `build/tests/headless-mdq3xf7y`, including the
  expanded checkpoint, stale-age, crime restriction and detached-row checks.
- The first cold Continue run reached the saved character, but its background
  hydration exceeded the 90-second test limit while the full regression suite
  was running concurrently. The failure remains in `restore.log` in the same
  profile. A follow-up adds stage and cursor diagnostics to distinguish slow
  progress from stalled hydration. The isolated `restore-trace` repeat passed
  exact character, relationships, diary and balance checks with no production
  hydration change or increased timeout. Retain the concurrent-run limitation.
- `restore-fixed` then passed cold Continue, three more consecutive years and a
  new save: year 2006, age 14, six diary years and $10,000. No engine or script
  errors occurred apart from the existing resource-cleanup warning.
- Shared Lives graphical cycle passed in `/tmp/eralife-upstream-20260928-shared`:
  a business choice left $8,800 personal funds and $1,200 company reserves; the
  first year saved $1,470 reserves. Cold Continue restored those exact values,
  advanced and saved the next year, then a second cold Continue restored $1,740
  reserves without awarding income again. The three logs are `household.log`,
  `restore.log`, and `restore-again.log`.
- Inspected graphical screenshots for the current diary, age and balance after
  repeated years and cold Continue. The host tiled the desktop window; these
  captures establish the tested host layout, not every desktop resolution.
- Structure check, regenerated code-map check, shell syntax, whitespace and
  conflict-marker checks passed. No package or public release was produced.

Next: review the integration branch for promotion to the desktop development
branch. Port to Portrait separately with its startup, touch and device checks.
The existing branches' roadmap priorities are unchanged by this integration.

Headless coverage does not certify full-lifetime play, native Windows/macOS,
or Android. The existing Portrait navigation and on-device issues remain open.
Classic and Redesigned UI selection was discussed as a possible follow-up; no
interface selector is implemented by this merge.
