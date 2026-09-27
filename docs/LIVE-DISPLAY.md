# Live diary and balance refresh

Desktop R07 follow-up, 2026-09-27, commit `6d0deea` on
`codex/shared-lives-desktop`.
This repairs the live display issue found after the consecutive Age Up input fix.
R07's broader performance and lifetime checks remain separate.

## Reproduction and cause

A copy of the retained R07 Household checkpoint resumed at age 41 in 2006 with
$9,700. Two Age Up actions displayed 2007 and 2008. After a care choice, the diary
returned to the 2006 checkpoint text and the sidebar showed $10,000. The current
bank balance remained $9,700. No money or saved history was lost.

The checkpoint renderer always preferred its immutable Continue packet. It also
bypassed the normal diary setup, leaving the resumed scene disconnected from
`LifeDiaryContractEngine.diary_entry_committed`. Age Up's separate presentation
callback could append new years, but a later diary redraw replaced those additions.
The bank animation continued using its cached target, including a stale target
restored by the shell's presentation packets.

## Repair

The checkpoint packet still supplies the first Continue frame. The scene observes
the existing diary engine when it arrives, even if it is created after the first
playable frame. Its first live delta seeds the complete history when hydration
imported that history after subscription. Once the engine has this actor's diary,
the renderer reads it and uses the existing committed-entry handler. It does not create an engine to paint the
checkpoint. New entries use the existing incremental display path. Age Up avoids
adding a second heading when the diary signal already published that year.

The existing HUD animation observes the controlled actor's bank mirror, maintained
by BankEngine, including on frames restricted to rendering. It retains the current
animation behavior and waits while background hydration is active. It does not
change accounts, payments, diary entries, save schemas or yearly simulation.

## Verification

`tests/test_live_diary_display.gd` exercises the real MainScene display functions
with a small isolated state. It checks the initial checkpoint fallback, committed
new entries after late engine attachment and silent history import, returning to
Life from another tab, preserved history, duplicate headings and actual
BankEngine transfers and credits. The completed pre-fix run failed the diary and
balance assertions. Earlier fixture attempts with setup/cleanup errors are not
counted as valid regressions.

The graphical mode harness now compares rendered diary text and the displayed
balance with the current state after every completed year and cold Continue.
Living Households also checks after dismissing a real care response, the point
where the original display regressed.

All 23 regressions passed on the final repair in `build/tests/headless-c8vmvfvg`.
Structure, code-map and whitespace checks passed. The code-map generator now uses
an ordinary hyphen for unnamed classes, respecting the repository writing rule. An intermediate graphical run still missed a live diary update; it exposed the
late subscription case and is retained with the existing-checkpoint evidence.
It is not counted as a passing run. The subsequent existing-checkpoint run passed
2007 to 2009, including the boundaries choice, current rendered diary, $9,700
and a save with ten diary years and four care decisions. Evidence:
`build/r07-display/existing-household/restore-subscription.log`.
The fresh Household passed three consecutive years and saved in 2003. Its first
cold-Continue attempt missed the Age Up click (`restore-three.log`, empty age-up
result); this is retained separately from display assertions and not counted as
a passing continuation. The instrumented repeat completed 2004, 2005 and 2006,
including the $300 payment and two later care responses. Every visible-label
assertion passed. A separate final Continue preserved all seven diary years,
three decisions and $9,700, including the rendered labels. Normal Narrative
newborn entry also passed two consecutive years, current diary/balance checks
and save (`build/r07-display/narrative-two-years`). Screenshots were
inspected. Evidence: `build/r07-display/fresh-household-cycle` (`household.log`,
`restore-repeat.log`, `restore-final.log`, with `restore-three.log` retained as
the missed-click run). The missed click remains a separate input follow-up. Original evidence is retained in
`build/r07-display/reproduced-stale-display`; the clean pre-fix regression is
`build/r07-display/failing-display-regression`.

```sh
python3 scripts/test-headless.py
ERA_YEARS=3 bash scripts/test-living-households.sh household /tmp/eralife-live-display
ERA_YEARS=3 ERA_RUN_LABEL=restore-three bash scripts/test-living-households.sh restore /tmp/eralife-live-display
ERA_YEARS=0 ERA_RUN_LABEL=restore-final bash scripts/test-living-households.sh restore /tmp/eralife-live-display
```

This is desktop verification. Portrait still needs its own readiness work and
port. Resource cleanup warnings, native Windows/macOS checks and complete
birth-to-death playthroughs remain outside this repair.

## Packaged repair

`build/r07-display/EraLife-linux-x86_64.tar.gz` was exported with Godot 4.4.1 from
clean commit `6d0deea`. Its archive checksum passed. The extracted executable
passed `test_live_diary_display.gd` using its packaged MainScene and BankEngine.
The source stamp is in `build/r07-display/package/BUILD_INFO.txt`; the result is
`build/r07-display/package-live-display.log`. The general
`build/EraLife-linux-x86_64.tar.gz` contains this same build. These are local
artifacts, not a published release or a Portrait update.
