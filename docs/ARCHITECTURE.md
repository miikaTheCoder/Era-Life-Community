# Architecture and ownership

ERA-LIFE is a Godot 4.4.1 project reconstructed from a packaged game. Its names
and contracts carry useful compatibility information, even where implementations
remain large. The layout groups that existing code by responsibility; it does
not replace the game's feature model.

Use the [generated code map](CODE-MAP.md) for every script and class. To find a
function, use the live index instead of reading a whole subsystem:

```sh
python3 scripts/code_map.py crime
python3 scripts/code_map.py --symbols extortion
python3 scripts/code_map.py --symbols MainScene _ready
python3 scripts/code_map.py --symbols checkpoint restore --limit 0
```

Results use `path:line` locations. Queries are case-insensitive and require all
words to match the path or symbol. Exact symbol matches appear first. The index
reads source directly, so it works before importing Godot.

## Repository layout

| Location | Responsibility |
| --- | --- |
| `project/core/state/` | `GameState`, its contract authority and hydration runtime |
| `project/core/persistence/` | Save/load, serialization, snapshots, checkpoints and continuity |
| `project/core/simulation/` | Year scheduling, phase budgets, runtime admission and prewarming |
| `project/core/events/` | Event bus, event types, action discovery and intent routing |
| `project/core/contracts/` | Shared contract registries, capabilities, truth and observability primitives |
| `project/core/diagnostics/` | Logging, fault routing, health checks and patch guards |
| `project/systems/<feature>/` | Gameplay implementation and the contracts it publishes |
| `project/ui/` | Theme, interface adapter, shell and brand drawing |
| `project/ui/common/` | Shared UI contracts, card support and panel base |
| `project/ui/panels/<feature>/` | Feature-specific panels; locate the corresponding rules in `systems/` |
| `project/ui/viewers/` | Life, God Mode, population, popup and property viewers |
| `project/ui/main/support/` | Static scene-support functions grouped by subject |
| `project/scenes/` | Scene resources, main scene coordinator and mobile bootstrap |
| `project/platform/mobile/` | Mobile detection, input adaptation and scrolling |
| `project/mods/` | Mod loading, bundles, menus and marketplace contracts |
| `project/integrations/` | Network/account, updater and AI boundaries |
| `project/data/` | Data loading, names, NPC factory and authored content |
| `project/audio/`, `project/branding/` | Audio implementation/assets and brand assets |
| `tests/` | Focused Godot regressions and desktop/mobile smoke harnesses |
| `scripts/` | Toolchain setup, exports, test runners and repository navigation |
| `docs/` | Architecture, gameplay checks, design notes and release guidance |
| `build/` | Ignored toolchain, test profiles, logs and exported builds |
| `third_party/` | Dependency notices |

## Where to make a change

| Task | Start here | Related checks |
| --- | --- | --- |
| Change colors, typography or layout | `ui/EraTheme.gd`, `ui/EraInterface.gd`, `ui/EraShell.gd` | `test_ui_presentation`, desktop smoke |
| Change a feature's rules | `systems/<feature>/`; its panel is under `ui/panels/` | Corresponding feature regressions |
| Change crime factions, territory or extortion | `systems/crime/CrimeWorldEngine.gd`, `CrimeHubContractEngine.gd`, `ui/panels/crime/CrimePanel.gd` | `test_crime_world`, `test_crime_target_refresh` |
| Change age-up processing | `core/simulation/AgeUpRuntimeEngine.gd`, `SimulationDirector.gd`, `YearBudgetEngine.gd` | `test_year_scheduler`, `test_year_diary`, desktop smoke |
| Change event delivery | `core/events/EventBus.gd`, `EventBusContractLayer.gd` | `test_event_bus_deferred` |
| Change save/load or hydration | `core/persistence/`, `core/state/GameStateHydrationRuntime.gd` | `test_checkpoint_*`, `test_mode_checkpoint`, `test_residency_projection_convergence` |
| Change narrative choices | `systems/narrative/`, `ui/panels/narrative/` | `test_narrative`, desktop smoke |
| Change menu/household/God Mode entry | `scenes/MainScene.gd`, `ui/main/support/CreationSceneSupport.gd`, `systems/characters/FamilyCreationContractEngine.gd` | `test_mode_checkpoint`, desktop smoke |
| Change scene formatting or queries | Named module under `ui/main/support/` | Full headless suite and affected scene flow |
| Change mobile input | `platform/mobile/`, `scenes/MobileBoot.gd` | `test_mobile`, `test_mobile_scroll` |
| Change mod admission | `mods/ModLoader.gd`, `ModBundleContractEngine.gd`, `core/state/GameStateContractEngine.gd` | Full headless suite and affected mod flow |
| Change release behavior | `integrations/updates/`, `project.godot`, `scripts/build.sh` | `test_release_channel`, export/import checks |

Paths in this table are relative to `project/` except `scripts/` and test names.
Pass test names individually to `python3 scripts/test-headless.py`; the runner's
arguments are literal stems, not wildcard patterns.

## Runtime boundaries

`project.godot` starts `scenes/main.scn` on desktop and `scenes/mobile_boot.tscn`
on Android. Network and updater autoload names remain unchanged; their scripts
live under `integrations/`.

The main scene coordinates the UI and a `GameState`. The state creates and owns
the domain engines. `SimulationDirector` schedules runtime phases and
`AgeUpRuntimeEngine` services year advancement. Engines publish contracts that
panels/viewers display; actions return through the existing intent and event
routes. Persistence and residency work must preserve the authoritative state
while these UI projections are being updated.

These are ownership guidelines, not an enforced one-way import graph. The
reconstructed code still has cross-domain dependencies and dynamic method calls.
Before moving behavior, inspect the actual callers, registered method strings,
signals and shared dictionaries.

## Scene support

The former `MainSceneHelpers` and `MainSceneLogic` classes have been replaced by
28 named classes under `ui/main/support/`. Their 881 static functions retain
their names, signatures, default arguments and implementations. Only the owning
class and static call targets changed. There are no forwarding compatibility
classes to maintain alongside the new owners.

For example, boxing presentation and queries are in `BoxingSceneSupport.gd`,
relationship details in `RelationshipsSceneSupport.gd`, intro content generation
in `IntroContentSceneSupport.gd`, and diary support in `DiarySceneSupport.gd`.
These modules can include UI construction and mutations on explicitly supplied
state; they are not all pure functions. They do not own the main scene's fields.

Add feature rules to the relevant system. Add scene-specific formatting or
adaptation to the matching support module. Avoid growing another generic
`Helpers`, `Logic`, or `Utils` class with unrelated responsibilities.

## Remaining structural debt

`MainScene.gd` still contains over 226,000 lines and owns many UI fields,
callbacks, deferred jobs and observation queues. `GameState.gd` remains large
too. Splitting those stateful responsibilities needs focused lifecycle and
ownership work; cutting them into an inheritance chain or routing all fields
through a generic host object would only relocate the coupling.

The next extraction candidates are the intro/menu controller, household creator,
main-tab presentation, and age-up presentation. Each should own its controls and
teardown, retain the existing signal/action behavior, and be exercised through
the corresponding desktop route before proceeding to the next component.

Two older resource lookup issues also remain: the optional minigame pack is
requested from a missing `MiniGameEcosystem/` path, and the contract-view fallback
tries several historical folders after global-class lookup. The organization
pass preserves those behaviors; repairing them may change feature admission and
needs separate coverage. Dynamic lookup strings are not all statically verifiable.

The graphical cold-restore test also exposes a checkpoint hydration timeout that
was reproduced on the original code. See [organization validation](ORGANIZATION-VALIDATION.md)
for the comparison, passing routes and limits before changing the restore lifecycle.

## Validation and maintenance

```sh
python3 scripts/check-structure.py
python3 scripts/test-headless.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
./scripts/test-desktop-modes.sh household
```

The headless runner requires the pinned Godot 4.4.1 editor, imports before testing,
uses separate save/config/cache directories per script, and checks both exit
status and logs. It supplies `--mobile-preview` to the mobile regressions. A
timeout or missing PASS marker fails the run. Results stay in `build/tests/`.
The existing resource-at-shutdown warning is tolerated explicitly; script errors
and other engine errors are not.

The graphical harness requires a desktop display and records its own profile,
screenshots and log. See [desktop gameplay validation](DESKTOP-GAMEPLAY.md) for
additional modes and longer runs. Native Windows/macOS checks remain separate.

Move `.gd.uid` files with their scripts, update resource literals and autoload
paths, and regenerate the code map. A clean Godot import is required after
reorganization; cached global class registrations are not validation.
