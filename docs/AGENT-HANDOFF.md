# EraLife desktop and Portrait: agent handoff

Last checked: **2026-09-28**. Read [AGENTS.md](../AGENTS.md), then
[ROADMAP.md](../ROADMAP.md) for priorities and [Architecture](ARCHITECTURE.md)
for ownership. This guide is shared by the two permanent branches.

## Start here

**Desktop `main` is the default for new tasks.** Use `portrait` only for phone
work. [Branch workflow](BRANCHES.md) records the policy and consolidation history.

| Target | Branch | Local checkout |
| --- | --- | --- |
| Desktop | `main` | `/home/nextg/opencode-sandbox/Era-Life-Community` |
| EraLife Portrait | `portrait` | `/home/nextg/.codex/worktrees/mobile-portrait/Era-Life-Community` |

`browser-play` is an active task in
`/home/nextg/Work/miikaTheCoder/Era-Life-Community-browser-play`. Its owner is
still working there. Leave that branch and worktree alone, including its
uncommitted files; it is excluded from this cleanup.

Desktop `main` contains verified integration `cffca1d`, including Shared Lives,
Living Households, R01, R07, and the eight upstream commits through `57ee128`.
Its 23 regressions, sequential cold Continue and Shared Lives save/load cycle
passed before promotion. Retain the concurrent-run hydration timeout described
in [integration evidence](UPSTREAM-SYNC-2026-09-28.md). This consolidation changes
branch organization and documentation, not gameplay or release artifacts.

`portrait` preserves the former Shared Lives phone branch at `d9628e8`, including
R01's shared port `e538708` and mobile Continue repair `74e8b07`. Desktop R05,
R07 and the latest upstream gameplay remain separate porting work. The latest
recorded desktop package is `6d0deea`, older than current `main`; Portrait R01
has not been repackaged. Do not describe old artifacts as builds of these tips.

Start in the checkout assigned to your task:

```sh
pwd
git status --short --branch
git worktree list
git log -5 --oneline
```

Both permanent branches track `origin`, the user's fork. `upstream` is the
original community project and is used for deliberate imports. Historical
feature branches named later in this guide or its linked evidence are not
current starting points. Use a temporary `codex/` branch only when isolation or
concurrent work needs it; integrate and retire it when the task is complete.
Preserve another task's checkout and uncommitted changes.

## What is shared, and what must stay platform-specific

The preferred sequence is **desktop gameplay first, then a tested Portrait port**.
Keep gameplay and content in the existing owners and adapt their UI contracts.

| Work | Owner / entry point |
| --- | --- |
| Authored stories and recurring cast | `project/data/life_stories.json`, `project/data/shared_lives.json`, desktop `project/data/living_households.json`, `project/systems/narrative/LifeStoryEngine.gd` |
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

Desktop R05 adds **Living Households**, a recurring care/work story and an
inherited family memory, with 11 chapters and 30 responses. See
[LIVING-HOUSEHOLDS.md](LIVING-HOUSEHOLDS.md) for eligibility, scope and evidence.
This pack and its engine additions are not on Portrait yet; port them under R06.

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
bash scripts/test-shared-lives.sh cycle /tmp/eralife-new-cold-test
# Desktop R05 only, until the verified Portrait port:
bash scripts/test-living-households.sh cycle /tmp/eralife-care-cold-test
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
- The earlier on-device God Mode → Begin Life crash remains R03. R01's cold
  Continue repairs passed desktop and Portrait preview checks, but have not been
  packaged or retested on the Honor phone. Prior phone measurements apply only
  to their recorded builds.
- New Portrait Household creation checks did not complete: one missed world
  preparation; another showed blank, narrow member buttons. R04 retains these
  failures separately from the successful cold-Continue route.
- The R05 second-click failure is repaired on desktop: navigation refreshes no
  longer cancel held input. R07 passed three consecutive years before and after
  cold Continue, plus a two-year Narrative route. See [input evidence](AGE-UP-INPUT.md).
  Portrait has not received this input repair. Broader lifetime checks remain open.
- The desktop live diary/balance repair is verified at `6d0deea`: all 23
  regressions pass, as do visible-label checks after years, care choices and cold
  Continue. See [display evidence](LIVE-DISPLAY.md). Portrait has not received it.
- One fresh-Continue test missed its first Age Up click without starting a command.
  The original 2003 checkpoint passed a traced repeat even before the follow-up
  fix. Two other focus resets in navigation rebinding and Continue destination
  publication were reproduced and repaired; all 23 desktop regressions pass.
  The smoke harness now retains click signals, focus and geometry. Keep the
  original miss unconfirmed until a matching live trace identifies its cause.
  See [first-click investigation](AGE-UP-INPUT.md#first-click-investigation-and-remaining-focus-resets).
- `snapshot_not_found` diagnostics and shutdown resource warnings remain.
- Native Windows/macOS checks and complete birth-to-death playthroughs are not
  established by the Linux/Portrait checks above.

R01 evidence: desktop 19/19 regressions (`headless-c0fg00yq`) and Portrait 23/23
(`headless-nux39kip`), plus separate-process Continue, age/save, and another cold
Continue with exact personal/company balances and history checks. See
[cold-restore validation](COLD-RESTORE.md) for fixtures, repairs, and retained logs.

Desktop R04 readiness is verified and packaged at `8ccfd37`; see
[Shared Lives readiness](SHARED-LIVES-READINESS.md). Desktop R05 is verified at
`c02f528`: all 21 regressions (`headless-c2aa11j9`), three complete family routes,
a later-life memory, five graphical years with saves between processes and a
final cold Continue. The clean Linux export and packaged content hashes passed.
See [Living Households](LIVING-HOUSEHOLDS.md) for retained fixtures and limits.
The subsequent desktop input repair at `28a4030` passes all 22 regressions,
consecutive-year graphical checks and the packaged input regression. See
[Age Up input](AGE-UP-INPUT.md). Its display follow-up is now verified at
`6d0deea`, with all 23 regressions and the fresh Household 3 + Continue + 3 +
Continue route passing. The visible diary and $9,700 balance match the saved
state. See [live display](LIVE-DISPLAY.md) for evidence and the separate missed click.
The subsequent focus follow-up `c10ac54` passes all 23 regressions and repeated
cold Continue with four more Household years, care choices and exact final restore.
It preserves focus during rebinding and destination publication. The original
one-off miss did not recur before or after the fix and remains unconfirmed.
The next platform step is R06 after Portrait readiness; no R05 gameplay was
copied to the Portrait checkout in this task.

Start follow-up investigations with [Shared Lives](SHARED-LIVES.md),
[desktop gameplay](DESKTOP-GAMEPLAY.md), and
[organization validation](ORGANIZATION-VALIDATION.md). Portrait-specific history
lives on the Portrait branch:
[Portrait UI](https://github.com/miikaTheCoder/Era-Life-Community/blob/portrait/docs/MOBILE-PORTRAIT.md),
[startup performance](https://github.com/miikaTheCoder/Era-Life-Community/blob/portrait/docs/STARTUP-PERFORMANCE.md),
and [Android](https://github.com/miikaTheCoder/Era-Life-Community/blob/portrait/docs/ANDROID.md).
Read the dated updates: older paragraphs describe superseded mobile builds.

## Leave the next task a usable handoff

Keep this guide aligned on both active branches when their locations, porting
workflow, or status changes. Record the target branch and commit, what changed,
checks actually run and their log locations, artifact path, unresolved failures,
and whether the exact APK was tested on a device. Put detailed feature evidence
in its owning document and link it here. A new task should be able to distinguish
implemented code, verified behavior, and remaining work without reading chat history.
