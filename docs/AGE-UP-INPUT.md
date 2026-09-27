# Consecutive Age Up input

Desktop R07 investigation, 2026-09-27, on `codex/shared-lives-desktop`.
This addresses the second-click failure recorded during R05. It does not close
R07's broader startup, memory or lifetime-performance work.

## Reproduction and cause

In a fresh Household, the first Age Up advanced 2000 to 2001 and completed every
required yearly phase. The second click reached the same visible button. The
button emitted `button_down`, then `button_up` about eight milliseconds later
while the left mouse button was still held. It never emitted `pressed`, so no
second age-up command was submitted. The simulation was idle and the normal
transition guards were clear.

The first hover refresh set the button's focus mode to `FOCUS_NONE`. The desktop
presentation adapter subsequently restored `FOCUS_ALL`. A repeated click at the
same position therefore acquired focus, which the next navigation refresh removed.
Godot cancels a held button press on that focus loss. The failure depended on UI
refresh timing and was not a stalled yearly simulation.

The focused regression invokes the real MainScene navigation refresh between
mouse-down and mouse-up. It reproduced the lost second command and the equivalent
keyboard failure before the change. It uses an isolated UI fixture without world
generation. The graphical trace independently reproduced the live failure twice.

## Repair

Visible navigation buttons retain `FOCUS_ALL` during registration, rebinding,
presentation updates and playable-surface restoration. Hidden or disabled controls
retain their existing visibility, input and focus restrictions. Action IDs, pressed
signals, duplicate-command guards, yearly scheduling and saved data are unchanged.

`tests/test_navigation_input.gd` checks repeated held mouse clicks, keyboard
activation, exactly one command per action and hidden-navigation behavior. The
existing presentation checks also pass. A fresh graphical household advanced
three consecutive years without restarting.
After cold Continue it advanced three more consecutive years, including the
care request, paid help, next-year review and later boundary choice. Each year ran
the health, school/career and diary phases, and the session saved all three care
decisions.

## Reproduce the checks

Use Godot 4.4.1 stable and fresh isolated profiles:

```sh
python3 scripts/test-headless.py test_navigation_input test_ui_presentation
ERA_YEARS=3 bash scripts/test-living-households.sh household /tmp/eralife-age-input
ERA_YEARS=3 ERA_RUN_LABEL=restore-three bash scripts/test-living-households.sh restore /tmp/eralife-age-input
ERA_YEARS=0 ERA_RUN_LABEL=restore-final bash scripts/test-living-households.sh restore /tmp/eralife-age-input
ERA_YEARS=2 bash scripts/test-desktop-modes.sh narrative-family /tmp/eralife-age-narrative
python3 scripts/test-headless.py
```

A focused passing run is `build/tests/headless-9_dvu8r8`; the valid failing
regression before the fix is `build/tests/headless-adsvqcw1`. All 22 regressions
passed in `build/tests/headless-abdhmb2m`. The graphical Household cycle passed
creation, three consecutive years, save, cold Continue, three further consecutive
years, save and final cold Continue. That final checkpoint retained age 41/year
2006, seven diary years, $9,700 personal funds and three household care decisions.
Screenshots were inspected; the live display caveat below is separate from input
and saved-state correctness. The ordinary Narrative newborn route also passed
two consecutive years and saved at age two in 1895.

Retained local evidence: `build/r07/household-three-plus-three`,
`build/r07/narrative-two-years`, `build/r07/reproduced-input-failure`,
`build/r07/reproduced-held-release` and `build/r07/initial-entry-failure`.
Structure, code-map and whitespace checks passed.

One initial fresh-entry diagnostic run missed the Household entry before reaching
Age Up. It is retained separately and is not counted as an Age Up reproduction or
a passing creation test. Resource cleanup warnings and long lifetime limits remain.
The focus repair is desktop-only until separately ported and checked in Portrait.

## Follow-up: live display refresh

After the continued session reached 2006, the header and year footer were current,
but the live diary still showed the 2003 checkpoint text and the sidebar showed
$10,000. The authoritative bank held $9,700 and the saved diary contained all seven
years; final cold Continue restored that exact state successfully. Investigate the
live diary and balance projections after continued gameplay. This input repair
did not resolve that separate issue. The subsequent [live display repair](LIVE-DISPLAY.md)
contains its cause, fix and verification. Neither check certifies an entire life.


## Packaged repair

The local Linux archive `build/r07/EraLife-linux-x86_64.tar.gz` was exported with
Godot 4.4.1 from clean commit `28a4030`. The archive checksum passed, and the
extracted executable passed `test_navigation_input.gd` against its packaged
MainScene. The source stamp and result are retained in `build/r07/package/BUILD_INFO.txt`
and `build/r07/package-navigation.log`. This replaces the older R05 archive for
local desktop playtesting; it does not publish a release or update Portrait.

The newer [live-display package](LIVE-DISPLAY.md) at `6d0deea` includes this
input repair and supersedes this archive for current desktop playtesting.
