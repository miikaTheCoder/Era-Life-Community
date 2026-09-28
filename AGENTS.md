# Working in ERA-LIFE

## Writing rule: no em dashes

Never use em dashes (Unicode U+2014) in replies, documentation, comments, commit
messages, or other text you write. Use commas, periods, colons, parentheses, or
ordinary hyphens instead. Check your output and edited text before finishing.

## Start on the right branch

`main` is the current desktop game and the default for new tasks. `portrait` is
the phone version. Use the normal project folder for desktop work and the existing
Portrait worktree for phone work. Read [the agent handoff](docs/AGENT-HANDOFF.md)
and [branch workflow](docs/BRANCHES.md) before choosing a different checkout.

Check `git status --short --branch` and `git worktree list` first. Work directly
on the intended permanent branch for sequential work when its checkout is clean.
Create a temporary `codex/` branch only when isolation or concurrent work needs
one, starting from current `main` or `portrait`. Integrate completed work and
remove its temporary branch after checking that all commits are preserved.
Preserve another task's checkout and uncommitted changes. `browser-play` is an
active task owned separately; leave its branch and worktree alone until that task
is finished. Keep shared gameplay and platform presentation responsibilities clear.

## Continue from the roadmap

Use [ROADMAP.md](ROADMAP.md) when planning or choosing follow-up work. When working
on an item, record its status, task/branch, verification, and next action before
handoff. Keep the roadmap aligned on desktop and Portrait. Its proposed work does
not expand or override the user's current task.

## Find the owner first

- Read `docs/ARCHITECTURE.md` for responsibilities and common change paths.
- Use `docs/CODE-MAP.md` for the complete script inventory.
- Search with `python3 scripts/code_map.py crime` or
  `python3 scripts/code_map.py --symbols checkpoint restore`.
- Use `rg -n` and bounded reads inside large scripts. Do not dump `MainScene.gd`
  or `GameState.gd` into context to locate a method.

## Keep responsibilities clear

- `project/core/`: state, persistence, simulation scheduling, events, contracts,
  diagnostics shared by multiple gameplay systems.
- `project/systems/<feature>/`: gameplay rules and feature contract producers.
- `project/ui/panels/<feature>/` and `project/ui/viewers/`: controls that present
  contracts and dispatch actions. The visual theme lives in `project/ui/EraTheme.gd`.
- `project/ui/main/support/`: named static support modules for the legacy main
  scene. They take state explicitly; avoid reintroducing catch-all helper classes.
- `project/mods/`: existing mod loaders, registries, bundle and marketplace contracts.
- `project/integrations/`: network, AI and updater integration code.
- `project/platform/`: platform-specific behavior. `project/data/`: content and loading.

Preserve features, appearance, action IDs, signals and contract keys during
structural work. Many methods are called by strings or registered dynamically;
an absence of direct callers is not evidence that a method is unused. Do not
replace domain contracts with UI-local state. Prefer extending an existing owner
over adding another abstraction with the same responsibility.

Move `.gd.uid` files with scripts. Update literal resource paths and autoload paths
when moving files. Keep `scenes/MainScene.gd` at its current path while the binary
`scenes/main.scn` refers to it. Do not edit binary resources with text replacement.

## Verify changes

Use Godot **4.4.1 stable**, not the system version if it differs. Run:

```sh
python3 scripts/check-structure.py
python3 scripts/test-headless.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
```

The regression runner imports the project, gives each test an isolated XDG
profile, and retains logs in `build/tests/`. It accepts individual test stems;
use `--list` to discover them. Use the full suite for resource moves and shared
state/scene-support changes. For gameplay entry or scene changes, also run the
relevant graphical checks in `scripts/test-desktop-modes.sh`.

Do not edit `.godot/`, build artifacts, or generated code-map tables by hand.
Regenerate the map after adding, moving, renaming or changing the size of scripts.
Report test limitations and existing failures accurately; headless checks alone
do not establish visual or full-lifetime gameplay correctness.
