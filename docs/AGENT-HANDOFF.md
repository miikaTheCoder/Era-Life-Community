# EraLife desktop and Portrait: agent handoff

Last checked: **2026-09-26**. Read [AGENTS.md](../AGENTS.md) for repository rules
and [Architecture](ARCHITECTURE.md) for ownership. This guide is kept on both
active branches so a new task can continue without the original conversation.
Branch names, worktree paths, build files, and test results below are a dated
snapshot: inspect Git and the current task before acting.

## Choose the correct version first

Both versions belong to `miikaTheCoder/Era-Life-Community`. They are separate Git
branches/worktrees, not two modes that can be selected by copying one config file.

| Target | Shared Lives branch | Latest gameplay commit in this snapshot | Local checkout on this host |
| --- | --- | --- | --- |
| Desktop | `codex/shared-lives-desktop` | `32ad0fb` | `/home/nextg/opencode-sandbox/Era-Life-Community` |
| EraLife Portrait | `codex/shared-lives-portrait` | `ebaf71c` (port begins at `c35a6e5`) | `/home/nextg/.codex/worktrees/mobile-portrait/Era-Life-Community` |

These branches are pushed to GitHub; this does **not** mean they are merged into
`main` or published as a release. Older starting points include `era-life-new-ui`
(desktop, `a3799d2`) and `codex/mobile-startup-performance` (Portrait, `7673961`).
`mobile` and `codex/mobile-portrait` are older mobile work. Do not choose `main`
or those older branches merely because a historical README paragraph names them.

Start in the checkout assigned to your task:

```sh
pwd
git status --short --branch
git worktree list
git log -5 --oneline
git remote -v
```

Confirm paths still exist. A worktree can be removed or occupied by another task.
Use explicit working directories, preserve uncommitted changes, and use a separate
worktree/`codex/` branch when concurrent work needs isolation. Do not switch or
reset another task's checkout to match this snapshot. On another machine, locate
or create a checkout from the corresponding branch; the paths above are host-local.
`origin` is the user's fork; `upstream` is the original project.

## What is shared, and what must stay platform-specific

The preferred sequence is **desktop gameplay first, then a tested Portrait port**.
Keep gameplay and content in the existing owners and adapt their UI contracts.

| Work | Owner / entry point |
| --- | --- |
| Authored stories and recurring cast | `project/data/life_stories.json`, `project/data/shared_lives.json`, `project/systems/narrative/LifeStoryEngine.gd` |
| Story admission and resolution | `ScenarioRuntimeContractEngine.gd`, `PendingSituationsEngine.gd` under `project/systems/narrative/` |
| Company stakes, management, succession, yearly surplus | `project/systems/economy/FamilyBusinessEngine.gd` |
| Personal and company money, account restrictions | `project/systems/economy/BankEngine.gd` |
| Assets projections and display | `project/systems/property/AssetsContractEngine.gd`, `project/ui/panels/property/AssetsPanel.gd` |
| Checkpoints and hydration | `project/core/persistence/GameStateSerializationRuntime.gd`, `project/core/state/GameStateHydrationRuntime.gd` |
| Desktop presentation | `project/ui/EraShell.gd`, `project/ui/EraInterface.gd`, `project/ui/EraTheme.gd` |
| Portrait presentation | `project/ui/EraMobileShell.gd`, `project/ui/EraMobilePanels.gd`, `project/platform/mobile/` |
| Portrait early menu and startup | `project/scenes/MobileBoot.gd`, `project/scenes/mobile_boot.tscn`; see the Portrait startup guide below |

Use [CODE-MAP.md](CODE-MAP.md) or `python3 scripts/code_map.py` for exact paths and
symbols. Read bounded portions of `MainScene.gd` and `GameState.gd`.

Shared Lives adds **two stories, 16 chapters, and 46 responses** to the original
six Life Stories. The founder saga is *The Business We Built*; the inherited sequel
is *The Keys They Left*. Eligibility, timing, authored choices, and the compact
business model are documented in [SHARED-LIVES.md](SHARED-LIVES.md).

Preserve these contracts when extending the feature:

- `scenario_state.life_stories` and `scenario_state.family_businesses` are version 1.
  Optional ensemble fields preserve older stories. Cast identities are saved;
  an unloaded participant is not a replacement opportunity.
- BankEngine owns the reserves. A business stores its account reference, not a
  second spendable balance. Failed payments must not commit story consequences;
  realm assignment and stale legacy mirrors must not recreate money.
- Succession transfers the existing stake, company, cast, and history. Same-year
  owner switches or restores must not award operating income twice.
- Compact checkpoints retain relevant actors and scoped bank state. Test actual
  binary hydration, not just dictionary serialization.
- Assets has immediate **and incremental** producers. Its progressive UI completion
  path also needs updated text/counts. Checking `active_contract` alone once missed
  a visible placeholder bug; check the rendered labels too.
- Portrait uses the existing actions and close routes. Add new modal roots to its
  adapter when needed; desktop columns can otherwise overflow phone widths.
- Preserve Portrait's lazy dependency loading and early menu. Avoid adding eager
  domain preloads through mobile startup; run `test_startup_dependencies`.

## Porting between the branches

1. Inspect both branches' status and existing changes. Locate the owning scripts
   and agree with the current task's platform scope.
2. Implement and verify shared gameplay on desktop. Commit coherent changes so
   the shared port can be reviewed independently of mobile presentation.
3. Apply the relevant commit(s) to the Portrait branch/worktree. Inspect conflicts
   and merged files; do not replace its whole tree with desktop files.
4. Preserve Portrait's `project.godot`, export presets, APK identity, build scripts,
   startup loading, touch controls, and mobile test-harness additions. Shared files
   can differ too, especially `GameState.gd` and `MainScene.gd`.
5. Regenerate `docs/CODE-MAP.md` for the target checkout if it conflicts. Never copy
   the other branch's generated map or hand-edit its tables.
6. Run target-specific checks, inspect actual phone-sized screenshots, then build
   from the intended source. A cherry-pick or successful export is not UI validation.

The Shared Lives port is already present on both branches. Do not reapply its
commits merely to start using it. Preserve action IDs, signals, saved keys, resource
paths, and `.gd.uid` files; see the root instructions for structural changes.

## Commands and artifacts

Run commands from the intended checkout. Use **Godot 4.4.1 stable** and matching
export templates, not an arbitrary system Godot. The bundled editor lives at
`build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64`; `GODOT_BIN` can select
an equivalent editor. If tools are absent, inspect `scripts/setup-godot.sh` first.

For gameplay changes on either branch:

```sh
python3 scripts/check-structure.py
python3 scripts/test-headless.py --list
python3 scripts/test-headless.py test_life_stories test_shared_lives
# Full suite for shared state, persistence, scene-support changes or resource moves:
python3 scripts/test-headless.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
git diff --check
```

Desktop graphical checks and Linux export:

```sh
bash scripts/test-shared-lives.sh
bash scripts/test-desktop-modes.sh household
bash scripts/build.sh linux
```

Portrait-only checks and ARM64 performance export:

```sh
python3 scripts/test-headless.py test_mobile_panels test_mobile_portrait test_startup_dependencies
ERA_PORTRAIT=1 bash scripts/test-shared-lives.sh
ERA_PORTRAIT=1 bash scripts/test-desktop-modes.sh household
python3 scripts/profile-startup.py
bash scripts/build.sh android-performance
```

The general Portrait Household smoke currently has a recorded Menu/Back failure;
keep it visible in reports. The focused content smoke does not certify that route.

Graphical scripts need a display. For Portrait, verify the **actual** viewport is
420×900; a tiling window manager can override the requested dimensions. Adjust only
the temporary test window as needed. `--mobile-preview` is a desktop preview, not
Android emulation or evidence of on-device correctness. Also check small layouts
such as 360×640 through the mobile regressions.

The runners isolate test saves with XDG profiles. Headless logs stay in
`build/tests/`; graphical runners print their `/tmp/eralife-*` profile containing
logs/screenshots. `/tmp` evidence may disappear. Startup profiles are retained in
`build/startup-profiles/`. Do not test against the user's normal save directory.
On this host, restricted Godot runs have failed on local socket access; distinguish
sandbox startup failures from game failures and use the permitted execution path.

| Artifact | Relative to its target checkout |
| --- | --- |
| Desktop Linux archive | `build/EraLife-linux-x86_64.tar.gz` |
| Desktop executable + matching data pack | `build/linux/EraLife.x86_64`, `build/linux/EraLife.pck` |
| Portrait ARM64 performance preview | `build/android/EraLife-portrait-android-performance.apk` |
| Portrait ARMv7 fallback (`bash scripts/build.sh android`) | `build/android/EraLife-portrait-android-debug.apk` |
| Export and signature logs | `build/logs/` |

Build outputs are ignored local artifacts, not files available from a fresh clone.
Check the actual build revision, logs, and checksum before handing one over. The
build scripts do not publish releases. Portrait's package is
`org.eralife.community.portrait`; the older mobile app has a different package.
Preserve the existing local Android test keystore and app data when updating.
Do not commit keys, signing secrets, or phone pairing codes. SSH Git commit signing
worked without a password prompt in this snapshot; use the current Git config.

## Evidence and unfinished work

This is historical evidence, not a promise that a later commit passes:

| Target | Latest recorded Shared Lives checks |
| --- | --- |
| Desktop | 19/19 headless regressions (`headless-5va5_mlj`); graphical funding → visible Assets → age → binary save passed; Linux export and packed story catalog checked |
| Portrait | 23/23 headless regressions (`headless-r27wrtkc`); final focused story/startup checks (`headless-6zcooyu0`) and mobile panel check (`headless-w7d3hklp`) passed; focused content flow passed at 420×900; APK signatures and packaged catalogs checked |

For the isolated graphical fixture, personal funds moved $10,000 → $8,800,
company reserves were $1,200, and the first year's saved reserves were $1,470.
The Portrait run `headless-6zcooyu0` also contained an intermediate mobile fixture
cleanup failure; only its story/startup checks passed. The corrected panel check
is `headless-w7d3hklp`. Do not report every test in that intermediate run as passing.

Open issues to retain in future handoffs:

- Portrait Character → Android Back → Menu can produce an exit confirmation that
  blocks Explore. The general graphical run failed; the focused Shared Lives
  smoke skips general drawer checks while retaining its content/layout checks.
- The earlier on-device God Mode → Begin Life crash and guest cold-restore issues
  were not fixed by Shared Lives. The new Shared Lives APK was not retested on the
  Honor phone. Prior phone startup measurements apply to their recorded builds.
- Broader cold-restore hydration, `snapshot_not_found`, and shutdown resource
  warnings remain documented. A successful save is not a successful cold restore.
- Native Windows/macOS checks and complete birth-to-death playthroughs are not
  established by the Linux/Portrait checks above.

Start follow-up investigations with [Shared Lives](SHARED-LIVES.md),
[desktop gameplay](DESKTOP-GAMEPLAY.md), and
[organization validation](ORGANIZATION-VALIDATION.md). Portrait-specific history
lives on the Portrait branch:
[Portrait UI](https://github.com/miikaTheCoder/Era-Life-Community/blob/codex/shared-lives-portrait/docs/MOBILE-PORTRAIT.md),
[startup performance](https://github.com/miikaTheCoder/Era-Life-Community/blob/codex/shared-lives-portrait/docs/STARTUP-PERFORMANCE.md),
and [Android](https://github.com/miikaTheCoder/Era-Life-Community/blob/codex/shared-lives-portrait/docs/ANDROID.md).
Read the dated updates: older paragraphs describe superseded mobile builds.

## Leave the next task a usable handoff

Keep this guide aligned on both active branches when their locations, porting
workflow, or status changes. Record the target branch and commit, what changed,
checks actually run and their log locations, artifact path, unresolved failures,
and whether the exact APK was tested on a device. Put detailed feature evidence
in its owning document and link it here. A new task should be able to distinguish
implemented code, verified behavior, and remaining work without reading chat history.
