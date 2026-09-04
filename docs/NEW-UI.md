# Era Life: life journal interface

The `era-life-new-ui` branch gives the reconstructed game a permanent dark theme,
neon light-blue controls, and a journal-oriented desktop layout. Gameplay
actions, entry contracts, and checkpoint formats retain their existing ownership.

## Design

- Graphite canvas `#101214`, panel `#191d20`, raised surface `#242b30`.
- Cool white text `#edf5fa`, secondary text `#a8bac5`, cyan actions `#66dbff`.
- Blue button fills `#102c39`, luminous borders, and stronger hover/selection glow.
- Ice-blue keyboard focus `#d4f5ff`; amber year markers and muted red for danger.
- Blue stat fills and slider tracks coordinate with the controls. Critical health
  retains a red warning. Disabled actions have muted borders and no glow.
- Bundled Liberation Sans for controls and prose; Liberation Serif for display
  headings. Font redistribution terms are included in `project/ui/fonts/LICENSE.txt`.
- Branching paths on the start menu represent the three ways to enter a life.

The start menu becomes a single scrollable column below 960 logical pixels.
Gameplay uses a character rail, a horizontal navigation row, a large scrolling
journal, labeled activity shortcuts, and a persistent Age Up footer. Below 1000
pixels, Character opens the stats rail and navigation scrolls horizontally.
Desktop density stays at native size through 1920×1080, with scaling for larger
displays, instead of shrinking the entire interface to a fixed reference stage.

God Mode keeps preparation and entry controls outside its scrolling form. Menu
bobbing, title glitches, household light sweeps, and glowing year text are removed.
Selected navigation has a visible underline; keyboard focus uses a separate bright
outline. Menu cards illuminate when their action is hovered or keyboard-focused.
Disabled gameplay actions remain disabled. Glow is static, without pulsing or
moving hit targets.

## Implementation

- `project/ui/EraTheme.gd`: palette, bundled typography, and shared control states.
- `project/ui/EraInterface.gd`: observes controls as they enter the tree and
  coalesces subsequent theme changes. This adapts legacy contract panels which
  continue to install their own local overrides. It copies style resources instead
  of mutating assets shared with gameplay renderers, and does not scan the full
  scene tree every frame. Embedded windows receive the same theme.
- `project/ui/EraShell.gd`: entry cards, responsive menu, gameplay layout, and
  read-only identity/year presentation. Existing buttons retain their signals.
- `project/ui/EraBranchMark.gd`: resolution-independent menu illustration.

New controls inherit the theme. Use `era_primary` for primary buttons and
`era_selected` for selection driven by a contract rather than a toggle button.
`era_owned` opts a custom control out of the legacy adapter; such a control must
apply the shared design tokens itself. No theme preference is stored in saves.

## Verification

Use the pinned Godot 4.4.1 runtime after importing `project/project.godot`.
All runtime tests should use isolated XDG data, configuration, and cache folders.

```sh
XDG_DATA_HOME=/tmp/era-ui/data XDG_CONFIG_HOME=/tmp/era-ui/config \
XDG_CACHE_HOME=/tmp/era-ui/cache \
build/tools/godot-4.4.1/Godot_v4.4.1-stable_linux.x86_64 \
  --headless --path project --script ../tests/test_ui_presentation.gd

ERA_UI_GALLERY=1 bash scripts/test-desktop-modes.sh god /tmp/era-ui-god-fresh
ERA_EXPLORE=1 bash scripts/test-desktop-modes.sh household /tmp/era-ui-household-fresh
```

`test_ui_presentation.gd` checks late theme replacement, shared-resource isolation,
disabled action preservation, keyboard activation, selected states, embedded
window theming, and menu bounds at 480, 768, 1440, and 1920 logical pixels.
`ERA_UI_GALLERY=1` adds gameplay captures and layout assertions at 768×1024,
1280×800, and 1920×1080 to the desktop smoke harness. These change the logical
viewport for inspection; the window manager can still determine the physical
screenshot size. The harness also captures the title and God Mode form.

Graphical creation, aging, and saving have been exercised in Household, God Mode,
and both Narrative entry routes. School, Career, and Relationships are included in
the household exploration pass. Focused narrative, checkpoint, diary, mobile
support, and presentation regressions are also checked. Native Windows/macOS and
Android device playtesting are not part of this change.

One test household restores its initial visible actor but times out waiting for
background checkpoint hydration. The same save reproduces the timeout in an
isolated copy of the original `main` commit, without this UI. This is an existing
restore limitation, not a passing restore certification. Existing Godot shutdown
resource warnings remain.
