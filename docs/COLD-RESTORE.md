# R01: save, cold restart, Continue

R01 verified **2026-09-27** on desktop and in Portrait preview, against the
completion criteria in [ROADMAP.md](../ROADMAP.md). Phone testing and the separate
Portrait creation failures below remain open.

## Reproduction and repairs

The unmodified desktop gameplay at `c277a93` created, aged, and saved an isolated
Household life successfully. A second process reached the playable first frame,
then failed `Checkpoint hydration did not finish` after 90 seconds. Actor 1
remained at age 9, year 2001. Engine construction finished all 248 steps, but the
hydration queue retained all 12 items with `core_identity` at its head.

The controlled-actor invariant snapshot consumed more than the loader's 1 ms
budget. The next budget check then declined the actual loading work, repeatedly.
The loader now guarantees one bounded unit of progress once a slice is admitted.
Actor protection, chunk caps, and total-duration reporting remain active. The
regression deliberately makes the invariant snapshot exceed the live budget.

Continuing beyond that failure exposed a concurrent projection crash. Two cold
restore attempts crashed while UI projection workers accessed the runtime being
constructed and hydrated on the main thread. One logged a cross-thread node
notification error. The native core confirms a worker-thread crash, but the
official binary lacks symbols, so its exact native function is not established.
Checkpoint projections now execute through the existing bounded main-thread step
path. Other projection entry paths retain their existing scheduling.

The first complete business restore exposed a third problem: the compact save
contained the company bank account, but a nonempty partial save-contract registry
omitted its hydration contract. The company, cast, ownership, and history survived;
its reserves appeared as zero. The resolver now includes the compact checkpoint's
bank and diary owners when missing, preserving existing contracts. A partial-registry
regression reproduces the missing account before this repair.

The Portrait entry check found one additional presentation bug. Its early menu
can display the title before deferred identity discovery finishes. The saved life
became available in the contract, but the touch Continue button and prompt still
showed the earlier empty state. Portrait now refreshes those controls after
identity discovery. Its cold-restore harness enters through MobileBoot's
**Saved life & account** button and taps **Continue**, retaining the failing route
as a graphical regression.

## Repeatable checks

Use Godot 4.4.1 and a graphical display. Each command exits fully before starting
the next process. Use a fresh profile for creation, and retain it for Continue:

```sh
bash scripts/test-shared-lives.sh cycle /tmp/eralife-cold-example
# Existing isolated fixture:
bash scripts/test-shared-lives.sh restore /path/to/copied-test-profile
```

The restore harness compares saved identity, age/year, diary, world history,
relationships, story records, business cast, ownership, settlement history, and
personal/company bank accounts. Repeated same-year business servicing must leave
company balances and settlement history unchanged. It then ages and saves again
unless `ERA_YEARS=0` is selected. A final cold restore checks that second save.

Run the same commands in the Portrait worktree with `ERA_PORTRAIT=1`, and verify
the actual 420×900 viewport. This focused content harness retains its documented
drawer-navigation exclusion. It cannot close R02 or certify an Android device.

```sh
python3 scripts/check-structure.py
python3 scripts/test-headless.py
python3 scripts/code_map.py --write
python3 scripts/code_map.py --check
git diff --check
```

## Evidence in this task

- Original desktop timeout: `/tmp/eralife-r01-desktop-baseline-live/restore.log`.
  The pre-fix profile is preserved separately in
  `/tmp/eralife-r01-desktop-existing-fixture`.
- Starvation regression failed before the repair in `headless-orytz6f_` and passed
  afterward in `headless-wxe3pzmn`, alongside Shared Lives.
- Checkpoint projection thread regression passed in `headless-b_l5z6lr`.
- Partial-registry business regression failed before its repair in
  `headless-iq0o5eee`.
- Original business fixture: `/tmp/eralife-r01-shared-existing-fixture`, copied
  before any successful cold restore. Its saved personal funds are $8,800 and
  company reserves are $1,470.
- The original failing Household save passed Continue, age, and save after the
  progress and projection fixes (`restore-main-projection.log`).

All 19 desktop regressions passed with the final repairs in `headless-c0fg00yq`.
The original `a174e11` Household fixture also passed cold restore, age, and save
(`/tmp/eralife-r01-historical-household`). The pre-fix business fixture restored
$8,800 personal funds and $1,470 company reserves exactly, aged, and saved
(`/tmp/eralife-shared-4OhhF6/restore-bank-fixed.log`). Baseline profiles are retained
in `build/r01/desktop-existing-fixture` and `build/r01/desktop-business-existing-fixture`.

The fresh desktop cycle passed creation, save, cold Continue, age/save, and a
second cold Continue: $8,800 personal funds and $1,470 then $1,740 company reserves,
with the same actor, cast, ownership, relationships, and history. The second restore
performed no additional age-up or settlement. See `build/r01/desktop-fresh`.

The shared repair is desktop commit `e2424ff`, ported as Portrait `e538708`.
Portrait's title update and entry-menu regression are `74e8b07`. All 23 Portrait
regressions passed with that update in `headless-nux39kip`.

The original Portrait business fixture passed cold Continue, exact balance and
history comparisons, age 36 to 37, and save in a 420×900 viewport. Its failure
before the title repair and successful rerun are retained under
`build/r01/portrait-existing`; the original data is preserved in
`build/r01/portrait-existing-fixture`. Its second cold process restored age 37,
year 2002, diary entries, $8,800 personal funds, and $1,740 company reserves with
no extra age-up or settlement.

Two fresh Portrait creation attempts did not complete and are not counted as
passing: a world-preparation tap did not activate; a repeat showed blank, narrow
member buttons and exited without a completion marker. Their logs and screenshots
are retained in `build/r01/portrait-creation-missed-tap` and
`build/r01/portrait-creation-repeat`. R04 tracks this separate entry coverage gap.
The fresh desktop-generated fixture also passed Portrait's cold-Continue route:
age 37/year 2002, $8,800 personal funds and $1,740 company reserves restored
exactly; it then aged to 38/year 2003 and saved four diary entries. Evidence is in
`build/r01/portrait-new-checkpoint/restore-focused.log`. Its first attempt timed
out at MobileBoot; the repeat explicitly focused the test window. The timeout's
cause is not established, and that attempt is not counted as a pass.

These results use Godot 4.4.1 on Linux and Portrait's desktop preview. Phone
verification, the Portrait Back issue, full-lifetime play, and native
Windows/macOS checks remain separate roadmap work. Existing `snapshot_not_found`
diagnostics and resource cleanup warnings also remain; the passing runs did not
contain other Godot script or engine errors. Builds exported before these commits
do not contain the repairs.
